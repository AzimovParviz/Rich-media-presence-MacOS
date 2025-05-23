#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>

#include "discord-files/discord_game_sdk.h"
void returnNowPlayingInfo();
#define DISCORD_REQUIRE(x) assert(x == DiscordResult_Ok)
#ifndef OSX_VER
#define OSX_VER STR("15.5.0")
#endif

struct Application
{
    struct IDiscordCore *core;
    struct IDiscordUserManager *users;
    struct IDiscordActivityManager *activities;
    struct IDiscordApplicationManager *application;
    bool DiscordOk;
    DiscordUserId user_id;
};

struct SongInformation
{
    char title[128];
    char artist[128];
    char duration[128];
};

enum ApplicationName
{
    unknown,
    Safari,
    Firefox,
    YouTube,
    Twitch,
    Spotify,
    f2k,
    AppleMusic,
    mpv
} mediaClientName;

const char *mediaClientIcons[] = {
    "unknown_icon",
    "safari_icon",
    "firefox_icon",
    "youtube_icon",
    "twitch_icon",
    "spotify_icon",
    "f2k_icon",
    "apple_music_icon",
    "mpv_icon"};

char appName[128];

struct Application app;
struct SongInformation songInformation;

void DISCORD_CALLBACK UpdateActivityCallback(void *data, enum EDiscordResult result)
{
    DISCORD_REQUIRE(result);
}

void DISCORD_CALLBACK OnUserUpdated(void *data)
{
    struct Application *app = (struct Application *)data;
    struct DiscordUser user;
    app->users->get_current_user(app->users, &user);
    app->user_id = user.id;
}

void DISCORD_CALLBACK OnOAuth2Token(void *data,
                                    enum EDiscordResult result,
                                    struct DiscordOAuth2Token *token)
{
    if (result == DiscordResult_Ok)
    {
        printf("OAuth2 token: %s\n", token->access_token);
        app.DiscordOk = true;
    }
    else
    {
        printf("GetOAuth2Token failed with %d\n", (int)result);
    }
}

void discordInit(DiscordClientId clientId)
{
    memset(&app, 0, sizeof(app));
    app.DiscordOk = false;
    struct IDiscordUserEvents users_events;
    memset(&users_events, 0, sizeof(users_events));
    users_events.on_current_user_update = OnUserUpdated;
    struct DiscordCreateParams params;
    DiscordCreateParamsSetDefault(&params);
    params.client_id = clientId;
    params.flags = DiscordCreateFlags_Default;
    params.event_data = &app;
    params.user_events = &users_events;
    int discordResult = DiscordCreate(DISCORD_VERSION, &params, &app.core);
    if (discordResult != DiscordResult_Ok)
    {
        printf("DiscordCreate failed with %d\n", (int)discordResult);
        app.DiscordOk = false;
        return;
    }
    else if (discordResult == DiscordResult_Ok)
    {
        app.DiscordOk = true;
    }
    DISCORD_REQUIRE(DiscordCreate(DISCORD_VERSION, &params, &app.core));
    app.activities = app.core->get_activity_manager(app.core);
    app.application = app.core->get_application_manager(app.core);
    // Only needed once
    app.application->get_oauth2_token(app.application, &app, OnOAuth2Token);
}

void readFileOutputSongInfo(FILE *infoFile, struct SongInformation *songInformation) {
  
    fgets(songInformation->title, sizeof(songInformation->title), infoFile);
    // Means the line was too long, so we have to put the fgets cursor to the next line
    if (songInformation->title[strlen(songInformation->title) - 1] != '\n')
    {
        printf("Title is too long\n");
        songInformation->title[127] = '\0';
        while (fgetc(infoFile) != '\n')
            ;
    }
    else
    {
        songInformation->title[strlen(songInformation->title) - 1] = '\0';
    }

    fgets(songInformation->artist, sizeof(songInformation->artist), infoFile);

    if (songInformation->artist[strlen(songInformation->artist) - 1] != '\n')
    {
        printf("Artist is too long\n");
        songInformation->artist[127] = '\0';
        while (fgetc(infoFile) != '\n')
            ;
    }
    else
    {
        songInformation->artist[strlen(songInformation->artist) - 1] = '\0';
    }

    fgets(songInformation->duration, sizeof(songInformation->duration), infoFile);
    fgets(appName, sizeof(appName), infoFile);
}

void readSongInformation(struct SongInformation *songInformation)
{
    //On version 15.4 and higher the swift solution won't work
    //meanwhile, on some lower versions, like Ventura 13.7.5, the AS won't work so we have to use the swift version on lower macos version
    //in theory, anything lower than 13 we could just use AppleScript
    FILE *songInfoFile;
    if(strstr(OSX_VER, "13.7.") !=NULL)
    {        
        songInfoFile = fopen("/tmp/song.txt", "r"); 
	readFileOutputSongInfo(songInfoFile, songInformation);	
	fclose(songInfoFile);
    }
    else
    {
        songInfoFile = popen("osascript nowPlaying.scptd", "r");
	readFileOutputSongInfo(songInfoFile, songInformation);	
	pclose(songInfoFile); 
    }
    if (songInfoFile == NULL)
    {
        perror("Failed to execute AppleScript or open file");
        return;
    }
    printf("Title: %s\nArtist: %s\nDuration: %s\n", songInformation->title, songInformation->artist, songInformation->duration);
}



static bool updateDiscordPresence(struct SongInformation *songInformation)
{
    static struct DiscordActivity activity;
    if(strstr(OSX_VER, "13.7.") != NULL)
	returnNowPlayingInfo();
    readSongInformation(songInformation);
    printf("App name: %s\n", appName);
    mediaClientName = unknown;
    if (strstr(appName, "Safari") != NULL)
    {
        mediaClientName = Safari;
    }
    else if (strstr(appName, "Firefox") != NULL && strstr(songInformation->title, "- Twitch") == NULL)
    {
        mediaClientName = Firefox;
    }
    else if (strstr(appName, "YouTube") != NULL)
    {
        mediaClientName = YouTube;
    }
    else if (strstr(songInformation->title, "- Twitch") != NULL)
    {
        mediaClientName = Twitch;
    }
    else if (strstr(appName, "Spotify") != NULL)
    {
        mediaClientName = Spotify;
    }
    else if (strstr(appName, "foobar2000") != NULL)
    {
        mediaClientName = f2k;
    }
	//this string differs and depends on macos version, so maybe just Music is better in this case
    else if (strstr(appName, "apple.Music") != NULL)
    {
        mediaClientName = AppleMusic;
    }
    else if (strstr(appName, "mpv") != NULL)
    {
        mediaClientName = mpv;
    }
    if (strcmp(activity.details, songInformation->title) != 0 || strcmp(activity.state, songInformation->artist) != 0)
    {
        // ActivityType is strictly for the purpose of handling events that you receive from Discord; though the SDK will not reject a payload with an ActivityType sent, it will be discarded and will not change anything in the client.
        //  sprintf(activity.name, "%s", "something");
        //  activity.type = 2;
        if (songInformation->duration[0] != '\0')
        {
            activity.timestamps.start = 0;
            activity.timestamps.end = strtol(songInformation->duration, NULL, 10);
        }
        printf("Updating Discord presence with song information:\n");
        // Discord only lets you have 128 characters and if title is in non latin characters it will be greater than 128 and crash
        sprintf(activity.details, "%s", songInformation->title);
        sprintf(activity.state, "%s", songInformation->artist);

        // FIXME: only send once, I think discord will cache the image
        sprintf(activity.assets.large_image, "%s", "https://safebooru.org//images/256/6afab002b8f139968229a48fa02943948fbed138.gif?5172035");
        sprintf(activity.assets.small_image, "%s", mediaClientIcons[mediaClientName]);
        app.activities->update_activity(app.activities, &activity, &app, UpdateActivityCallback);
        return true;
    }
    else
    {
        printf("No need to update Discord presence\n");
        return false;
    }
}

void *updateLoop()
{
    struct SongInformation curSong = songInformation;
    if (!app.DiscordOk)
        return NULL;
    for (;;)
    {
        if (updateDiscordPresence(&songInformation))
            DISCORD_REQUIRE(app.core->run_callbacks(app.core));
        usleep(1666667 * 2);
    }
}

int main(int argc, char **argv)
{
    //if (argc < 2)
    //{
    //    printf("Usage: %s <client_id>\n", argv[0]);
    //    return 1;
    //}
    //DiscordClientId clientId = atoll(argv[1]);
    discordInit(CLIENT_ID);
    pthread_t t1;
    pthread_create(&t1, NULL, updateLoop, NULL);
    pthread_detach(t1);
    pthread_exit(NULL);
}
