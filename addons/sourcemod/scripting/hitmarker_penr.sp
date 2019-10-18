#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Tetragromaton"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#include <zombiereloaded>
bool IgnoreHits[MAXPLAYERS + 1];
int Hitmarker[MAXPLAYERS + 1];
#define foreach(%0) for (int %0 = 1; %0 <= MaxClients; %0++) if (IsClientInGame(%0) && !IsFakeClient(%0))
EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "Hitmarkers",
	author = PLUGIN_AUTHOR,
	description = "Hitmarkers based at the concept of particles.",
	version = PLUGIN_VERSION,
	url = "https://hlmod.ru/members/tetragromaton.80537/"
	//See skiddo does some things at github -> https://github.com/Tetragromaton
};

Handle g_Setting_ParamX;
Handle g_Setting_ClientSound;

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	g_Setting_ParamX = RegClientCookie("hitmarker_toggled", "", CookieAccess_Private);
	g_Setting_ClientSound = RegClientCookie("hitmarker_sound_toggled", "", CookieAccess_Private);
	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("toggleh", Cmd_ToggleShit_FIX);
	RegConsoleCmd("togglehh", Cmd_ToggleShit);
	HookEvent("round_start", OnRoundStart);
	DoHandle();
	DownloadShit();
	LoadTranslations("hitmarkerpenr.phrases");
}
public Action Cmd_ToggleShit_FIX(client,args)
{
	FakeClientCommand(client, "togglehh");
	//Dunno what's wrong but it fixes trouble with translates
	return Plugin_Handled;
}
DoHandle()
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		//To get hitmarkers work with bots.
		if(IsValidEntity(i))
		{
		char gen[255];
		GetEntityClassname(i, gen, sizeof(gen));
		if (StrEqual(gen, "worldspawn"))continue;
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}
public Action OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) 
{
	//PrintToChatAll("s");
	if(victim != attacker)
	{
		if(damage > 5.0 && hitgroup == 1)
		{
			int team_vi = GetClientTeam(victim);
			int team_at = GetClientTeam(attacker);
			if(team_vi != team_at)
			{//Ignore hitmarker for non zombies and etc...
			Hitmarker[attacker] = 1;
			DoParticle(attacker, "burning_4hitmarker_DMGMORI", "OnUser1 !self:kill::0.3:-1");
			}
		}
	}
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		Hitmarker[client] = 0;
}
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	DownloadShit();
	CreateTimer(1.0, GGS);
	DoHandle();
}
public Action GGS(Handle timer)
{
	DownloadShit();
}
DownloadShit()
{
	PrecacheSound("wefliem/hit.mp3");
	AddFileToDownloadsTable("sound/wefliem/hit.mp3");
	AddFileToDownloadsTable("materials/wefliem/hitsh_infected.vtf");
	AddFileToDownloadsTable("materials/wefliem/hitsh_infected.vmt");
	AddFileToDownloadsTable("materials/wefliem/hitsh.vtf");
	AddFileToDownloadsTable("materials/wefliem/hitsh.vmt");
	AddFileToDownloadsTable("materials/wefliem/hitsh_killedzombie.vtf");
	AddFileToDownloadsTable("materials/wefliem/hitsh_killedzombie.vmt");
	AddFileToDownloadsTable("materials/wefliem/hitsh_huge.vtf");
	AddFileToDownloadsTable("materials/wefliem/hitsh_huge.vmt");
	AddFileToDownloadsTable("materials/wefliem/hitsh_killedzombie.vtf");
	AddFileToDownloadsTable("materials/wefliem/hitsh_killedzombie.vmt");
	AddFileToDownloadsTable("particles/lolz/hitmarker_govno.pcf");
	PrecacheGeneric("particles/lolz/hitmarker_govno.pcf", true);
}
public OnMapStart()
{
	DownloadShit();
}
public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(0 < attacker <= MaxClients)
	{
		if(client != attacker)
		{
			if(GetCookieInt(attacker, g_Setting_ParamX) < 1)
			{
			//If player have hitmarkers toggled off, dont show it to him then ????
			//Take in mind that we shouldn't display hitmarker if we killed someone.
			//Big oof is that i have checking for param in cookie right in DoParticle function.
			if(ZR_IsClientHuman(attacker))
			{
				//Display particle that human has killed zombie.
				if(IgnoreHits[client] == true)
				{
					DoParticle(attacker, "burning_4hitmarker_killed", "OnUser1 !self:kill::1.3:-1");
				}
			}
			}
		}
	}
}
public ZR_OnClientInfected(client, attacker)
{
	if(client != attacker)
	{
		if (!IsValidEntity(client) || !IsValidEntity(attacker))return;//We need to have only this situation (Player Infected Other Player), else do nothing.
		DoParticle(attacker, "burning_4hitmarker_infected", "OnUser1 !self:kill::0.5:-1");
	}
}
DoParticle(client, const char[] name, const char[] InputShit)
{
	//Input in char format because Format() with float value didn't work so....
	int inter = GetCookieInt(client, g_Setting_ParamX);
	if (inter > 0)return;
	float pos[3];
	float ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	int ent = CreateEntityByName("info_particle_system");
	if(ent == -1) SetFailState("Error creating \"info_particle_system\" entity!");		
	TeleportEntity(ent, pos, ang, NULL_VECTOR);		
	DispatchKeyValue(ent, "effect_name", name);
	DispatchKeyValue(ent, "start_active", "1");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SDKHook(ent, SDKHook_SetTransmit, SetTransmit_Hook);
	SetVariantString(InputShit);
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (client == attacker)return Plugin_Continue;//Dont mess with ourselves.
	int sound = GetCookieInt(attacker, g_Setting_ClientSound);
	int ovr = GetCookieInt(attacker, g_Setting_ParamX);
	if(sound < 1) EmitSoundToClient(attacker, "wefliem/hit.mp3");
	if(ovr < 1)
	{
	int health = GetEntProp(client, Prop_Send, "m_iHealth");
	if (!IsValidEntity(client) || !IsValidEntity(attacker))return Plugin_Continue;//To make sure client has not dealt damage to himself or damage goes from world or etc..
	if (ZR_IsClientZombie(attacker))return Plugin_Continue;//Zombies must see only infection skull thingy
	if(health < 100)
	{
		//Zombie has too low HP and about to die.
		//We have to keep in mind that we have to display partcile that zombie was killed so.
		IgnoreHits[client] = true;
		return Plugin_Continue;
	} else {
		IgnoreHits[client] = false;
	}
	if (Hitmarker[attacker] > 0){
		//Если был выстрел в голову, просто проигнорим следующий хитмаркер или будут два хитмаркера.
		Hitmarker[attacker] = 0;
		return Plugin_Continue;
	} else {
		Hitmarker[attacker] = 0;
	}
	//burning_4hitmarker_DMGMORI - too much dmg
	//burning_4hitmarker_infected - infected lol
	//burning_4hitmarker_killed - killed ofc
	DoParticle(attacker, "burning_3hitmarkerg_copy", "OnUser1 !self:kill::0.3:-1");
	}
}
public Action SetTransmit_Hook(int entity, int client)
{
	if(GetEdictFlags(entity) & FL_EDICT_ALWAYS)
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	
	if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client || GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 || GetEntProp(client, Prop_Send, "m_iObserverMode") == 5)
		return Plugin_Continue;
	
	return Plugin_Stop;
}
public Action Cmd_ToggleShit(client,args)
{
	int state = GetCookieInt(client, g_Setting_ParamX);
	int sst = GetCookieInt(client, g_Setting_ClientSound);
	char SoundSTR[48];
	char HitSTR[48];
	if(state > 0)
	{
		Format(HitSTR, sizeof(HitSTR), "%t (● ○)", "GBRICK Menu Hitmarker");
	} else Format(HitSTR, sizeof(HitSTR), "%t (○ ●)", "GBRICK Menu Hitmarker");
	if(sst > 0)
	{
		Format(SoundSTR, sizeof(SoundSTR), "%t (● ○)", "GBIRCK Menu Sound");
		//SoundSTR = "Звук попадания (● ○)";
	} else Format(SoundSTR, sizeof(SoundSTR), "%t (○ ●)", "GBIRCK Menu Sound");
	new Handle:menu = CreateMenu(SetaFunctionelSWITCH);
	SetMenuTitle(menu, "%t", "Title333");
	//More than 0 means that it is turned off(by default it is toggled on that's why)
	AddMenuItem(menu, "htoggle", HitSTR);
	AddMenuItem(menu, "stoggle", SoundSTR);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 35);
	return Plugin_Handled;
}
public SetaFunctionelSWITCH(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is item
			
			new String:item[255];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "htoggle"))
			{
				int wtf = GetCookieInt(param1, g_Setting_ParamX);
				if(wtf > 0)
				{
					PrintToChat(param1, "%t: %t", "Toggle Hitmarker", "ON420");
					SetClientCookieInt(param1, g_Setting_ParamX, 0);
					FakeClientCommand(param1, "toggleh");
				}else
				{
					PrintToChat(param1, "%t: %t", "Toggle Hitmarker", "OFF420");
					SetClientCookieInt(param1, g_Setting_ParamX, 1);
					//PrintToChat(param1, "Хитмаркер: ВЫКЛ");
					FakeClientCommand(param1, "toggleh");
				}
			}else if(StrEqual(item, "stoggle"))
			{
				int wtf = GetCookieInt(param1, g_Setting_ClientSound);
				if(wtf > 0)
				{
					PrintToChat(param1, "%t: %t", "Toggle Sound", "ON420");
					SetClientCookieInt(param1, g_Setting_ClientSound, 0);
					FakeClientCommand(param1, "toggleh");
				}else {
					PrintToChat(param1, "%t: %t", "Toggle Sound", "OFF420");
					SetClientCookieInt(param1, g_Setting_ClientSound, 1);
					FakeClientCommand(param1, "toggleh");
				}
			}
		}
		
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);
			
		}
		
	}
}
int GetCookieInt(client, Handle cookie)
{
	int wtf;
	char gg[255];
	GetClientCookie(client, cookie, gg, sizeof(gg));
	wtf = StringToInt(gg);
	return wtf;
}
bool SetClientCookieInt(client, Handle cookie, int value)
{
	char penr[255];
	IntToString(value, penr, sizeof(penr));
	SetClientCookie(client, cookie, penr);
	return true;
}