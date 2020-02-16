#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <ripext>
#include <tf2>

#define PLUGIN_VERSION "1.0"
#define EFFECTS 24
HTTPClient httpClient;
char sClientID[64];
char sCommands[EFFECTS][64] = {"slow", "zoom", "disguising", "ubercharged", "taunt", "kritz", "dazed", "charging", "bonked", "critcola", "fire", "jarate", "bleeding", "marked", "parachute", "halloweenkart", "balloonhead", "meleeonly", "swimmingcurse", "lostfooting", "aircurrent", "rocketpack", "gas", "random"};
int iConds[EFFECTS] = {0, 1, 2, 5, 7, 11, 15, 17, 14, 19, 22, 24, 25, 30, 80, 82, 84, 85, 86, 126, 127, 125, 123, 0};
bool bPlaying = false;

public Plugin myinfo =
{
	name		= "Screw This Game",
	author		= "Noodl",
	description	= "Random player effects pulled from a webserver",
	version		= PLUGIN_VERSION,
	url			= "http://flux.tf"
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("arena_win_panel", OnRoundWin);
	httpClient = new HTTPClient("https://stg-api.monotron.me");
	RegisterServer();
}

public Action OnRoundWin(Handle hEvent, char[] sName, bool dontBroadcast)
{
    bPlaying = false;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bPlaying = true;
}

public void RegisterServer()
{
	PrintToServer("Registering server");
	httpClient.SetHeader("X-Client-Type", "Team_Fortress_2");
	JSONObject body = new JSONObject();
	JSONArray capabilities = new JSONArray();
	for (int i = 0; i < EFFECTS-1; i++) capabilities.PushString(sCommands[i]);
	body.Set("capabilities", capabilities);
	httpClient.Post("client/register", body, ServerRegistered);
	delete capabilities;
	delete body;	
}

public void ServerRegistered(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK) 
	{
		return;
	}
	char sres[512];
	JSONObject res = view_as<JSONObject>(response.Data);
	res.GetString("clientId", sClientID, sizeof(sClientID));
	res.GetString("status", sres, sizeof(sres));
	PrintToServer(sres);
	PrintToServer(sClientID);

	PrintToServer("Retrieved client ID with title '%s'", sClientID);
	CreateTimer(5.0, Poll, _, TIMER_REPEAT);
}

public Action Poll(Handle timer, any Pack)
{
	char sEndpoint[256];
	Format(sEndpoint, sizeof(sEndpoint), "client/%s/effects", sClientID);
	PrintToServer("Polling %s", sEndpoint);
	httpClient.Get(sEndpoint, GotEffect);
}

public void GotEffect(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK) 
	{
		// Failed to retrieve todo
		return;
	}
	if (!bPlaying) return;

	char effect[128];
	char status[64];
	JSONObject res = view_as<JSONObject>(response.Data);
	JSONArray effects = view_as<JSONArray>(res.Get("effects"));
	for (int i = 0; i < 1; i++) 
	{
        effects.GetString(i, effect, sizeof(effect));
        // Get() creates a new handle, so delete it when we are done with it
    }
	PrintToServer(effect);

	//res.GetString("effects", effect, sizeof(effect));
	//res.GetString("status", status, sizeof(status));
	if (!StrEqual(status, "SUCCESS", false)) return;

	for (int i = 0; i < EFFECTS - 1; i++)
	{
		if (StrEqual(effect, sCommands[i], false))
		{
			for (int r = 0; r < GetRandomInt(GetClientCount() / 4, GetClientCount()); r++)
				TF2_AddCondition(GetRandomPlayer(), view_as<TFCond>(iConds[i] ? iConds[i] : GetRandomInt(1, 126)), GetRandomFloat(5.0, 15.0), 0);
			CPrintToChatAll("[{yellow}STG{default}] The %s effect has been activated!", effect);
		}
	}
	delete res;
	delete effects;
}

public int GetRandomPlayer()
{
	int client;
	do
	{
		client = GetRandomInt(1, MaxClients);
	}
	while(!IsClientInGame(client) || !IsPlayerAlive(client));
	return client;
}