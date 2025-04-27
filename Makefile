DISCORD_SDK_URL = https://dl-game-sdk.discordapp.net/3.2.1/discord_game_sdk.zip
DISCORD_SDK_ZIP = discord_game_sdk.zip
DISCORD_SDK_DIR = discord-files
MACOSX_DEPLOYMENT_TARGET = 10.15
LIB_DIR = lib
ARCH = $(shell uname -m)
ifeq ($(ARCH),arm64)
    ARCH = aarch64
endif

BINARY_NAME = main

.PHONY: all download clean unzip

all: clean download unzip build

# Separate unzipping logic into its own target
unzip:
	@echo "Unzipping discord_game_sdk"
	unzip $(DISCORD_SDK_ZIP) "c/discord_game_sdk.h" -d $(DISCORD_SDK_DIR)
	mv $(DISCORD_SDK_DIR)/c/discord_game_sdk.h $(DISCORD_SDK_DIR)/discord_game_sdk.h
	unzip $(DISCORD_SDK_ZIP) "lib/$(ARCH)/discord_game_sdk.dylib" -d $(LIB_DIR)
	mv $(LIB_DIR)/lib/$(ARCH)/discord_game_sdk.dylib $(LIB_DIR)/libdiscord_game_sdk.dylib
	rm -r $(LIB_DIR)/lib

download:
	@echo "Downloading $(DISCORD_SDK_ZIP).zip"
	curl -o $(DISCORD_SDK_ZIP) $(DISCORD_SDK_URL)

build:
	clang -o $(BINARY_NAME) main.c -L./$(LIB_DIR) -ldiscord_game_sdk -lpthread -rpath ./$(LIB_DIR) -target $(ARCH)-apple-macosx10.15
	mv $(LIB_DIR)/libdiscord_game_sdk.dylib $(LIB_DIR)/discord_game_sdk.dylib

clean:
	rm -f $(BINARY_NAME)
	rm -rf $(DISCORD_SDK_DIR) $(LIB_DIR) $(DISCORD_SDK_ZIP)