DISCORD_SDK_URL = https://dl-game-sdk.discordapp.net/3.2.1/discord_game_sdk.zip
DISCORD_SDK_ZIP = discord_game_sdk.zip
DISCORD_SDK_DIR = discord-files
LIB_DIR = lib
ARCH = $(shell uname -m)
ifeq ($(ARCH),arm64)
    ARCH = aarch64
endif

.PHONY: all download clean

all: main

download:
	@echo "Downloading discord_game_sdk"
	curl -o $(DISCORD_SDK_ZIP) $(DISCORD_SDK_URL)
	@echo "Unzipping discord_game_sdk"
	unzip $(DISCORD_SDK_ZIP) "c/discord_game_sdk.h" -d $(DISCORD_SDK_DIR)
	mv $(DISCORD_SDK_DIR)/c/discord_game_sdk.h $(DISCORD_SDK_DIR)/discord_game_sdk.h
	unzip $(DISCORD_SDK_ZIP) "lib/$(ARCH)/discord_game_sdk.dylib" -d $(LIB_DIR)
	mv $(LIB_DIR)/lib/$(ARCH)/discord_game_sdk.dylib $(LIB_DIR)/libdiscord_game_sdk.dylib
	rm -r $(LIB_DIR)/lib
	ln -s $(LIB_DIR)/libdiscord_game_sdk.dylib $(LIB_DIR)/discord_game_sdk.dylib

dylib:
	swiftc nowPlayingInfo.swift -emit-library 

main: dylib
	gcc -o main.o main.c -L./$(LIB_DIR) -ldiscord_game_sdk -L./ -lnowPlayingInfo -lpthread -rpath $(LIB_DIR)

clean:
	rm -f main main.o nowPlayingInfo.dylib
	rm -rf $(DISCORD_SDK_DIR) $(LIB_DIR) $(DISCORD_SDK_ZIP)