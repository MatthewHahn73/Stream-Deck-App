"""
AutoInstall.py

Current Bugs
    -Steam doesn't populate the non-steam games with the right artwork. 
        -Steamgriddb picks a different appid
            -Still doesn't load some of the artwork? Only the icon

TODO
    -Need to add in better documentation of current script progress and exception handling
    -Need to better optimize the GrabAndSetArtworkForGivenAppIDs function 
"""

import os, json, logging, random, binascii, struct
import Modules.VDF as vdf
from urllib.request import Request, urlopen

GlobalLogger = logging.getLogger()
GlobalLogger.setLevel(logging.DEBUG)

User = os.getlogin()
MainDirectory = os.path.abspath(os.path.join(os.path.dirname(__file__), '..')) + "/Streaming App/"
StreamingAppLocation = "/home/" + User + "/Streaming/"
SteamUserData = "/home/" + User + "/.steam/steam/userdata/"
PathToUserConfig = SteamUserData + os.listdir(SteamUserData)[0] + "/config/grid/"
PathToSteamShortcutsFile = SteamUserData + os.listdir(SteamUserData)[0] + "/config/shortcuts.vdf"

#Generates an APPID
def GenerateAppID(exe_path: str, app_name: str) -> int:
    unique_string = exe_path + app_name
    crc32_value = binascii.crc32(unique_string.encode()) & 0xFFFFFFFF
    return crc32_value

#Queries steamdb for the artwork for each given streaming service and creates the file in the <User ID>/config/grid directory of the steam user
def GrabAndSetSteamArtwork():
    ShortcutsDict = vdf.binary_load(open(PathToSteamShortcutsFile, "rb"))

    for Shortcut in ShortcutsDict["shortcuts"]:
        AppID = ShortcutsDict["shortcuts"][Shortcut]["appid"]
        print(AppID)
    
#Updates the steam shortcuts.vdf file with the new Stream Deck application
def GenerateStreamDeckVdfEntry():
    PathToDirectory = "/home/" + User + "/Streaming/Streaming App/"
    PathToScript = PathToDirectory + "Streaming Services App.x86_64"

    if not os.path.exists(PathToSteamShortcutsFile):
        logging.info("Creating new shortcut file at '" + PathToSteamShortcutsFile + "'")
        with open(PathToSteamShortcutsFile, "wb") as NewlyCreatedShortcutsFile:
            NewlyCreatedShortcutsFile.write(b'\x00' + b'shortcuts' + b'\x00\x08\x08')
        NewlyCreatedShortcutsFile.close()

    logging.info("Appending new shortcut to '" + PathToSteamShortcutsFile + "' ...")
    ShortcutsDict = vdf.binary_load(open(PathToSteamShortcutsFile, "rb"))
    CurrentIteration = len(ShortcutsDict["shortcuts"])

    AppName = "Stream Deck"
    ExecutablePath = '"' + PathToScript + '"'
    IconPath = "/home/" + User + "/Streaming/Streaming App/Artwork/SteamDeckIcon.png"
    AppID = GenerateAppID(AppName, ExecutablePath)

    ShortcutsDict["shortcuts"][str(CurrentIteration + 1)] = {
        "appid" : AppID,
        "AppName" : AppName,
        "Exe" : ExecutablePath,
        "StartDir" : '"' + PathToDirectory + '"',
        "icon" : IconPath,
        "ShortcutPath" : "",
        "LaunchOptions" : "",
        "IsHidden" : 0,
        "AllowDesktopConfig" : 1,
        "AllowOverlay" : 1,
        "OpenVR" : 0,
        "Devkit" : 0,
        "DevkitGameID" : "",
        "DevkitOverrideAppID" : 0,
        "LastPlayTime" : 0,
        "FlatpakAppID" : "",
        "tags" : {}
    }

    ShortcutsDictParsed = vdf.binary_dump(ShortcutsDict, open(PathToSteamShortcutsFile, "wb"))
        
if __name__ == "__main__":
    #logging.info("Installing the app in '" + StreamingAppLocation + "' ...")
    os.makedirs("/home/" + User + "/Streaming/")
    os.system("cp -a '" + MainDirectory + "' '" + StreamingAppLocation + "'")

    GenerateStreamDeckVdfEntry()
    GrabAndSetSteamArtwork()
