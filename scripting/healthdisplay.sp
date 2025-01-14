#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <healthdisplay>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <synmodes>
#tryinclude <synbuildnpcinfo>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "1.995"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/healthdisplayupdater.txt"

public Plugin myinfo = 
{
	name = "HealthDisplay",
	author = "Balimbanana",
	description = "Shows health of npcs while looking at them.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

Handle airelarr = INVALID_HANDLE;
Handle htarr = INVALID_HANDLE;
Handle liarr = INVALID_HANDLE;
Handle globalsarr = INVALID_HANDLE;
bool bugbaitpicked = false;
bool ShowPlayers = false;
bool SynModesAct = false;
int targmode = 0;
float antispamchk[128];

Handle Handle_Database = INVALID_HANDLE;
char SteamID[128][32];
int bclcookie[128];
int bclcookie2[128];
int bclcookie3[128];
int bclcookie4[128][3];
int bclcookie4f[128][3];
int defaultmode = 0;
float bclcookie5x[128];
float bclcookie5y[128];
int hChanged[128];

public void OnPluginStart()
{
	LoadTranslations("healthdisplay.phrases");
	LoadTranslations("colors.phrases");
	airelarr = CreateArray(64);
	htarr = CreateArray(64);
	liarr = CreateArray(64);
	globalsarr = CreateArray(16);
	char Err[100];
	Handle_Database = SQLite_UseDatabase("sourcemod-local",Err,100-1);
	if (Handle_Database == INVALID_HANDLE)
		LogError("SQLite error: %s",Err);
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS healthdisplay(SteamID VARCHAR(32) NOT NULL PRIMARY KEY,H1 INT NOT NULL,H2 INT NOT NULL,H3 INT NOT NULL,H4 INT NOT NULL,H5 INT NOT NULL,H6 INT NOT NULL,H7 INT NOT NULL,H8 INT NOT NULL,H9 INT NOT NULL,H10 FLOAT NOT NULL,H11 FLOAT NOT NULL);"))
	{
		char Err2[100];
		SQL_GetError(Handle_Database,Err2,100);
		LogError("SQLite error: %s",Err2);
	}
	//Update legacy databases
	char tmpquer[100];
	Format(tmpquer,sizeof(tmpquer),"SELECT H10, H11 FROM healthdisplay;");
	if (!SQL_FastQuery(Handle_Database,tmpquer))
	{
		//Update legacy database
		//Can't put these all on one query for some reason,
		//but it is for the local database so it shouldn't be too much of a spam.
		Format(tmpquer,sizeof(tmpquer),"ALTER TABLE healthdisplay ADD H10 FLOAT NOT NULL DEFAULT (-1.0);");
		SQL_FastQuery(Handle_Database,tmpquer);
		Format(tmpquer,sizeof(tmpquer),"ALTER TABLE healthdisplay ADD H11 FLOAT NOT NULL DEFAULT (0.55);");
		SQL_FastQuery(Handle_Database,tmpquer);
		return;
	}
	Handle targmodh = CreateConVar("healthdisplay_targmode", "2", "Set targeting mode by: traceray and aimtarget 2, traceray 1, or aimtarget 0.", _, true, 0.0, true, 2.0);
	HookConVarChange(targmodh, targmodech);
	targmode = GetConVarInt(targmodh);
	CloseHandle(targmodh);
	Handle defmodeh = CreateConVar("healthdisplay_defaultmode", "0", "Set default healthdisplay mode for new clients.", _, true, 0.0, true, 3.0);
	HookConVarChange(defmodeh, defaultmodech);
	defaultmode = GetConVarInt(defmodeh);
	CloseHandle(defmodeh);
	//This is on a timer to call a function because when the function is called at this point,
	//it can sometimes fail, so I found it was best to wait 1 second.
	CreateTimer(1.0, reloadclientstime);
	RegConsoleCmd("hpmenu",showinf);
	RegConsoleCmd("hitpointmenu",showinf);
	RegConsoleCmd("sm_healthdisplay",showinf);
	RegConsoleCmd("sm_healthtype",sethealthtype);
	RegConsoleCmd("sm_healthnum",sethealthnum);
	RegConsoleCmd("sm_healthfriendlies",sethealthfriendly);
	RegConsoleCmd("sm_healthcolor",Display_HudSelect);
	RegConsoleCmd("sm_healthfriendcol",Display_HudFriendSelect);
	RegConsoleCmd("sm_healthenemycol",Display_HudEnemySelect);
	RegConsoleCmd("sm_healthpos",sethealthhudpos);
	CreateTimer(10.0,cleararr,_,TIMER_REPEAT);
	CreateTimer(0.1,ShowTimer,_,TIMER_REPEAT);
}

public void OnMapStart()
{
	ClearArray(airelarr);
	ClearArray(htarr);
	ClearArray(liarr);
	ClearArray(globalsarr);
	char gamedescoriginal[24];
	GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
	ReplaceString(gamedescoriginal,sizeof(gamedescoriginal),"synergy","",false);
	ReplaceString(gamedescoriginal,sizeof(gamedescoriginal)," ","",false);
	if ((StrEqual(gamedescoriginal,"20.1",false)) || (StrEqual(gamedescoriginal,"20.3",false))) ShowPlayers = true;
	bugbaitpicked = false;
	HookEntityOutput("weapon_bugbait", "OnPlayerPickup", onbugbaitpickup);
}

public void OnAllPluginsLoaded()
{
	Handle cvar = FindConVar("sm_gamemodeset");
	if (cvar != INVALID_HANDLE) SynModesAct = true;
	else SynModesAct = false;
	CloseHandle(cvar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("HealthDisplay");
	CreateNative("CheckNPCAlly", Native_GetNPCAlly);
	CreateNative("GetLIList", Native_GetLIList);
	CreateNative("GetHTList", Native_GetHTList);
	MarkNativeAsOptional("GetCLTeam");
	MarkNativeAsOptional("GetNPCNames");
	MarkNativeAsOptional("GetNPCEnts");
	return APLRes_Success;
}

public int Native_GetNPCAlly(Handle plugin, int numParams)
{
	if (numParams > 1)
	{
		char clsname[64];
		GetNativeString(1,clsname,sizeof(clsname));
		int enttarg = GetNativeCell(2);
		if (!GetNPCAlly(clsname,enttarg)) return false;
		else return true;
	}
	return false;
}

public int Native_GetLIList(Handle plugin, int numParams)
{
	return view_as<int>(liarr);
	//return _:liarr;
}

public int Native_GetHTList(Handle plugin, int numParams)
{
	return view_as<int>(htarr);
	//return _:htarr;
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	GetClientAuthId(client,AuthId_Steam2,SteamID[client],32-1);
	ReplaceString(SteamID[client],sizeof(SteamID[]),"STEAM_1","STEAM_0");
	LoadClient(client);
}

public void OnClientPutInServer(int client)
{
	GetClientAuthId(client,AuthId_Steam2,SteamID[client],32-1);
	ReplaceString(SteamID[client],sizeof(SteamID[]),"STEAM_1","STEAM_0");
	LoadClient(client);
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		LoadClient(client);
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	if (StrEqual(name,"SynBuildNPCInfo",false))
	{
		SynNPCInfRunning = true;
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public Action showinf(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	char titledisp[64];
	Format(titledisp,sizeof(titledisp),"%T","HealthMenuTitle",client);
	menu.SetTitle(titledisp);
	char hdtype[64];
	Format(hdtype,sizeof(hdtype),"%T","HealthMenuType",client);
	menu.AddItem("type",hdtype);
	char hdfr[64];
	Format(hdfr,sizeof(hdfr),"%T","HealthMenuFR",client);
	menu.AddItem("friendlies",hdfr);
	char hdnum[64];
	Format(hdnum,sizeof(hdnum),"%T","HealthMenuNum",client);
	menu.AddItem("num",hdnum);
	char hdcol[64];
	Format(hdcol,sizeof(hdcol),"%T","HealthMenuCol",client);
	menu.AddItem("color",hdcol);
	menu.ExitButton = true;
	menu.Display(client, 120);
	if (args != 10)
	{
		PrintToChat(client,"!healthtype <1-4>");
		PrintToChat(client,"%T","HealthTypeDesc",client);
		PrintToChat(client,"!healthfriendlies <0-2>");
		PrintToChat(client,"%T","HealthFriendlyDesc",client);
		PrintToChat(client,"!healthnum <1-2>");
		PrintToChat(client,"%T","HealthNum",client);
		PrintToChat(client,"%T","HealthColMenu",client);
		PrintToChat(client,"!healthpos <0.1> <0.1>");
	}
	return Plugin_Handled;
}

public Action sethealthtype(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"!healthtype <1-4>");
		PrintToChat(client,"%T","HealthTypeDesc",client);
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		char sethdto[128];
		char setting[64];
		if (numset == 0)
		{
			PrintToChat(client,"%T","InvalidNum",client);
			return Plugin_Handled;
		}
		else if (numset == 1)
		{
			Format(setting,sizeof(setting),"%T","HudText",client);
			bclcookie[client] = 0;
			hChanged[client] = 1;
		}
		else if (numset == 2)
		{
			Format(setting,sizeof(setting),"%T","HintTxt",client);
			bclcookie[client] = 1;
			hChanged[client] = 1;
		}
		else if (numset == 3)
		{
			Format(setting,sizeof(setting),"%T","CenterTxt",client);
			bclcookie[client] = 2;
			hChanged[client] = 1;
		}
		else
		{
			PrintToChat(client,"%T","DisabledHD",client);
			bclcookie[client] = 3;
			hChanged[client] = 1;
			return Plugin_Handled;
		}
		Format(sethdto,sizeof(sethdto),"%T","HealthSetTo",client,setting);
		PrintToChat(client,"%s",sethdto);
	}
	return Plugin_Handled;
}

public Action sethealthfriendly(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"!healthfriendlies <0-2>");
		PrintToChat(client,"%T","HealthFriendlyDesc",client);
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		char sethdto[128];
		char setting[64];
		if (numset == 0)
		{
			Format(setting,sizeof(setting),"%T","EnemiesOnly",client);
			bclcookie3[client] = 0;
			hChanged[client] = 1;
		}
		else if (numset == 1)
		{
			Format(setting,sizeof(setting),"%T","Friendlies",client);
			bclcookie3[client] = 1;
			hChanged[client] = 1;
		}
		else if (numset == 2)
		{
			Format(setting,sizeof(setting),"%T","FriendliesWith",client);
			bclcookie3[client] = 2;
			hChanged[client] = 1;
		}
		else
		{
			PrintToChat(client,"%T","InvalidNum",client);
			return Plugin_Handled;
		}
		Format(sethdto,sizeof(sethdto),"%T","HealthSetTo",client,setting);
		PrintToChat(client,"%s",sethdto);
	}
	return Plugin_Handled;
}

public Action sethealthnum(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"!healthnum <1-2>");
		PrintToChat(client,"%T","HealthNum",client);
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		char sethdto[128];
		char setting[64];
		if ((numset == 0) || (numset > 2))
		{
			PrintToChat(client,"%T","InvalidNum",client);
			return Plugin_Handled;
		}
		else if (numset == 1)
		{
			Format(setting,sizeof(setting),"%T","Percentage",client);
			bclcookie2[client] = 0;
			hChanged[client] = 1;
		}
		else if (numset == 2)
		{
			Format(setting,sizeof(setting),"%T","HitPoints",client);
			bclcookie2[client] = 1;
			hChanged[client] = 1;
		}
		Format(sethdto,sizeof(sethdto),"%T","HealthSetTo",client,setting);
		PrintToChat(client,"%s",sethdto);
	}
	return Plugin_Handled;
}

public Action cleararr(Handle timer)
{
	//This is to force recheck of ai relationships as the lowest impact check possible.
	ClearArray(htarr);
	ClearArray(liarr);
	ClearArray(airelarr);
	for (int client = 1;client<MaxClients+1;client++)
	{
		if (IsClientInGame(client))
		{
			if (!IsFakeClient(client))
			{
				CLStoreInTable(client);
				if (strlen(SteamID[client]) > 8)
				{
					if (FindStringInArray(liarr,SteamID[client]) == -1)
						PushArrayString(liarr,SteamID[client]);
				}
			}
		}
	}
	findairel(-1,"ai_relationship");
	addht("npc_combine_s");
	addht("npc_metropolice");
	addht("prop_vehicle_apc");
	addht("npc_breen");
	addht("npc_barnacle");
	addht("npc_combine_camera");
	addht("npc_helicopter");
	addht("npc_cscanner");
	addht("npc_rollermine");
	addht("npc_combinegunship");
	addht("npc_combinedropship");
	addht("npc_turret_ceiling");
	addht("npc_turret_ground");
	addht("npc_manhack");
	addht("npc_strider");
	addht("npc_stalker");
	addht("npc_sniper");
	addht("npc_turret_floor");
	addht("npc_zombie");
	addht("npc_zombie_torso");
	addht("npc_zombie_worker");
	addht("npc_zombine");
	addht("npc_fastzombie");
	addht("npc_fastzombie_torso");
	addht("npc_poisonzombie");
	addht("npc_headcrab");
	addht("npc_headcrab_poison");
	addht("npc_headcrab_black");
	addht("npc_headcrab_fast");
	addht("npc_gargantua");
	addht("npc_gonarch");
	addht("npc_babycrab");
	addht("npc_hunter");
	addht("npc_advisor");
	addht("npc_antlion");
	addht("npc_antlionworker");
	addht("npc_antlionguard");
	addht("npc_zombie_scientist");
	addht("npc_zombie_scientist_torso");
	addht("npc_zombie_security");
	addht("npc_alien_slave");
	addht("npc_alien_grunt");
	addht("npc_houndeye");
	addht("npc_tentacle");
	addht("npc_snark");
	addht("npc_bullsquid");
	addht("npc_sentry_ground");
	addht("npc_sentry_ceiling");
	addht("npc_human_grunt");
	addht("npc_human_commander");
	addht("npc_human_medic");
	addht("npc_human_grenadier");
	addht("npc_human_assassin");
	addht("npc_abrams");
	addht("npc_apache");
	addht("npc_ichthyosaur");
	addht("npc_clawscanner");
	addht("npc_doramn_window");
	addht("npc_doramn_power_cell");
	addht("monster_alien_slave");
	addht("monster_bullchicken");
	addht("monster_headcrab");
	addht("monster_ichthyosaur");
	addht("monster_tentacle");
	addht("monster_sentry");
	addht("monster_snark");
	addht("monster_houndeye");
	addht("monster_barnacle");
	addht("monster_apache");
	addht("monster_zombie");
	addht("monster_alien_grunt");
	addht("monster_bigmomma");
	addht("monster_babycrab");
	addht("monster_gargantua");
	addht("monster_human_assassin");
	addht("monster_human_grunt");
	addht("monster_miniturret");
	addht("monster_nihilanth");
	for (int i = 0;i<GetArraySize(airelarr);i++)
	{
		int rel = GetArrayCell(airelarr, i);
		if (IsValidEntity(rel))
		{
			char clsnamechk[16];
			GetEntityClassname(rel, clsnamechk, sizeof(clsnamechk));
			if (StrEqual(clsnamechk,"ai_relationship",false))
			{
				char subj[32];
				GetEntPropString(rel,Prop_Data,"m_iszSubject",subj,sizeof(subj));
				char targ[32];
				GetEntPropString(rel,Prop_Data,"m_target",targ,sizeof(targ));
				int disp = GetEntProp(rel,Prop_Data,"m_iDisposition");
				int act = GetEntProp(rel,Prop_Data,"m_bIsActive");
				//disp 1 = D_HT // 2 = D_NT // 3 = D_LI // 4 = D_FR
				//PrintToServer("sub %s targ %s disp %i act %i",subj,targ,disp,act);
				if ((StrContains(targ,"player",false) != -1) && (disp == 1) && (act != 0))
				{
					if (FindStringInArray(htarr,targ) == -1)
						addht(subj);
				}
				else if ((StrContains(targ,"player",false) != -1) && (disp == 3) && (act != 0))
				{
					//PrintToServer("Rem %s %i",subj,disp);
					int find = FindStringInArray(htarr,subj);
					if (find != -1)
					{
						RemoveFromArray(htarr,find);
					}
					if (FindStringInArray(liarr,subj) == -1)
						PushArrayString(liarr,subj);
				}
				else if ((StrContains(subj,"player",false) != -1) && (disp == 1) && (act != 0))
				{
					if (FindStringInArray(htarr,targ) == -1)
						addht(targ);
				}
				else if ((StrContains(subj,"player",false) != -1) && (disp == 3) && (act != 0))
				{
					//PrintToServer("Rem %s %i",targ,disp);
					int find = FindStringInArray(htarr,targ);
					if (find != -1)
					{
						RemoveFromArray(htarr,find);
						find = FindStringInArray(htarr,targ);
						if (find != -1)
						{
							RemoveFromArray(htarr,find);
						}
					}
					if (FindStringInArray(liarr,targ) == -1)
						PushArrayString(liarr,targ);
				}
			}
		}
		else
			findairel(-1,"ai_relationship");
	}
	if (GetAntAlly())
	{
		int find = FindStringInArray(htarr,"npc_antlion");
		if (find != -1)
			RemoveFromArray(htarr,find);
	}
}

bool IsInViewCtrl(int client)
{
	if ((IsValidEntity(client)) && (IsClientConnected(client)))
	{
		int m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
		char classname[20];
		if(IsValidEdict(m_hViewEntity) && GetEdictClassname(m_hViewEntity,classname,sizeof(classname)))
			if(StrEqual(classname, "point_viewcontrol"))
				return true;
	}
	return false;
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if (StrEqual(clsname,"func_vehicleclip",false))
			return false;
	}
	if (entity == data)
	{
		return false;
	}
	return true;
}

//public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
public Action ShowTimer(Handle timer)
{
	for (int client = 1;client<MaxClients+1;client++)
	{
		if (IsValidEntity(client))
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client) && !IsFakeClient(client) && (bclcookie[client] != 3))
				{
					int targ = -1;
					float PlayerOrigin[3];
					float Location[3];
					float clang[3];
					GetClientEyePosition(client, Location);
					GetClientEyeAngles(client,clang);
					Handle hhitpos = INVALID_HANDLE;
					if (targmode == 1)
					{
						TR_TraceRayFilter(Location,clang,MASK_VISIBLE_AND_NPCS,RayType_Infinite,TraceEntityFilter,client);
						targ = TR_GetEntityIndex(hhitpos);
					}
					else if (targmode == 2)
					{
						TR_TraceRayFilter(Location,clang,MASK_VISIBLE_AND_NPCS,RayType_Infinite,TraceEntityFilter,client);
						int tmptarg = TR_GetEntityIndex(hhitpos);
						targ = GetClientAimTarget(client,false);
						if (targ != tmptarg)
						{
							if (IsValidEntity(targ))
							{
								char clsname[32];
								GetEntityClassname(targ,clsname,sizeof(clsname));
								int vck = GetEntProp(client,Prop_Send,"m_hVehicle");
								if ((StrContains(clsname,"clip",false) != -1) || ((StrContains(clsname,"prop_vehicle",false) != -1) && (vck != -1)))
								{
									PlayerOrigin[0] = (Location[0] + (60 * Cosine(DegToRad(clang[1]))));
									PlayerOrigin[1] = (Location[1] + (60 * Sine(DegToRad(clang[1]))));
									PlayerOrigin[2] = (Location[2] + 10);
									Location[0] = (PlayerOrigin[0] + (10 * Cosine(DegToRad(clang[1]))));
									Location[1] = (PlayerOrigin[1] + (10 * Sine(DegToRad(clang[1]))));
									Location[2] = (PlayerOrigin[2] + 10);
									if (vck != -1)
									{
										Location[0] = (PlayerOrigin[0] - (10 * Cosine(DegToRad(clang[1]))));
										Location[1] = (PlayerOrigin[1] - (10 * Sine(DegToRad(clang[1]))));
										Location[2] = (PlayerOrigin[2] - 10);
									}
									Handle hhitposthrough = INVALID_HANDLE;
									TR_TraceRayFilter(Location,clang,MASK_VISIBLE_AND_NPCS,RayType_Infinite,TraceEntityFilter,client);
									targ = TR_GetEntityIndex(hhitposthrough);
									CloseHandle(hhitposthrough);
									if (targ != -1)
										GetEntityClassname(targ,clsname,sizeof(clsname));
								}
								else targ = -1;
							}
							else targ = -1;
						}
					}
					else
					{
						targ = GetClientAimTarget(client,false);
					}
					CloseHandle(hhitpos);
					if ((targ != -1) && ((targ > MaxClients) || (ShowPlayers)))
					{
						char clsname[64];
						GetEntityClassname(targ,clsname,sizeof(clsname));
						int vck = GetEntProp(client,Prop_Send,"m_hVehicle");
						if ((StrContains(clsname,"clip",false) != -1) || ((StrContains(clsname,"prop_vehicle",false) != -1) && (vck != -1)))
						{
							PlayerOrigin[0] = (Location[0] + (60 * Cosine(DegToRad(clang[1]))));
							PlayerOrigin[1] = (Location[1] + (60 * Sine(DegToRad(clang[1]))));
							PlayerOrigin[2] = (Location[2] + 10);
							Location[0] = (PlayerOrigin[0] + (10 * Cosine(DegToRad(clang[1]))));
							Location[1] = (PlayerOrigin[1] + (10 * Sine(DegToRad(clang[1]))));
							Location[2] = (PlayerOrigin[2] + 10);
							if (vck != -1)
							{
								Location[0] = (PlayerOrigin[0] - (10 * Cosine(DegToRad(clang[1]))));
								Location[1] = (PlayerOrigin[1] - (10 * Sine(DegToRad(clang[1]))));
								Location[2] = (PlayerOrigin[2] - 10);
							}
							Handle hhitposthrough = INVALID_HANDLE;
							TR_TraceRayFilter(Location,clang,MASK_VISIBLE_AND_NPCS,RayType_Infinite,TraceEntityFilter,client);
							targ = TR_GetEntityIndex(hhitposthrough);
							CloseHandle(hhitposthrough);
							if (targ != -1)
								GetEntityClassname(targ,clsname,sizeof(clsname));
						}
						if ((targ != -1) && (IsValidEntity(targ)) && ((targ > MaxClients) || (ShowPlayers)))
						{
							char targn[64];
							if (StrEqual(clsname,"player",false))
							{
								Format(clsname,sizeof(clsname),"%N",targ);
								int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
								int maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
								float Time = GetTickedTime();
								if ((antispamchk[client] <= Time) && (curh > 0))
								{
									antispamchk[client] = Time + 0.07;
									if (!SynModesAct) PrintTheMsg(client,curh,maxh,clsname,true);
									else
									{
										int CurTeam = GetCLTeam(client);
										int TargTeam = GetCLTeam(targ);
										if (CurTeam != TargTeam) PrintTheMsg(client,curh,maxh,clsname,false);
										else PrintTheMsg(client,curh,maxh,clsname,true);
									}
								}
								continue;
							}
							else if (StrEqual(clsname,"generic_actor",false))
							{
								if (HasEntProp(targ,Prop_Data,"m_iName"))
								{
									GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (StrContains(targn,"lamar",false) != -1)
										Format(clsname,sizeof(clsname),"npc_lamarr");
									else if (HasEntProp(targ,Prop_Data,"m_hParent"))
									{
										int parchk = GetEntPropEnt(targ,Prop_Data,"m_hParent");
										if ((parchk != 0) && (IsValidEntity(parchk)))
										{
											targ = parchk;
											GetEntityClassname(targ,clsname,sizeof(clsname));
										}
									}
								}
							}
							else if (StrEqual(clsname,"npc_bullseye",false))
							{
								if (HasEntProp(targ,Prop_Data,"m_iName"))
								{
									GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (StrEqual(targn,"dra_bull_eye",false))
									{
										Format(clsname,sizeof(clsname),"npc_doramn_window");
									}
									else if (StrEqual(targn,"dra_bull",false))
									{
										Format(clsname,sizeof(clsname),"npc_doramn_power_cell");
									}
								}
							}
							if (SynNPCInfRunning)
							{
								Handle npcnameentsl = GetNPCEnts();
								if (npcnameentsl != INVALID_HANDLE)
								{
									int findname = FindValueInArray(npcnameentsl,targ);
									if (findname != -1)
									{
										Handle npcnamestrl = GetNPCNames();
										GetArrayString(npcnamestrl,findname,targn,sizeof(targn));
										if (strlen(targn) > 0)
										{
											if (!GetNPCAlly(clsname,targ))
											{
												Format(clsname,sizeof(clsname),"npc_%s",targn);
												addht(clsname);
											}
											Format(clsname,sizeof(clsname),"npc_%s",targn);
										}
										CloseHandle(npcnamestrl);
									}
								}
								CloseHandle(npcnameentsl);
							}
							if ((HasEntProp(targ,Prop_Data,"m_nRenderMode")) && (!StrEqual(clsname,"npc_houndeye",false)) && (!StrEqual(clsname,"npc_bullsquid",false)))
								if (GetEntProp(targ,Prop_Data,"m_nRenderMode") == 10) targ = 0;
							if (HasEntProp(targ,Prop_Data,"m_NPCState"))
								if (GetEntProp(targ,Prop_Data,"m_NPCState") == 7) targ = 0;
						}
						if  ((targ == -1) || (targ == 0) || (!IsValidEntity(targ))) continue;
						if ((targ != -1) && ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"monster_",false) != -1)) && (!StrEqual(clsname,"npc_furniture")) && (!StrEqual(clsname,"npc_bullseye")) && (StrContains(clsname,"grenade",false) == -1) && (StrContains(clsname,"satchel",false) == -1) && (!IsInViewCtrl(client)) || (StrEqual(clsname,"prop_vehicle_apc",false)))
						{
							bool ismonster = false;
							bool friendly = true;
							if (!GetNPCAlly(clsname,targ))
							{
								friendly = false;
							}
							if (!bclcookie3[client])
							{
								if (!friendly)
								{
									int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
									if (StrContains(clsname,"monster_",false) != -1)
									{
										ReplaceString(clsname,sizeof(clsname),"monster_","");
										ismonster = true;
									}
									else ReplaceString(clsname,sizeof(clsname),"npc_","");
									int maxh = 20;
									if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
									{
										maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
										if (StrEqual(clsname,"combine_camera",false))
											maxh = 50;
										else if (StrEqual(clsname,"antlion_grub",false))
											maxh = 1;
										else if (StrEqual(clsname,"combinedropship",false))
											maxh = 100;
										else if ((maxh == 0) && ((StrEqual(clsname,"turret_ceiling",false)) || (StrEqual(clsname,"security_camera",false))))
											maxh = 1000;
										else if (maxh == 0)
										{
											char cvarren[32];
											if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
											else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
											Handle cvarchk = FindConVar(cvarren);
											if (cvarchk == INVALID_HANDLE)
												maxh = 20;
											else
												maxh = GetConVarInt(cvarchk);
										}
									}
									clsname[0] &= ~(1 << 5);
									float Time = GetTickedTime();
									if ((antispamchk[client] <= Time) && (curh > 0))
									{
										if (StrEqual(clsname,"combine_s",false))
										{
											char cmodel[64];
											GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
											if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
												Format(clsname,sizeof(clsname),"Combine Elite");
											else if (StrContains(cmodel,"models/sttr_easyrider",false) == 0)
												Format(clsname,sizeof(clsname),"Easy Rider");
											else if (StrContains(cmodel,"models/helghast/",false) == 0)
												Format(clsname,sizeof(clsname),"Helghast Soldier");
											else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
												Format(clsname,sizeof(clsname),"Combine Shotgunner");
											else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
												Format(clsname,sizeof(clsname),"Combine Guard");
											else
												Format(clsname,sizeof(clsname),"Combine Soldier");
										}
										else if (StrEqual(clsname,"citizen",false))
										{
											char targn[64];
											char cmodel[64];
											GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
											if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
											if (StrEqual(cmodel,"models/odessa.mdl",false)) Format(clsname,sizeof(clsname),"Odessa Cubbage");
											else if (StrContains(cmodel,"models/humans/group03m/",false) == 0) Format(clsname,sizeof(clsname),"Rebel Medic");
											else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Griggs");
											else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Sheckley");
											else if (StrContains(targn,"larry",false) != -1) Format(clsname,sizeof(clsname),"Larry");
											else if (StrContains(targn,"anne",false) != -1) Format(clsname,sizeof(clsname),"Anne");
											else if (StrContains(targn,"arthur",false) != -1) Format(clsname,sizeof(clsname),"Arthur");
											else if (StrContains(targn,"sarah",false) != -1) Format(clsname,sizeof(clsname),"Sarah");
											else if (StrContains(targn,"mary",false) != -1) Format(clsname,sizeof(clsname),"Mary");
											else if (StrContains(targn,"matt",false) != -1) Format(clsname,sizeof(clsname),"Matt");
											else if (StrEqual(targn,"mina",false)) Format(clsname,sizeof(clsname),"Mina");
											else if (StrEqual(targn,"arlene",false)) Format(clsname,sizeof(clsname),"Arlene");
											else if (StrEqual(targn,"john",false)) Format(clsname,sizeof(clsname),"John");
											else if (StrContains(targn,"mitch",false) != -1) Format(clsname,sizeof(clsname),"Mitch");
											else if ((StrEqual(targn,"argento",false)) || (StrEqual(targn,"rebel_argento",false))) Format(clsname,sizeof(clsname),"Argento");
											else if (StrContains(targn,"oleg",false) != -1) Format(clsname,sizeof(clsname),"Oleg");
											else if (StrEqual(targn,"Richard",false)) Format(clsname,sizeof(clsname),"Richard");
											else if (StrEqual(targn,"laura",false)) Format(clsname,sizeof(clsname),"Laura");
											else if (StrEqual(targn,"winston",false)) Format(clsname,sizeof(clsname),"Winston");
											else if (StrEqual(targn,"stanley",false)) Format(clsname,sizeof(clsname),"Stanley");
											else if (StrEqual(targn,"tobias",false)) Format(clsname,sizeof(clsname),"Laszlo Tobias");
											else if (StrEqual(targn,"chester",false)) Format(clsname,sizeof(clsname),"Chester");
											else if (StrEqual(targn,"warehouse_citizen_leon",false)) Format(clsname,sizeof(clsname),"Leon");
											else if ((StrEqual(targn,"jackCarver",false)) || (StrEqual(targn,"jack",false))) Format(clsname,sizeof(clsname),"Jack");
											else if ((StrContains(targn,"ugly",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_02.mdl",false))) Format(clsname,sizeof(clsname),"The Ugly");
											else if ((StrContains(targn,"bad",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_03.mdl",false))) Format(clsname,sizeof(clsname),"The Bad");
											else if (StrEqual(targn,"mike",false)) Format(clsname,sizeof(clsname),"Mike");
											else if (StrEqual(targn,"Larson",false)) Format(clsname,sizeof(clsname),"Larson");
											else if (StrEqual(targn,"Eloise",false)) Format(clsname,sizeof(clsname),"Eloise");
											else if (StrEqual(targn,"Noah",false)) Format(clsname,sizeof(clsname),"Noah");
											else if (StrEqual(targn,"Eve",false)) Format(clsname,sizeof(clsname),"Eve");
											else if ((StrEqual(targn,"Olivia",false)) || (StrEqual(targn,"actor_olivia",false))) Format(clsname,sizeof(clsname),"Olivia");
											else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Refugee");
											else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Rebel");
											if (GetNPCAllyTarg(targn)) friendly = true;
										}
										else if (StrEqual(clsname,"turret_floor",false))
										{
											Format(clsname,sizeof(clsname),"Floor Turret");
										}
										else if (StrEqual(clsname,"cscanner",false))
										{
											char cmodel[64];
											GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
											if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Claw Scanner");
										}
										else if (StrEqual(clsname,"vortigaunt",false))
										{
											char cmodel[64];
											GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
											if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Uriah");
											else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Vortigaunt Slave");
										}
										else if (StrEqual(clsname,"antlion",false))
										{
											char cmodel[64];
											GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
											if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
										}
										else if (StrEqual(clsname,"antlionguard",false))
										{
											Format(clsname,sizeof(clsname),"Antlion Guard");
											if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Antlion Guardian");
										}
										else if (StrEqual(clsname,"rollermine",false))
										{
											curh = 1;
											maxh = 1;
										}
										else if (StrEqual(clsname,"alyx",false))
										{
											char targn[64];
											if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
											if (StrEqual(targn,"clockface_npc",false)) Format(clsname,sizeof(clsname),"Clock Face");
										}
										antispamchk[client] = Time + 0.07;
										PrintTheMsg(client,curh,maxh,clsname,friendly);
									}
								}
							}
							else if (bclcookie3[client] == 1)
							{
								int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
								if (StrContains(clsname,"monster_",false) != -1)
								{
									ReplaceString(clsname,sizeof(clsname),"monster_","");
									ismonster = true;
								}
								else ReplaceString(clsname,sizeof(clsname),"npc_","");
								int maxh = 20;
								if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
								{
									maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
									if (StrEqual(clsname,"combine_camera",false))
										maxh = 50;
									else if (StrEqual(clsname,"antlion_grub",false))
										maxh = 1;
									else if (StrEqual(clsname,"combinedropship",false))
										maxh = 100;
									else if ((maxh == 0) && ((StrEqual(clsname,"turret_ceiling",false)) || (StrEqual(clsname,"security_camera",false))))
										maxh = 1000;
									else if (maxh == 0)
									{
										char cvarren[32];
										if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
										else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
										Handle cvarchk = FindConVar(cvarren);
										if (cvarchk == INVALID_HANDLE)
											maxh = 20;
										else
											maxh = GetConVarInt(cvarchk);
									}
								}
								clsname[0] &= ~(1 << 5);
								float Time = GetTickedTime();
								if ((antispamchk[client] <= Time) && (curh > 0))
								{
									char targn[64];
									if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (StrEqual(clsname,"combine_s",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
											Format(clsname,sizeof(clsname),"Combine Elite");
										else if (StrContains(cmodel,"models/sttr_easyrider",false) == 0)
											Format(clsname,sizeof(clsname),"Easy Rider");
										else if (StrContains(cmodel,"models/helghast/",false) == 0)
											Format(clsname,sizeof(clsname),"Helghast Soldier");
										else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
												Format(clsname,sizeof(clsname),"Combine Shotgunner");
										else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
											Format(clsname,sizeof(clsname),"Combine Guard");
										else
											Format(clsname,sizeof(clsname),"Combine Soldier");
									}
									else if (StrEqual(clsname,"combinedropship",false)) Format(clsname,sizeof(clsname),"Combine Dropship");
									else if (StrEqual(clsname,"citizen",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/odessa.mdl",false)) Format(clsname,sizeof(clsname),"Odessa Cubbage");
										else if (StrContains(cmodel,"models/humans/group03m/",false) == 0) Format(clsname,sizeof(clsname),"Rebel Medic");
										else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Griggs");
										else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Sheckley");
										else if (StrContains(targn,"larry",false) != -1) Format(clsname,sizeof(clsname),"Larry");
										else if (StrContains(targn,"anne",false) != -1) Format(clsname,sizeof(clsname),"Anne");
										else if (StrContains(targn,"arthur",false) != -1) Format(clsname,sizeof(clsname),"Arthur");
										else if (StrContains(targn,"sarah",false) != -1) Format(clsname,sizeof(clsname),"Sarah");
										else if (StrContains(targn,"mary",false) != -1) Format(clsname,sizeof(clsname),"Mary");
										else if (StrContains(targn,"matt",false) != -1) Format(clsname,sizeof(clsname),"Matt");
										else if (StrEqual(targn,"mina",false)) Format(clsname,sizeof(clsname),"Mina");
										else if (StrEqual(targn,"arlene",false)) Format(clsname,sizeof(clsname),"Arlene");
										else if ((StrEqual(targn,"argento",false)) || (StrEqual(targn,"rebel_argento",false))) Format(clsname,sizeof(clsname),"Argento");
										else if (StrEqual(targn,"oleg",false)) Format(clsname,sizeof(clsname),"Oleg");
										else if (StrEqual(targn,"Richard",false)) Format(clsname,sizeof(clsname),"Richard");
										else if (StrEqual(targn,"laura",false)) Format(clsname,sizeof(clsname),"Laura");
										else if (StrEqual(targn,"winston",false)) Format(clsname,sizeof(clsname),"Winston");
										else if (StrEqual(targn,"stanley",false)) Format(clsname,sizeof(clsname),"Stanley");
										else if (StrEqual(targn,"tobias",false)) Format(clsname,sizeof(clsname),"Laszlo Tobias");
										else if (StrEqual(targn,"chester",false)) Format(clsname,sizeof(clsname),"Chester");
										else if (StrEqual(targn,"warehouse_citizen_leon",false)) Format(clsname,sizeof(clsname),"Leon");
										else if ((StrEqual(targn,"jackCarver",false)) || (StrEqual(targn,"jack",false))) Format(clsname,sizeof(clsname),"Jack");
										else if ((StrContains(targn,"ugly",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_02.mdl",false))) Format(clsname,sizeof(clsname),"The Ugly");
										else if ((StrContains(targn,"bad",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_03.mdl",false))) Format(clsname,sizeof(clsname),"The Bad");
										else if (StrEqual(targn,"mike",false)) Format(clsname,sizeof(clsname),"Mike");
										else if (StrEqual(targn,"Larson",false)) Format(clsname,sizeof(clsname),"Larson");
										else if (StrEqual(targn,"Eloise",false)) Format(clsname,sizeof(clsname),"Eloise");
										else if (StrEqual(targn,"Noah",false)) Format(clsname,sizeof(clsname),"Noah");
										else if (StrEqual(targn,"Eve",false)) Format(clsname,sizeof(clsname),"Eve");
										else if ((StrEqual(targn,"Olivia",false)) || (StrEqual(targn,"actor_olivia",false))) Format(clsname,sizeof(clsname),"Olivia");
										else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Refugee");
										else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Rebel");
										if (GetNPCAllyTarg(targn)) friendly = true;
									}
									else if (StrEqual(clsname,"turret_floor",false))
									{
										Format(clsname,sizeof(clsname),"Floor Turret");
									}
									else if (StrEqual(clsname,"cscanner",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Claw Scanner");
									}
									else if (StrEqual(clsname,"vortigaunt",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Uriah");
										else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Vortigaunt Slave");
									}
									else if (StrEqual(clsname,"antlion",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
									}
									else if (StrEqual(clsname,"antlionguard",false))
									{
										Format(clsname,sizeof(clsname),"Antlion Guard");
										if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Antlion Guardian");
									}
									else if (StrEqual(clsname,"rollermine",false))
									{
										curh = 1;
										maxh = 1;
									}
									else if ((StrEqual(clsname,"alyx",false)) && (StrEqual(targn,"clockface_npc",false)))
									{
										Format(clsname,sizeof(clsname),"Clock Face");
									}
									else if (StrContains(targn,"STEAM_",false) != -1)
									{
										for (int i = 1;i<MaxClients+1;i++)
										{
											if (StrEqual(targn,SteamID[i],false))
											{
												if (IsValidEntity(i)) Format(clsname,sizeof(clsname),"%N's %s",i,clsname);
												else Format(clsname,sizeof(clsname),"Summoned %s",clsname);
												break;
											}
										}
									}
									antispamchk[client] = Time + 0.07;
									PrintTheMsg(client,curh,maxh,clsname,friendly);
								}
							}
							else
							{
								char friendfoe[64];
								Format(friendfoe,sizeof(friendfoe),clsname);
								int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
								if (StrContains(clsname,"monster_",false) != -1)
								{
									ReplaceString(clsname,sizeof(clsname),"monster_","");
									ismonster = true;
								}
								else ReplaceString(clsname,sizeof(clsname),"npc_","");
								int maxh = 20;
								if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
								{
									maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
									if (StrEqual(clsname,"combine_camera",false))
										maxh = 50;
									else if (StrEqual(clsname,"antlion_grub",false))
										maxh = 1;
									else if (StrEqual(clsname,"combinedropship",false))
										maxh = 100;
									else if (StrEqual(clsname,"turret_ceiling",false))
										maxh = 1000;
									else if (maxh == 0)
									{
										char cvarren[32];
										if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
										else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
										Handle cvarchk = FindConVar(cvarren);
										if (cvarchk == INVALID_HANDLE)
											maxh = 20;
										else
											maxh = GetConVarInt(cvarchk);
									}
								}
								if (StrEqual(clsname,"rollermine",false))
								{
									curh = 1;
									maxh = 1;
								}
								float Time = GetTickedTime();
								if ((antispamchk[client] <= Time) && (curh > 0))
								{
									antispamchk[client] = Time + 0.07;
									char targn[32];
									if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (StrContains(targn,"STEAM_",false) != -1)
									{
										for (int i = 1;i<MaxClients+1;i++)
										{
											if (StrEqual(targn,SteamID[i],false))
											{
												Format(friendfoe,sizeof(friendfoe),"%N's %s",i,friendfoe);
												break;
											}
										}
									}
									PrintTheMsgf(client,curh,maxh,friendfoe,targ);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public void PrintTheMsg(int client, int curh, int maxh, char clsname[64], bool friendly)
{
	char hudbuf[40];
	if (StrEqual(clsname,"monk",false)) Format(clsname,sizeof(clsname),"Father Grigori");
	else if (StrEqual(clsname,"kleiner",false)) Format(clsname,sizeof(clsname),"Isaac Kleiner");
	else if (StrEqual(clsname,"mossman",false)) Format(clsname,sizeof(clsname),"Judith Mossman");
	else if (StrEqual(clsname,"magnusson",false)) Format(clsname,sizeof(clsname),"Arne Magnusson");
	else if (StrEqual(clsname,"breen",false)) Format(clsname,sizeof(clsname),"Dr Breen");
	else if (StrEqual(clsname,"alyx",false)) Format(clsname,sizeof(clsname),"Alyx Vance");
	else if (StrEqual(clsname,"eli",false)) Format(clsname,sizeof(clsname),"Eli Vance");
	else if (StrEqual(clsname,"antlionworker",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
	else if (StrEqual(clsname,"cscanner",false)) Format(clsname,sizeof(clsname),"City Scanner");
	else if (StrEqual(clsname,"turret_floor",false)) Format(clsname,sizeof(clsname),"Floor Turret");
	else if (StrEqual(clsname,"combinegunship",false)) Format(clsname,sizeof(clsname),"Combine Gunship");
	else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Combine APC");
	else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Fast Zombie");
	else if (StrEqual(clsname,"npc_fastzombie_torso",false)) Format(clsname,sizeof(clsname),"Fast Zombie Torso");
	else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Fast Headcrab");
	else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Poison Headcrab");
	else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Black Headcrab");
	else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Poison Zombie");
	else if (StrEqual(clsname,"combinedropship",false)) Format(clsname,sizeof(clsname),"Combine Dropship");
	else if (StrContains(clsname,"_",false) != -1)
	{
		clsname[0] &= ~(1 << 5);
		char rebuildupper[32][32];
		ExplodeString(clsname,"_",rebuildupper,32,32);
		clsname = "";
		for (int i = 0;i<32;i++)
		{
			if (strlen(rebuildupper[i]) > 0)
			{
				rebuildupper[i][0] &= ~(1 << 5);
				if (strlen(clsname) > 0)
					Format(clsname,sizeof(clsname),"%s %s",clsname,rebuildupper[i]);
				else
					Format(clsname,sizeof(clsname),"%s",rebuildupper[i]);
			}
			else break;
		}
	}
	if (bclcookie2[client])
		Format(hudbuf,sizeof(hudbuf),"%s (%i HP)",clsname,curh);
	else
	{
		float perch = (float(curh)/float(maxh))*100;
		if (perch < 1.0)
			perch = 1.0;
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,perch);
	}
	if (bclcookie[client] == 0)
	{
		if (friendly) SetHudTextParams(bclcookie5x[client], bclcookie5y[client], 0.1, bclcookie4f[client][0], bclcookie4f[client][1], bclcookie4f[client][2], 255, 0, 0.1, 0.0, 0.1);
		else SetHudTextParams(bclcookie5x[client], bclcookie5y[client], 0.1, bclcookie4[client][0], bclcookie4[client][1], bclcookie4[client][2], 255, 0, 0.1, 0.0, 0.1);
		ShowHudText(client,0,"%s",hudbuf);
	}
	else if (bclcookie[client] == 1)
	{
		float Time = GetTickedTime();
		antispamchk[client] = Time + 0.5;
		PrintHintText(client,hudbuf);
	}
	else if (bclcookie[client] == 2)
	{
		PrintCenterText(client,hudbuf);
	}
}

public void PrintTheMsgf(int client, int curh, int maxh, char clsname[64], int targ)
{
	bool targetally = false;
	if (StrEqual(clsname,"npc_metropolice",false))
	{
		if ((GetCopAlly()) || (FindStringInArray(liarr,clsname) != -1)) Format(clsname,sizeof(clsname),"Friend: Metropolice");
		else Format(clsname,sizeof(clsname),"Enemy: Metropolice");
	}
	char targn[32];
	if (HasEntProp(targ,Prop_Data,"m_iName"))
	{
		GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
		if (strlen(targn) > 0)
			if (GetNPCAllyTarg(targn))
				targetally = true;
	}
	if ((GetNPCAlly(clsname,targ)) || (targetally))
	{
		if (StrEqual(clsname,"npc_combine_s",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Combine Elite");
			else if (StrContains(cmodel,"models/sttr_easyrider",false) == 0)
				Format(clsname,sizeof(clsname),"Friend: Easy Rider");
			else if (StrContains(cmodel,"models/helghast/",false) == 0)
				Format(clsname,sizeof(clsname),"Friend: Helghast Soldier");
			else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
				Format(clsname,sizeof(clsname),"Friend: Combine Shotgunner");
			else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Combine Guard");
			else
				Format(clsname,sizeof(clsname),"Friend: Combine Soldier");
		}
		else if (StrEqual(clsname,"npc_combinedropship",false)) Format(clsname,sizeof(clsname),"Friend: Combine Dropship");
		else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Friend: Griggs");
		else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Friend: Sheckley");
		else if (StrContains(targn,"larry",false) != -1) Format(clsname,sizeof(clsname),"Friend: Larry");
		else if (StrEqual(targn,"anne",false)) Format(clsname,sizeof(clsname),"Friend: Anne");
		else if (StrContains(targn,"arthur",false) != -1) Format(clsname,sizeof(clsname),"Friend: Arthur");
		else if (StrContains(targn,"sarah",false) != -1) Format(clsname,sizeof(clsname),"Friend: Sarah");
		else if (StrContains(targn,"mary",false) != -1) Format(clsname,sizeof(clsname),"Friend: Mary");
		else if (StrContains(targn,"matt",false) != -1) Format(clsname,sizeof(clsname),"Friend: Matt");
		else if (StrEqual(targn,"mina",false)) Format(clsname,sizeof(clsname),"Friend: Mina");
		else if (StrEqual(targn,"arlene",false)) Format(clsname,sizeof(clsname),"Friend: Arlene");
		else if (StrEqual(targn,"john",false)) Format(clsname,sizeof(clsname),"Friend: John");
		else if (StrContains(targn,"mitch",false) != -1) Format(clsname,sizeof(clsname),"Friend: Mitch");
		else if ((StrEqual(targn,"argento",false)) || (StrEqual(targn,"rebel_argento",false))) Format(clsname,sizeof(clsname),"Friend: Argento");
		else if (StrContains(targn,"oleg",false) != -1) Format(clsname,sizeof(clsname),"Friend: Oleg");
		else if (StrEqual(targn,"Richard",false)) Format(clsname,sizeof(clsname),"Friend: Richard");
		else if (StrEqual(targn,"laura",false)) Format(clsname,sizeof(clsname),"Friend: Laura");
		else if (StrEqual(targn,"winston",false)) Format(clsname,sizeof(clsname),"Friend: Winston");
		else if (StrEqual(targn,"stanley",false)) Format(clsname,sizeof(clsname),"Friend: Stanley");
		else if (StrEqual(targn,"tobias",false)) Format(clsname,sizeof(clsname),"Friend: Laszlo Tobias");
		else if (StrEqual(targn,"chester",false)) Format(clsname,sizeof(clsname),"Friend: Chester");
		else if (StrEqual(targn,"warehouse_citizen_leon",false)) Format(clsname,sizeof(clsname),"Friend: Leon");
		else if ((StrEqual(targn,"jackCarver",false)) || (StrEqual(targn,"jack",false))) Format(clsname,sizeof(clsname),"Friend: Jack");
		else if (StrEqual(targn,"mike",false)) Format(clsname,sizeof(clsname),"Friend: Mike");
		else if (StrEqual(targn,"Larson",false)) Format(clsname,sizeof(clsname),"Friend: Larson");
		else if (StrEqual(targn,"Eloise",false)) Format(clsname,sizeof(clsname),"Friend: Eloise");
		else if (StrEqual(targn,"Noah",false)) Format(clsname,sizeof(clsname),"Friend: Noah");
		else if (StrEqual(targn,"Eve",false)) Format(clsname,sizeof(clsname),"Friend: Eve");
		else if ((StrEqual(targn,"Olivia",false)) || (StrEqual(targn,"actor_olivia",false))) Format(clsname,sizeof(clsname),"Friend: Olivia");
		else if (StrEqual(clsname,"npc_citizen",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if ((StrContains(targn,"ugly",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_02.mdl",false))) Format(clsname,sizeof(clsname),"Enemy: The Ugly");
			else if ((StrContains(targn,"bad",false) == 0) && (StrEqual(cmodel,"models/Humans/Group01/male_03.mdl",false))) Format(clsname,sizeof(clsname),"Enemy: The Bad");
			else if (StrEqual(cmodel,"models/odessa.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Odessa Cubbage");
			else if (StrContains(cmodel,"models/humans/group03m/",false) == 0)
				Format(clsname,sizeof(clsname),"Friend: Rebel Medic");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Friend: Refugee");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Friend: Rebel");
		}
		else if (StrEqual(clsname,"npc_monk",false)) Format(clsname,sizeof(clsname),"Friend: Father Grigori");
		else if (StrEqual(clsname,"npc_kleiner",false)) Format(clsname,sizeof(clsname),"Friend: Isaac Kleiner");
		else if (StrEqual(clsname,"npc_mossman",false)) Format(clsname,sizeof(clsname),"Friend: Judith Mossman");
		else if (StrEqual(clsname,"npc_magnusson",false)) Format(clsname,sizeof(clsname),"Friend: Arne Magnusson");
		else if (StrEqual(clsname,"npc_breen",false)) Format(clsname,sizeof(clsname),"Friend: Dr Breen");
		else if (StrEqual(clsname,"npc_alyx",false))
		{
			if (StrEqual(targn,"clockface_npc",false)) Format(clsname,sizeof(clsname),"Friend: Clock Face");
			else Format(clsname,sizeof(clsname),"Friend: Alyx Vance");
		}
		else if (StrEqual(clsname,"npc_eli",false)) Format(clsname,sizeof(clsname),"Friend: Eli Vance");
		else if (StrEqual(clsname,"npc_antlionworker",false)) Format(clsname,sizeof(clsname),"Friend: Antlion Worker");
		else if (StrEqual(clsname,"npc_antlion",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Antlion Worker");
		}
		else if (StrEqual(clsname,"npc_antlionguard",false))
		{
			Format(clsname,sizeof(clsname),"Friend: Antlion Guard");
			if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Friend: Antlion Guardian");
		}
		else if (StrEqual(clsname,"npc_turret_floor",false)) Format(clsname,sizeof(clsname),"Friend: Floor Turret");
		else if (StrEqual(clsname,"npc_cscanner",false))
		{
			Format(clsname,sizeof(clsname),"Friend: City Scanner");
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Claw Scanner");
		}
		else if (StrEqual(clsname,"npc_vortigaunt",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Uriah");
			else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Vortigaunt Slave");
		}
		else if (StrEqual(clsname,"npc_combinegunship",false)) Format(clsname,sizeof(clsname),"Friend: Combine Gunship");
		else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Friend: Combine APC");
		else if (StrEqual(clsname,"npc_gman",false)) Format(clsname,sizeof(clsname),"Government Man");
		else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Friend: Fast Zombie");
		else if (StrEqual(clsname,"npc_fastzombie_torso",false)) Format(clsname,sizeof(clsname),"Friend: Fast Zombie Torso");
		else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Friend: Poison Zombie");
		else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Friend: Fast Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Friend: Poison Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Friend: Black Headcrab");
		if (StrContains(clsname,"monster_",false) != -1) ReplaceString(clsname,sizeof(clsname),"monster","Friend:");
		else ReplaceString(clsname,sizeof(clsname),"npc","Friend:");
		clsname[0] &= ~(1 << 5);
		char rebuildupper[32][32];
		ExplodeString(clsname,"_",rebuildupper,32,32);
		clsname = "";
		for (int i = 0;i<32;i++)
		{
			if (strlen(rebuildupper[i]) > 0)
			{
				rebuildupper[i][0] &= ~(1 << 5);
				if (strlen(clsname) > 0)
					Format(clsname,sizeof(clsname),"%s %s",clsname,rebuildupper[i]);
				else
					Format(clsname,sizeof(clsname),"%s",rebuildupper[i]);
			}
			else break;
		}
	}
	else
	{
		if (StrEqual(clsname,"npc_combine_s",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Combine Elite");
			else if (StrContains(cmodel,"models/sttr_easyrider",false) == 0)
				Format(clsname,sizeof(clsname),"Enemy: Easy Rider");
			else if (StrContains(cmodel,"models/helghast/",false) == 0)
				Format(clsname,sizeof(clsname),"Enemy: Helghast Soldier");
			else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
				Format(clsname,sizeof(clsname),"Enemy: Combine Shotgunner");
			else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Combine Guard");
			else
				Format(clsname,sizeof(clsname),"Enemy: Combine Soldier");
		}
		else if (StrEqual(clsname,"npc_combinedropship",false)) Format(clsname,sizeof(clsname),"Enemy: Combine Dropship");
		else if (StrEqual(clsname,"npc_citizen",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/odessa.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Odessa Cubbage");
			else if (StrContains(cmodel,"models/humans/group03m/",false) == 0)
				Format(clsname,sizeof(clsname),"Enemy: Rebel Medic");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Enemy: Refugee");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Enemy: Rebel");
		}
		else if (StrEqual(clsname,"npc_monk",false)) Format(clsname,sizeof(clsname),"Enemy: Father Grigori");
		else if (StrEqual(clsname,"npc_kleiner",false)) Format(clsname,sizeof(clsname),"Enemy: Isaac Kleiner");
		else if (StrEqual(clsname,"npc_mossman",false)) Format(clsname,sizeof(clsname),"Enemy: Judith Mossman");
		else if (StrEqual(clsname,"npc_magnusson",false)) Format(clsname,sizeof(clsname),"Enemy: Arne Magnusson");
		else if (StrEqual(clsname,"npc_breen",false)) Format(clsname,sizeof(clsname),"Enemy: Dr Breen");
		else if (StrEqual(clsname,"npc_alyx",false)) Format(clsname,sizeof(clsname),"Enemy: Alyx Vance");
		else if (StrEqual(clsname,"npc_eli",false)) Format(clsname,sizeof(clsname),"Enemy: Eli Vance");
		else if (StrEqual(clsname,"npc_antlionworker",false)) Format(clsname,sizeof(clsname),"Enemy: Antlion Worker");
		else if (StrEqual(clsname,"npc_antlion",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Antlion Worker");
		}
		else if (StrEqual(clsname,"npc_antlionguard",false))
		{
			Format(clsname,sizeof(clsname),"Enemy: Antlion Guard");
			if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Enemy: Antlion Guardian");
		}
		else if (StrEqual(clsname,"npc_turret_floor",false)) Format(clsname,sizeof(clsname),"Enemy: Floor Turret");
		else if (StrEqual(clsname,"npc_cscanner",false))
		{
			Format(clsname,sizeof(clsname),"Enemy: City Scanner");
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Claw Scanner");
		}
		else if (StrEqual(clsname,"npc_vortigaunt",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Uriah");
			else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Vortigaunt Slave");
		}
		else if (StrEqual(clsname,"npc_combinegunship",false)) Format(clsname,sizeof(clsname),"Enemy: Combine Gunship");
		else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Enemy: Combine APC");
		else if (StrEqual(clsname,"npc_gman",false)) Format(clsname,sizeof(clsname),"Government Man");
		else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Enemy: Fast Zombie");
		else if (StrEqual(clsname,"npc_fastzombie_torso",false)) Format(clsname,sizeof(clsname),"Enemy: Fast Zombie Torso");
		else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Enemy: Poison Zombie");
		else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Enemy: Fast Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Enemy: Poison Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Enemy: Black Headcrab");
		if (StrContains(clsname,"monster_",false) != -1) ReplaceString(clsname,sizeof(clsname),"monster","Enemy: ");
		else ReplaceString(clsname,sizeof(clsname),"npc","Enemy:");
		clsname[0] &= ~(1 << 5);
		char rebuildupper[32][32];
		ExplodeString(clsname,"_",rebuildupper,32,32);
		clsname = "";
		for (int i = 0;i<32;i++)
		{
			if (strlen(rebuildupper[i]) > 0)
			{
				rebuildupper[i][0] &= ~(1 << 5);
				if (strlen(clsname) > 0)
					Format(clsname,sizeof(clsname),"%s %s",clsname,rebuildupper[i]);
				else
					Format(clsname,sizeof(clsname),"%s",rebuildupper[i]);
			}
			else break;
		}
	}
	char hudbuf[40];
	if (StrContains(clsname,"_",false) != -1)
	{
		int upper = ReplaceStringEx(clsname,sizeof(clsname),"_"," ");
		if (upper != -1)
			clsname[upper] &= ~(1 << 5);
	}
	if (bclcookie2[client])
		Format(hudbuf,sizeof(hudbuf),"%s (%i HP)",clsname,curh);
	else
	{
		float perch = (float(curh)/float(maxh))*100;
		if (perch < 1.0)
			perch = 1.0;
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,perch);
	}
	if (bclcookie[client] == 0)
	{
		if (StrContains(clsname,"enemy",false) != -1)
			SetHudTextParams(bclcookie5x[client], bclcookie5y[client], 0.1, bclcookie4[client][0], bclcookie4[client][1], bclcookie4[client][2], 255, 0, 0.1, 0.0, 0.1);
		else
			SetHudTextParams(bclcookie5x[client], bclcookie5y[client], 0.1, bclcookie4f[client][0], bclcookie4f[client][1], bclcookie4f[client][2], 255, 0, 0.1, 0.0, 0.1);
		ShowHudText(client,0,"%s",hudbuf);
	}
	else if (bclcookie[client] == 1)
	{
		float Time = GetTickedTime();
		antispamchk[client] = Time + 0.5;
		PrintHintText(client,hudbuf);
	}
	else if (bclcookie[client] == 2)
	{
		PrintCenterText(client,hudbuf);
	}
}

public void OnClientDisconnect(int client)
{
	CLStoreInTable(client);
}

public void OnClientDisconnectPost(int client)
{
	initcl(client);
}

void initcl(int client)
{
	antispamchk[client] = 0.0;
	bclcookie[client] = defaultmode;
	bclcookie2[client] = 0;
	bclcookie3[client] = 0;
	bclcookie4[client][0] = 255;
	bclcookie4[client][1] = 0;
	bclcookie4[client][2] = 0;
	bclcookie4f[client][0] = 0;
	bclcookie4f[client][1] = 255;
	bclcookie4f[client][2] = 0;
	bclcookie5x[client] = -1.0;
	bclcookie5y[client] = 0.55;
}

bool GetCopAlly()
{
	if (GetArraySize(globalsarr) > 0)
	{
		for (int i = 0;i<GetArraySize(globalsarr);i++)
		{
			char itmp[32];
			GetArrayString(globalsarr, i, itmp, sizeof(itmp));
			int glo = StringToInt(itmp);
			if (IsValidEntity(glo))
			{
				char state[64];
				GetEntPropString(glo,Prop_Data,"m_iName",state,sizeof(state));
				char state2[64];
				GetEntPropString(glo,Prop_Data,"m_globalstate",state2,sizeof(state2));
				int initstate = GetEntProp(glo,Prop_Data,"m_initialstate");
				if ((StrEqual(state,"global.precriminal",false)) || (StrEqual(state2,"gordon_precriminal",false)))
					if (initstate > 0)
					{
						return true;
					}
			}
		}
	}
	return false;
}

public Action findglobals(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char prevtmp[16];
		Format(prevtmp, sizeof(prevtmp), "%i", thisent);
		if((thisent >= 0) && (FindStringInArray(globalsarr, prevtmp) == -1))
		{
			PushArrayString(globalsarr, prevtmp);
		}
		findglobals(thisent++,clsname);
	}
	return Plugin_Handled;
}

bool GetNPCAllyTarg(char[] clsname)
{
	if (FindStringInArray(liarr,clsname) != -1) return true;
	return false;
}

bool GetNPCAlly(char[] clsname, int entchk)
{
	if (GetArraySize(airelarr) < 1)
		findairel(-1,"ai_relationship");
	if (GetArraySize(htarr) > 0)
	{
		if (StrEqual(clsname,"npc_turret_floor",false))
		{
			int sf = GetEntProp(entchk,Prop_Data,"m_spawnflags");
			if (sf & 1<<9) return true; //512
		}
		else if (HasEntProp(entchk,Prop_Data,"m_bHackedByAlyx"))
		{
			int hck = GetEntProp(entchk,Prop_Data,"m_bHackedByAlyx");
			if (hck > 0) return true;
		}
		if (FindStringInArray(liarr,clsname) != -1) return true;
		else if (FindStringInArray(htarr,clsname) != -1) return false;
		else return true;
	}
	else
	{
		addht("npc_combine_s");
		addht("npc_metropolice");
		addht("prop_vehicle_apc");
		addht("npc_breen");
		addht("npc_barnacle");
		addht("npc_combine_camera");
		addht("npc_helicopter");
		addht("npc_cscanner");
		addht("npc_rollermine");
		addht("npc_combinegunship");
		addht("npc_combinedropship");
		addht("npc_turret_ceiling");
		addht("npc_turret_ground");
		addht("npc_manhack");
		addht("npc_strider");
		addht("npc_stalker");
		addht("npc_sniper");
		addht("npc_turret_floor");
		addht("npc_zombie");
		addht("npc_zombie_torso");
		addht("npc_zombie_worker");
		addht("npc_zombine");
		addht("npc_fastzombie");
		addht("npc_fastzombie_torso");
		addht("npc_poisonzombie");
		addht("npc_headcrab");
		addht("npc_headcrab_poison");
		addht("npc_headcrab_black");
		addht("npc_headcrab_fast");
		addht("npc_gargantua");
		addht("npc_gonarch");
		addht("npc_babycrab");
		addht("npc_hunter");
		addht("npc_advisor");
		addht("npc_antlion");
		addht("npc_antlionworker");
		addht("npc_antlionguard");
		addht("npc_zombie_scientist");
		addht("npc_zombie_scientist_torso");
		addht("npc_zombie_security");
		addht("npc_alien_slave");
		addht("npc_alien_grunt");
		addht("npc_houndeye");
		addht("npc_tentacle");
		addht("npc_snark");
		addht("npc_bullsquid");
		addht("npc_sentry_ground");
		addht("npc_sentry_ceiling");
		addht("npc_human_grunt");
		addht("npc_human_commander");
		addht("npc_human_medic");
		addht("npc_human_grenadier");
		addht("npc_human_assassin");
		addht("npc_abrams");
		addht("npc_apache");
		addht("npc_ichthyosaur");
		addht("npc_clawscanner");
		addht("npc_doramn_window");
		addht("npc_doramn_power_cell");
		addht("monster_alien_slave");
		addht("monster_bullchicken");
		addht("monster_headcrab");
		addht("monster_ichthyosaur");
		addht("monster_tentacle");
		addht("monster_sentry");
		addht("monster_snark");
		addht("monster_houndeye");
		addht("monster_barnacle");
		addht("monster_apache");
		addht("monster_zombie");
		addht("monster_alien_grunt");
		addht("monster_bigmomma");
		addht("monster_babycrab");
		addht("monster_gargantua");
		addht("monster_human_assassin");
		addht("monster_human_grunt");
		addht("monster_miniturret");
		addht("monster_nihilanth");
		for (int i = 0;i<GetArraySize(airelarr);i++)
		{
			int rel = GetArrayCell(airelarr, i);
			if (IsValidEntity(rel))
			{
				char clsnamechk[16];
				GetEntityClassname(rel, clsnamechk, sizeof(clsnamechk));
				if (StrEqual(clsnamechk,"ai_relationship",false))
				{
					char subj[32];
					GetEntPropString(rel,Prop_Data,"m_iszSubject",subj,sizeof(subj));
					char targ[32];
					GetEntPropString(rel,Prop_Data,"m_target",targ,sizeof(targ));
					int disp = GetEntProp(rel,Prop_Data,"m_iDisposition");
					int act = GetEntProp(rel,Prop_Data,"m_bIsActive");
					//disp 1 = D_HT // 2 = D_NT // 3 = D_LI // 4 = D_FR
					if ((StrContains(targ,"player",false) != -1) && (disp == 1) && (act != 0))
					{
						addht(subj);
					}
					else if ((StrContains(targ,"player",false) != -1) && (disp == 3) && (act != 0))
					{
						//PrintToServer("Rem %s %i",subj,disp);
						int find = FindStringInArray(htarr,subj);
						if (find != -1)
						{
							RemoveFromArray(htarr,find);
						}
						if (FindStringInArray(liarr,subj) == -1)
							PushArrayString(liarr,subj);
					}
					else if ((StrContains(subj,"player",false) != -1) && (disp == 1) && (act != 0))
					{
						if (FindStringInArray(htarr,targ) == -1)
							addht(targ);
					}
					else if ((StrContains(subj,"player",false) != -1) && (disp == 3) && (act != 0))
					{
						//PrintToServer("Rem %s %i",targ,disp);
						int find = FindStringInArray(htarr,targ);
						if (find != -1)
						{
							RemoveFromArray(htarr,find);
							find = FindStringInArray(htarr,targ);
							if (find != -1)
							{
								RemoveFromArray(htarr,find);
							}
						}
						if (FindStringInArray(liarr,targ) == -1)
							PushArrayString(liarr,targ);
					}
				}
			}
			else
				findairel(-1,"ai_relationship");
		}
		if (GetAntAlly())
		{
			int find = FindStringInArray(htarr,"npc_antlion");
			if (find != -1)
				RemoveFromArray(htarr,find);
		}
	}
	if (GetArraySize(htarr) > 0)
	{
		if (StrEqual(clsname,"npc_turret_floor",false))
		{
			int sf = GetEntProp(entchk,Prop_Data,"m_spawnflags");
			if (sf & 1<<9) return true;
		}
		else if (HasEntProp(entchk,Prop_Data,"m_bHackedByAlyx"))
		{
			int hck = GetEntProp(entchk,Prop_Data,"m_bHackedByAlyx");
			if (hck > 0) return true;
		}
		if (FindStringInArray(liarr,clsname) != -1) return true;
		else if (FindStringInArray(htarr,clsname) != -1) return false;
		else return true;
	}
	return true;
}

void addht(char[] addht)
{
	if (FindStringInArray(htarr,addht) == -1)
		PushArrayString(htarr,addht);
	int findli = FindStringInArray(liarr,addht);
	if (findli != -1)
		RemoveFromArray(liarr,findli);
}

bool GetAntAlly()
{
	if (bugbaitpicked)
		return true;
	if (GetArraySize(globalsarr) > 0)
	{
		for (int i = 0;i<GetArraySize(globalsarr);i++)
		{
			char itmp[32];
			GetArrayString(globalsarr, i, itmp, sizeof(itmp));
			int glo = StringToInt(itmp);
			if (IsValidEntity(glo))
			{
				char state[64];
				GetEntPropString(glo,Prop_Data,"m_iName",state,sizeof(state));
				char state2[64];
				GetEntPropString(glo,Prop_Data,"m_globalstate",state2,sizeof(state2));
				int offs = FindDataMapInfo(glo, "m_counter");
				int initstate = GetEntData(glo, offs);
				if ((StrEqual(state,"antlions_friendly",false)) || (StrEqual(state2,"antlion_allied",false)))
					if (initstate > 0)
						return true;
			}
		}
	}
	return false;
}

public Action onbugbaitpickup(const char[] output, int caller, int activator, float delay)
{
	bugbaitpicked = true;
}

public Action findairel(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		if((thisent >= 0) && (FindValueInArray(airelarr, thisent) == -1))
		{
			char subj[32];
			GetEntPropString(thisent,Prop_Data,"m_iszSubject",subj,sizeof(subj));
			char targ[32];
			GetEntPropString(thisent,Prop_Data,"m_target",targ,sizeof(targ));
			int act = GetEntProp(thisent,Prop_Data,"m_bIsActive");
			int recip = GetEntProp(thisent,Prop_Data,"m_bReciprocal");
			if (((StrContains(subj,"player",false) != -1) || (StrContains(targ,"player",false) != -1)) && (act != 0) && (recip == 1))
			{
				PushArrayCell(airelarr, thisent);
			}
		}
		findairel(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action Display_HudTypes(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","HealthMenuType",client);
	menu.SetTitle(titleset);
	char hudtxt[64];
	Format(hudtxt,sizeof(hudtxt),"%T","HudText",client);
	menu.AddItem("settext",hudtxt);
	char hinttxt[64];
	Format(hinttxt,sizeof(hinttxt),"%T","HintTxt",client);
	menu.AddItem("sethint",hinttxt);
	char centertxt[64];
	Format(centertxt,sizeof(centertxt),"%T","CenterTxt",client);
	menu.AddItem("setcent",centertxt);
	char disablehd[64];
	Format(disablehd,sizeof(disablehd),"%T","DisabledHD",client);
	menu.AddItem("setdisable",disablehd);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("backtotop",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudNum(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","HealthMenuNum",client);
	menu.SetTitle(titleset);
	char percdisp[64];
	Format(percdisp,sizeof(percdisp),"%T","Percentage",client);
	menu.AddItem("setperc",percdisp);
	char hpdisp[64];
	Format(hpdisp,sizeof(hpdisp),"%T","HitPoints",client);
	menu.AddItem("sethp",hpdisp);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("backtotop",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudFriendlies(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","HealthMenuFR",client);
	menu.SetTitle(titleset);
	char enemonly[64];
	Format(enemonly,sizeof(enemonly),"%T","EnemiesOnly",client);
	menu.AddItem("friend0",enemonly);
	char frenwo[64];
	Format(frenwo,sizeof(frenwo),"%T","Friendlies",client);
	menu.AddItem("friend1",frenwo);
	char franden[64];
	Format(franden,sizeof(franden),"%T","FriendliesWith",client);
	menu.AddItem("friend2",franden);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("backtotop",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudSelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"%T","ColorsApply",client);
		return Plugin_Handled;
	}
	if (bclcookie3[client] < 1) PrintToChat(client,"%T","ColorsApplyType",client);
	Menu menu = new Menu(PanelHandlerDisplayt);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","HealthMenuCol",client);
	menu.SetTitle(titleset);
	char frcol[64];
	Format(frcol,sizeof(frcol),"%T","FriendliesCol",client);
	menu.AddItem("friendlies",frcol);
	char encol[64];
	Format(encol,sizeof(encol),"%T","EnemiesCol",client);
	menu.AddItem("enemies",encol);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("back",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudFriendSelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"%T","ColorsApply",client);
		return Plugin_Handled;
	}
	Menu menu = new Menu(PanelHandlerDisplay);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","FriendliesCol",client);
	menu.SetTitle(titleset);
	char red[32];
	Format(red,sizeof(red),"%T","Red",client);
	menu.AddItem("ff red",red);
	char green[32];
	Format(green,sizeof(green),"%T","Green",client);
	menu.AddItem("ff green",green);
	char blue[32];
	Format(blue,sizeof(blue),"%T","Blue",client);
	menu.AddItem("ff blue",blue);
	char yellow[32];
	Format(yellow,sizeof(yellow),"%T","Yellow",client);
	menu.AddItem("ff yellow",yellow);
	char white[32];
	Format(white,sizeof(white),"%T","White",client);
	menu.AddItem("ff white",white);
	char purple[32];
	Format(purple,sizeof(purple),"%T","Purple",client);
	menu.AddItem("ff purple",purple);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("back",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudEnemySelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"%T","ColorsApply",client);
		return Plugin_Handled;
	}
	Menu menu = new Menu(PanelHandlerDisplay);
	char titleset[64];
	Format(titleset,sizeof(titleset),"%T","EnemiesCol",client);
	menu.SetTitle(titleset);
	char red[32];
	Format(red,sizeof(red),"%T","Red",client);
	menu.AddItem("en red",red);
	char green[32];
	Format(green,sizeof(green),"%T","Green",client);
	menu.AddItem("en green",green);
	char blue[32];
	Format(blue,sizeof(blue),"%T","Blue",client);
	menu.AddItem("en blue",blue);
	char yellow[32];
	Format(yellow,sizeof(yellow),"%T","Yellow",client);
	menu.AddItem("en yellow",yellow);
	char white[32];
	Format(white,sizeof(white),"%T","White",client);
	menu.AddItem("en white",white);
	char purple[32];
	Format(purple,sizeof(purple),"%T","Purple",client);
	menu.AddItem("en purple",purple);
	char back[32];
	Format(back,sizeof(back),"%T","BackButton",client);
	menu.AddItem("back",back);
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action sethealthhudpos(int client, int args)
{
	if ((client == 0) || (!IsValidEntity(client))) return Plugin_Handled;
	if (args < 2)
	{
		PrintToChat(client,"%T","InvalidNum",client);
		return Plugin_Handled;
	}
	char xpos[8];
	char ypos[8];
	GetCmdArg(1,xpos,sizeof(xpos));
	GetCmdArg(2,ypos,sizeof(ypos));
	if (StrContains(xpos,".",false) == -1) StrCat(xpos,sizeof(xpos),".");
	if (StrContains(ypos,".",false) == -1) StrCat(ypos,sizeof(ypos),".");
	if (strlen(xpos) < 3) StrCat(xpos,sizeof(xpos),"00");
	if (strlen(ypos) < 3) StrCat(ypos,sizeof(ypos),"00");
	float xposf = StringToFloat(xpos);
	float yposf = StringToFloat(ypos);
	if ((((xposf < 0.0) && (xposf != -1.0)) || ((yposf < 0.0) && (yposf != -1.0)) || (xposf > 1.0) || (yposf > 1.0)))
	{
		PrintToChat(client,"%T","InvalidNum",client);
		return Plugin_Handled;
	}
	PrintToChat(client,"Set %f %f",xposf,yposf);
	bclcookie5x[client] = xposf;
	bclcookie5y[client] = yposf;
	hChanged[client] = 1;
	return Plugin_Handled;
}

public int PanelHandlerDisplayFull(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		char sethdto[128];
		char setting[64];
		if (StrEqual(info,"type",false))
		{
			Display_HudTypes(param1,0);
			return 0;
		}
		else if (StrEqual(info,"friendlies",false))
		{
			Display_HudFriendlies(param1,0);
			return 0;
		}
		else if (StrEqual(info,"num",false))
		{
			Display_HudNum(param1,0);
			return 0;
		}
		else if (StrEqual(info,"color",false))
		{
			Display_HudSelect(param1,0);
			return 0;
		}
		else if (StrEqual(info,"setperc",false))
		{
			Format(setting,sizeof(setting),"%T","Percentage",param1);
			bclcookie2[param1] = 0;
			hChanged[param1] = 1;
			Display_HudNum(param1,0);
		}
		else if (StrEqual(info,"sethp",false))
		{
			Format(setting,sizeof(setting),"%T","HitPoints",param1);
			bclcookie2[param1] = 1;
			hChanged[param1] = 1;
			Display_HudNum(param1,0);
		}
		else if (StrEqual(info,"friend0",false))
		{
			Format(setting,sizeof(setting),"%T","EnemiesOnly",param1);
			bclcookie3[param1] = 0;
			hChanged[param1] = 1;
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"friend1",false))
		{
			Format(setting,sizeof(setting),"%T","Friendlies",param1);
			bclcookie3[param1] = 1;
			hChanged[param1] = 1;
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"friend2",false))
		{
			Format(setting,sizeof(setting),"%T","FriendliesWith",param1);
			bclcookie3[param1] = 2;
			hChanged[param1] = 1;
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"settext",false))
		{
			Format(setting,sizeof(setting),"%T","HudText",param1);
			bclcookie[param1] = 0;
			hChanged[param1] = 1;
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"sethint",false))
		{
			Format(setting,sizeof(setting),"%T","HintTxt",param1);
			bclcookie[param1] = 1;
			hChanged[param1] = 1;
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"setcent",false))
		{
			Format(setting,sizeof(setting),"%T","CenterTxt",param1);
			bclcookie[param1] = 2;
			hChanged[param1] = 1;
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"setdisable",false))
		{
			PrintToChat(param1,"%T","DisabledHD",param1);
			bclcookie[param1] = 3;
			hChanged[param1] = 1;
			Display_HudTypes(param1,0);
			return 0;
		}
		else if (StrEqual(info,"backtotop",false))
		{
			showinf(param1,10);
			return 0;
		}
		Format(sethdto,sizeof(sethdto),"%T","HealthSetTo",param1,setting);
		PrintToChat(param1,"%s",sethdto);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int PanelHandlerDisplayt(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		if (StrEqual(info,"friendlies",false))
		{
			Display_HudFriendSelect(param1,0);
		}
		else if (StrEqual(info,"enemies",false))
		{
			Display_HudEnemySelect(param1,0);
		}
		else if (StrEqual(info,"back",false))
		{
			showinf(param1,10);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int PanelHandlerDisplay(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		if (StrEqual(info,"back",false))
			Display_HudSelect(param1,0);
		if (StrEqual(info,"en red",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"en green",false))
		{
			bclcookie4[param1][0] = 0;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"en blue",false))
		{
			bclcookie4[param1][0] = 0;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 255;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"en yellow",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"en white",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 255;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"en purple",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 255;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff red",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff green",false))
		{
			bclcookie4f[param1][0] = 0;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff blue",false))
		{
			bclcookie4f[param1][0] = 0;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 255;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff yellow",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 0;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff white",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 255;
			hChanged[param1] = 1;
		}
		else if (StrEqual(info,"ff purple",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 255;
			hChanged[param1] = 1;
		}
		if (StrContains(info,"ff ",false) != -1) Display_HudFriendSelect(param1,0);
		else if (StrContains(info,"en ",false) != -1) Display_HudEnemySelect(param1,0);
		else Display_HudSelect(param1,0);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public bool IsCLStored(int client)
{
	char Query[100];
	Format(Query,100,"SELECT H1 FROM healthdisplay WHERE SteamID = '%s'",SteamID[client]);
	Handle hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return false;
	}
	while (SQL_FetchRow(hQuery))
	{
		CloseHandle(hQuery);
		return true;
	}
	CloseHandle(hQuery);
	return false;
}

public void LoadClient(int client)
{
	if (!IsCLStored(client))
	{
		CLStoreInTable(client);
		CreateTimer(1.0,reloadcl,client);
		return;
	}
	char Query[100];
	Format(Query,100,"SELECT * FROM healthdisplay WHERE SteamID = '%s';",SteamID[client]);
	Handle hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s with query %s",Err,Query);
		return;
	}
	while(SQL_FetchRow(hQuery))
	{
		bclcookie[client] = SQL_FetchInt(hQuery,1);
		bclcookie2[client] = SQL_FetchInt(hQuery,2);
		bclcookie3[client] = SQL_FetchInt(hQuery,3);
		bclcookie4[client][0] = SQL_FetchInt(hQuery,4);
		bclcookie4[client][1] = SQL_FetchInt(hQuery,5);
		bclcookie4[client][2] = SQL_FetchInt(hQuery,6);
		bclcookie4f[client][0] = SQL_FetchInt(hQuery,7);
		bclcookie4f[client][1] = SQL_FetchInt(hQuery,8);
		bclcookie4f[client][2] = SQL_FetchInt(hQuery,9);
		bclcookie5x[client] = SQL_FetchFloat(hQuery,10);
		bclcookie5y[client] = SQL_FetchFloat(hQuery,11);
		if (bclcookie5x[client] == 0.00)
		{
			bclcookie5x[client] = -1.0;
			hChanged[client] = 1;
		}
		if (bclcookie5y[client] == 0.00)
		{
			bclcookie5y[client] = 0.55;
			hChanged[client] = 1;
		}
	}
	CloseHandle(hQuery);
	return;
}

public Action reloadcl(Handle timer, int client)
{
	if (IsClientConnected(client) && IsClientAuthorized(client))
	{
		LoadClient(client);
	}
}

public Action reloadclients(int args)
{
	for (int client = 0; client<MaxClients+1 ;client++)
	{
		if (client == 0)
		{
			
		}
		else
		{
			if (IsClientConnected(client) && IsClientAuthorized(client))
			{
				GetClientAuthId(client,AuthId_Steam2,SteamID[client],32-1);
				ReplaceString(SteamID[client],sizeof(SteamID[]),"STEAM_1","STEAM_0");
				LoadClient(client);
			}
		}
	}
}

public Action reloadclientstime(Handle timer)
{
	reloadclients(0);
}

public void CLStoreInTable(int client)
{
	char Query[500];
	char Temp[100];
	if (bclcookie5x[client] == 0.00)
	{
		bclcookie5x[client] = -1.0;
		hChanged[client] = 1;
	}
	if (bclcookie5y[client] == 0.00)
	{
		bclcookie5y[client] = 0.55;
		hChanged[client] = 1;
	}
	if (IsCLStored(client) && (hChanged[client]))
	{
		StrCat(Query,500,"UPDATE healthdisplay SET ");
		Format(Temp,100,"H1 = %i, ",bclcookie[client]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H2 = %i, ",bclcookie2[client]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H3 = %i, ",bclcookie3[client]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H4 = %i, ",bclcookie4[client][0]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H5 = %i, ",bclcookie4[client][1]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H6 = %i, ",bclcookie4[client][2]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H7 = %i, ",bclcookie4f[client][0]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H8 = %i, ",bclcookie4f[client][1]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H9 = %i, ",bclcookie4f[client][2]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H10 = %f, ",bclcookie5x[client]);
		StrCat(Query,500,Temp);
		Format(Temp,100,"H11 = %f, ",bclcookie5y[client]);
		StrCat(Query,500,Temp);
		Query[strlen(Query)-2] = '\0';
		Format(Temp,100," WHERE SteamID = '%s';",SteamID[client]);
		StrCat(Query,500,Temp);
	}
	else if (hChanged[client])
	{
		StrCat(Query,500,"INSERT INTO healthdisplay VALUES( ");
		char thistemp[34];
		Format(thistemp,sizeof(thistemp),"'%s'",SteamID[client]);
		StrCat(Query,500,thistemp);
		StrCat(Query,500,", ");
		IntToString(defaultmode,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(bclcookie2[client],Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(bclcookie3[client],Temp,100);
		StrCat(Query,500,"1");
		StrCat(Query,500,", ");
		IntToString(255,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(0,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(0,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(0,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(255,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		IntToString(0,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		FloatToString(-1.000,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,", ");
		FloatToString(0.550,Temp,100);
		StrCat(Query,500,Temp);
		StrCat(Query,500,");");
	}
	if (strlen(Query) > 32)
	{
		if (!SQL_FastQuery(Handle_Database,Query))
		{
			char Err[100];
			SQL_GetError(Handle_Database,Err,100);
			LogError("SQLite error: %s with query %s",Err,Query);
			return;
		}
	}
	hChanged[client] = 0;
}

public void targmodech(Handle convar, const char[] oldValue, const char[] newValue)
{
	targmode = StringToInt(newValue);
}

public void defaultmodech(Handle convar, const char[] oldValue, const char[] newValue)
{
	defaultmode = StringToInt(newValue);
}