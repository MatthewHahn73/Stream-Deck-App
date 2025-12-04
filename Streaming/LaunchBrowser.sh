#!/bin/bash

LINK="$1"
DIR=$(pwd)
source ${DIR}/Streaming/Config/Streaming.conf
"/usr/bin/flatpak" run ${FLATPAKOPTIONS} ${BROWSERAPP} @@u @@ ${BROWSEROPTIONS} ${LINK}
