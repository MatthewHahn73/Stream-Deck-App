"""
Module for deserializing/serializing to and from VDF
"""

import re
import sys
import struct
from binascii import crc32
from io import BytesIO
from io import StringIO as unicodeIO

try:
    from collections.abc import Mapping
except:
    from collections import Mapping

# Py2 & Py3 compatibility
if sys.version_info[0] >= 3:
    string_type = str
    int_type = int
    BOMS = '\ufffe\ufeff'

    def strip_bom(line):
        return line.lstrip(BOMS)
else:
    from StringIO import StringIO as strIO
    string_type = basestring
    int_type = long
    BOMS = '\xef\xbb\xbf\xff\xfe\xfe\xff'
    BOMS_UNICODE = '\\ufffe\\ufeff'.decode('unicode-escape')

    def strip_bom(line):
        return line.lstrip(BOMS if isinstance(line, str) else BOMS_UNICODE)

BIN_NONE        = b'\x00'
BIN_STRING      = b'\x01'
BIN_INT32       = b'\x02'
BIN_FLOAT32     = b'\x03'
BIN_POINTER     = b'\x04'
BIN_WIDESTRING  = b'\x05'
BIN_COLOR       = b'\x06'
BIN_UINT64      = b'\x07'
BIN_END         = b'\x08'
BIN_INT64       = b'\x0A'
BIN_END_ALT     = b'\x0B'

class BASE_INT(int_type):
    def __repr__(self):
        return "%s(%d)" % (self.__class__.__name__, self)

class UINT_64(BASE_INT):
    pass

class INT_64(BASE_INT):
    pass

class POINTER(BASE_INT):
    pass

class COLOR(BASE_INT):
    pass

def _binary_dump_gen(obj, level=0, alt_format=False):
    if level == 0 and len(obj) == 0:
        return

    int32 = struct.Struct('<i')
    uint64 = struct.Struct('<Q')
    int64 = struct.Struct('<q')
    float32 = struct.Struct('<f')

    for key, value in obj.items():
        if isinstance(key, string_type):
            key = key.encode('utf-8')
        else:
            raise TypeError("dict keys must be of type str, got %s" % type(key))

        if isinstance(value, Mapping):
            yield BIN_NONE + key + BIN_NONE
            for chunk in _binary_dump_gen(value, level+1, alt_format=alt_format):
                yield chunk
        elif isinstance(value, UINT_64):
            yield BIN_UINT64 + key + BIN_NONE + uint64.pack(value)
        elif isinstance(value, INT_64):
            yield BIN_INT64 + key + BIN_NONE + int64.pack(value)
        elif isinstance(value, string_type):
            try:
                value = value.encode('utf-8') + BIN_NONE
                yield BIN_STRING
            except:
                value = value.encode('utf-16') + BIN_NONE*2
                yield BIN_WIDESTRING
            yield key + BIN_NONE + value
        elif isinstance(value, float):
            yield BIN_FLOAT32 + key + BIN_NONE + float32.pack(value)
        elif isinstance(value, (COLOR, POINTER, int, int_type)):
            if isinstance(value, COLOR):
                yield BIN_COLOR
            elif isinstance(value, POINTER):
                yield BIN_POINTER
            else:
                yield BIN_INT32
            yield key + BIN_NONE
            yield int32.pack(value)
        else:
            raise TypeError("Unsupported type: %s" % type(value))

    yield BIN_END if not alt_format else BIN_END_ALT


def binary_dump(obj, fp, alt_format=False):
    """
    Serialize ``obj`` to a binary VDF formatted ``bytes`` and write it to ``fp`` filelike object
    """
    if not isinstance(obj, Mapping):
        raise TypeError("Expected obj to be type of Mapping")
    if not hasattr(fp, 'write'):
        raise TypeError("Expected fp to have write() method")

    for chunk in _binary_dump_gen(obj, alt_format=alt_format):
        fp.write(chunk)

def binary_load(fp, mapper=dict, merge_duplicate_keys=True, alt_format=False, raise_on_remaining=False):
    """
    Deserialize ``fp`` (a ``.read()``-supporting file-like object containing
    binary VDF) to a Python object.

    ``mapper`` specifies the Python object used after deserializetion. ``dict` is
    used by default. Alternatively, ``collections.OrderedDict`` can be used if you
    wish to preserve key order. Or any object that acts like a ``dict``.

    ``merge_duplicate_keys`` when ``True`` will merge multiple KeyValue lists with the
    same key into one instead of overwriting. You can se this to ``False`` if you are
    using ``VDFDict`` and need to preserve the duplicates.
    """
    if not hasattr(fp, 'read') or not hasattr(fp, 'tell') or not hasattr(fp, 'seek'):
        raise TypeError("Expected fp to be a file-like object with tell()/seek() and read() returning bytes")
    if not issubclass(mapper, Mapping):
        raise TypeError("Expected mapper to be subclass of dict, got %s" % type(mapper))

    # helpers
    int32 = struct.Struct('<i')
    uint64 = struct.Struct('<Q')
    int64 = struct.Struct('<q')
    float32 = struct.Struct('<f')

    def read_string(fp, wide=False):
        buf, end = b'', -1
        offset = fp.tell()

        # locate string end
        while end == -1:
            chunk = fp.read(64)

            if chunk == b'':
                raise SyntaxError("Unterminated cstring (offset: %d)" % offset)

            buf += chunk
            end = buf.find(b'\x00\x00' if wide else b'\x00')

        if wide:
            end += end % 2

        # rewind fp
        fp.seek(end - len(buf) + (2 if wide else 1), 1)

        # decode string
        result = buf[:end]

        if wide:
            result = result.decode('utf-16')
        elif bytes is not str:
            result = result.decode('utf-8', 'replace')
        else:
            try:
                result.decode('ascii')
            except:
                result = result.decode('utf-8', 'replace')

        return result

    stack = [mapper()]
    CURRENT_BIN_END = BIN_END if not alt_format else BIN_END_ALT

    for t in iter(lambda: fp.read(1), b''):
        if t == CURRENT_BIN_END:
            if len(stack) > 1:
                stack.pop()
                continue
            break

        key = read_string(fp)

        if t == BIN_NONE:
            if merge_duplicate_keys and key in stack[-1]:
                _m = stack[-1][key]
            else:
                _m = mapper()
                stack[-1][key] = _m
            stack.append(_m)
        elif t == BIN_STRING:
            stack[-1][key] = read_string(fp)
        elif t == BIN_WIDESTRING:
            stack[-1][key] = read_string(fp, wide=True)
        elif t in (BIN_INT32, BIN_POINTER, BIN_COLOR):
            val = int32.unpack(fp.read(int32.size))[0]

            if t == BIN_POINTER:
                val = POINTER(val)
            elif t == BIN_COLOR:
                val = COLOR(val)

            stack[-1][key] = val
        elif t == BIN_UINT64:
            stack[-1][key] = UINT_64(uint64.unpack(fp.read(int64.size))[0])
        elif t == BIN_INT64:
            stack[-1][key] = INT_64(int64.unpack(fp.read(int64.size))[0])
        elif t == BIN_FLOAT32:
            stack[-1][key] = float32.unpack(fp.read(float32.size))[0]
        else:
            raise SyntaxError("Unknown data type at offset %d: %s" % (fp.tell() - 1, repr(t)))

    if len(stack) != 1:
        raise SyntaxError("Reached EOF, but Binary VDF is incomplete")
    if raise_on_remaining and fp.read(1) != b'':
        fp.seek(-1, 1)
        raise SyntaxError("Binary VDF ended at offset %d, but there is more data remaining" % (fp.tell() - 1))

    return stack.pop()
