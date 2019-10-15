//WARNING !! RUNTIME CODE THAT WAS WRITTEN WHILE DOING JOB AT DEV-SOURCE.RU.
//This document is goes as a proof if something gone wrong and that who has requested this plugin will decide to not pay for it
//and to leak it to hlmod.ru or any forum without payment to me.
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
//#pragma newdecls required
#define foreach(%0) for (int %0 = 1; %0 <= MaxClients; %0++) if (IsClientInGame(%0) && !IsFakeClient(%0))
EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "Hitmarkers",
	author = PLUGIN_AUTHOR,
	description = "Hitmarkers based at the concept of particles.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Tetragromaton"
};
Handle g_Setting_ParamX;
Handle g_Setting_ClientSound;
public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	g_Setting_ParamX = RegClientCookie("hitmarker_toggled", "", CookieAccess_Private);
	g_Setting_ClientSound = RegClientCookie("hitmarker_sound_toggled", "", CookieAccess_Private);
	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("toggleh", Cmd_ToggleShit);
	RegConsoleCmd("debugs", CMD_T);
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		if(IsValidEntity(i))
		{
		//To get hitmarkers runtime thingy work with bots.
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		//PrintToChatAll("%i", i);
		}
	}
	DownloadShit();
}
public Action CMD_T(client,args)
{
	PrecacheSound("wefliem/hit.mp3");
	EmitSoundToClient(client, "wefliem/hit.mp3");
}
DownloadShit()
{
	PrecacheSound("wefliem/hit.mp3");
	AddFileToDownloadsTable("sound/wefliem/hit.mp3");
	//Also add particle file and materials for them.
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
			
			if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client))
			{
				//Display particle that human has killed zombie.
				if(IgnoreHits[client] == true)
				{
					//Display hitmarker for attacker that zombie is killed.
				}
			}
			//Particle thingy for zombie we display on ZR_OnClientInfected callback.
			}
			//if(GetCookieInt(9))
		}
	}
}
public ZR_OnClientInfected(client, attacker)
{
	//PrintToChatAll("debug: client->%i attacker->%i", client, attacker);
	if(client != attacker)
	{
		if (!IsValidEntity(client) || !IsValidEntity(attacker))return;//We have to have only this situation (Player Infected Other Player), else do nothing.
		//PrintToChatAll("FINE");
		//Display infected someone particle.
	}
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	//PrintToChat(client, "DEBUG ALL FINE");
	if(GetCookieInt(client, g_Setting_ClientSound) < 1) EmitSoundToClient(attacker, "wefliem/hit.mp3");
	if(GetCookieInt(client, g_Setting_ParamX) < 1)
	{
	int health = GetEntProp(client, Prop_Send, "m_iHealth");
	//PrintToChat(attacker, "%i", health);
	if (!IsValidEntity(client) || !IsValidEntity(attacker))return;//To make sure client has not dealt damage to himself or damage goes from world or etc..
	if (ZR_IsClientZombie(attacker))return;//Zombies must see only infection skull thingy
	if(health < 10)
	{
		//Zombie has too much HP and about to die.
		//We have to keep in mind that we have to display partcile that zombie was killed.
		IgnoreHits[client] = true;
		return;
	} else IgnoreHits[client] = false;
	char particlename[64];
	if(damage > 100.0)
	{
		
		//DIsplay particle with damage > 100 (yellow or some kind of this shit)
	}else {
		particlename = "burning_3hitmarkerg_copy";
	}
	float pos[3];
	float ang[3];
	GetClientAbsOrigin(attacker, pos);
	GetClientAbsAngles(attacker, ang);
	int ent = CreateEntityByName("info_particle_system");
	if(ent == -1) SetFailState("Error creating \"info_particle_system\" entity!");		
	TeleportEntity(ent, pos, ang, NULL_VECTOR);		
	DispatchKeyValue(ent, "effect_name", particlename);
	DispatchKeyValue(ent, "start_active", "1");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", attacker);
	SDKHook(ent, SDKHook_SetTransmit, SetTransmit_Hook);
	SetVariantString("OnUser1 !self:kill::0.3:-1");
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
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
	//Put menu shit inside this function.
	new Handle:menu = CreateMenu(SetaFunctionelSWITCH);
	SetMenuTitle(menu, "Хитмаркер & Звуки");
	char SoundSTR[48];
	char HitSTR[48];
	//More than 0 means that it is turned off(by default it is toggled on that's why)
	if(state > 0)
	{
		HitSTR = "Хитмаркер (● ○)";
	} else HitSTR = "Хитмаркер (○ ●)";
	if(sst > 0)
	{
		SoundSTR = "Звук попадания (● ○)";
	} else SoundSTR = "Звук попадания (○ ●)";
	AddMenuItem(menu, "htoggle", HitSTR);
	AddMenuItem(menu, "stoggle", SoundSTR);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 35);
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
					PrintToChat(param1, "Хитмаркер: ВКЛ");
					SetClientCookieInt(param1, g_Setting_ParamX, 0);
					FakeClientCommand(param1, "toggleh");
				}else {
					SetClientCookieInt(param1, g_Setting_ParamX, 1);
					PrintToChat(param1, "Хитмаркер: ВЫКЛ");
					FakeClientCommand(param1, "toggleh");
				}
			}else if(StrEqual(item, "stoggle"))
			{
				int wtf = GetCookieInt(param1, g_Setting_ClientSound);
				if(wtf > 0)
				{
					PrintToChat(param1, "Звук хитмаркера: ВКЛ");
					SetClientCookieInt(param1, g_Setting_ClientSound, 0);
					FakeClientCommand(param1, "toggleh");
				}else {
					SetClientCookieInt(param1, g_Setting_ClientSound, 1);
					PrintToChat(param1, "Звук хитмаркера: ВЫКЛ");
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
