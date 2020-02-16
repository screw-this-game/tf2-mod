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
	httpClient = new HTTPClient("https://stg-api.monotron.me");
	RegisterServer();
}

public void RegisterServer()
{
	httpClient.SetHeader("X-Client-Type", "Team_Fortress_2");
	JSONObject body;
	httpClient.Post("client/register", body, ServerRegistered);
}

public void ServerRegistered(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK) 
	{
		// Failed to retrieve todo
		return;
	}

	JSONObject res = view_as<JSONObject>(response.Data);
	res.GetString("clientId", sClientID, sizeof(sClientID));

	PrintToServer("Retrieved client ID with title '%s'", sClientID);
	CreateTimer(10.0, Poll, _, TIMER_REPEAT);

}

public Action Poll(Handle timer, any Pack)
{
	char sEndpoint[256];
	Format(sEndpoint, sizeof(sEndpoint), "client/%s/effects");
	httpClient.Get(sEndpoint, GotEffect);
}

public void GotEffect(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK) 
	{
		// Failed to retrieve todo
		return;
	}

	char effect[128];
	char status[64];
	JSONObject res = view_as<JSONObject>(response.Data);
	res.GetString("effect", effect, sizeof(effect));
	res.GetString("status", status, sizeof(status));
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