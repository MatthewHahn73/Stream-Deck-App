#!/bin/sh
printf '\033c\033]0;%s\a' Steam Deck Streaming
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Streaming Services App.x86_64" "$@"
