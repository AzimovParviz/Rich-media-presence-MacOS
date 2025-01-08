#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>

#include "discord-files/discord_game_sdk.h" 
void returnNowPlayingInfo(); 
#define DISCORD_REQUIRE(x) assert(x == DiscordResult_Ok)

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
    char title[256];
    char artist[256];
    char duration[256];
};

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

void readSongInformation(struct SongInformation *songInformation)
{
    // TODO: make a temporary file to store song information
    // tmpfile() creates a temporary file in read/write mode (w+)
    FILE *file = fopen("song.txt", "r");
    if (file == NULL)
    {
        perror("Failed to open song.txt");
        return;
    }

    char title[256], artist[256], duration[256];
    if (fscanf(file, "%255[^\n]\n%255[^\n]\n%255s", songInformation->title, songInformation->artist, songInformation->duration) != 3)
    {
        perror("Failed to read song information");
        fclose(file);
        return;
    }
    fclose(file);
    printf("Title: %s\nArtist: %s\nDuration: %s\n", title, artist, duration);
}

static void updateDiscordPresence(struct SongInformation *songInformation)
{
    struct DiscordActivity activity;
    memset(&activity, 0, sizeof(activity));
    activity.type = DiscordActivityType_Playing;
    returnNowPlayingInfo();
    readSongInformation(songInformation);
    printf("Updating Discord presence with song information:\n");
    printf("Title: %s\n", songInformation->title);
    printf("Artist: %s\n", songInformation->artist);
    printf("Duration: %s\n", songInformation->duration);
    activity.type = DiscordActivityType_Listening;
    sprintf(activity.name, "%s", "Losing mind to");
    sprintf(activity.details, "%s", songInformation->title);
    sprintf(activity.state, "%s", songInformation->artist);
    // FIXME: only send once, I think discord will cache the image
    sprintf(activity.assets.large_image, "%s", "https://safebooru.org//images/256/6afab002b8f139968229a48fa02943948fbed138.gif?5172035");
    sprintf(activity.assets.large_text, "Now Playing");
    // sprintf(activity.details, );
    // snprintf(activity.state, sizeof(activity.state), "%s", duration);

    app.activities->update_activity(app.activities, &activity, &app, UpdateActivityCallback);
}

void *updateLoop()
{
    struct SongInformation curSong = songInformation;
    if (!app.DiscordOk)
        return NULL;
    for (;;)
    {
        updateDiscordPresence(&songInformation);
        DISCORD_REQUIRE(app.core->run_callbacks(app.core));
        usleep(1666667 * 2);
    }
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        printf("Usage: %s <client_id>\n", argv[0]);
        return 1;
    }
    DiscordClientId clientId = atoll(argv[1]);
    discordInit(clientId);
    pthread_t t1;
    pthread_create(&t1, NULL, updateLoop, NULL);
    pthread_detach(t1);
    pthread_exit(NULL);
}