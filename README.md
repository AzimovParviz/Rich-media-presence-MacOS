# Rich Media Presence MacOS

Fetches information from MacOS's MediaRemote private framework on the currently playing media and displays it under your Discord Profile

## Getting started

### Dependencies
* Swift 
* Discord Game SDK (at least 3.2.1)
* gcc
* unzip
* curl

### Installing
TBD

### Building

#### Automatic

There's build.sh in the repo. Run ```build.sh download``` after cloning and then without arguments on next builds

#### Manual

* [Download Discord Game SDK](https://discord.com/developers/docs/developer-tools/game-sdk#getting-started)

* extract the C header from C/discord_game_sdk.h
* extract lib/x86_64/discord_game_sdk.dylib if you're on Intel Mac or lib/aarch64/discord_game_sdk.dylib if you are on M-series chip
* ```swiftc nowPlayingInfo.swift -emit-library``` which will build nowPlayingInfo.dylib
* ```gcc -o main.o main.c -L./lib -ldiscord_game_sdk -L./ -lnowPlayingInfo -lpthread -rpath lib``` to build the executable
* ```./main.o ${your client Id}```

### Usage

* Head to Discord Developer Portal and register an app
* After it's created, copy the Client ID
* run ```build.sh download``` or build manually
* run ```./main.o *insert client id here*```