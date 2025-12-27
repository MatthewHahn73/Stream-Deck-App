Front end application that launches streaming services from the Steam Deck's 'Game Mode' interface

## Supported Browsers
One of the following browsers will be need to be installed on the Steam Deck for full functionality:
- Firefox - <a href="https://flathub.org/apps/org.mozilla.firefox">Flathub Link</a>
- Librewolf - <a href="https://flathub.org/apps/io.gitlab.librewolf-community">Flathub Link</a>
- Google Chrome - <a href="https://flathub.org/apps/com.google.Chrome">Flathub Link</a>
- Microsoft Edge - <a href="https://flathub.org/apps/com.microsoft.Edge">Flathub Link</a>
- Opera - <a href="https://flathub.org/apps/com.opera.Opera">Flathub Link</a>
- Brave - <a href="https://flathub.org/apps/com.brave.Browser">Flathub Link</a>

## Installation/Configuration
Will need to navigate to the Steam Deck's 'Desktop Mode' and download the latest release found <a href="https://github.com/MatthewHahn73/Stream-Deck-App/releases/latest/">here</a>

Each release includes a 'AutoInstall.sh' script, which is executable and will do the following:
- Move the required application files to /home/$USER/Streaming/
- Appends a new steam shortcut to /home/$USER/.steam/steam/userdata/$STEAMUSERID/config/shortcuts.vdf 
- Populates the newly created shortcut with artwork

The settings and configuration files can be found at:
- /home/$USER/.local/share/godot/app_userdata/StreamDeck/Streaming/
