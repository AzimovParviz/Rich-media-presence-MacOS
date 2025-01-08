#!/bin/bash
if [ "$1" == "download" ]; then
  echo "Downloading discord_game_sdk"
  curl -o discord_game_sdk.zip https://dl-game-sdk.discordapp.net/3.2.1/discord_game_sdk.zip
  echo "Unzipping discord_game_sdk"
  unzip discord_game_sdk.zip "c/discord_game_sdk.h" -d ./discord_files
  unzip discord_game_sdk.zip "lib/x86_64/discord_game_sdk.dylib" -d ./lib
  # should be a more elegant way to do this
  mv ./lib/lib/x86_64/discord_game_sdk.dylib ./lib/libdiscord_game_sdk.dylib
  rm -r ./lib/lib
  # will build but will not run without this, PRs welcome
  ln -s ./lib/libdiscord_game_sdk.dylib ./lib/discord_game_sdk.dylib
fi
swiftc nowPlayingInfo.swift -emit-library
gcc -o main.o main.c -L./lib -ldiscord_game_sdk -L./ -lnowPlayingInfo -lpthread -rpath lib