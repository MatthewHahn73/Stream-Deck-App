"""
AutoInstall.py

Author: https://github.com/MatthewHahn73

Creates a steam shortcut for the 'Stream Deck' application and populates the shortcut with the right artwork

Uses portions of the VDF module for modifications to shortcuts.vdf
Required sections imported locally to prevent having to install the vdf module on the steam deck
Credit: https://github.com/ValvePython/vdf
"""

import os, time, binascii
import Modules.VDF as vdf

USER = os.getlogin()
MAINDIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), '..')) + "/Streaming App/"
STREAMINGAPPLOCATION = f"/home/{USER}/Streaming/"
STEAMUSERDATA = f"/home/{USER}/.steam/steam/userdata/"
PATHTOUSERCONFIGGRIDS = STEAMUSERDATA + os.listdir(STEAMUSERDATA)[0] + "/config/grid/"
PATHTOSTEAMSHORTCUTSFILE = STEAMUSERDATA + os.listdir(STEAMUSERDATA)[0] + "/config/shortcuts.vdf"

#Generates an APPID based on the EXE and AppName
def GeneratePreliminaryId(ExePath, AppName):
    Key = ExePath + AppName
    Top = int(binascii.crc32(Key.encode())) | int(0x80000000)
    return (int(Top) << int(32)) | int(0x02000000)

#Used for appid in grid artwork
def GenerateShortAppId(ExePath, AppName):
    return str(GeneratePreliminaryId(ExePath, AppName) >> int(32))

#Used as appid in shortcuts.vdf
def GenerateShortcutId(ExePath, AppName):
    return int((GeneratePreliminaryId(ExePath, AppName) >> int(32)) - int(0x100000000))

#Main function
if __name__ == "__main__":
    StartTime = time.time()
    print(f"Installing the app in '{STREAMINGAPPLOCATION}' ...")
    os.makedirs(f"/home/{USER}/Streaming/")
    os.system(f"cp -a '{MAINDIRECTORY}' '{STREAMINGAPPLOCATION}'")
    os.system(f"rm -r '{STREAMINGAPPLOCATION}Streaming App/Modules/'")                                                                          #Delete the installation folders that aren't needed
    os.system(f"rm '{STREAMINGAPPLOCATION}Streaming App/CreateSteamShortcut.py' '{STREAMINGAPPLOCATION}Streaming App/AutoInstall.sh'")          #Delete the installation files that aren't needed

    print(f"Appending new shortcut to '{PATHTOSTEAMSHORTCUTSFILE}' ...")
    if not os.path.exists(PATHTOSTEAMSHORTCUTSFILE):
        with open(PATHTOSTEAMSHORTCUTSFILE, "wb") as NewlyCreatedShortcutsFile:
            NewlyCreatedShortcutsFile.write(b'\x00' + b'shortcuts' + b'\x00\x08\x08')
        NewlyCreatedShortcutsFile.close()

    ShortcutsDict = vdf.binary_load(open(PATHTOSTEAMSHORTCUTSFILE, "rb"))
    CurrentIteration = len(ShortcutsDict["shortcuts"])
    PathToDirectory = f"/home/{USER}/Streaming/Streaming App/"
    PathToScript = f"{PathToDirectory}Streaming Services App.x86_64"
    AppName = "Stream Deck"
    ExecutablePathReadable = '"' + PathToScript + '"'
    DirectoryPathReadable = '"' + PathToDirectory + '"'
    AppID = GenerateShortcutId(AppName, ExecutablePathReadable)
    ArtworkAppID = GenerateShortAppId(AppName, ExecutablePathReadable)
    ShortcutsDict["shortcuts"][str(CurrentIteration + 1)] = {
        "appid" : AppID,
        "AppName" : AppName,
        "Exe" : ExecutablePathReadable,
        "StartDir" : DirectoryPathReadable,
        "icon" : f"{PathToDirectory}Artwork/SteamDeckIcon.png",
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

    ShortcutsDictParsed = vdf.binary_dump(ShortcutsDict, open(PATHTOSTEAMSHORTCUTSFILE, "wb"))

    NewFileNames = {
        "SDStreamingGrid": f"{ArtworkAppID}p.png",
        "SDStreamingGridLong": f"{ArtworkAppID}.png",
        "SDStreamingHero":   f"{ArtworkAppID}_hero.png",
        "SDStreamingLogo":   f"{ArtworkAppID}_logo.png",
    }
    for OldFileName, NewFileName in NewFileNames.items():
        OldFileFullPath = f"{MAINDIRECTORY}Artwork/{OldFileName}.png"
        NewFileFullPath = PATHTOUSERCONFIGGRIDS + NewFileName
        print(f"Copying '{OldFileFullPath}' to '{NewFileFullPath }' ...")
        os.system(f"cp '{OldFileFullPath}' '{NewFileFullPath}'")

    print(f"Stream Deck has been successfully installed\nScript runtime: {round(time.time()-StartTime, 2)} second(s)")
