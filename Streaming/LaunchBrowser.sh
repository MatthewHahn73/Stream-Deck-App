#!/bin/bash

LINK="$1"
DIR=$(cd "$(dirname "${BASH_SOURCE}")" && pwd)
source "${DIR}/Config/Streaming.conf"
"/usr/bin/flatpak" run ${FLATPAKOPTIONS} ${BROWSERAPP} @@u @@ ${BROWSEROPTIONS} ${LINK}
