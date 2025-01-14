#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <healthdisplay>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "0.997"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synswepsupdater.txt"

bool friendlyfire = false;
bool tauknockback = false;
bool customcvarsset = false;
bool loweredsprint = false;
bool InChargeUp[2048];
bool InIronSights[128];
bool dbgmdlsetup = false;
bool bCSS = false;
int g_LastButtons[128];
int difficulty = 1;
int iWeapList = -1;
int SL8Scope = -1;
int OICWScope = -1;
int clsummonfil = -1;
int CLManhackRel = -1;
int mdlus = -1;
int mdlus3 = -1;
int beamindx = -1;
int haloindx = -1;
int gluonbeam = -1;
int taubeam = -1;
int tauhl1beam = -1;
int tauhl2beam = -1;
int goopbeam = -1;
int headgroup = 2;
int equip = -1;
int flareammo[128];
int ManHackAmmo[128];
int CGuardAmm[128];
int EnergyAmm[128];
int HiveAmm[128];
int SnarkAmm[128];
int SatchelAmm[128];
int TripMineAmm[128];
int Ammo3Reset[128];
int Ammo12Reset[128];
int Ammo24Reset[128];
int AmmArr[128][32];
int CLManhack[128];
int clsummontarg[128];
int EndTarg[128];
int HandAttach[128];
int TauCharge[128];
int CLInScope[128];
int CLAttachment[128];
int Reviving[128];
float ReviveTime[128];
float Healchk[128];
float MedkitAmm[128];
float centnextatk[2048];
float centnextatk2[2048];
float clsummoncdc[128];
float antispamchk[128];
float WeapSnd[128];
float WeapAttackSpeed[128];
float flWeapReloadTime[2048];
char equipper[128];
char SteamID[128][32];
char custammtype[2048][32];
char custammtype2[2048][32];
char mapbuf[64];

Handle sweps = INVALID_HANDLE;
Handle swepsweap = INVALID_HANDLE; //Holds position for info array.
Handle swepsinfo = INVALID_HANDLE; //Contains info read from scriptedweap.
Handle weapanimcls = INVALID_HANDLE; //Holds position for info array.
Handle weapaniminf = INVALID_HANDLE; //Contains info read from other weap.
Handle hBaseWeapons = INVALID_HANDLE; //Automated list of base game weapons to ignore sweps functions
Handle precachedarr = INVALID_HANDLE;

ConVar hMolotovRadius;
ConVar hMaxMolotov;

public Plugin myinfo =
{
	name = "SynSweps",
	author = "Balimbanana",
	description = "Adds a few scripted weapons.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	sweps = CreateArray(48);
	swepsweap = CreateArray(48);
	swepsinfo = CreateArray(48);
	weapanimcls = CreateArray(48);
	weapaniminf = CreateArray(48);
	hBaseWeapons = CreateArray(64);
	precachedarr = CreateArray(48);
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	Handle cvar = FindConVar("synswepsdbg");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("synswepsdbg", "0", "SynSwepsdbg of setup.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, swepssetupch);
	dbgmdlsetup = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("sk_flaregun_ignighttime");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_flaregun_ignighttime", "10", "Time to ignight for.", _, true, 1.0, true, 99.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_immolator_ignighttime");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_immolator_ignighttime", "10", "Time to ignight for.", _, true, 1.0, true, 99.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_max_flaregun");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_flaregun", "20", "Maximum ammo for the flaregun.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_max_manhackgun");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_manhackgun", "3", "Maximum ammo for the manhack gun.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_max_energy");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_energy", "100", "Maximum ammo for the gluon and tau cannon.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_max_hivehand");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_hivehand", "100", "Maximum ammo for the hivehand.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_gluon");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_gluon", "30.0", "Damage per tick for the gluon gun.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_sl8");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_sl8", "8.0", "Damage for the SL8 weapon.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_oicw");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_oicw", "15.0", "Damage for the OICW.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_tau");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_tau", "20.0", "Damage for the Tau cannon.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_axe");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_axe", "20.0", "Damage for the FireAxe.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_m4");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_m4", "9.0", "Damage for the M4.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_g36c");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_g36c", "11.0", "Damage for the M4.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_tripmine_radius");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_tripmine_radius", "200", "Explosion radius of player tripmines.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_tripmine");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_tripmine", "150", "Explosion damage of player tripmines.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_satchel_radius");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_satchel_radius", "150", "Explosion radius of player satchels.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_satchel");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_satchel", "150", "Explosion damage of player satchels.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_glock");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_glock", "8", "Damage for the glock.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_sniperrifle");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_sniperrifle", "80", "Damage for the sniper rifle.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_uzi");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_uzi", "8", "Damage for the uzi.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_smg3");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_smg3", "14", "Damage for the smg3.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_smg4");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_smg4", "10", "Damage for the smg4.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_pistol1");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_pistol1", "50", "Damage for the Pistol1.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_pistol2");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_pistol2", "10", "Damage for the Pistol2.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_p911");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_p911", "18", "Damage for the P911.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_rifle1");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_rifle1", "10", "Damage for the Rifle1.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("sk_plr_dmg_vc32sniperrifle");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_vc32sniperrifle", "150", "Damage for the Rifle1.", _, true, 1.0, true, 999.0);
	CloseHandle(cvar);
	cvar = FindConVar("syn_tauknockback");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_tauknockback", "1", "Enables knock back effect for players from Tau cannon charged shots.", _, true, 0.0, true, 1.0);
	tauknockback = GetConVarBool(cvar);
	HookConVarChange(cvar, tauknockch);
	CloseHandle(cvar);
	hMolotovRadius = FindConVar("sk_molotov_radius");
	if (hMolotovRadius == INVALID_HANDLE) hMolotovRadius = CreateConVar("sk_molotov_radius", "140.0", "Molotov explode radius.", _, true, 1.0, false);
	hMaxMolotov = FindConVar("sk_max_molotov");
	if (hMaxMolotov == INVALID_HANDLE) hMaxMolotov = CreateConVar("sk_max_molotov", "10", "Maximum amount of molotovs held.", _, true, 1.0, false);
	cvar = FindConVar("sk_npc_head");
	if (cvar != INVALID_HANDLE)
	{
		headgroup = GetConVarInt(cvar);
		HookConVarChange(cvar, headgrpch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("mp_friendlyfire");
	if (cvar != INVALID_HANDLE)
	{
		friendlyfire = GetConVarBool(cvar);
		HookConVarChange(cvar, ffhch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("skill");
	if (cvar != INVALID_HANDLE)
	{
		difficulty = GetConVarInt(cvar);
		HookConVarChange(cvar, difficultych);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sv_weapon_lower_sprint");
	if (cvar != INVALID_HANDLE)
	{
		loweredsprint = GetConVarBool(cvar);
		HookConVarChange(cvar, weploweredch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("synsweps_spawnwith");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("synsweps_spawnwith", "", "Change what custom weapons you can spawn with. Separate each with a space.");
	GetConVarString(cvar,equipper,sizeof(equipper));
	HookConVarChange(cvar,spawnwithch);
	CloseHandle(cvar);
	CreateTimer(0.1, weaponticks, _, TIMER_REPEAT);
	CreateTimer(1.0, chkdisttargs, _, TIMER_REPEAT);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	RegConsoleCmd("dropweapon",dropcustweap);
	RegConsoleCmd("inventory",inventory);
	RegConsoleCmd("ironsights",ironsights);
	RegAdminCmd("sweps",sweplist,ADMFLAG_ROOT,"List of sweps.");
	RegAdminCmd("swepsanim",sweplistanim,ADMFLAG_ROOT,"Sweps weapanim.");
	//AddAmbientSoundHook(weapsoundchecks);
	//AddNormalSoundHook(weapnormsoundchecks);
	//HookUserMessage(GetUserMessageId("ItemPickup"),pickupusrmsg,true,_);
	char gamename[16];
	GetGameFolderName(gamename,sizeof(gamename));
	if ((StrEqual(gamename,"cstrike",false)) || (StrEqual(gamename,"csgo",false)))
	{
		bCSS = true;
	}
}

public void OnMapStart()
{
	GetCurrentMap(mapbuf,sizeof(mapbuf));
	ClearArray(sweps);
	ClearArray(swepsweap);
	ClearArray(swepsinfo);
	ClearArray(weapanimcls);
	ClearArray(weapaniminf);
	ClearArray(precachedarr);
	PushArrayString(sweps,"weapon_flaregun");
	PushArrayString(sweps,"weapon_manhack");
	PushArrayString(sweps,"weapon_manhackgun");
	PushArrayString(sweps,"weapon_manhacktoss");
	PushArrayString(sweps,"weapon_immolator");
	PushArrayString(sweps,"weapon_cguard");
	PushArrayString(sweps,"weapon_medkit");
	PushArrayString(sweps,"weapon_hivehand");
	PushArrayString(sweps,"weapon_hornetgun");
	PushArrayString(sweps,"weapon_snark");
	PushArrayString(sweps,"weapon_satchel");
	PushArrayString(sweps,"weapon_tripmine");
	PushArrayString(sweps,"weapon_handgrenade");
	PushArrayString(sweps,"weapon_mp5");
	PushArrayString(sweps,"weapon_sl8");
	PushArrayString(sweps,"weapon_oicw");
	PushArrayString(sweps,"weapon_glock");
	PushArrayString(sweps,"weapon_gauss");
	PushArrayString(sweps,"weapon_tau");
	PushArrayString(sweps,"weapon_gluon");
	PushArrayString(sweps,"weapon_m4");
	PushArrayString(sweps,"weapon_axe");
	PushArrayString(sweps,"weapon_g36c");
	PushArrayString(sweps,"weapon_colt");
	PushArrayString(sweps,"weapon_dualmp5k");
	PushArrayString(sweps,"weapon_sniperrifle");
	PushArrayString(sweps,"weapon_uzi");
	PushArrayString(sweps,"weapon_healer");
	PushArrayString(sweps,"weapon_goop");
	PushArrayString(sweps,"weapon_molotov");
	PushArrayString(sweps,"weapon_bhg");
	/*
	PushArrayString(sweps,"weapon_pistol1");
	PushArrayString(sweps,"weapon_pistol2");
	PushArrayString(sweps,"weapon_isa_knife");
	PushArrayString(sweps,"weapon_ls13");
	PushArrayString(sweps,"weapon_lugergun");
	PushArrayString(sweps,"weapon_rifle1");
	PushArrayString(sweps,"weapon_smg3");
	PushArrayString(sweps,"weapon_smg4");
	PushArrayString(sweps,"weapon_vc32sniperrifle");
	*/
	iWeapList = -1;
	OICWScope = -1;
	SL8Scope = -1;
	clsummonfil = -1;
	CLManhackRel = -1;
	customcvarsset = false;
	mdlus = PrecacheModel("effects/strider_pinch_dudv.vmt",true);
	mdlus3 = PrecacheModel("effects/strider_bulge_dudv.vmt",true);
	beamindx = PrecacheModel("sprites/bluelaser1.vmt",true);
	haloindx = PrecacheModel("sprites/blueshaft1.vmt",true);
	gluonbeam = PrecacheModel("effects/gluon_beam.vmt",true);
	taubeam = PrecacheModel("effects/tau_beam.vmt",true);
	tauhl1beam = PrecacheModel("sprites/smoke.vmt",true);
	tauhl2beam = PrecacheModel("sprites/laserbeam.vmt",true);
	goopbeam = PrecacheModel("sprites/goop/goop_beam.vmt",true);
	if ((GetMapHistorySize() > -1) && (strlen(equipper) > 0))
	{
		equip = CreateEntityByName("info_player_equip");
		if (equip != -1)
		{
			DispatchKeyValue(equip,"ResponseContext",equipper);
			DispatchSpawn(equip);
			ActivateEntity(equip);
		}
	}
	for (int i = 1;i<MaxClients+1;i++)
	{
		MedkitAmm[i] = 0.0;
		Healchk[i] = 0.0;
		antispamchk[i] = 0.0;
		WeapSnd[i] = 0.0;
		WeapAttackSpeed[i] = 0.0;
		CLManhack[i] = 0;
		clsummontarg[i] = 0;
		EndTarg[i] = 0;
		HandAttach[i] = 0;
		TauCharge[i] = 0;
		CLInScope[i] = 0;
		CLAttachment[i] = 0;
		Reviving[i] = -1;
		ReviveTime[i] = 0.0;
		HiveAmm[i] = 0;
		SnarkAmm[i] = 0;
		SatchelAmm[i] = 0;
		TripMineAmm[i] = 0;
		Ammo3Reset[i] = 0;
		Ammo12Reset[i] = 0;
		Ammo24Reset[i] = 0;
		AmmArr[i][0] = 3;
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
		}
	}
	for (int i = MaxClients+1;i<2048;i++)
	{
		centnextatk[i] = 0.0;
		centnextatk2[i] = 0.0;
		InChargeUp[i] = false;
		Format(custammtype[i],sizeof(custammtype[]),"");
		Format(custammtype2[i],sizeof(custammtype2[]),"");
	}
	if (FileExists("sound/weapons/flaregun/fire.wav",true,NULL_STRING)) PrecacheSound("weapons\\flaregun\\fire.wav",true);
	if (FileExists("sound/weapons/flaregun/flaregun_reload.wav",true,NULL_STRING)) PrecacheSound("weapons\\flaregun\\flaregun_reload.wav",true);
	if (FileExists("materials/models/HealthVial/plr_healthvial.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/HealthVial/plr_healthvial.vmt");
	if (FileExists("materials/models/HealthVial/plr_healthvial.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/HealthVial/plr_healthvial.vtf");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_normal.vtf");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_sheet.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_sheet.vmt");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_sheet.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_sheet.vtf");
	if (FileExists("materials/models/weapons/W_FlareGun/w_flaregun.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_FlareGun/w_flaregun.vmt");
	if (FileExists("materials/models/weapons/W_FlareGun/w_flaregun.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_FlareGun/w_flaregun.vtf");
	if (FileExists("models/items/boxflares.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.dx80.vtx");
	if (FileExists("models/items/boxflares.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.dx90.vtx");
	if (FileExists("models/items/boxflares.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.mdl");
	if (FileExists("models/items/boxflares.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.phy");
	if (FileExists("models/items/boxflares.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.sw.vtx");
	if (FileExists("models/items/boxflares.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.vvd");
	if (FileExists("models/weapons/v_flaregun.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.dx80.vtx");
	if (FileExists("models/weapons/v_flaregun.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.dx90.vtx");
	if (FileExists("models/weapons/v_flaregun.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.mdl");
	if (FileExists("models/weapons/v_flaregun.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.sw.vtx");
	if (FileExists("models/weapons/v_flaregun.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.vvd");
	if (FileExists("models/weapons/v_medkit.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.dx80.vtx");
	if (FileExists("models/weapons/v_medkit.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.dx90.vtx");
	if (FileExists("models/weapons/v_medkit.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.mdl");
	if (FileExists("models/weapons/v_medkit.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.sw.vtx");
	if (FileExists("models/weapons/v_medkit.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.vvd");
	if (FileExists("models/weapons/W_FlareGun.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.dx80.vtx");
	if (FileExists("models/weapons/W_FlareGun.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.dx90.vtx");
	if (FileExists("models/weapons/w_flaregun.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_flaregun.mdl");
	if (FileExists("models/weapons/W_FlareGun.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.phy");
	if (FileExists("models/weapons/W_FlareGun.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.sw.vtx");
	if (FileExists("models/weapons/w_flaregun.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_flaregun.vvd");
	if (FileExists("models/weapons/W_medkitweap.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.dx80.vtx");
	if (FileExists("models/weapons/W_medkitweap.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.dx90.vtx");
	if (FileExists("models/weapons/w_medkitweap.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_medkitweap.mdl");
	if (FileExists("models/weapons/W_medkitweap.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.phy");
	if (FileExists("models/weapons/W_medkitweap.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.sw.vtx");
	if (FileExists("models/weapons/w_medkitweap.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_medkitweap.vvd");
	if (FileExists("models/weapons/v_sl8.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.dx80.vtx");
	if (FileExists("models/weapons/v_sl8.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.dx90.vtx");
	if (FileExists("models/weapons/v_sl8.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.mdl");
	if (FileExists("models/weapons/v_sl8.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.sw.vtx");
	if (FileExists("models/weapons/v_sl8.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.vvd");
	if (FileExists("models/weapons/w_sl8.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.dx80.vtx");
	if (FileExists("models/weapons/w_sl8.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.dx90.vtx");
	if (FileExists("models/weapons/w_sl8.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.mdl");
	if (FileExists("models/weapons/w_sl8.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.phy");
	if (FileExists("models/weapons/w_sl8.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.sw.vtx");
	if (FileExists("models/weapons/w_sl8.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.vvd");
	if (FileExists("materials/models/weapons/V_SL8/base.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/base.vmt");
	if (FileExists("materials/models/weapons/V_SL8/base.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/base.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Base_Normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Base_Normal.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Scope.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope.vmt");
	if (FileExists("materials/models/weapons/V_SL8/Scope.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Scope_Normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope_Normal.vtf");
	if (FileExists("materials/models/weapons/W_SL8/wbase.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase.vmt");
	if (FileExists("materials/models/weapons/W_SL8/wbase.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase.vtf");
	if (FileExists("materials/models/weapons/W_SL8/wbase-n.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase-n.vtf");
	if (FileExists("sound/weapons/SL8/sl8_boltback.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_boltback.wav");
	if (FileExists("sound/weapons/SL8/sl8_boltforward.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_boltforward.wav");
	if (FileExists("sound/weapons/SL8/sl8_magin.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_magin.wav");
	if (FileExists("sound/weapons/SL8/sl8_magout.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_magout.wav");
	if (FileExists("sound/weapons/SL8/SL8-1.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/SL8-1.wav");
	if (FileExists("materials/sprites/scope01.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/scope01.vtf");
	if (FileExists("materials/sprites/scope01.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/scope01.vmt");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet.vmt");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet.vtf");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet_normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet_normal.vtf");
	if (FileExists("materials/models/weapons/W_oicw/w_oicw.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_oicw/w_oicw.vmt");
	if (FileExists("materials/models/weapons/W_oicw/w_oicw.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_oicw/w_oicw.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope2.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope2.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope_lens.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope_lens.vmt");
	if (FileExists("models/weapons/v_oicw.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.dx80.vtx");
	if (FileExists("models/weapons/v_oicw.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.dx90.vtx");
	if (FileExists("models/weapons/v_oicw.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.mdl");
	if (FileExists("models/weapons/v_oicw.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.sw.vtx");
	if (FileExists("models/weapons/v_oicw.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.vvd");
	if (FileExists("models/weapons/w_oicw.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.dx80.vtx");
	if (FileExists("models/weapons/w_oicw.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.dx90.vtx");
	if (FileExists("models/weapons/w_oicw.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.mdl");
	if (FileExists("models/weapons/w_oicw.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.phy");
	if (FileExists("models/weapons/w_oicw.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.sw.vtx");
	if (FileExists("models/weapons/w_oicw.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.vvd");
	if (FileExists("scripts/weapon_flaregun.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_flaregun.txt");
	if (FileExists("scripts/weapon_medkit.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_medkit.txt");
	if (FileExists("scripts/weapon_sl8.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_sl8.txt");
	if (FileExists("scripts/weapon_oicw.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_oicw.txt");
	PrecacheSound("items/suitchargeno1.wav",true);
	PrecacheSound("items/suitchargeok1.wav",true);
	PrecacheSound("items/medshot4.wav",true);
	PrecacheSound("weapons/gauss/fire1.wav",true);
	PrecacheSound("weapons/pistol/empty.wav",true);
	PrecacheSound("weapons\\pistol\\empty.wav",true);
	findentlist(-1,"npc_*");
	findentlist(-1,"monster_*");
	findentlist(-1,"generic_actor");
	findentlist(-1,"monster_generic");
	findentlist(-1,"item_ammo*");
}

public Action sweplistanim(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	char szWeapCls[64];
	if (args < 1)
	{
		int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
		if (IsValidEntity(weap)) GetEntityClassname(weap,szWeapCls,sizeof(szWeapCls));
	}
	if (strlen(szWeapCls) > 0)
	{
		int arrindx = FindStringInArray(weapanimcls,szWeapCls);
		if (arrindx == -1)
		{
			Handle dp = CreateDataPack();
			char filepath[128];
			Format(filepath,sizeof(filepath),"scripts/%s.txt",szWeapCls);
			char weapmdl[128];
			if (FileExists(filepath,true,NULL_STRING))
			{
				Handle filehandlesub = OpenFile(filepath,"r",true,NULL_STRING);
				if (filehandlesub != INVALID_HANDLE)
				{
					char scrline[128];
					while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
					{
						TrimString(scrline);
						if (strlen(scrline) > 0)
						{
							if ((StrContains(scrline,"viewmodel",false) != -1) && (StrContains(scrline,"csviewmodel",false) == -1))
							{
								char tmp[64];
								Format(tmp,sizeof(tmp),"%s",scrline);
								ReplaceString(tmp,sizeof(tmp),"\"","");
								ReplaceString(tmp,sizeof(tmp),"	"," ");
								TrimString(tmp);
								char fixuptmp[32][128];
								ExplodeString(tmp," ",fixuptmp,32,128,true);
								for (int i = 0;i<5;i++)
								{
									TrimString(fixuptmp[i]);
									if ((strlen(fixuptmp[i]) > 0) && (i > 1))
									{
										Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
									}
								}
								Format(weapmdl,sizeof(weapmdl),"%s",fixuptmp[1]);
								break;
							}
						}
					}
					CloseHandle(filehandlesub);
					if (strlen(weapmdl) > 0)
					{
						if (FileExists(weapmdl,true,NULL_STRING))
						{
							Handle actmap = CreateArray(64);
							Handle filehandlemdl = OpenFile(weapmdl,"rb",true,NULL_STRING);
							if (filehandlemdl != INVALID_HANDLE)
							{
								char tmp[500];
								char push[80];
								while(!IsEndOfFile(filehandlemdl)&&ReadFileLine(filehandlemdl,tmp,sizeof(tmp)))
								{
									TrimString(tmp);
									if (StrContains(tmp,"ACT",false) != -1)
									{
										Format(push,sizeof(push),"%s %s",push,tmp);
										if (dbgmdlsetup) PrintToServer("ActMap %s %s",szWeapCls,push);
										PushArrayString(actmap,push);
										PrintToConsole(client,"%s",push);
										push = "";
									}
									else if (strlen(tmp) > 0)
									{
										Format(push,sizeof(push),"%s",tmp);
									}
								}
							}
							CloseHandle(filehandlemdl);
							if (GetArraySize(actmap) > 0)
							{
								GetSequencesFromAnim(dp,actmap,weapmdl,false);
							}
							CloseHandle(actmap);
						}
					}
					PushArrayString(weapanimcls,szWeapCls);
				}
			}
		}
		else if (arrindx < GetArraySize(weapaniminf))
		{
			Handle dp = GetArrayCell(weapaniminf,arrindx);
			if (dp != INVALID_HANDLE)
			{
				char weapdata[80];
				ResetPack(dp);
				ReadPackString(dp,weapdata,sizeof(weapdata));
				while (!StrEqual(weapdata,"endofpack",false))
				{
					PrintToConsole(client,"%s",weapdata);
					ReadPackString(dp,weapdata,sizeof(weapdata));
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action sweplist(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if (GetArraySize(sweps) > 0)
	{
		Menu menu = new Menu(MenuHandlerSweps);
		menu.SetTitle("Sweps");
		for (int i = 0;i<GetArraySize(sweps);i++)
		{
			char swep[64];
			GetArrayString(sweps,i,swep,sizeof(swep));
			char swepchk[72];
			Format(swepchk,sizeof(swepchk),"scripts/%s.txt",swep);
			if (FileExists(swepchk,true,NULL_STRING))
			{
				if (client == 0) PrintToServer("%s",swep);
				else
				{
					char szWeapClsren[64];
					Format(szWeapClsren,sizeof(szWeapClsren),"%s",swep);
					ReplaceStringEx(szWeapClsren,sizeof(szWeapClsren),"weapon_","");
					if (strlen(szWeapClsren) < 5)
					{
						for (int j = 0;j<strlen(szWeapClsren)+1;j++)
						{
							if (StringToInt(szWeapClsren[j]) == 0)
								szWeapClsren[j] &= ~(1 << 5);
						}
					}
					else
					{
						szWeapClsren[0] &= ~(1 << 5);
					}
					menu.AddItem(swep,szWeapClsren);
				}
			}
		}
		if (GetArraySize(swepsweap) > 0)
		{
			for (int i = 0;i<GetArraySize(swepsweap);i++)
			{
				char swep[64];
				GetArrayString(swepsweap,i,swep,sizeof(swep));
				char swepchk[72];
				Format(swepchk,sizeof(swepchk),"scripts/%s.txt",swep);
				if (FileExists(swepchk,true,NULL_STRING))
				{
					if (client == 0) PrintToServer("%s",swep);
					else
					{
						char lastposarr[16][128];
						char szWeapClsren[64];
						ExplodeString(swep,"/",lastposarr,16,128,true);
						for (int j = 0;j<5;j++)
						{
							TrimString(lastposarr[j]);
							if ((strlen(lastposarr[j]) > 0) && (j > 1) && (StrContains(lastposarr[j],"//",false) == -1))
							{
								Format(szWeapClsren,sizeof(szWeapClsren),"%s",lastposarr[j]);
							}
						}
						Format(szWeapClsren,sizeof(szWeapClsren),"%s",swep);
						ReplaceStringEx(szWeapClsren,sizeof(szWeapClsren),"custom_","");
						if (strlen(szWeapClsren) < 5)
						{
							for (int j = 0;j<strlen(szWeapClsren)+1;j++)
							{
								if (StringToInt(szWeapClsren[j]) == 0)
									szWeapClsren[j] &= ~(1 << 5);
							}
						}
						else
						{
							szWeapClsren[0] &= ~(1 << 5);
						}
						menu.AddItem(swep,szWeapClsren);
					}
				}
			}
		}
		if (client != 0)
		{
			menu.ExitButton = true;
			menu.Display(client, 120);
		}
		else CloseHandle(menu);
	}
	return Plugin_Handled;
}

void findentlist(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char classname[32];
		GetEntityClassname(thisent,classname,sizeof(classname));
		if ((StrEqual(classname,"item_ammo_flare_box",false)) || (StrEqual(classname,"item_box_flare_rounds",false)) || (StrEqual(classname,"item_ammo_manhack",false)) || (StrEqual(classname,"item_ammo_energy",false)) || (StrEqual(classname,"item_ammo_bhg",false)))
		{
			SDKHookEx(thisent, SDKHook_StartTouch, StartTouchAmmoPickup);
		}
		if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"env_xen_portal",false)) && (!StrEqual(classname,"env_xen_portal_template",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)) && (StrContains(classname,"info_",false) == -1) && (StrContains(classname,"game_",false) == -1) && (StrContains(classname,"trigger_",false) == -1))
		{
			SDKHookEx(thisent, SDKHook_OnTakeDamage, OnNPCTakeDamage);
		}
		findentlist(thisent++,clsname);
	}
}

public Action OnNPCTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((IsValidEntity(attacker)) && (IsValidEntity(victim)))
	{
		if (HasEntProp(attacker,Prop_Data,"m_hOwnerEntity"))
		{
			int client = GetEntPropEnt(attacker,Prop_Data,"m_hOwnerEntity");
			if (IsValidEntity(client))
			{
				char clschk[32];
				GetEntityClassname(client,clschk,sizeof(clschk));
				if (StrEqual(clschk,"env_explosion",false))
				{
					client = GetEntPropEnt(client,Prop_Data,"m_hEffectEntity");
				}
			}
			/*
			char vicname[64];
			GetEntityClassname(victim,vicname,sizeof(vicname));
			char atkname[64];
			GetEntityClassname(attacker,atkname,sizeof(atkname));
			PrintToServer("%i atk %i %s inf %i dmg fr %i %s",client,attacker,atkname,inflictor,victim,vicname);
			*/
			if ((!IsValidEntity(client)) || (client > MaxClients) || (client == 0))
			{
				if ((attacker > 0) && (attacker < MaxClients+1)) client = attacker;
			}
			if ((client > 0) && (client < MaxClients+1))
			{
				char weapdmg[64];
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					inflictor = weap;
					GetEntityClassname(weap,weapdmg,sizeof(weapdmg));
					if (FindStringInArray(sweps,weapdmg) != -1)
					{
						char clsname[64];
						GetEntityClassname(victim,clsname,sizeof(clsname));
						if (StrEqual(clsname,"generic_actor",false))
						{
							int parchk = GetEntPropEnt(victim,Prop_Data,"m_hParent");
							if (IsValidEntity(parchk))
							{
								victim = parchk;
								GetEntityClassname(victim,clsname,sizeof(clsname));
							}
						}
						if (CheckNPCAlly(clsname,victim))
						{
							damage = 0.0;
							return Plugin_Changed;
						}
						attacker = client;
						ReplaceStringEx(weapdmg,sizeof(weapdmg),"weapon_","sk_plr_dmg_");
						Handle cvar = FindConVar(weapdmg);
						if (cvar != INVALID_HANDLE)
						{
							damage = GetConVarFloat(cvar);
							float tkscale = 1.0;
							char scalechk[32];
							Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
							Handle scaleh = FindConVar(scalechk);
							if (scaleh != INVALID_HANDLE) tkscale = GetConVarFloat(scaleh);
							CloseHandle(scaleh);
							damage = damage/tkscale;
							if (StrEqual(weapdmg,"sk_plr_dmg_tau",false))
							{
								if (TauCharge[client] > 1)
								{
									damage = damage*(1.0+TauCharge[client]/2);
								}
								damagetype = 256;
							}
							else if (StrEqual(weapdmg,"sk_plr_dmg_gluon",false))
							{
								damagetype = 1024;
							}
						}
						CloseHandle(cvar);
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if ((killed > 0) && (killed < MaxClients+1))
	{
		FindStrayWeaps(-1,killed);
	}
}

public void swepssetupch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) dbgmdlsetup = true;
	else dbgmdlsetup = false;
}

public void tauknockch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) tauknockback = true;
	else tauknockback = false;
}

public void headgrpch(Handle convar, const char[] oldValue, const char[] newValue)
{
	headgroup = StringToInt(newValue);
}

public void ffhch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) friendlyfire = true;
	else friendlyfire = false;
}

public void difficultych(Handle convar, const char[] oldValue, const char[] newValue)
{
	difficulty = StringToInt(newValue);
}

public void weploweredch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) loweredsprint = true;
	else loweredsprint = false;
}

public void spawnwithch(Handle convar, const char[] oldValue, const char[] newValue)
{
	Format(equipper,sizeof(equipper),"%s",newValue);
	if (IsValidEntity(equip))
	{
		SetEntPropString(equip,Prop_Data,"m_iszResponseContext",newValue);
	}
	else if ((GetMapHistorySize() > 0) && (strlen(newValue) > 0))
	{
		equip = CreateEntityByName("info_player_equip");
		if (equip != -1)
		{
			DispatchKeyValue(equip,"ResponseContext",newValue);
			DispatchSpawn(equip);
			ActivateEntity(equip);
		}
	}
}

void FindStrayWeaps(int ent, int client)
{
	int thisent = FindEntityByClassname(ent,"weapon_*");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		if (HasEntProp(thisent,Prop_Data,"m_hParent"))
		{
			int parentchk = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
			if (parentchk == client) AcceptEntityInput(thisent,"ClearParent");
		}
		FindStrayWeaps(thisent++,client);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname,"weapon_",false) == 0)
	{
		if (FindStringInArray(hBaseWeapons,classname) == -1) PushArrayString(hBaseWeapons,classname);
		CreateTimer(0.5,waititem,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrContains(classname,"item_ammo",false) == 0)
	{
		CreateTimer(0.5,waititem,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"env_xen_portal",false)) && (!StrEqual(classname,"env_xen_portal_template",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)) && (StrContains(classname,"info_",false) == -1) && (StrContains(classname,"game_",false) == -1) && (StrContains(classname,"trigger_",false) == -1))
	{
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
	}
	/*
	if (StrEqual(classname,"weapon_smg1",false))
	{
		SDKHookEx(entity, SDKHook_Spawn, PreModelSetSpawn);
	}
	*/
}

public Action PreModelSetSpawn(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_ModelName"))
		{
			if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity"))
			{
				int owner = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
				if (owner != -1)
				{
					PrintToServer("%i has owner %i",entity,owner);
					char mdl[64];
					GetEntPropString(entity,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (strlen(mdl) < 1)
					{
						DispatchKeyValue(entity,"classname","kzsmodifiedweaps/weapon_ar2");
						//DispatchKeyValue(entity,"classname","weapon_shotgun");
						DispatchKeyValue(entity,"model","models/weapons/w_smg1.mdl");
						if (!IsModelPrecached("models/weapons/w_smg1.mdl")) PrecacheModel("models/weapons/w_smg1.mdl",true);
						SetEntityModel(entity,"models/weapons/w_smg1.mdl");
						SetEntPropString(entity,Prop_Data,"m_ModelName","models/weapons/w_smg1.mdl");
						CreateTimer(0.1,SetMdlAgain,entity,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

public Action SetMdlAgain(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		DispatchKeyValue(entity,"model","models/weapons/w_smg1.mdl");
		SetEntityModel(entity,"models/weapons/w_smg1.mdl");
		SetEntPropString(entity,Prop_Data,"m_ModelName","models/weapons/w_smg1.mdl");
	}
}

public void OnEntityDestroyed(int entity)
{
	SDKUnhook(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
	if (entity > 0)
	{
		InChargeUp[entity] = false;
		flWeapReloadTime[entity] = 0.0;
		Format(custammtype[entity],sizeof(custammtype[]),"");
		Format(custammtype2[entity],sizeof(custammtype2[]),"");
	}
}

public Action inventory(int client, int args)
{
	if (IsValidEntity(client))
	{
		if (IsPlayerAlive(client))
		{
			Menu menu = new Menu(MenuHandler);
			menu.SetTitle("Inventory");
			if (iWeapList == -1) iWeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
			if (iWeapList != -1)
			{
				char szWeapCls[64];
				char szWeapClsren[64];
				for (int j; j<104; j += 4)
				{
					int tmpi = GetEntDataEnt2(client,iWeapList + j);
					if (tmpi != -1)
					{
						GetEntityClassname(tmpi,szWeapCls,sizeof(szWeapCls));
						Format(szWeapClsren,sizeof(szWeapClsren),"%s",szWeapCls);
						ReplaceStringEx(szWeapClsren,sizeof(szWeapClsren),"weapon_","");
						if (strlen(szWeapClsren) < 5)
						{
							for (int i = 0;i<strlen(szWeapClsren)+1;i++)
							{
								if (StringToInt(szWeapClsren[i]) == 0)
									szWeapClsren[i] &= ~(1 << 5);
							}
						}
						else
						{
							szWeapClsren[0] &= ~(1 << 5);
						}
						menu.AddItem(szWeapCls,szWeapClsren);
					}
				}
			}
			menu.ExitButton = true;
			menu.Display(client, 120);
		}
	}
	return Plugin_Handled;
}

public Action ironsights(int client, int args)
{
	if ((!IsValidEntity(client)) || (client == 0)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if (InIronSights[client])
	{
		int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
		if (weap != -1)
		{
			char curweap[64];
			GetEntPropString(weap,Prop_Data,"m_iszResponseContext",curweap,sizeof(curweap));
			InIronSights[client] = false;
			int fov = GetEntProp(client,Prop_Send,"m_iFOV");
			if (fov == 0) fov = 60;
			SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
			SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
			SetEntProp(client,Prop_Send,"m_iFOV",90);
			SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
			int findweap = FindStringInArray(swepsweap,curweap);
			if (findweap != -1)
			{
				Handle dp = GetArrayCell(swepsinfo,findweap);
				if (dp != INVALID_HANDLE)
				{
					char weapdata[80];
					ResetPack(dp);
					ReadPackString(dp,weapdata,sizeof(weapdata));
					while (!StrEqual(weapdata,"endofpack",false))
					{
						if (StrContains(weapdata,"ACT_VM_IDLE",false) >= 2)
						{
							char tmp[4][64];
							ExplodeString(weapdata," ",tmp,4,64);
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != StringToInt(tmp[0]))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",StringToInt(tmp[0]));
								}
							}
							break;
						}
						ReadPackString(dp,weapdata,sizeof(weapdata));
					}
				}
			}
		}
	}
	else
	{
		int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
		if (weap != -1)
		{
			char curweap[64];
			GetEntPropString(weap,Prop_Data,"m_iszResponseContext",curweap,sizeof(curweap));
			bool HasIronSights = false;
			int findweap = FindStringInArray(swepsweap,curweap);
			if (findweap != -1)
			{
				Handle dp = GetArrayCell(swepsinfo,findweap);
				if (dp != INVALID_HANDLE)
				{
					char weapdata[80];
					ResetPack(dp);
					ReadPackString(dp,weapdata,sizeof(weapdata));
					while (!StrEqual(weapdata,"endofpack",false))
					{
						if ((StrContains(weapdata,"SIGHTS_IN",false) >= 2) || (StrContains(weapdata,"IRONSIGHTED",false) >= 2))
						{
							char tmp[4][64];
							ExplodeString(weapdata," ",tmp,4,64);
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != StringToInt(tmp[0]))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",StringToInt(tmp[0]));
								}
							}
							HasIronSights = true;
							break;
						}
						ReadPackString(dp,weapdata,sizeof(weapdata));
					}
				}
			}
			if (HasIronSights)
			{
				InIronSights[client] = true;
				int fov = GetEntProp(client,Prop_Send,"m_iFOV");
				if (fov == 0) fov = 90;
				SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
				SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
				SetEntProp(client,Prop_Send,"m_iFOV",60);
				SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
			}
			else PrintToChat(client,"Current weapon doesn't have iron sights.");
		}
	}
	return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (IsValidEntity(param1)))
	{
		if (IsPlayerAlive(param1))
		{
			char info[128];
			menu.GetItem(param2, info, sizeof(info));
			if (strlen(info) > 0)
			{
				ClientCommand(param1,"use %s",info);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlerSweps(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (IsValidEntity(param1)))
	{
		if (IsPlayerAlive(param1))
		{
			char info[128];
			menu.GetItem(param2, info, sizeof(info));
			if (strlen(info) > 0)
			{
				char weapscr[72];
				Format(weapscr,sizeof(weapscr),"scripts/%s.txt",info);
				if (FileExists(weapscr,true,NULL_STRING))
				{
					bool nouse = false;
					char basecls[64];
					if (bCSS)
					{
						Format(basecls,sizeof(basecls),"weapon_csbase_gun");
					}
					else
					{
						if (StrEqual(info,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
						else if (StrEqual(info,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
						else if ((StrEqual(info,"weapon_glock",false)) || (StrEqual(info,"weapon_pistol_worker",false)) || (StrEqual(info,"weapon_flaregun",false)) || (StrEqual(info,"weapon_manhack",false)) || (StrEqual(info,"weapon_manhackgun",false)) || (StrEqual(info,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
						else if ((StrEqual(info,"weapon_medkit",false)) || (StrEqual(info,"weapon_healer",false)) || (StrEqual(info,"weapon_snark",false)) || (StrEqual(info,"weapon_hivehand",false)) || (StrEqual(info,"weapon_hornetgun",false)) || (StrEqual(info,"weapon_satchel",false)) || (StrEqual(info,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
						else if ((StrEqual(info,"weapon_mp5",false)) || (StrEqual(info,"weapon_m4",false)) || (StrEqual(info,"weapon_sl8",false)) || (StrEqual(info,"weapon_g36c",false)) || (StrEqual(info,"weapon_oicw",false)) || (StrEqual(info,"weapon_uzi",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
						else if ((StrEqual(info,"weapon_gauss",false)) || (StrEqual(info,"weapon_tau",false)) || (StrEqual(info,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
						else if (StrEqual(info,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
						else if (StrEqual(info,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
						else if (StrContains(info,"custom_",false) != -1)
						{
							Handle filehandlesub = OpenFile(weapscr,"r",true,NULL_STRING);
							if (filehandlesub != INVALID_HANDLE)
							{
								char scrline[64];
								while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
								{
									TrimString(scrline);
									if (StrContains(scrline,"\"anim_prefix\"",false) != -1)
									{
										ReplaceStringEx(scrline,sizeof(scrline),"\"anim_prefix\"","",_,_,false);
										ReplaceString(scrline,sizeof(scrline),"\"","");
										TrimString(scrline);
										if (StrEqual(scrline,"python",false)) Format(scrline,sizeof(scrline),"357");
										else if (StrEqual(scrline,"gauss",false)) Format(scrline,sizeof(scrline),"shotgun");
										else if (StrEqual(scrline,"smg2",false)) Format(scrline,sizeof(scrline),"smg1");
										else if (StrEqual(scrline,"grenade",false)) Format(scrline,sizeof(scrline),"crowbar");
										Format(scrline,sizeof(scrline),"weapon_%s",scrline);
										Format(basecls,sizeof(basecls),"%s",scrline);
										nouse = true;
										break;
									}
								}
							}
							CloseHandle(filehandlesub);
						}
					}
					int ent = CreateEntityByName(basecls);
					if (ent != -1)
					{
						float clorigin[3];
						GetClientAbsOrigin(param1,clorigin);
						clorigin[2]+=20.0;
						TeleportEntity(ent,clorigin,NULL_VECTOR,NULL_VECTOR);
						DispatchKeyValue(ent,"classname",info);
						DispatchSpawn(ent);
						ActivateEntity(ent);
						if (!nouse)
						{
							Handle dp = CreateDataPack();
							WritePackCell(dp,param1);
							WritePackString(dp,info);
							CreateTimer(0.1,useweap,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
				else
				{
					PrintToChat(param1,"Cannot spawn this swep. Most likely not currently mounted.");
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action useweap(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		char weap[64];
		ResetPack(dp);
		int client = ReadPackCell(dp);
		ReadPackString(dp,weap,sizeof(weap));
		CloseHandle(dp);
		if ((strlen(weap) > 0) && (IsValidEntity(client)))
		{
			ClientCommand(client,"use %s",weap);
		}
	}
}

public Action dropcustweap(int client, int args)
{
	int weapdrop = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
	if ((weapdrop != 0) && (IsValidEntity(weapdrop)))
	{
		char szWeapCls[64];
		GetEntityClassname(weapdrop,szWeapCls,sizeof(szWeapCls));
		if (FindStringInArray(sweps,szWeapCls) != -1)
		{
			if (HasEntProp(weapdrop,Prop_Data,"m_fEffects")) SetEntProp(weapdrop,Prop_Data,"m_fEffects",128);
			if (HasEntProp(weapdrop,Prop_Send,"m_fEffects")) SetEntProp(weapdrop,Prop_Send,"m_fEffects",128);
			if (HasEntProp(weapdrop,Prop_Data,"m_fFlags")) SetEntProp(weapdrop,Prop_Data,"m_fFlags",0);
			if (HasEntProp(weapdrop,Prop_Send,"m_fFlags")) SetEntProp(weapdrop,Prop_Send,"m_fFlags",0);
			if (HasEntProp(weapdrop,Prop_Data,"m_nViewModelIndex")) SetEntProp(weapdrop,Prop_Data,"m_nViewModelIndex",0);
			if (HasEntProp(weapdrop,Prop_Data,"m_usSolidFlags")) SetEntProp(weapdrop,Prop_Data,"m_usSolidFlags",136);
			SetEntityMoveType(weapdrop,MOVETYPE_VPHYSICS);
			ChangeEdictState(weapdrop);
			AcceptEntityInput(weapdrop,"ClearParent");
		}
	}
	return Plugin_Continue;
}

public Action weaponticks(Handle timer)
{
	if (GetClientCount(false))
	{
		float Time = GetTickedTime();
		for (int client = 1;client<MaxClients+1;client++)
		{
			if (IsValidEntity(client))
			{
				if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
				{
					char curweap[32];
					char scrwep[64];
					//GetClientWeapon(client,curweap,sizeof(curweap));
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (IsValidEntity(weap))
					{
						GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
						GetEntPropString(weap,Prop_Data,"m_iszResponseContext",scrwep,sizeof(scrwep));
					}
					int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
					int useent = GetEntPropEnt(client,Prop_Data,"m_hUseEntity");
					if ((vehicle == -1) && (useent == -1) && (FindStringInArray(sweps,curweap) != -1))
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int effects = GetEntProp(viewmdl,Prop_Send,"m_fEffects");
							if ((effects & 32))
							{
								effects &= ~32;
								SetEntProp(viewmdl,Prop_Send,"m_fEffects",effects);
							}
						}
						if (((StrEqual(curweap,"weapon_medkit",false)) || (StrEqual(curweap,"weapon_healer",false))) && (MedkitAmm[client] <= Time))
						{
							int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
							if (medkitammo < 100)
							{
								if (medkitammo+5 < 100) SetEntProp(client,Prop_Data,"m_iHealthPack",medkitammo+5);
								else SetEntProp(client,Prop_Data,"m_iHealthPack",100);
								ChangeEdictState(client);
							}
							MedkitAmm[client] = Time+1.0;
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if ((StrContains(curweap,"weapon_manhack",false) == 0) || (StrEqual(curweap,"weapon_cguard",false)) || (StrEqual(curweap,"weapon_gauss",false)))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if ((StrEqual(curweap,"weapon_gluon",false)) || (StrEqual(curweap,"weapon_goop",false)))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 3)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						else if (StrEqual(curweap,"weapon_tau",false))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
							ChangeEdictState(weap);
							if ((idletime > 1.0) && (centnextatk[client] < Time))
							{
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if ((seq < 4) && (seq > 0))
									{
										int rand = GetRandomInt(1,3);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
										if (rand == 3) centnextatk[client] = Time+GetRandomFloat(6.0,10.0);
										else centnextatk[client] = Time+GetRandomFloat(1.0,4.0);
									}
									else if (seq > 10)
									{
										int rand = GetRandomInt(1,3);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									}
								}
							}
						}
						else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
							ChangeEdictState(weap);
							if ((idletime > 10.0) && (idletime < 10.2))
							{
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if ((seq != 3) && (seq != 4))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
										CreateTimer(1.0,resetviewmdl,viewmdl);
									}
								}
							}
							if (idletime > 1.0)
							{
								int maxhivehand = 100;
								Handle cvar = FindConVar("sk_max_hivehand");
								if (cvar != INVALID_HANDLE) maxhivehand = GetConVarInt(cvar);
								CloseHandle(cvar);
								if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxhivehand)
								{
									HiveAmm[client]++;
									SetEntProp(weap,Prop_Data,"m_iClip1",HiveAmm[client]);
								}
							}
						}
						else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
						{
							if (weap != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								//Allow default secondary attack handling
								//SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
								int mdlseq = 2;
								int lowerseq = 7;
								int maxclip = 30;
								char snd[64];
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									mdlseq = 3;
									maxclip = 50;
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									mdlseq = 7;
									Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
								}
								else if (StrEqual(curweap,"weapon_g36c",false))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\mp5\\mp5_reload.wav");
								}
								else
								{
									Format(snd,sizeof(snd),"weapons\\mp5\\reload.wav");
								}
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											//StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											flWeapReloadTime[weap] = GetTickedTime()+1.7;
										}
										if ((flWeapReloadTime[weap] != 0.0) && (flWeapReloadTime[weap] <= GetTickedTime()))
										{
											flWeapReloadTime[weap] = 0.0;
											if (viewmdl != -1)
											{
												SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
												SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
												SetEntProp(weap,Prop_Data,"m_bInReload",0);
												//CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
												//SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
											}
										}
									}
								}
								else if (!inreload)
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if ((seq == mdlseq) || (seq == lowerseq))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
									}
								}
								//StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_sl8",false))
						{
							if (weap != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
								int mdlseq = 2;
								int maxclip = 20;
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								SetEntPropFloat(weap,Prop_Data,"m_fFireDuration",0.0);
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
											StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (FileExists("sound/weapons/sl8/sl8_magout.wav",true,NULL_STRING))
											{
												char snd[64];
												Format(snd,sizeof(snd),"weapons\\sl8\\sl8_magout.wav");
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
												CreateTimer(0.6,resetviewmdl,viewmdl);
											}
										}
									}
								}
								else if (!inreload)
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq == 1)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
									}
								}
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_uzi",false))
						{
							if (weap != -1)
							{
								/*
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								if (!inreload)
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										int mdlseq = 0;
										if (CLAttachment[client]) mdlseq = 2;
										if (seq != mdlseq)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										}
									}
								}
								*/
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_oicw",false))
						{
							if (weap != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
								int mdlseq = 5;
								int maxclip = 30;
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								SetEntPropFloat(weap,Prop_Data,"m_fFireDuration",0.0);
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (FileExists("sound/weapons/oicw/oicw_reload.wav",true,NULL_STRING))
											{
												char snd[64];
												Format(snd,sizeof(snd),"weapons\\oicw\\oicw_reload.wav");
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
												CreateTimer(2.3,resetviewmdl,viewmdl);
												SetEntProp(weap,Prop_Data,"m_bInReload",1);
											}
										}
									}
								}
								else if (!inreload)
								{
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq == 5)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
										else if (seq == 9)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
										}
									}
								}
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_glock",false))
						{
							if (weap != -1)
							{
								int maxclip = 17;
								if (viewmdl != -1)
								{
									int mdlseq = 0;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									char snd[64];
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										mdlseq = 5;
										Format(snd,sizeof(snd),"weapons\\reload%i.wav",GetRandomInt(1,3));
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										maxclip = 15;
										mdlseq = 9;
										Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload1.wav");
									}
									else
									{
										Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
									}
									if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (GetEntProp(weap,Prop_Data,"m_bInReload") == 1))
									{
										if (((seq != 6) && (seq != 7)) || ((mdlseq != 0) && (seq != mdlseq)))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											if (mdlseq != 0) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											else SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
									}
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if (seq == 8) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										if (seq == 10) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else
									{
										if (seq == 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
									}
								}
							}
						}
						else if (StrEqual(curweap,"weapon_flaregun",false))
						{
							if (weap != -1)
							{
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
									SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
									ChangeEdictState(weap);
									if (seq == 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						else if (StrEqual(curweap,"weapon_tripmine",false))
						{
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
							}
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_satchel",false))
						{
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
							}
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_snark",false))
						{
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
								if ((seq == 6) && (SnarkAmm[client] > 0)) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								else if (((seq <= 2) || (seq >= 10)) && (idletime > 14.0))
								{
									if (IsValidEntity(weap))
									{
										int rand = GetRandomInt(1,3);
										if (rand == 3) rand = GetRandomInt(10,15);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
										if (rand != 12) SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",GetRandomFloat(8.0,12.0));
										else SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
									}
								}
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
							}
						}
						else if (StrEqual(curweap,"weapon_colt",false))
						{
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int maxclip = 8;
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (GetEntProp(weap,Prop_Data,"m_bInReload") == 1))
								{
									int mdlseq = 4;
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
								}
							}
						}
						else if (StrEqual(curweap,"weapon_sniperrifle",false))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
							if ((GetEntProp(client,Prop_Send,"m_iAmmo",_,10) > 0) && (!inreload) && (amm == 0))
							{
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != 4)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
										CreateTimer(2.8,resetviewmdl,viewmdl);
										EmitSoundToAll("weapons\\sniper\\sniper_reload.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									}
								}
							}
						}
						else if (StrEqual(curweap,"weapon_molotov",false))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_bhg",false))
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
							if (AmmArr[client][0] != GetEntProp(weap,Prop_Data,"m_iClip1")) AmmArr[client][0] = GetEntProp(weap,Prop_Data,"m_iClip1");
							if (AmmArr[client][1] != GetEntProp(client,Prop_Send,"m_iAmmo",_,12)) SetEntProp(client,Prop_Data,"m_iAmmo",AmmArr[client][1],_,12);
							if (viewmdl != -1)
							{
								if (WeapAttackSpeed[client] > Time+0.8)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
								else if (WeapAttackSpeed[client] < Time)
								{
									int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int seqreload = GetWepAnim(curweap,seq,"ACT_VM_RELOAD");
									if ((inreload) || (seq == seqreload))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										SetEntProp(weap,Prop_Data,"m_bInReload",0);
									}
								}
							}
						}
						else if (strlen(scrwep) > 0)
						{
							if (FindStringInArray(sweps,curweap) != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
							}
						}
					}
				}
			}
		}
	}
}

public Action waititem(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		if (IsEntNetworkable(entity))
		{
			char cls[128];
			GetEntityClassname(entity,cls,sizeof(cls));
			if ((StrEqual(cls,"item_ammo_flare_box",false)) || (StrEqual(cls,"item_box_flare_rounds",false)) || (StrEqual(cls,"item_ammo_manhack",false)) || (StrEqual(cls,"item_ammo_energy",false)) || (StrEqual(cls,"item_ammo_goop",false)) || (StrEqual(cls,"item_ammo_bhg",false)))
			{
				SDKHook(entity, SDKHook_StartTouch, StartTouchAmmoPickup);
			}
			else if (FindStringInArray(sweps,cls) != -1)
			{
				HookSingleEntityOutput(entity,"OnCacheInteraction",SweapCacheInteraction);
			}
			if (StrContains(cls,"weapon_isa_knife",false) != -1)
			{
				char fixup[32][128];
				char fixupcls[64];
				if (StrContains(cls,"/",false) != -1)
				{
					int explarr = ExplodeString(cls,"/",fixup,32,128,true);
					for (int i = 0;i<explarr;i++)
					{
						if (strlen(fixup[i+1]) < 1)
						{
							Format(fixupcls,sizeof(fixupcls),"%s",fixup[i]);
							break;
						}
					}
				}
				else Format(fixupcls,sizeof(fixupcls),"%s",cls);
				if (strlen(fixupcls) > 0)
				{
					SetEntPropString(entity,Prop_Data,"m_iClassname",fixupcls);
				}
			}
			else if ((StrContains(cls,"custom_",false) != -1) || (StrContains(cls,"kzsmodifiedweaps/",false) == 0))
			{
				if (!customcvarsset)
				{
					char findmodify[128];
					Format(findmodify,sizeof(findmodify),"maps/cfg/%s_modify.txt",mapbuf);
					if (FileExists(findmodify,true,NULL_STRING))
					{
						bool readammdata = false;
						Handle filehandlesub = OpenFile(findmodify,"r",true,NULL_STRING);
						if (filehandlesub != INVALID_HANDLE)
						{
							char scrline[128];
							char cvarc[64];
							char plrdmg[4];
							int openbrackets = 0;
							while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
							{
								TrimString(scrline);
								if (strlen(scrline) > 0)
								{
									if (StrContains(scrline,"CustomAmmo",false) != -1)
									{
										readammdata = true;
										//openbrackets++;
									}
									else if (readammdata)
									{
										ReplaceString(scrline,sizeof(scrline),"\"","",false);
										ReplaceString(scrline,sizeof(scrline),"	"," ",false);
										if (StrContains(scrline,"{",false) != -1) openbrackets++;
										else if (StrContains(scrline,"}",false) != -1) openbrackets--;
										if ((readammdata) && (openbrackets > 0) && (!StrEqual(scrline,"{",false)) && (!StrEqual(scrline,"}",false)))
										{
											if (StrContains(scrline," ",false) == -1)
											{
												if (strlen(cvarc) > 0)
												{
													Handle cvar = FindConVar(cvarc);
													if (cvar == INVALID_HANDLE) cvar = CreateConVar(cvarc, plrdmg, "Custom weap damage.", _, true, 0.0, true, 999.0);
													CloseHandle(cvar);
												}
												Format(cvarc,sizeof(cvarc),"sk_plr_dmg_%s",scrline);
											}
											else
											{
												if (StrContains(scrline,"plrdmg",false) == 0)
												{
													char fixuptmp[32][128];
													ExplodeString(scrline," ",fixuptmp,32,128,true);
													for (int i = 0;i<3;i++)
													{
														TrimString(fixuptmp[i]);
														if ((strlen(fixuptmp[i]) > 0) && (i > 1) && (StrContains(fixuptmp[i],"//",false) == -1))
														{
															Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
														}
													}
													Format(plrdmg,sizeof(plrdmg),"%s",fixuptmp[1]);
												}
											}
										}
										if ((openbrackets < 1) && (readammdata))
										{
											readammdata = false;
											break;
										}
									}
								}
							}
						}
					}
					customcvarsset = true;
				}
				if ((StrContains(cls,"/",false) != -1) || (FindStringInArray(sweps,cls) == -1))
				{
					char fixup[32][128];
					char fixupcls[64];
					if (StrContains(cls,"/",false) != -1)
					{
						int explarr = ExplodeString(cls,"/",fixup,32,128,true);
						for (int i = 0;i<explarr;i++)
						{
							if (strlen(fixup[i+1]) < 1)
							{
								Format(fixupcls,sizeof(fixupcls),"%s",fixup[i]);
								break;
							}
						}
					}
					else Format(fixupcls,sizeof(fixupcls),"%s",cls);
					if (strlen(fixupcls) > 0)
					{
						SetEntPropString(entity,Prop_Data,"m_iszResponseContext",cls);
						SetEntPropString(entity,Prop_Data,"m_iClassname",fixupcls);
						if (FindStringInArray(sweps,fixupcls) == -1)
						{
							PushArrayString(sweps,fixupcls);
							PushArrayString(swepsweap,cls);
							Handle dp = CreateDataPack();
							char filepath[128];
							Format(filepath,sizeof(filepath),"scripts/%s.txt",cls);
							char weapmdl[128];
							if (FileExists(filepath,true,NULL_STRING))
							{
								bool readsounds = false;
								bool readweapdata = false;
								Handle filehandlesub = OpenFile(filepath,"r",true,NULL_STRING);
								if (filehandlesub != INVALID_HANDLE)
								{
									char scrline[128];
									while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
									{
										TrimString(scrline);
										if (strlen(scrline) > 0)
										{
											if ((StrContains(scrline,"SoundData",false) != -1) && (!readsounds))
											{
												readsounds = true;
											}
											if (StrContains(scrline,"clip_size",false) != -1)
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											else if (StrContains(scrline,"default_clip",false))
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												if (StringToInt(fixuptmp[1]) > 0)
												{
													if (HasEntProp(entity,Prop_Data,"m_iMaxHealth")) SetEntProp(entity,Prop_Data,"m_iMaxHealth",StringToInt(fixuptmp[1]));
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											if ((StrContains(scrline,"Advanced",false) != -1) && (!readweapdata))
											{
												readweapdata = true;
											}
											if (StrContains(scrline,"BuiltRightHanded",false) != -1)
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											if (StrContains(scrline,"primary_ammo",false) != -1)
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												if (StrEqual(fixuptmp[1],"SniperRound",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",10);
												}
												else if (StrEqual(fixuptmp[1],"SMG3",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",4);
												}
												else if (StrEqual(fixuptmp[1],"Rifle1",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",1);
												}
												else if ((!StrEqual(fixuptmp[1],"None",false)) && (!StrEqual(fixuptmp[1],"Buckshot",false)) && (!StrEqual(fixuptmp[1],"357",false)) && (!StrEqual(fixuptmp[1],"Pistol",false)) && (!StrEqual(fixuptmp[1],"XBowBolt",false)) && (!StrEqual(fixuptmp[1],"AR2",false)) && (!StrEqual(fixuptmp[1],"AR2AltFire",false)) && (!StrEqual(fixuptmp[1],"grenade",false)) && (!StrEqual(fixuptmp[1],"SMG1",false)) && (!StrEqual(fixuptmp[1],"SMG1_Grenade",false)) && (!StrEqual(fixuptmp[1],"rpg_round",false)) && (!StrEqual(fixuptmp[1],"slam",false)))
												{
													if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",12);
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											else if (StrContains(scrline,"secondary_ammo",false) != -1)
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												if (StrEqual(fixuptmp[1],"SniperRound",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iSecondaryAmmoType",10);
												}
												else if (StrEqual(fixuptmp[1],"M203_Grenade",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iSecondaryAmmoType",9);
												}
												else if ((!StrEqual(fixuptmp[1],"None",false)) && (!StrEqual(fixuptmp[1],"Buckshot",false)) && (!StrEqual(fixuptmp[1],"357",false)) && (!StrEqual(fixuptmp[1],"Pistol",false)) && (!StrEqual(fixuptmp[1],"XBowBolt",false)) && (!StrEqual(fixuptmp[1],"AR2",false)) && (!StrEqual(fixuptmp[1],"AR2AltFire",false)) && (!StrEqual(fixuptmp[1],"grenade",false)) && (!StrEqual(fixuptmp[1],"SMG1",false)) && (!StrEqual(fixuptmp[1],"SMG1_Grenade",false)) && (!StrEqual(fixuptmp[1],"rpg_round",false)) && (!StrEqual(fixuptmp[1],"slam",false)))
												{
													if (HasEntProp(entity,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iSecondaryAmmoType",24);
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											else if ((StrContains(scrline,"viewmodel",false) != -1) && (StrContains(scrline,"csviewmodel",false) == -1))
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												Format(weapmdl,sizeof(weapmdl),"%s",fixuptmp[1]);
											}
											else if ((StrContains(scrline,"playermodel",false) != -1) || (StrContains(scrline,"damage",false) != -1))
											{
												char tmp[64];
												Format(tmp,sizeof(tmp),"%s",scrline);
												ReplaceString(tmp,sizeof(tmp),"\"","");
												ReplaceString(tmp,sizeof(tmp),"	"," ");
												TrimString(tmp);
												char fixuptmp[32][128];
												ExplodeString(tmp," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												Format(tmp,sizeof(tmp),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,tmp);
											}
											if (StrContains(scrline,"}",false) != -1)
											{
												if (readsounds) readsounds = false;
												if (readweapdata) readweapdata = false;
											}
											else if ((readsounds) && (StrContains(scrline,"//",false) != 0) && (StrContains(scrline,"\"SoundData\"",false) == -1) && (!StrEqual(scrline,"{",false)))
											{
												char snd[64];
												Format(snd,sizeof(snd),"%s",scrline);
												ReplaceString(snd,sizeof(snd),"\"","");
												ReplaceString(snd,sizeof(snd),"	"," ");
												TrimString(snd);
												ReplaceStringEx(snd,sizeof(snd)," ","\"repl\"");
												ReplaceString(snd,sizeof(snd)," ","");
												ReplaceStringEx(snd,sizeof(snd),"\"repl\""," ");
												char fixuptmp[32][128];
												ExplodeString(snd," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												Format(snd,sizeof(snd),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,snd);
											}
											else if ((readweapdata) && (StrContains(scrline,"//",false) != 0) && (StrContains(scrline,"Advanced",false) == -1) && (!StrEqual(scrline,"{",false)))
											{
												char weapdata[64];
												Format(weapdata,sizeof(weapdata),"%s",scrline);
												ReplaceString(weapdata,sizeof(weapdata),"\"","");
												ReplaceString(weapdata,sizeof(weapdata),"	"," ");
												TrimString(weapdata);
												char fixuptmp[32][128];
												ExplodeString(weapdata," ",fixuptmp,32,128,true);
												for (int i = 0;i<5;i++)
												{
													TrimString(fixuptmp[i]);
													if ((strlen(fixuptmp[i]) > 0) && (i > 1))
													{
														Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
													}
												}
												if (StrEqual(fixuptmp[0],"FireUnderWater1",false))
												{
													if (HasEntProp(entity,Prop_Data,"m_bFiresUnderwater")) SetEntProp(entity,Prop_Data,"m_bFiresUnderwater",StringToInt(fixuptmp[1]));
												}
												Format(weapdata,sizeof(weapdata),"%s %s",fixuptmp[0],fixuptmp[1]);
												WritePackString(dp,weapdata);
											}
										}
									}
								}
								CloseHandle(filehandlesub);
							}
							if (FileExists(weapmdl,true,NULL_STRING))
							{
								Handle actmap = CreateArray(64);
								Handle filehandlemdl = OpenFile(weapmdl,"rb",true,NULL_STRING);
								if (filehandlemdl != INVALID_HANDLE)
								{
									char tmp[500];
									char push[80];
									while(!IsEndOfFile(filehandlemdl)&&ReadFileLine(filehandlemdl,tmp,sizeof(tmp)))
									{
										TrimString(tmp);
										if (StrContains(tmp,"ACT",false) != -1)
										{
											Format(push,sizeof(push),"%s %s",push,tmp);
											//PrintToServer("ActMap %s %s",fixupcls,push);
											PushArrayString(actmap,push);
											push = "";
										}
										else if (strlen(tmp) > 0)
										{
											Format(push,sizeof(push),"%s",tmp);
										}
									}
								}
								CloseHandle(filehandlemdl);
								if (GetArraySize(actmap) > 0)
								{
									GetSequencesFromAnim(dp,actmap,weapmdl,true);
								}
								CloseHandle(actmap);
							}
						}
					}
				}
				else if (FindStringInArray(sweps,cls) == -1) PushArrayString(sweps,cls);
				if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity"))
				{
					int client = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
					if ((IsValidEntity(client)) && (client != 0) && (strlen(cls) > 0))
					{
						if (iWeapList == -1) iWeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
						if (iWeapList != -1)
						{
							char szWeapCls[64];
							for (int j; j<104; j += 4)
							{
								int tmpi = GetEntDataEnt2(client,iWeapList + j);
								if (tmpi != -1)
								{
									GetEntityClassname(tmpi,szWeapCls,sizeof(szWeapCls));
									if ((StrEqual(szWeapCls,cls,false)) && (tmpi != entity))
									{
										//Duplicated pickup
										int ammtype = 0;
										if (HasEntProp(entity,Prop_Send,"m_iPrimaryAmmoType")) ammtype = GetEntProp(entity,Prop_Send,"m_iPrimaryAmmoType");
										else if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) ammtype = GetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType");
										if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
										{
											int actweap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
											if (tmpi == actweap) AcceptEntityInput(entity,"kill");
											else AcceptEntityInput(tmpi,"kill");
										}
										else
										{
											AcceptEntityInput(entity,"kill");
										}
										if (ammtype != 0)
										{
											int curamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,ammtype);
											SetEntProp(client,Prop_Data,"m_iAmmo",curamm+20,_,ammtype);
										}
										break;
									}
								}
							}
						}
					}
				}
			}
			else if ((StrContains(cls,"weapon_",false) == 0) && (FindStringInArray(hBaseWeapons,cls) != -1))
			{
				int ammtype = 0;
				if (HasEntProp(entity,Prop_Send,"m_iPrimaryAmmoType")) ammtype = GetEntProp(entity,Prop_Send,"m_iPrimaryAmmoType");
				else if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) ammtype = GetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType");
				if (ammtype <= 1)
				{
					if (StrEqual(cls,"weapon_ar2",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",1);
						
					}
					else if (StrEqual(cls,"weapon_alyxgun",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",2);
					}
					else if (StrEqual(cls,"weapon_pistol",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",3);
					}
					else if (StrEqual(cls,"weapon_smg1",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",4);
					}
					else if ((StrEqual(cls,"weapon_357",false)) || (StrEqual(cls,"weapon_annabelle",false)))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",5);
					}
					else if (StrEqual(cls,"weapon_crossbow",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",6);
					}
					else if (StrEqual(cls,"weapon_shotgun",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",7);
					}
					else if (StrEqual(cls,"weapon_rpg",false))
					{
						if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",8);
					}
				}
			}
			/*
			else if (StrContains(cls,"kzsmodifiedweaps/",false) == 0)
			{
				char fixupcls[64];
				Format(fixupcls,sizeof(fixupcls),"%s",cls);
				ReplaceStringEx(fixupcls,sizeof(fixupcls),"kzsmodifiedweaps/","");
				SetEntPropString(entity,Prop_Data,"m_iClassname",fixupcls);
				if ((StrEqual(fixupcls,"weapon_smg3",false)) || (StrEqual(fixupcls,"weapon_smg4",false)))
				{
					if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",4);
				}
				else if (StrEqual(fixupcls,"weapon_lugergun",false))
				{
					if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",7);
				}
			}
			*/
			if ((StrEqual(cls,"weapon_satchel",false)) || (StrEqual(cls,"weapon_tripmine",false)) || (StrEqual(cls,"weapon_molotov",false)))
			{
				SDKHook(entity, SDKHook_StartTouch, StartTouchAmmoPickup);
			}
		}
	}
}

int GetWepAnim(char[] szWeapCls, int seq, char[] ACTVM)
{
	if (strlen(szWeapCls) > 0)
	{
		if (FindStringInArray(hBaseWeapons,szWeapCls) != -1) return 0;
		int arrindx = FindStringInArray(weapanimcls,szWeapCls);
		if (arrindx == -1)
		{
			Handle dp = CreateDataPack();
			char filepath[128];
			Format(filepath,sizeof(filepath),"scripts/%s.txt",szWeapCls);
			char weapmdl[128];
			if (FileExists(filepath,true,NULL_STRING))
			{
				Handle filehandlesub = OpenFile(filepath,"r",true,NULL_STRING);
				if (filehandlesub != INVALID_HANDLE)
				{
					char scrline[128];
					while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
					{
						TrimString(scrline);
						if (strlen(scrline) > 0)
						{
							if ((StrContains(scrline,"viewmodel",false) != -1) && (StrContains(scrline,"csviewmodel",false) == -1))
							{
								char tmp[64];
								Format(tmp,sizeof(tmp),"%s",scrline);
								ReplaceString(tmp,sizeof(tmp),"\"","");
								ReplaceString(tmp,sizeof(tmp),"	"," ");
								TrimString(tmp);
								char fixuptmp[32][128];
								ExplodeString(tmp," ",fixuptmp,32,128,true);
								for (int i = 0;i<5;i++)
								{
									TrimString(fixuptmp[i]);
									if ((strlen(fixuptmp[i]) > 0) && (i > 1))
									{
										Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
									}
								}
								Format(weapmdl,sizeof(weapmdl),"%s",fixuptmp[1]);
								break;
							}
						}
					}
					CloseHandle(filehandlesub);
					if (strlen(weapmdl) > 0)
					{
						if (FileExists(weapmdl,true,NULL_STRING))
						{
							Handle actmap = CreateArray(64);
							Handle filehandlemdl = OpenFile(weapmdl,"rb",true,NULL_STRING);
							if (filehandlemdl != INVALID_HANDLE)
							{
								char tmp[500];
								char push[80];
								while(!IsEndOfFile(filehandlemdl)&&ReadFileLine(filehandlemdl,tmp,sizeof(tmp)))
								{
									TrimString(tmp);
									if (StrContains(tmp,"ACT",false) != -1)
									{
										Format(push,sizeof(push),"%s %s",push,tmp);
										if (dbgmdlsetup) PrintToServer("ActMap %s %s",szWeapCls,push);
										PushArrayString(actmap,push);
										push = "";
									}
									else if (strlen(tmp) > 0)
									{
										Format(push,sizeof(push),"%s",tmp);
									}
								}
							}
							CloseHandle(filehandlemdl);
							if (GetArraySize(actmap) > 0)
							{
								GetSequencesFromAnim(dp,actmap,weapmdl,false);
							}
							CloseHandle(actmap);
						}
					}
					PushArrayString(weapanimcls,szWeapCls);
					/*
					if (dp != INVALID_HANDLE)
					{
						char weapdata[80];
						int atkanim[10];
						ResetPack(dp);
						ReadPackString(dp,weapdata,sizeof(weapdata));
						while (!StrEqual(weapdata,"endofpack",false))
						{
							if (StrContains(weapdata,ACTVM,false) >= 2)
							{
								char tmp[4][64];
								ExplodeString(weapdata," ",tmp,4,64);
								int prev;
								for (int i = 0;i<10;i++)
								{
									if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
									{
										atkanim[i] = StringToInt(tmp[0]);
										prev = atkanim[i];
									}
								}
							}
							ReadPackString(dp,weapdata,sizeof(weapdata));
						}
						int randanim;
						for (int i = 0;i<10;i++)
						{
							if (atkanim[i] != 0) randanim = atkanim[i];
							else break;
						}
						int rand = GetRandomInt(atkanim[0],randanim);
						if (seq == rand)
						{
							if ((rand > atkanim[0]) && (rand-1 >= atkanim[0])) rand--;
							else if (rand < randanim) rand++;
						}
						return rand;
					}
					*/
				}
			}
			else
			{
				// Script was not found, add to ignore list
				CloseHandle(dp);
				if (FindStringInArray(hBaseWeapons,szWeapCls) == -1)
				{
					PushArrayString(hBaseWeapons,szWeapCls);
				}
			}
		}
		else if (arrindx < GetArraySize(weapaniminf))
		{
			Handle dp = GetArrayCell(weapaniminf,arrindx);
			if (dp != INVALID_HANDLE)
			{
				char weapdata[80];
				int atkanim[10];
				ResetPack(dp);
				ReadPackString(dp,weapdata,sizeof(weapdata));
				while (!StrEqual(weapdata,"endofpack",false))
				{
					if (StrContains(weapdata,ACTVM,false) >= 2)
					{
						char tmp[4][64];
						ExplodeString(weapdata," ",tmp,4,64);
						int prev;
						for (int i = 0;i<10;i++)
						{
							if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
							{
								atkanim[i] = StringToInt(tmp[0]);
								prev = atkanim[i];
							}
						}
						if (StrEqual(tmp[1],ACTVM,false)) break;
					}
					ReadPackString(dp,weapdata,sizeof(weapdata));
				}
				int randanim;
				for (int i = 0;i<10;i++)
				{
					if (atkanim[i] != 0) randanim = atkanim[i];
					else break;
				}
				int rand = GetRandomInt(atkanim[0],randanim);
				if (seq == rand)
				{
					if ((rand > atkanim[0]) && (rand-1 >= atkanim[0])) rand--;
					else if (rand < randanim) rand++;
				}
				return rand;
			}
		}
	}
	return 0;
}

void GetSequencesFromAnim(Handle dp, Handle actmap, char[] mdl, bool custweap)
{
	if ((dp != INVALID_HANDLE) && (actmap != INVALID_HANDLE))
	{
		int propset = CreateEntityByName("prop_dynamic");
		if (propset != -1)
		{
			DispatchKeyValue(propset,"model",mdl);
			DispatchSpawn(propset);
			ActivateEntity(propset);
			int prevseq = 0;
			char prevanim[64];
			for (int i = 0;i<GetArraySize(actmap);i++)
			{
				char split[4][64];
				char acts[80];
				GetArrayString(actmap,i,acts,sizeof(acts));
				ExplodeString(acts," ",split,4,64,true);
				SetVariantString(split[0]);
				AcceptEntityInput(propset,"SetAnimation");
				int seq = GetEntProp(propset,Prop_Data,"m_nSequence");
				if ((seq > prevseq) && (i > 0))
				{
					for (int j = prevseq+1;j<seq;j++)
					{
						Format(acts,sizeof(acts),"%i %s",j,prevanim);
						WritePackString(dp,acts);
						if (dbgmdlsetup) PrintToServer("PushVMActsub %s",acts);
					}
				}
				Format(acts,sizeof(acts),"%i %s",seq,split[1]);
				prevseq = seq;
				Format(prevanim,sizeof(prevanim),"%s",split[1]);
				WritePackString(dp,acts);
				if (dbgmdlsetup) PrintToServer("PushVMAct %s",acts);
			}
			AcceptEntityInput(propset,"kill");
		}
		WritePackString(dp,"endofpack");
		if (custweap) PushArrayCell(swepsinfo,dp);
		else PushArrayCell(weapaniminf,dp);
	}
}

public Action SweapCacheInteraction(const char[] output, int caller, int activator, float delay)
{
	if ((HasEntProp(caller,Prop_Data,"m_iRespawnCount")) && (activator > 0) && (activator < MaxClients+1))
	{
		char cls[32];
		GetEntityClassname(caller,cls,sizeof(cls));
		if (!HasWeapon(activator,cls))
		{
			int respawns = GetEntProp(caller,Prop_Data,"m_iRespawnCount");
			if (respawns != 0)
			{
				char basecls[32];
				float orgs[3];
				float angs[3];
				if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",orgs);
				if (StrEqual(cls,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
				else if ((StrEqual(cls,"weapon_glock",false)) || (StrEqual(cls,"weapon_colt",false)) || (StrEqual(cls,"weapon_pistol_worker",false)) || (StrEqual(cls,"weapon_flaregun",false)) || (StrEqual(cls,"weapon_manhack",false)) || (StrEqual(cls,"weapon_manhackgun",false)) || (StrEqual(cls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
				else if ((StrEqual(cls,"weapon_medkit",false)) || (StrEqual(cls,"weapon_healer",false)) || (StrEqual(cls,"weapon_snark",false)) || (StrEqual(cls,"weapon_hivehand",false)) || (StrEqual(cls,"weapon_hornetgun",false)) || (StrEqual(cls,"weapon_satchel",false)) || (StrEqual(cls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
				else if ((StrEqual(cls,"weapon_mp5",false)) || (StrEqual(cls,"weapon_m4",false)) || (StrEqual(cls,"weapon_sl8",false)) || (StrEqual(cls,"weapon_g36c",false)) || (StrEqual(cls,"weapon_oicw",false)) || (StrEqual(cls,"weapon_uzi",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
				else if ((StrEqual(cls,"weapon_gauss",false)) || (StrEqual(cls,"weapon_tau",false)) || (StrEqual(cls,"weapon_goop",false)) || (StrEqual(cls,"weapon_sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
				else if (StrEqual(cls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
				else if (StrEqual(cls,"weapon_dualmp5k",false)) Format(basecls,sizeof(basecls),"weapon_mp5k");
				else if (StrEqual(cls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
				int respawnweap = CreateEntityByName(basecls);
				if (respawnweap != -1)
				{
					char respawnch[4];
					if (respawns != -1) Format(respawnch,sizeof(respawnch),"%i",respawns--);
					else Format(respawnch,sizeof(respawnch),"-1");
					DispatchKeyValue(respawnweap,"classname",cls);
					DispatchKeyValue(respawnweap,"RespawnCount",respawnch);
					TeleportEntity(respawnweap,orgs,angs,NULL_VECTOR);
					DispatchSpawn(respawnweap);
					ActivateEntity(respawnweap);
				}
			}
			if (StrEqual(cls,"weapon_bhg",false))
			{
				if (HasEntProp(caller,Prop_Data,"m_iClip1"))
				{
					AmmArr[activator][1] = GetEntProp(caller,Prop_Data,"m_iClip1");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action StartTouchAmmoPickup(int entity, int other)
{
	if ((IsValidEntity(entity)) && (IsValidEntity(other)) && (other != 0) && (entity != 0))
	{
		if ((other > 0) && (other < MaxClients+1))
		{
			char cls[32];
			GetEntityClassname(entity,cls,sizeof(cls));
			if ((StrEqual(cls,"item_ammo_flare_box",false)) || (StrEqual(cls,"item_box_flare_rounds",false)))
			{
				Handle cvar = FindConVar("sk_max_flaregun");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (flareammo[other] < maxamm)
				{
					if (flareammo[other]+5 < maxamm)
					{
						flareammo[other]+=5;
					}
					else
					{
						flareammo[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_pistol");
					EndMessage();
					AcceptEntityInput(entity,"kill");
				}
			}
			else if (StrEqual(cls,"item_ammo_manhack",false))
			{
				Handle cvar = FindConVar("sk_max_manhackgun");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (ManHackAmmo[other] < maxamm)
				{
					if (ManHackAmmo[other]+2 < maxamm)
					{
						ManHackAmmo[other]+=2;
					}
					else
					{
						ManHackAmmo[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_pistol");
					EndMessage();
					AcceptEntityInput(entity,"kill");
				}
			}
			else if ((StrEqual(cls,"item_ammo_energy",false)) || (StrEqual(cls,"item_ammo_goop",false)))
			{
				Handle cvar = FindConVar("sk_max_energy");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (EnergyAmm[other] < maxamm)
				{
					if (EnergyAmm[other]+20 < maxamm)
					{
						EnergyAmm[other]+=20;
					}
					else
					{
						EnergyAmm[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_energy");
					EndMessage();
					int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						char szWeapCls[24];
						GetEntityClassname(weap,szWeapCls,sizeof(szWeapCls));
						if ((StrEqual(szWeapCls,"weapon_gluon",false)) || (StrEqual(szWeapCls,"weapon_tau",false)) || (StrEqual(szWeapCls,"weapon_goop",false)))
						{
							if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[other]);
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[other]);
						}
					}
					AcceptEntityInput(entity,"kill");
				}
			}
			else if (StrEqual(cls,"weapon_satchel",false))
			{
				if (HasWeapon(other,cls))
				{
					int maxamm = 10;
					Handle cvar = FindConVar("sk_max_satchel");
					if (cvar != INVALID_HANDLE) maxamm = GetConVarInt(cvar);
					CloseHandle(cvar);
					if (SatchelAmm[other] < maxamm)
					{
						SatchelAmm[other]++;
						EmitGameSoundToAll("HL2Player.PickupWeapon",other);
						int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char szWeapCls[24];
							GetEntityClassname(weap,szWeapCls,sizeof(szWeapCls));
							if (StrEqual(szWeapCls,"weapon_satchel",false))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",SatchelAmm[other]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SatchelAmm[other]);
							}
						}
						AcceptEntityInput(entity,"kill");
					}
				}
			}
			else if (StrEqual(cls,"weapon_tripmine",false))
			{
				if (HasWeapon(other,cls))
				{
					int maxamm = 10;
					Handle cvar = FindConVar("sk_max_tripmine");
					if (cvar != INVALID_HANDLE) maxamm = GetConVarInt(cvar);
					CloseHandle(cvar);
					if (TripMineAmm[other] < maxamm)
					{
						TripMineAmm[other]++;
						EmitGameSoundToAll("HL2Player.PickupWeapon",other);
						int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char szWeapCls[24];
							GetEntityClassname(weap,szWeapCls,sizeof(szWeapCls));
							if (StrEqual(szWeapCls,"weapon_tripmine",false))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",TripMineAmm[other]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",TripMineAmm[other]);
							}
						}
						AcceptEntityInput(entity,"kill");
					}
				}
			}
			else if (StrEqual(cls,"weapon_molotov",false))
			{
				int weap = HasWeapon(other,cls);
				if (weap)
				{
					if (HasEntProp(weap,Prop_Data,"m_iClip1"))
					{
						int iCurAmm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if (iCurAmm < hMaxMolotov.IntValue)
						{
							SetEntProp(weap,Prop_Data,"m_iClip1",iCurAmm+1);
							AcceptEntityInput(entity,"kill");
						}
					}
				}
			}
			else if (StrEqual(cls,"item_ammo_bhg",false))
			{
				if (AmmArr[other][1] < 10)
				{
					AmmArr[other][1]+=3;
					AcceptEntityInput(entity,"kill");
				}
			}
		}
	}
}

public Action StartTouchFlare(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(activator))
	{
		char clsname[64];
		GetEntityClassname(activator,clsname,sizeof(clsname));
		if (!CheckNPCAlly(clsname,activator))
		{
			int client = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if (client == -1) client = caller;
			char flareduration[8];
			Format(flareduration,sizeof(flareduration),"10");
			Handle cvar = FindConVar("sk_flaregun_ignighttime");
			if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
			CloseHandle(cvar);
			SetVariantString(flareduration);
			AcceptEntityInput(activator,"Ignite",client);
			float dmgset = 10.0;
			float damageForce[3];
			float curorg[3];
			GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",curorg);
			SDKHooks_TakeDamage(activator,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
		}
		else if (StrEqual(clsname,"prop_physics",false))
		{
			char mdl[64];
			GetEntPropString(activator,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrContains(mdl,"wood_",false) != -1)
			{
				int client = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
				if (client == -1) client = caller;
				char flareduration[8];
				Format(flareduration,sizeof(flareduration),"10");
				Handle cvar = FindConVar("sk_flaregun_ignighttime");
				if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
				CloseHandle(cvar);
				SetVariantString(flareduration);
				AcceptEntityInput(activator,"Ignite",client);
				float dmgset = 10.0;
				float damageForce[3];
				float curorg[3];
				GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",curorg);
				SDKHooks_TakeDamage(activator,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
			}
		}
	}
}

public Action StartTouchFlaretch(int entity, int other)
{
	if ((IsValidEntity(entity)) && (IsValidEntity(other)) && (other != 0) && (entity != 0))
	{
		char clsname[64];
		GetEntityClassname(other,clsname,sizeof(clsname));
		if (!CheckNPCAlly(clsname,other))
		{
			int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			if (client == -1) client = entity;
			char flareduration[8];
			Format(flareduration,sizeof(flareduration),"10");
			Handle cvar = FindConVar("sk_flaregun_ignighttime");
			if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
			CloseHandle(cvar);
			SetVariantString(flareduration);
			AcceptEntityInput(other,"Ignite",client);
			float dmgset = 10.0;
			float damageForce[3];
			float curorg[3];
			GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
			SDKHooks_TakeDamage(other,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
		}
		else if (StrEqual(clsname,"prop_physics",false))
		{
			char mdl[64];
			GetEntPropString(other,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrContains(mdl,"wood_",false) != -1)
			{
				int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				if (client == -1) client = entity;
				char flareduration[8];
				Format(flareduration,sizeof(flareduration),"10");
				Handle cvar = FindConVar("sk_flaregun_ignighttime");
				if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
				CloseHandle(cvar);
				SetVariantString(flareduration);
				AcceptEntityInput(other,"Ignite",client);
				float dmgset = 10.0;
				float damageForce[3];
				float curorg[3];
				GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				SDKHooks_TakeDamage(other,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
			}
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
	MedkitAmm[client] = 0.0;
	Healchk[client] = 0.0;
	CLManhack[client] = 0;
	clsummontarg[client] = 0;
	EndTarg[client] = 0;
	HandAttach[client] = 0;
	TauCharge[client] = 0;
	CLInScope[client] = 0;
	CLAttachment[client] = 0;
	Reviving[client] = -1;
	ReviveTime[client] = 0.0;
	clsummoncdc[client] = 0.0;
	WeapSnd[client] = 0.0;
	WeapAttackSpeed[client] = 0.0;
	SteamID[client] = "";
	for (int i = 0;i<32;i++)
	{
		if (i == 0) AmmArr[client][i] = 3;
		else AmmArr[client][i] = 0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ((buttons & IN_ZOOM) || (IsFakeClient(client))) return Plugin_Continue;
	bool setbuttons = true;
	static char curweap[24];
	static char custweap[64];
	//GetClientWeapon(client,curweap,sizeof(curweap));
	int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
	if (IsValidEntity(weap))
	{
		GetEntPropString(weap,Prop_Data,"m_iszResponseContext",custweap,sizeof(custweap));
		GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
	}
	if (strlen(curweap) < 1) return Plugin_Continue;
	if (FindStringInArray(hBaseWeapons,curweap) != -1) return Plugin_Continue;
	int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
	int useent = GetEntPropEnt(client,Prop_Data,"m_hUseEntity");
	if ((vehicle == -1) && (useent == -1))
	{
		if (loweredsprint)
		{
			if (buttons & IN_SPEED)
			{
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
				{
					int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
					int seqlowered = GetWepAnim(curweap,seq,"ACT_VM_LOWERED");
					if (StrEqual(curweap,"weapon_uzi",false))
					{
						if (CLAttachment[client]) seqlowered = GetWepAnim(curweap,seq,"Uzi_IdleDual");
					}
					else if ((StrEqual(curweap,"weapon_tau",false)) && ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)))
					{
						seqlowered = 9;
					}
					if (seq != seqlowered)
					{
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqlowered);
						InIronSights[client] = false;
						if (weap != -1) flWeapReloadTime[weap] = 0.0;
					}
					return Plugin_Continue;
				}
			}
		}
		if (buttons & IN_ATTACK)
		{
			if (!(g_LastButtons[client] & IN_ATTACK))
			{
				if ((StrContains(curweap,"custom_",false) == 0) || (StrContains(custweap,"kzsmodifiedweaps/",false) == 0))
				{
					if (IsValidEntity(weap))
					{
						if (centnextatk[weap] < GetGameTime())
						{
							FireCustomWeap(client,weap,custweap,1);
						}
					}
					setbuttons = false;
				}
				else if (StrEqual(curweap,"weapon_crossbow",false))
				{
					if (IsValidEntity(weap))
					{
						if (HasEntProp(weap,Prop_Data,"m_iClip1"))
						{
							int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
							float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
							if ((curclip > 0) && (centnextatk[client] < nextatk))
							{
								if (HasEntProp(weap,Prop_Data,"m_bReloadsSingly")) SetEntProp(weap,Prop_Data,"m_bReloadsSingly",0);
								if (HasEntProp(weap,Prop_Send,"m_bMustReload"))
								{
									int mustrel = GetEntProp(weap,Prop_Send,"m_bMustReload");
									SetEntProp(weap,Prop_Send,"m_bMustReload",0);
									if (mustrel)
									{
										SetEntProp(weap,Prop_Data,"m_bInReload",0);
										char shootsnd[64];
										int chan,sndlvl,pitch;
										float vol;
										GetGameSoundParams("Weapon_Crossbow.Single",chan,sndlvl,vol,pitch,shootsnd,sizeof(shootsnd),0);
										if (strlen(shootsnd) > 0)
										{
											EmitGameSoundToAll("Weapon_Crossbow.Single",client);
										}
									}
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										int relseq = GetWepAnim(curweap,seq,"ACT_VM_RELOAD");
										if (relseq == seq)
										{
											relseq = GetWepAnim(curweap,seq,"ACT_CROSSBOW_BOLT_BACK");
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",relseq);
											centnextatk[client] = nextatk+0.05;
										}
									}
								}
								setbuttons = false;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_immolator",false))
				{
					if (IsValidEntity(weap))
					{
						if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
						{
							float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
							if (centnextatk[client] < nextatk)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",nextatk-0.1);
								centnextatk[client] = nextatk+0.05;
								//create fireball sprite moving from cl with cone
								//check collision dist from sprite, remove when out of world or timer
							}
							setbuttons = false;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_flaregun",false))
				{
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if ((GetEntProp(weap,Prop_Data,"m_iClip1") > 0) && (WeapAttackSpeed[client] < Time))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 1;
								char mdl[64];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
									mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",GetEntProp(weap,Prop_Data,"m_iClip1")-1);
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(0.6,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
									int flare = CreateEntityByName("env_flare");
									if (flare != -1)
									{
										float plyfirepos[3];
										float plyang[3];
										GetClientEyeAngles(client,plyang);
										GetClientEyePosition(client,plyfirepos);
										char flareduration[8];
										Format(flareduration,sizeof(flareduration),"10");
										Handle cvar = FindConVar("sk_flaregun_ignighttime");
										if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
										CloseHandle(cvar);
										DispatchKeyValue(flare,"duration",flareduration);
										TeleportEntity(flare,plyfirepos,plyang,NULL_VECTOR);
										DispatchSpawn(flare);
										ActivateEntity(flare);
										SetVariantString("900 0 10");
										AcceptEntityInput(flare,"Launch");
										int flarebox = CreateEntityByName("trigger_multiple");
										if (flarebox != -1)
										{
											DispatchKeyValue(flarebox,"spawnflags","66");
											DispatchKeyValue(flarebox,"wait","1");
											if (!IsModelPrecached("*1")) PrecacheModel("*1",true);
											DispatchKeyValue(flarebox,"model","*1");
											TeleportEntity(flarebox,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(flarebox);
											ActivateEntity(flarebox);
											SetVariantString("!activator");
											AcceptEntityInput(flarebox,"SetParent",flare);
											HookSingleEntityOutput(flarebox,"OnTrigger",StartTouchFlare);
											SDKHook(flarebox, SDKHook_StartTouch, StartTouchFlaretch);
											SDKHook(flare, SDKHook_StartTouch, StartTouchFlaretch);
											float small[3];
											small[0] = -30.0;
											small[1] = -30.0;
											small[2] = -30.0;
											SetEntPropVector(flarebox,Prop_Data,"m_vecMins",small);
											small[0] = 30.0;
											small[1] = 30.0;
											small[2] = 30.0;
											SetEntPropVector(flarebox,Prop_Data,"m_vecMaxs",small);
											SetEntPropEnt(flarebox,Prop_Data,"m_hEffectEntity",client);
											SetEntPropEnt(flare,Prop_Data,"m_hEffectEntity",client);
										}
									}
									if (FileExists("sound/weapons/flaregun/fire.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\flaregun\\fire.wav", weap, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								}
							}
							WeapAttackSpeed[client] = Time+1.0;
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_medkit",false)) || (StrEqual(curweap,"weapon_healer",false)))
				{
					if (weap != -1)
					{
						int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
						if (medkitammo > 0)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 3;
								if (seq != mdlseq)
								{
									int targ = GetClientAimTarget(client, false);
									if ((targ > 0) && (targ < MaxClients+1))
									{
										char clsname[24];
										GetEntityClassname(targ,clsname,sizeof(clsname));
										float orgs[3];
										float targorgs[3];
										GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", orgs);
										GetEntPropVector(targ, Prop_Data, "m_vecAbsOrigin", targorgs);
										float chkdist = GetVectorDistance(orgs, targorgs, false);
										if ((StrEqual(clsname, "player")) && (RoundFloat(chkdist) < 91))
										{
											int a,b;
											if (HasEntProp(client,Prop_Data,"m_iTeamNum")) a = GetEntProp(client,Prop_Data,"m_iTeamNum");
											if (HasEntProp(targ,Prop_Data,"m_iTeamNum")) b = GetEntProp(targ,Prop_Data,"m_iTeamNum");
											if (a == b)
											{
												int targh = GetClientHealth(targ);
												int targmh = 100;
												if (HasEntProp(targ,Prop_Send,"m_iMaxHealth")) targmh = GetEntProp(targ,Prop_Send,"m_iMaxHealth");
												if (targh < targmh)
												{
													float Time = GetTickedTime();
													if (Time >= Healchk[client])
													{
														if (medkitammo-10 < 0) SetEntProp(client, Prop_Data, "m_iHealthPack", 0);
														else SetEntProp(client, Prop_Data, "m_iHealthPack", medkitammo-10);
														if (targh+10 > targmh) SetEntProp(targ, Prop_Data, "m_iHealth", targmh);
														else SetEntProp(targ, Prop_Data, "m_iHealth", targh+10);
														Healchk[client] = Time+0.6;
														EmitSoundToAll("items/medshot4.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
													}
												}
											}
										}
									}
									else if (IsValidEntity(targ))
									{
										char clsname[24];
										GetEntityClassname(targ,clsname,sizeof(clsname));
										if ((StrContains(clsname,"npc_",false) == 0) || (StrContains(clsname,"monster_",false) == 0))
										if (CheckNPCAlly(clsname,targ))
										{
											int targh = GetEntProp(targ,Prop_Data,"m_iHealth");
											int targmh = 100;
											if (HasEntProp(targ,Prop_Data,"m_iMaxHealth")) targmh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
											if (targh < targmh)
											{
												float Time = GetTickedTime();
												if (Time >= Healchk[client])
												{
													if (medkitammo-10 < 0) SetEntProp(client, Prop_Data, "m_iHealthPack", 0);
													else SetEntProp(client, Prop_Data, "m_iHealthPack", medkitammo-10);
													if (targh+10 > targmh) SetEntProp(targ, Prop_Data, "m_iHealth", targmh);
													else SetEntProp(targ, Prop_Data, "m_iHealth", targh+10);
													Healchk[client] = Time+0.6;
													EmitSoundToAll("items/medshot4.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
												}
											}
										}
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(0.6,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_manhacktoss",false)) || (StrEqual(curweap,"weapon_manhackgun",false)) || (StrEqual(curweap,"weapon_manhack",false)))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((seq >= 3) && (seq <= 6))
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
								ChangeEdictState(viewmdl);
								CreateTimer(0.75,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								ManHackGo(client);
							}
							else if (ManHackAmmo[client] > 0)
							{
								int mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(2.0,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_cguard"))
				{
					float Time = GetTickedTime();
					if ((antispamchk[client] <= Time) && (CGuardAmm[client] > 0))
					{
						cstr(client);
						antispamchk[client] = Time + 1.5;
						CGuardAmm[client]--;
					}
				}
				else if ((StrEqual(curweap,"weapon_gluon",false)) || (StrEqual(curweap,"weapon_goop",false)))
				{
					setbuttons = false;
					g_LastButtons[client] = 0;
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int seqprime = GetWepAnim(curweap,seq,"ACT_VM_PRIMARYATTACK");
							if ((EnergyAmm[client] < 1) && (seq == seqprime))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								float orgs[3];
								if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
								else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqprime);
								char snd[64];
								if (StrEqual(curweap,"weapon_goop",false))
								{
									Format(snd,sizeof(snd),"physics/goop/goop_loop.wav");
									StopSound(weap,SNDCHAN_WEAPON,snd);
									if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
									EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								}
								else
								{
									Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
									StopSound(weap,SNDCHAN_WEAPON,snd);
									if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
									Format(snd,sizeof(snd),"weapons\\gluon\\special2.wav");
									EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								}
								CreateTimer(0.2,resetviewmdl,viewmdl);
								WeapSnd[client] = 0.0;
								if ((EndTarg[client] != 0) && (IsValidEntity(EndTarg[client])))
								{
									if (StrEqual(curweap,"weapon_gluon",false))
									{
										int effect = CreateEntityByName("info_particle_system");
										if (effect != -1)
										{
											float endorg[3];
											if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
											else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
											float angs[3];
											if (HasEntProp(EndTarg[client],Prop_Data,"m_angAbsRotation")) GetEntPropVector(EndTarg[client],Prop_Data,"m_angAbsRotation",angs);
											DispatchKeyValue(effect,"effect_name","gluon_beam_burst");
											DispatchKeyValue(effect,"start_active","1");
											TeleportEntity(effect,endorg,angs,NULL_VECTOR);
											DispatchSpawn(effect);
											ActivateEntity(effect);
											AcceptEntityInput(effect,"Start");
											int entindx = EntIndexToEntRef(effect);
											CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
											int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
											if ((beam != 0) && (IsValidEntity(beam)))
											{
												int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
												if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
												AcceptEntityInput(beam,"kill");
											}
											if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
											{
												int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
												if ((sprite != 0) && (IsValidEntity(sprite)))
												{
													SetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity",-1);
													AcceptEntityInput(sprite,"kill");
												}
											}
											AcceptEntityInput(EndTarg[client],"kill");
										}
									}
									else if (StrEqual(curweap,"weapon_goop",false))
									{
										int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
										if ((beam != 0) && (IsValidEntity(beam)))
										{
											int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
											if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
											AcceptEntityInput(beam,"kill");
										}
										if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
										{
											int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
											if ((sprite != 0) && (IsValidEntity(sprite)))
											{
												SetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity",-1);
												AcceptEntityInput(sprite,"kill");
											}
										}
										AcceptEntityInput(EndTarg[client],"kill");
									}
									EndTarg[client] = 0;
								}
							}
							else if (EnergyAmm[client] > 0)
							{
								if (seq != seqprime)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqprime);
								}
								else
								{
									if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
									if (HasEntProp(weap,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType",12);
									int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
									if (ammover > 0)
									{
										Ammo12Reset[client] = ammover;
										SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
									}
									float Time = GetTickedTime();
									//GameSounds: weapon_gluon.Empty weapon_gluon.Special1 weapon_gluon.Special2 weapon_gluon.Special3
									if (WeapSnd[client] < Time)
									{
										char snd[64];
										if (StrEqual(curweap,"weapon_goop",false)) Format(snd,sizeof(snd),"physics/goop/goop_loop.wav");
										else Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
										StopSound(weap,SNDCHAN_WEAPON,snd);
										if (WeapSnd[client] > 0.0)
										{
											float orgs[3];
											if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
											else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
										}
										else
										{
											float orgs[3];
											if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
											else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
											//EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
										}
										WeapSnd[client] = Time+9.0;
									}
									float endpos[3];
									float plyfirepos[3];
									float plyang[3];
									GetClientEyeAngles(client,plyang);
									GetClientEyePosition(client,plyfirepos);
									TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
									TR_GetEndPosition(endpos);
									if (WeapAttackSpeed[client] < Time)
									{
										int targ = TR_GetEntityIndex();
										int hitgroup = 0;
										if ((IsValidEntity(targ)) && (targ != 0)) hitgroup = TR_GetHitGroup();
										int ent = CreateEntityByName("env_explosion");
										if (ent != -1)
										{
											DispatchKeyValue(ent,"iMagnitude","20");
											DispatchKeyValue(ent,"iRadiusOverride","50");
											DispatchKeyValue(ent,"spawnflags","9084");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										//Push effect
										ent = CreateEntityByName("env_physexplosion");
										if (ent != -1)
										{
											DispatchKeyValue(ent,"magnitude","20");
											DispatchKeyValue(ent,"radius","100");
											DispatchKeyValue(ent,"inner_radius","0");
											DispatchKeyValue(ent,"spawnflags","10");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										if ((EndTarg[client] == 0) || (!IsValidEntity(EndTarg[client])))
										{
											EndTarg[client] = CreateEntityByName("generic_actor");
											if (EndTarg[client] != -1)
											{
												DispatchKeyValue(EndTarg[client],"rendermode","10");
												DispatchKeyValue(EndTarg[client],"DisableShadows","1");
												DispatchKeyValue(EndTarg[client],"solid","0");
												DispatchKeyValue(EndTarg[client],"model","models/props_junk/popcan01a.mdl");
												TeleportEntity(EndTarg[client],endpos,plyang,NULL_VECTOR);
												DispatchSpawn(EndTarg[client]);
												ActivateEntity(EndTarg[client]);
												if (HasEntProp(EndTarg[client],Prop_Data,"m_CollisionGroup")) SetEntProp(EndTarg[client],Prop_Data,"m_CollisionGroup",5);
												if (HasEntProp(EndTarg[client],Prop_Data,"m_bloodColor")) SetEntProp(EndTarg[client],Prop_Data,"m_bloodColor",3);
											}
											if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
											{
												HandAttach[client] = CreateEntityByName("info_target");
												if (HandAttach[client] != -1)
												{
													TeleportEntity(HandAttach[client],plyfirepos,plyang,NULL_VECTOR);
													DispatchSpawn(HandAttach[client]);
													ActivateEntity(HandAttach[client]);
													SetVariantString("!activator");
													AcceptEntityInput(HandAttach[client],"SetParent",client);
													if (!bCSS)
													{
														SetVariantString("anim_attachment_RH");
														AcceptEntityInput(HandAttach[client],"SetParentAttachment");
													}
													float orgoffs[3];
													orgoffs[0] = 5.0;
													orgoffs[1] = 0.0;
													orgoffs[2] = 5.0;
													SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
													int effect = CreateEntityByName("env_sprite");
													if (effect != -1)
													{
														DispatchKeyValue(effect,"model","sprites/glow01.spr");
														DispatchKeyValue(effect,"scale","1.0");
														DispatchKeyValue(effect,"GlowProxySize","8");
														DispatchKeyValue(effect,"rendermode","9");
														DispatchKeyValue(effect,"rendercolor","100 100 200");
														TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
														DispatchSpawn(effect);
														ActivateEntity(effect);
														AcceptEntityInput(effect,"Activate");
														SetVariantString("!activator");
														AcceptEntityInput(effect,"SetParent",client);
														if (!bCSS)
														{
															SetVariantString("anim_attachment_RH");
															AcceptEntityInput(effect,"SetParentAttachment");
														}
														orgoffs[0] = 7.0;
														orgoffs[1] = 0.0;
														orgoffs[2] = 0.0;
														SetEntPropVector(effect,Prop_Data,"m_vecOrigin",orgoffs);
													}
													SetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity",effect);
												}
											}
											int effect = CreateEntityByName("env_sprite");
											if (effect != -1)
											{
												DispatchKeyValue(effect,"model","sprites/glow01.spr");//effects/glowball.vmt
												DispatchKeyValue(effect,"scale","1.0");
												DispatchKeyValue(effect,"GlowProxySize","8");
												DispatchKeyValue(effect,"rendermode","9");//2
												DispatchKeyValue(effect,"rendercolor","200 200 255");
												TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
												DispatchSpawn(effect);
												ActivateEntity(effect);
												AcceptEntityInput(effect,"Activate");
												SetVariantString("!activator");
												AcceptEntityInput(effect,"SetParent",EndTarg[client]);
											}
											int beam = CreateEntityByName("beam");
											if (beam != -1)
											{
												if (StrEqual(curweap,"weapon_goop",false))
												{
													DispatchKeyValue(beam,"model","sprites/goop/goop_beam.vmt");
													DispatchKeyValue(beam,"texture","sprites/goop/goop_beam.vmt");
													if (goopbeam != -1)
													{
														SetEntProp(beam,Prop_Data,"m_nModelIndex",goopbeam);
														SetEntProp(beam,Prop_Data,"m_nHaloIndex",goopbeam);
													}
												}
												else
												{
													DispatchKeyValue(beam,"model","effects/gluon_beam.vmt");
													DispatchKeyValue(beam,"texture","effects/gluon_beam.vmt");
													if (gluonbeam != -1)
													{
														SetEntProp(beam,Prop_Data,"m_nModelIndex",gluonbeam);
														SetEntProp(beam,Prop_Data,"m_nHaloIndex",gluonbeam);
													}
												}
												TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(beam);
												ActivateEntity(beam);
												SetEntityRenderColor(beam,255,255,255,255);
												SetEntProp(beam,Prop_Data,"m_nBeamType",1);
												SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
												SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
												SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
												//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
												//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
												//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
												SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
												SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
												//SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
												SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",2.0);
												SetEntPropFloat(beam,Prop_Data,"m_fWidth",4.0);
												SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",8.0);
												SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
												SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
												SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
												SetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity",beam);
											}
											if (!StrEqual(curweap,"weapon_goop",false))
											{
												int beam2 = CreateEntityByName("beam");
												if (beam2 != -1)
												{
													DispatchKeyValue(beam2,"model","effects/gluon_beam.vmt");
													DispatchKeyValue(beam2,"texture","effects/gluon_beam.vmt");
													if (gluonbeam != -1) SetEntProp(beam2,Prop_Data,"m_nModelIndex",gluonbeam);
													TeleportEntity(beam2,plyfirepos,plyang,NULL_VECTOR);
													DispatchSpawn(beam2);
													ActivateEntity(beam2);
													SetEntityRenderColor(beam2,255,255,255,255);
													SetEntProp(beam2,Prop_Data,"m_nBeamType",1);
													SetEntProp(beam2,Prop_Data,"m_nBeamFlags",0);
													SetEntProp(beam2,Prop_Data,"m_nNumBeamEnts",2);
													SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
													//SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",client,0);
													//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
													//SetEntProp(beam2,Prop_Data,"m_nAttachIndex",handatt,0);
													SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
													SetEntPropEnt(beam2,Prop_Data,"m_hEndEntity",EndTarg[client]);
													//SetEntPropVector(beam2,Prop_Data,"m_vecEndPos",endpos);
													SetEntPropFloat(beam2,Prop_Data,"m_fAmplitude",2.25);
													SetEntPropFloat(beam2,Prop_Data,"m_fWidth",3.5);
													SetEntPropFloat(beam2,Prop_Data,"m_fEndWidth",3.5);
													SetEntPropFloat(beam2,Prop_Data,"m_fSpeed",1.0);
													SetEntPropFloat(beam2,Prop_Data,"m_flFrameRate",1.0);
													SetEntPropFloat(beam2,Prop_Data,"m_flHDRColorScale",1.0);
													SetEntProp(beam2,Prop_Data,"m_nDissolveType",-1);
													SetEntProp(beam2,Prop_Data,"m_nRenderMode",2);
													SetEntProp(beam2,Prop_Data,"m_nHaloIndex",0);
													SetEntPropFloat(beam2,Prop_Data,"m_fHaloScale",5.0);
													SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",beam2);
												}
											}
										}
										else
										{
											SetEntProp(EndTarg[client],Prop_Data,"m_MoveType",8);
											float endorg[3];
											if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
											else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
											float shootvel[3];
											MakeVectorFromPoints(endorg,endpos,shootvel);
											ScaleVector(shootvel,3.0);
											if (((shootvel[0] < 100.0) && (shootvel[0] > -100.0)) || ((shootvel[1] < 100.0) && (shootvel[1] > -100.0)))
												ScaleVector(shootvel,2.0);
											TeleportEntity(EndTarg[client],NULL_VECTOR,plyang,shootvel);
											int decal = CreateEntityByName("infodecal");
											if (decal != -1)
											{
												//effects/glowball
												if (StrEqual(curweap,"weapon_goop",false))
												{
													DispatchKeyValue(decal,"texture","decals/goop/goop_decal_1");
													endorg[2]-=7.0;
												}
												else DispatchKeyValue(decal,"texture","decals/scorch2");
												DispatchKeyValue(decal,"LowPriority","1");
												TeleportEntity(decal,endorg,NULL_VECTOR,NULL_VECTOR);
												DispatchSpawn(decal);
												ActivateEntity(decal);
												AcceptEntityInput(decal,"Activate");
											}
										}
										if ((IsValidEntity(targ)) && (targ != 0))
										{
											char snd[64];
											if (StrEqual(curweap,"weapon_goop",false)) Format(snd,sizeof(snd),"physics/goop/goop_loop.wav");
											else Format(snd,sizeof(snd),"weapons\\gluon\\hit%i.wav",GetRandomInt(1,4));
											EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											char clsname[32];
											GetEntityClassname(targ,clsname,sizeof(clsname));
											float damage = 1.0;
											Handle cvar = FindConVar("sk_plr_dmg_gluon");
											if (cvar != INVALID_HANDLE)
											{
												damage = GetConVarFloat(cvar);
												float inflictscale = 1.0;
												char scalechk[32];
												Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
												Handle scaleh = FindConVar(scalechk);
												if (scaleh != INVALID_HANDLE) inflictscale = GetConVarFloat(scaleh);
												CloseHandle(scaleh);
												damage = damage/inflictscale;
												if (hitgroup == headgroup) damage = damage*2.0;
											}
											CloseHandle(cvar);
											if ((!CheckNPCAlly(clsname,targ)) || ((targ < MaxClients+1) && (targ > 0) && (friendlyfire)))
											{
												SDKHooks_TakeDamage(targ,client,client,damage,DMG_ENERGYBEAM|DMG_SONIC,-1,NULL_VECTOR,endpos);
											}
										}
										EnergyAmm[client]--;
										WeapAttackSpeed[client] = Time+0.25;
									}
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
				{
					setbuttons = false;
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							float Time = GetTickedTime();
							if ((EnergyAmm[client] > 0) && (WeapAttackSpeed[client] < Time))
							{
								//int seqmdl = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK");
								EnergyAmm[client]--;
								char mdl[64];
								char snd[64];
								char beammdl[64];
								int taubeammdl = tauhl2beam;
								int posside = 8;
								float posz = 12.0;
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (FileExists("materials/effects/tau_beam.vmt",true,NULL_STRING))
								{
									Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
									taubeammdl = taubeam;
								}
								else Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
								if (StrEqual(mdl,"models/v_gauss.mdl",false))
								{
									Format(snd,sizeof(snd),"weapons\\gauss2.wav");
									taubeammdl = tauhl1beam;
									Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
									if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
									posside = 5;
								}
								else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
								{
									float cycle = GetEntPropFloat(viewmdl,Prop_Data,"m_flCycle");
									if (seq != 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									else if ((seq == 4) && (cycle > 0.2)) SetEntPropFloat(viewmdl,Prop_Data,"m_flCycle",0.0);
									Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
									taubeammdl = tauhl2beam;
									Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
									posside = 5;
									posz = 8.0;
								}
								else
								{
									int randsnd = GetRandomInt(1,5);
									if (randsnd == 4) Format(snd,sizeof(snd),"weapons\\tau\\single.wav");
									else if (randsnd == 5) Format(snd,sizeof(snd),"weapons\\tau\\single2.wav");
									else Format(snd,sizeof(snd),"weapons\\tau\\single0%i.wav",randsnd);
									char sndpathchk[128];
									Format(sndpathchk,sizeof(sndpathchk),"sound\\%s",snd);
									if (!FileExists(sndpathchk,true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
									if (seq == 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
									else SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
								}
								if (taubeammdl == -1)
								{
									if (tauhl2beam != -1)
									{
										taubeammdl = tauhl2beam;
										Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
									}
									else if (tauhl1beam != -1)
									{
										taubeammdl = tauhl1beam;
										Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
									}
									else if (taubeam != -1)
									{
										taubeammdl = taubeam;
										Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
									}
								}
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								CreateTimer(0.2,resetviewmdl,viewmdl);
								WeapAttackSpeed[client] = Time+0.3;
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
								float endpos[3];
								float plyfirepos[3];
								float plyang[3];
								float traceNormal[3];
								GetClientEyeAngles(client,plyang);
								GetClientEyePosition(client,plyfirepos);
								TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
								TR_GetEndPosition(endpos);
								int targ = TR_GetEntityIndex();
								TR_GetPlaneNormal(INVALID_HANDLE,traceNormal);
								float dmg = 20.0;
								Handle cvar = FindConVar("sk_plr_dmg_tau");
								if (cvar != INVALID_HANDLE) dmg = GetConVarFloat(cvar);
								CloseHandle(cvar);
								if (IsValidEntity(targ) && (targ != 0))
								{
									float damageForce[3];
									damageForce[0]+=10.0;
									damageForce[1]+=10.0;
									damageForce[2]+=10.0;
									SDKHooks_TakeDamage(targ,client,client,dmg,DMG_BLAST,-1,damageForce,endpos);
								}
								/* from SDK vehicle_jeep
									//Draw the main beam shaft
									CBeam *pBeam = CBeam::BeamCreate( GAUSS_BEAM_SPRITE, 0.5 );
									
									pBeam->SetStartPos( startPos );
									pBeam->PointEntInit( endPos, this );
									pBeam->SetEndAttachment( LookupAttachment("Muzzle") );
									//Value of width charged beam 9.6 regular 2.4
									pBeam->SetWidth( width );
									pBeam->SetEndWidth( 0.05f );
									pBeam->SetBrightness( 255 );
									pBeam->SetColor( 255, 185+random->RandomInt( -16, 16 ), 40 );
									pBeam->RelinkBeam();
									pBeam->LiveForTime( 0.1f );

									//Draw electric bolts along shaft
									pBeam = CBeam::BeamCreate( GAUSS_BEAM_SPRITE, 3.0f );
									
									pBeam->SetStartPos( startPos );
									pBeam->PointEntInit( endPos, this );
									pBeam->SetEndAttachment( LookupAttachment("Muzzle") );

									pBeam->SetBrightness( random->RandomInt( 64, 255 ) );
									pBeam->SetColor( 255, 255, 150+random->RandomInt( 0, 64 ) );
									pBeam->RelinkBeam();
									pBeam->LiveForTime( 0.1f );
									pBeam->SetNoise( 1.6f );
									pBeam->SetEndWidth( 0.1f );
								*/
								int beam = CreateEntityByName("beam");
								if (beam != -1)
								{
									if ((strlen(beammdl) > 0) && (taubeammdl != -1))
									{
										DispatchKeyValue(beam,"model",beammdl);
										DispatchKeyValue(beam,"texture",beammdl);
										SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
										SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
										SetVariantString("OnUser4 !self:kill::0.1:-1");
										AcceptEntityInput(beam,"AddOutput");
										AcceptEntityInput(beam,"FireUser4");
									}
									plyang[1]-=90.0;
									plyfirepos[0] = (plyfirepos[0] + (posside * Cosine(DegToRad(plyang[1]))));
									plyfirepos[1] = (plyfirepos[1] + (posside * Sine(DegToRad(plyang[1]))));
									plyang[1]+=90.0;
									plyfirepos[0] = (plyfirepos[0] + (8 * Cosine(DegToRad(plyang[1]))));
									plyfirepos[1] = (plyfirepos[1] + (8 * Sine(DegToRad(plyang[1]))));
									plyfirepos[2]-=posz;
									if ((strlen(beammdl) > 0) && (taubeammdl != -1))
									{
										TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
										DispatchSpawn(beam);
										ActivateEntity(beam);
										SetEntityRenderColor(beam,255,GetRandomInt(150,201),40,255);
										SetEntProp(beam,Prop_Data,"m_nBeamType",1);
										SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
										SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
										//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
										//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
										//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
										//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
										//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
										//SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
										SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
										SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",0.0);
										SetEntPropFloat(beam,Prop_Data,"m_fWidth",2.4);
										SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.05);
										SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
										SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
										SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
										SetEntProp(beam,Prop_Data,"m_nHaloIndex",0);
										SetEntPropFloat(beam,Prop_Data,"m_fHaloScale",10.0);
										for (int i = 0;i<3;i++)
										{
											beam = CreateEntityByName("beam");
											if (beam != -1)
											{
												DispatchKeyValue(beam,"model",beammdl);
												DispatchKeyValue(beam,"texture",beammdl);
												SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
												SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
												TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(beam);
												ActivateEntity(beam);
												SetVariantString("OnUser4 !self:kill::0.1:-1");
												AcceptEntityInput(beam,"AddOutput");
												AcceptEntityInput(beam,"FireUser4");
												SetEntityRenderColor(beam,255,255,GetRandomInt(150,214),GetRandomInt(64,255));
												SetEntProp(beam,Prop_Data,"m_nBeamType",1);
												SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
												SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
												SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
												SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",1.6);//2.6+i
												SetEntPropFloat(beam,Prop_Data,"m_fWidth",3.0);//+i
												SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.1);
												SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
												SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
												SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
												SetEntProp(beam,Prop_Data,"m_nHaloIndex",0);
												SetEntPropFloat(beam,Prop_Data,"m_fHaloScale",10.0);
											}
										}
									}
									else AcceptEntityInput(beam,"kill");
									int ent = CreateEntityByName("env_physexplosion");
									if(ent != -1)
									{
										DispatchKeyValueFloat(ent,"magnitude",20.0);
										DispatchKeyValue(ent,"radius","0");
										DispatchKeyValue(ent,"inner_radius","0");
										DispatchKeyValue(ent,"spawnflags","10");
										TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
										DispatchSpawn(ent);
										SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
										AcceptEntityInput(ent,"Explode");
										AcceptEntityInput(ent,"Kill");
									}
									int decal = CreateEntityByName("infodecal");
									if (decal != -1)
									{
										DispatchKeyValue(decal,"texture","decals/scorch2");
										DispatchKeyValue(decal,"LowPriority","1");
										TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
										DispatchSpawn(decal);
										ActivateEntity(decal);
										AcceptEntityInput(decal,"Activate");
									}
									//From weapon_gauss CustomGuns plugin:
									float vecFwd[3], vecUp[3], vecRight[3];
									GetAngleVectors(plyang, vecFwd, vecRight, vecUp);
									float vecDir[3];
									float x, y, z;
									//Gassian spread
									do {
										x = GetRandomFloat(-0.5,0.5) + GetRandomFloat(-0.5,0.5);
										y = GetRandomFloat(-0.5,0.5) + GetRandomFloat(-0.5,0.5);
										z = x*x+y*y;
									} while (z > 1);
								 
									vecDir[0] = vecFwd[0] + x * 0.00873 * vecRight[0] + y * 0.00873 * vecUp[0];
									vecDir[1] = vecFwd[1] + x * 0.00873 * vecRight[1] + y * 0.00873 * vecUp[1];
									vecDir[2] = vecFwd[2] + x * 0.00873 * vecRight[2] + y * 0.00873 * vecUp[2];
									TE_Start("GaussExplosion");
									TE_WriteFloat("m_vecOrigin[0]",endpos[0]);
									TE_WriteFloat("m_vecOrigin[1]",endpos[1]);
									TE_WriteFloat("m_vecOrigin[2]",endpos[2]);
									TE_WriteNum("m_nType",0);
									TE_WriteVector("m_vecDirection",traceNormal);
									TE_SendToAll();
									float hitAngle = -GetVectorDotProduct(traceNormal, vecDir);
									if ( hitAngle < 0.5 )
									{
										float vReflection[3];
										vReflection[0] = 2.0 * traceNormal[0] * hitAngle + vecDir[0];
										vReflection[1] = 2.0 * traceNormal[1] * hitAngle + vecDir[1];
										vReflection[2] = 2.0 * traceNormal[2] * hitAngle + vecDir[2];
										GetVectorAngles(vReflection, plyang);
										plyfirepos = endpos;
										TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
										TR_GetEndPosition(endpos);
										targ = TR_GetEntityIndex();
										if (IsValidEntity(targ) && (targ != 0))
										{
											float damageForce[3];
											damageForce[0]+=10.0;
											damageForce[1]+=10.0;
											damageForce[2]+=10.0;
											SDKHooks_TakeDamage(targ,client,client,dmg,DMG_BLAST,-1,damageForce,endpos);
										}
										if ((strlen(beammdl) > 0) && (taubeammdl != -1))
										{
											for (int i = 0;i<3;i++)
											{
												beam = CreateEntityByName("beam");
												if (beam != -1)
												{
													DispatchKeyValue(beam,"model",beammdl);
													DispatchKeyValue(beam,"texture",beammdl);
													SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
													SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
													TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
													DispatchSpawn(beam);
													ActivateEntity(beam);
													SetVariantString("OnUser4 !self:kill::0.1:-1");
													AcceptEntityInput(beam,"addoutput");
													AcceptEntityInput(beam,"FireUser4");
													if (i == 0)
													{
														SetEntPropFloat(beam,Prop_Data,"m_fWidth",2.4);
														SetEntityRenderColor(beam,255,GetRandomInt(150,220),40,255);
													}
													else
													{
														SetEntPropFloat(beam,Prop_Data,"m_fWidth",2.4);
														SetEntityRenderColor(beam,255,255,GetRandomInt(150,214),GetRandomInt(64,255));
													}
													SetEntProp(beam,Prop_Data,"m_nBeamType",1);
													SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
													SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
													SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
													SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",GetRandomFloat(1.0,1.7));
													SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.1);
													SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
													SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
													SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
													SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
													SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
													SetEntProp(beam,Prop_Data,"m_nHaloIndex",0);
													SetEntPropFloat(beam,Prop_Data,"m_fHaloScale",10.0);
												}
											}
										}
										TE_Start("GaussExplosion");
										TE_WriteFloat("m_vecOrigin[0]",endpos[0]);
										TE_WriteFloat("m_vecOrigin[1]",endpos[1]);
										TE_WriteFloat("m_vecOrigin[2]",endpos[2]);
										TE_WriteNum("m_nType",0);
										TE_WriteVector("m_vecDirection",traceNormal);
										TE_SendToAll();
										ent = CreateEntityByName("env_physexplosion");
										if (ent != -1)
										{
											DispatchKeyValueFloat(ent,"magnitude",20.0);
											DispatchKeyValue(ent,"radius","0");
											DispatchKeyValue(ent,"inner_radius","0");
											DispatchKeyValue(ent,"spawnflags","10");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										decal = CreateEntityByName("infodecal");
										if (decal != -1)
										{
											DispatchKeyValue(decal,"texture","decals/scorch2");//decals/redglowfade
											DispatchKeyValue(decal,"LowPriority","1");
											TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(decal);
											ActivateEntity(decal);
											AcceptEntityInput(decal,"Activate");
										}
									}
									if (FileExists("materials/sprites/glow01.spr",true,NULL_STRING))
									{
										int effect = CreateEntityByName("env_sprite");
										if (effect != -1)
										{
											DispatchKeyValue(effect,"model","sprites/glow01.spr");
											DispatchKeyValue(effect,"scale","1.0");
											DispatchKeyValue(effect,"GlowProxySize","3");
											DispatchKeyValue(effect,"rendermode","9");
											DispatchKeyValue(effect,"rendercolor","200 200 0");
											TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
											DispatchSpawn(effect);
											ActivateEntity(effect);
											AcceptEntityInput(effect,"Activate");
											SetVariantString("OnUser4 !self:kill::0.1:-1");
											AcceptEntityInput(effect,"addoutput");
											AcceptEntityInput(effect,"FireUser4");
										}
									}
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_bhg",false))
				{
					if (weap != -1)
					{
						int bInReload = 0;
						if (HasEntProp(weap,Prop_Data,"m_bInReload")) bInReload = GetEntProp(weap,Prop_Data,"m_bInReload");
						if (!bInReload)
						{
							float Time = GetTickedTime();
							if (WeapAttackSpeed[client] < Time)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int hasammo = 0;
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
									AmmArr[client][0] = hasammo;
									if (hasammo)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										int mdlseq = GetWepAnim(curweap,seq,"ACT_VM_PRIMARYATTACK");
										if (seq == mdlseq)
										{
											SetEntProp(weap,Prop_Data,"m_nViewModelIndex",0);
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetWepAnim(curweap,seq,"ACT_VM_IDLE"));
											seq = 0;
										}
										if (seq != mdlseq)
										{
											WeapAttackSpeed[client] = Time+1.0;
											AmmArr[client][0]--;
											if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",hasammo-1);
											SetEntProp(weap,Prop_Data,"m_nViewModelIndex",1);
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											float vecFirePos[3];
											float vecAngs[3];
											float vecEndPos[3];
											float shootvel[3];
											GetClientEyePosition(client,vecFirePos);
											GetClientEyeAngles(client,vecAngs);
											TR_TraceRayFilter(vecFirePos, vecAngs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
											TR_GetEndPosition(vecEndPos);
											MakeVectorFromPoints(vecFirePos,vecEndPos,shootvel);
											ScaleVector(shootvel,2.5);
											float maxscaler = 500.0;
											EmitSoundToAll("weapons/smg1/switch_single.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
											{
												while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
												{
													ScaleVector(shootvel,0.95);
												}
											}
											int iBall = CreateEntityByName("prop_combine_ball");//npc_concussiongrenade
											if (iBall != -1)
											{
												vecFirePos[0] = (vecFirePos[0] + (50 * Cosine(DegToRad(vecAngs[1]))));
												vecFirePos[1] = (vecFirePos[1] + (50 * Sine(DegToRad(vecAngs[1]))));
												if (vecAngs[0] > -45.0) vecFirePos[2] = (vecFirePos[2] - (50 * Sine(DegToRad(vecAngs[0]))));
												else vecFirePos[2] = (vecFirePos[2] - (75 * Sine(DegToRad(vecAngs[0]))));
												DispatchKeyValue(iBall,"model","models/effects/combineball.mdl");
												TeleportEntity(iBall,vecFirePos,vecAngs,NULL_VECTOR);
												DispatchSpawn(iBall);
												ActivateEntity(iBall);
												SetEntProp(iBall,Prop_Data,"m_nRenderFX",15);
												//SetEntProp(iBall,Prop_Data,"m_MoveType",4);
												TeleportEntity(iBall,NULL_VECTOR,NULL_VECTOR,shootvel);
												//SetEntPropEnt(iBall,Prop_Data,"m_hThrower",client);
												//SetEntProp(iBall,Prop_Data,"m_bIsLive",1);
												SetEntProp(iBall,Prop_Data,"m_nState",2);
												SetEntProp(iBall,Prop_Data,"m_bBounceDie",1);
												SetEntProp(iBall,Prop_Data,"m_nMaxBounces",0);
												SetEntProp(iBall,Prop_Data,"m_bForward",1);
												SetEntPropFloat(iBall,Prop_Data,"m_flRadius",10.0);
												//SetEntPropEnt(iBall,Prop_Data,"m_hSpawner",client);
												SetEntPropEnt(iBall,Prop_Data,"m_hOwnerEntity",client);
												SDKHook(iBall, SDKHook_VPhysicsUpdate, BHGTouch);
											}
										}
									}
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					if (weap != -1)
					{
						setbuttons = false;
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
						float Time = GetTickedTime();
						StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_fire2.wav");
						if ((nextatk < GetGameTime()+0.04) && (WeapSnd[client] < Time))
						{
							//StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_fire2.wav");
							char snd[64];
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
							{
								if (CLAttachment[client] == 1)
								{
									Format(snd,sizeof(snd),"weapons\\pl_gun1.wav");
									SetEntPropFloat(client,Prop_Data,"m_flFlashTime",0.0);
								}
								else Format(snd,sizeof(snd),"weapons\\pl_gun3.wav");
							}
							else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
							{
								Format(snd,sizeof(snd),"weapons\\pistol\\glock_fire.wav");
							}
							else
							{
								Format(snd,sizeof(snd),"weapons\\glock\\single.wav");
							}
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
							if ((amm > 0) && (!inreload))
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq == 3)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									}
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									WeapSnd[client] = Time+0.05;
								}
							}
							else if (inreload)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if ((seq != 5) && (seq != 6))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										}
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										if (seq != 9)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
									else if ((seq != 6) && (seq != 7))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
										StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
										EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									}
								}
							}
							else
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != 0)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
									}
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
				{
					if (weap != -1)
					{
						//StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if ((!inreload) && (amm == 0) && (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0))
						{
							SetEntProp(weap,Prop_Data,"m_bInReload",1);
						}
						if (GetEntProp(client,Prop_Data,"m_nWaterLevel") == 3)
						{
							int fireunderwater = GetEntProp(weap,Prop_Data,"m_bFiresUnderwater");
							if (!fireunderwater) amm = 0;
						}
						if (amm > 0)// && (!inreload))
						{
							flWeapReloadTime[weap] = 0.0;
							SetEntProp(weap,Prop_Data,"m_bInReload",0);
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								char snd[64];
								if (FileExists("sound/weapons/mp5/single1.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\mp5\\single%i.wav",GetRandomInt(1,3));
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									Format(snd,sizeof(snd),"weapons\\hks%i.wav",GetRandomInt(1,3));
									if (seq == 6)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
									}
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									int rand = GetRandomInt(0,3);
									if (seq == rand)
									{
										if (rand == 3) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\m4\\m4_fire.wav");
								}
								else if (StrEqual(curweap,"weapon_g36c",false))
								{
									int rand = GetRandomInt(1,6);
									if (seq == rand)
									{
										if (rand == 6) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_fire.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									int rand = GetRandomInt(1,6);
									if (seq == rand)
									{
										if (rand == 3) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\mp5\\mp5_fire.wav");
								}
								else
								{
									if (seq == 3)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									}
								}
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								WeapAttackSpeed[client] = Time+0.1;
								SetEntProp(weap,Prop_Data,"m_iClip1",amm-1);
								int shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
								if (shotsfired < 10) SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
								float orgs[3];
								float angs[3];
								GetClientEyePosition(client,orgs);
								GetClientEyeAngles(client,angs);
								ShootBullet(client,weap,1,curweap,orgs,angs,0,(3.5*shotsfired/8));
							}
						}
						else if (inreload)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int mdlseq = 2;
								int maxclip = 30;
								char snd[64];
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									maxclip = 50;
									mdlseq = 3;
									Format(snd,sizeof(snd),"weapons\\reload3.wav");
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									mdlseq = 7;
									Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
								}
								else if (FileExists("sound/weapons/mp5/reload.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\mp5\\reload.wav");
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									if ((flWeapReloadTime[weap] != 0.0) && (flWeapReloadTime[weap] <= GetTickedTime()))
									{
										flWeapReloadTime[weap] = 0.0;
										if (viewmdl != -1)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
											SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
											SetEntProp(weap,Prop_Data,"m_bInReload",0);
										}
									}
									else
									{
										flWeapReloadTime[weap] = GetTickedTime()+1.7;
										SetEntProp(weap,Prop_Data,"m_bInReload",1);
									}
								}
							}
						}
						else
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 0)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_sniperrifle",false))
				{
					if (weap != -1)
					{
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								EmitSoundToAll("weapons\\sniper\\sniper_fire.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(1,2);
								if (seq == rand)
								{
									if (rand == 2) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								WeapAttackSpeed[client] = Time+0.2;
								float orgs[3];
								float angs[3];
								GetClientEyeAngles(client, angs);
								if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
								{
									HandAttach[client] = CreateEntityByName("info_target");
									if (HandAttach[client] != -1)
									{
										float plyfirepos[3];
										GetClientEyePosition(client,plyfirepos);
										TeleportEntity(HandAttach[client],plyfirepos,angs,NULL_VECTOR);
										DispatchSpawn(HandAttach[client]);
										ActivateEntity(HandAttach[client]);
										SetVariantString("!activator");
										AcceptEntityInput(HandAttach[client],"SetParent",client);
										if (!bCSS)
										{
											SetVariantString("anim_attachment_RH");
											AcceptEntityInput(HandAttach[client],"SetParentAttachment");
										}
										float orgoffs[3];
										orgoffs[0] = 5.0;
										orgoffs[1] = 0.0;
										orgoffs[2] = 5.0;
										SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
									}
								}
								//if (HasEntProp(HandAttach[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(HandAttach[client],Prop_Data,"m_vecAbsOrigin",orgs);
								//else if (HasEntProp(HandAttach[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(HandAttach[client],Prop_Send,"m_vecOrigin",orgs);
								GetClientEyePosition(client,orgs);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",amm-1);
								float maxspread = 0.25;
								int sideoffs = 5;
								ShootBullet(client,weap,0,curweap,orgs,angs,sideoffs,maxspread);
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_sl8",false)) || (StrEqual(curweap,"weapon_uzi",false)))
				{
					if (weap != -1)
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								if (StrEqual(curweap,"weapon_uzi",false)) EmitSoundToAll("weapons\\uzi\\uzi_fire1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								else EmitSoundToAll("weapons\\SL8\\SL8-1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 1;
								int defanim = 0;
								if (StrEqual(curweap,"weapon_uzi",false))
								{
									WeapAttackSpeed[client] = Time+0.1;
									if (CLAttachment[client])
									{
										mdlseq = 5;
										defanim = 6;
									}
								}
								if (seq == mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",defanim);
								}
								else
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								}
								if (!StrEqual(curweap,"weapon_uzi",false))
								{
									WeapAttackSpeed[client] = Time+0.125;
									int shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
									SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
									float orgs[3];
									float angs[3];
									GetClientEyeAngles(client, angs);
									if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
									{
										HandAttach[client] = CreateEntityByName("info_target");
										if (HandAttach[client] != -1)
										{
											float plyfirepos[3];
											GetClientEyePosition(client,plyfirepos);
											TeleportEntity(HandAttach[client],plyfirepos,angs,NULL_VECTOR);
											DispatchSpawn(HandAttach[client]);
											ActivateEntity(HandAttach[client]);
											SetVariantString("!activator");
											AcceptEntityInput(HandAttach[client],"SetParent",client);
											if (!bCSS)
											{
												SetVariantString("anim_attachment_RH");
												AcceptEntityInput(HandAttach[client],"SetParentAttachment");
											}
											float orgoffs[3];
											orgoffs[0] = 5.0;
											orgoffs[1] = 0.0;
											orgoffs[2] = 5.0;
											SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
										}
									}
									//if (HasEntProp(HandAttach[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(HandAttach[client],Prop_Data,"m_vecAbsOrigin",orgs);
									//else if (HasEntProp(HandAttach[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(HandAttach[client],Prop_Send,"m_vecOrigin",orgs);
									GetClientEyePosition(client,orgs);
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",amm-1);
									float maxspread = 0.5+(shotsfired/2);
									if (maxspread > 2.0) maxspread = 2.0;
									int sideoffs = 2;
									ShootBullet(client,weap,0,curweap,orgs,angs,sideoffs,maxspread);
								}
							}
						}
						else if ((amm <= 0) && (!inreload))
						{
							int ammtype = GetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType");
							int reserveamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,ammtype);
							if (reserveamm > 0)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 2;
								if (StrEqual(curweap,"weapon_uzi",false))
								{
									mdlseq = 9;
									if (CLAttachment[client]) mdlseq = 10;
								}
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
									if (StrEqual(curweap,"weapon_uzi",false))
									{
										EmitSoundToAll("weapons\\uzi\\uzi_clipout.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										if (CLAttachment[client]) CreateTimer(4.5,resetviewmdl,viewmdl);
										else CreateTimer(2.8,resetviewmdl,viewmdl);
									}
									else
									{
										if (FileExists("sound/weapons/sl8/sl8_magout.wav",true,NULL_STRING))
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\sl8\\sl8_magout.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											CreateTimer(0.6,resetviewmdl,viewmdl);
										}
									}
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_oicw",false))
				{
					if (weap != -1)
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								if (FileExists("sound/weapons/oicw/oicw_fire1.wav",true,NULL_STRING))
								{
									char snd[64];
									Format(snd,sizeof(snd),"weapons\\oicw\\oicw_fire%i.wav",GetRandomInt(1,3));
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								}
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(1,3);
								if (rand == seq)
								{
									if (rand+1 > 3) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								WeapAttackSpeed[client] = Time+0.1;
								float orgs[3];
								float angs[3];
								GetClientEyeAngles(client, angs);
								if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
								{
									HandAttach[client] = CreateEntityByName("info_target");
									if (HandAttach[client] != -1)
									{
										float plyfirepos[3];
										GetClientEyePosition(client,plyfirepos);
										TeleportEntity(HandAttach[client],plyfirepos,angs,NULL_VECTOR);
										DispatchSpawn(HandAttach[client]);
										ActivateEntity(HandAttach[client]);
										SetVariantString("!activator");
										AcceptEntityInput(HandAttach[client],"SetParent",client);
										if (!bCSS)
										{
											SetVariantString("anim_attachment_RH");
											AcceptEntityInput(HandAttach[client],"SetParentAttachment");
										}
										float orgoffs[3];
										orgoffs[0] = 5.0;
										orgoffs[1] = 0.0;
										orgoffs[2] = 5.0;
										SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
									}
								}
								//if (HasEntProp(HandAttach[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(HandAttach[client],Prop_Data,"m_vecAbsOrigin",orgs);
								//else if (HasEntProp(HandAttach[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(HandAttach[client],Prop_Send,"m_vecOrigin",orgs);
								GetClientEyePosition(client,orgs);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",amm-1);
								int shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
								SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
								int sideoffs = 5;
								float maxspread = 0.5+(shotsfired/2);
								if (maxspread > 2.0) maxspread = 2.0;
								ShootBullet(client,weap,0,curweap,orgs,angs,sideoffs,maxspread);
							}
						}
						else if ((amm <= 0) && (!inreload))
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 5;
							if (seq != mdlseq)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
								if (FileExists("sound/weapons/oicw/oicw_reload.wav",true,NULL_STRING))
								{
									EmitSoundToAll("weapons\\oicw\\oicw_reload.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									CreateTimer(2.3,resetviewmdl,viewmdl);
									SetEntProp(weap,Prop_Data,"m_bInReload",1);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
				{
					if (weap != -1)
					{
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if (amm > 0)
						{
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(7,12);
								if (seq == rand)
								{
									if (seq > 11) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
								WeapAttackSpeed[client] = Time+0.5;
								CreateHornet(client,weap);
							}
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_molotov",false))
				{
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if (WeapAttackSpeed[client] < Time)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int hasammo = 0;
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
								if (hasammo)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int mdlseq = GetWepAnim(curweap,seq,"ACT_VM_HAULBACK");//ACT_VM_THROW
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									}
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_handgrenade",false)) || (StrEqual(curweap,"weapon_satchel",false)))
				{
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if (WeapAttackSpeed[client] < Time)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int hasammo = 0;
								int mdlseq = 2;
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
								if ((seq != mdlseq) && (hasammo))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									if (!StrEqual(curweap,"weapon_handgrenade",false))
									{
										CreateTimer(0.75,resetviewmdl,viewmdl);
										float targpos[3];
										float shootvel[3];
										float plyfirepos[3];
										float plyang[3];
										float maxscaler = 500.0;
										float sideadj = 0.0;
										char grenademdl[64];
										GetClientEyeAngles(client,plyang);
										if (StrEqual(curweap,"weapon_satchel",false))
										{
											sideadj = 10.0;
											Format(grenademdl,sizeof(grenademdl),"models/weapons/w_satchel.mdl");
										}
										else
										{
											sideadj = -10.0;
											maxscaler = 800.0;
											Format(grenademdl,sizeof(grenademdl),"models/items/boxmrounds.mdl");
										}
										plyang[1]+=sideadj;
										GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
										plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
										plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
										if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
										else plyfirepos[2]+=48.0;
										plyang[1]-=sideadj;
										TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
										TR_GetEndPosition(targpos);
										MakeVectorFromPoints(plyfirepos,targpos,shootvel);
										ScaleVector(shootvel,2.5);
										if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
										{
											while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
											{
												ScaleVector(shootvel,0.95);
											}
										}
										SatchelAmm[client]--;
										if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SatchelAmm[client]);
										int satchel = CreateEntityByName("prop_physics_override");
										if (satchel != -1)
										{
											DispatchKeyValue(satchel,"classname","grenade_satchel");
											if (StrEqual(mdl,"models/v_satchel.mdl",false)) DispatchKeyValue(satchel,"model","models/items/boxmrounds.mdl");
											else DispatchKeyValue(satchel,"model",grenademdl);
											DispatchKeyValue(satchel,"solid","6");
											DispatchKeyValue(satchel,"spawnflags","256");
											TeleportEntity(satchel,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(satchel);
											ActivateEntity(satchel);
											if (HasEntProp(satchel,Prop_Data,"m_CollisionGroup"))
											{
												SetEntProp(satchel,Prop_Data,"m_CollisionGroup",5);
												Handle dp = CreateDataPack();
												WritePackCell(dp,satchel);
												WritePackCell(dp,5);
												CreateTimer(0.1,resetcoll,dp,TIMER_FLAG_NO_MAPCHANGE);
											}
											if (StrEqual(mdl,"models/v_satchel.mdl",false))
											{
												if (!IsModelPrecached("models/w_satchel.mdl")) PrecacheModel("models/w_satchel.mdl",true);
												SetEntityModel(satchel,"models/w_satchel.mdl");
												SetEntProp(satchel,Prop_Data,"m_usSolidFlags",1);
											}
											/*
											else
											{
												int arrsize = GetEntPropArraySize(client,Prop_Data,"m_hViewModel");
												if (arrsize > 1)
												{
													int vModel2 = GetEntPropEnt(client,Prop_Data,"m_hViewModel",1);
													if (!IsValidEntity(vModel2))
													{
														int iSecondViewModel = CreateEntityByName("predicted_viewmodel");
														if (IsValidEntity(iSecondViewModel))
														{
															DispatchKeyValue(iSecondViewModel,"model","models/weapons/v_satchel_radio.mdl");
															GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",targpos);
															TeleportEntity(iSecondViewModel,targpos,NULL_VECTOR,NULL_VECTOR);
															DispatchSpawn(iSecondViewModel);
															ActivateEntity(iSecondViewModel);
															SetEntPropEnt(iSecondViewModel,Prop_Data,"m_hOwner",client);
															SetEntProp(iSecondViewModel,Prop_Data,"m_nViewModelIndex",1);
															SetEntPropEnt(client,Prop_Data,"m_hViewModel",iSecondViewModel,1);
															SetEntProp(iSecondViewModel,Prop_Send,"m_nSequence",4);
															//Need to expand GetWeapAnim to account for this additional VM
															//0 IDLE 2 PRIMARY_ATTACK2 4 VM_DRAW
															SetVariantString("!activator");
															AcceptEntityInput(iSecondViewModel,"SetParent",client);
															float vecNull[3];
															SetEntPropVector(iSecondViewModel,Prop_Data,"m_vecOrigin",vecNull);
														}
														//if by prop_dynamic
														//set parent to first VM
														//vecOrigin -8 5 5
														//flModelScale 0.25
														//SetTransmit to CL only
													}
												}
											}
											*/
											TeleportEntity(satchel,NULL_VECTOR,NULL_VECTOR,shootvel);
											int endpoint = CreateEntityByName("env_explosion");
											if (endpoint != -1)
											{
												char dmgmag[8] = "300";
												char radius[8] = "150";
												Handle cvar = FindConVar("sk_plr_dmg_satchel");
												SDKHookEx(satchel,SDKHook_OnTakeDamage,grenademinetkdmg);
												if (cvar != INVALID_HANDLE)
												{
													GetConVarString(cvar,dmgmag,sizeof(dmgmag));
													if (StringToInt(dmgmag) < 1)
													{
														SetConVarString(cvar,"300",false,false);
														Format(dmgmag,sizeof(dmgmag),"300");
													}
												}
												cvar = FindConVar("sk_satchel_radius");
												if (cvar != INVALID_HANDLE)
												{
													GetConVarString(cvar,radius,sizeof(radius));
													if (StringToInt(radius) < 1)
													{
														SetConVarString(cvar,"150",false,false);
														Format(radius,sizeof(radius),"150");
													}
												}
												CloseHandle(cvar);
												DispatchKeyValue(endpoint,"imagnitude",dmgmag);
												DispatchKeyValue(endpoint,"iRadiusOverride",radius);
												DispatchKeyValue(endpoint,"rendermode","0");
												TeleportEntity(endpoint,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(endpoint);
												ActivateEntity(endpoint);
												SetVariantString("!activator");
												AcceptEntityInput(endpoint,"SetParent",satchel);
												SetEntPropEnt(satchel,Prop_Data,"m_hOwnerEntity",endpoint);
												SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",client);
											}
										}
									}
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_tripmine",false))
				{
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if (WeapAttackSpeed[client] < Time)
						{
							float plyfirepos[3];
							float angs[3];
							float endpos[3];
							GetClientEyePosition(client,plyfirepos);
							GetClientEyeAngles(client,angs);
							TR_TraceRayFilter(plyfirepos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(endpos);
							float chkdist = GetVectorDistance(plyfirepos,endpos,false);
							if (chkdist < 100.0)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int mdlseq = 6;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_tripmine.mdl",false)) mdlseq = 3;
									int hasammo = 0;
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
									if ((seq != mdlseq) && (hasammo))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										CreateTimer(0.15,resetviewmdl,viewmdl);
									}
								}
								WeapAttackSpeed[client] = Time+1.0;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_axe",false))
				{
					if (weap != -1)
					{
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
						if (nextatk < GetGameTime())
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								float plyfirepos[3];
								float angs[3];
								float endpos[3];
								GetClientEyePosition(client,plyfirepos);
								GetClientEyeAngles(client,angs);
								TR_TraceRayFilter(plyfirepos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
								TR_GetEndPosition(endpos);
								float chkdist = GetVectorDistance(plyfirepos,endpos,false);
								if (chkdist > 80.0)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int randmiss = GetRandomInt(3,5);
									if (seq == randmiss)
									{
										if (randmiss == 5) randmiss--;
										else randmiss++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",randmiss);
								}
								else
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int randhit = GetRandomInt(6,7);
									if (randhit == 5) randhit = 3;
									if (seq == randhit)
									{
										if (randhit == 7) randhit--;
										else if (randhit == 3) randhit = 6;
										else randhit++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",randhit);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_snark",false))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 3;
							int type = 1;
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_squeak.mdl",false))
							{
								mdlseq = 5;
								type = 0;
							}
							if ((seq != mdlseq) && (SnarkAmm[client] > 0))
							{
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								CreateTimer(0.5,resetviewmdl,viewmdl);
								SnarkAmm[client]--;
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",SnarkAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SnarkAmm[client]);
								CreateSnark(client,type);
								ChangeEdictState(weap);
							}
							else
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int hasammo = 0;
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
							if (nextatk < GetGameTime()+0.05)
							{
								if (((seq != 1) || (seq != 2)) && (hasammo > 0) && (!inreload))
								{
									if (seq == 2) SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
									else SetEntProp(viewmdl,Prop_Send,"m_nSequence",2);
								}
								else if (inreload)
								{
									if (seq != 4)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
								}
							}
							setbuttons = false;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_dualmp5k",false))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int hasammo = 0;
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((hasammo > 0) && (!inreload))
							{
								int rand = GetRandomInt(1,6);
								if (seq == rand)
								{
									if (rand == 6) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
							}
							else if (inreload)
							{
								if (seq != 8)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
								}
							}
							setbuttons = false;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_camera",false))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int seqmdl = GetWepAnim(curweap,seq,"ACT_VM_THROW");
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqmdl);
							int targ = GetClientAimTarget(client,false);
							if ((IsValidEntity(targ)) && (targ != 0))
							{
								if (HasEntProp(targ,Prop_Data,"m_iName"))
								{
									char targn[64];
									GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (strlen(targn) > 0)
										FireCamOutp(client,targ,targn);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_drill",false))
				{
					//int seqmdl = GetWepAnim(curweap,seq,"ACT_VM_HITCENTER");
					//ACT_VM_MISSCENTER
					//ACT_VM_HITCENTER
					//ACT_VM_HITKILL
				}
				else if (StrEqual(curweap,"weapon_shotgundouble",false))
				{
					//int seqmdl = GetWepAnim(curweap,seq,"ACT_VM_PRIMARYATTACK");
					//ACT_SHOTGUN_RELOAD_START
					//ACT_SHOTGUN_RELOAD_FINISH
					//ACT_VM_RELOAD
					//ACT_VM_PRIMARYATTACK
					//ACT_VM_SECONDARYATTACK
					//ACT_VM_DRYFIRE
				}
			}
		}
		else if (buttons & IN_ATTACK2)
		{
			if (!(g_LastButtons[client] & IN_ATTACK2))
			{
				if ((StrContains(curweap,"custom_",false) == 0) || (StrContains(custweap,"kzsmodifiedweaps/",false) == 0))
				{
					if (centnextatk[weap] < GetGameTime())
					{
						FireCustomWeap(client,weap,custweap,2);
					}
					setbuttons = false;
				}
				else if ((StrEqual(curweap,"weapon_medkit",false)) || (StrEqual(curweap,"weapon_healer",false)))
				{
					if ((!IsValidEntity(Reviving[client])) && (Reviving[client] != -1)) Reviving[client] = -1;
					if ((IsValidEntity(Reviving[client])) && (Reviving[client] != 0))
					{
						if (IsPlayerAlive(Reviving[client]))
						{
							Reviving[client] = -1;
							ReviveTime[client] = 0.0;
						}
						else
						{
							setbuttons = false;
							if (ReviveTime[client] == 0.0)
							{
								ReviveTime[client] = GetGameTime()+4.0;
							}
							int ragdoll = GetEntPropEnt(Reviving[client],Prop_Send,"m_hRagdoll");
							float ragpos[3];
							if (IsValidEntity(ragdoll))
							{
								float curorgs[3];
								GetClientEyePosition(client,curorgs);
								if (HasEntProp(ragdoll,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ragdoll,Prop_Data,"m_vecAbsOrigin",ragpos);
								else if (HasEntProp(ragdoll,Prop_Send,"m_vecOrigin")) GetEntPropVector(ragdoll,Prop_Send,"m_vecOrigin",ragpos);
								if (GetVectorDistance(curorgs,ragpos,false) > 100.0)
								{
									Reviving[client] = -1;
									ReviveTime[client] = 0.0;
									return Plugin_Continue;
								}
							}
							float time = GetGameTime();
							if (time >= ReviveTime[client])
							{
								int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
								SetEntProp(client,Prop_Data,"m_iHealthPack",medkitammo-80);
								EmitSoundToAll("weapons/gauss/fire1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, _, _, 150);
								if (IsValidEntity(ragdoll))
								{
									float ragang[3];
									GetEntPropVector(ragdoll,Prop_Data,"m_angRotation",ragang);
									ragang[0] = 0.0;
									ragang[2] = 0.0;
									DispatchSpawn(Reviving[client]);
									ActivateEntity(Reviving[client]);
									TeleportEntity(Reviving[client],ragpos,ragang,NULL_VECTOR);
									AcceptEntityInput(ragdoll,"kill");
								}
							}
						}
					}
					else
					{
						//m_hRagdoll
						int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
						if (medkitammo >= 80)
						{
							float curorgs[3];
							GetClientEyePosition(client,curorgs);
							for (int i = 1;i<MaxClients+1;i++)
							{
								if ((IsValidEntity(i)) && (i != client))
								{
									if (IsClientInGame(i))
									{
										if (!IsPlayerAlive(i))
										{
											int ragdoll = GetEntPropEnt(i,Prop_Send,"m_hRagdoll");
											if (IsValidEntity(ragdoll))
											{
												float targorgs[3];
												if (HasEntProp(ragdoll,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ragdoll,Prop_Data,"m_vecAbsOrigin",targorgs);
												else if (HasEntProp(ragdoll,Prop_Send,"m_vecOrigin")) GetEntPropVector(ragdoll,Prop_Send,"m_vecOrigin",targorgs);
												float chkdist = GetVectorDistance(curorgs,targorgs,false);
												if (chkdist < 100.0)
												{
													float angs[3];
													float endpos[3];
													GetEntPropVector(client,Prop_Data,"m_angRotation",angs);
													TR_TraceRayFilter(curorgs,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,client);
													TR_GetEndPosition(endpos);
													chkdist = GetVectorDistance(endpos,targorgs,false);
													if (chkdist < 100.0)
													{
														Reviving[client] = i;
														EmitSoundToAll("items/suitchargeok1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
														setbuttons = false;
														break;
													}
												}
											}
										}
									}
								}
							}//asfasf
							if ((!IsValidEntity(Reviving[client])) || (Reviving[client] == 0))
							{
								EmitSoundToAll("items/suitchargeno1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)))
				{
					if (IsValidEntity(weap))
					{
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack");
						if (nextatk < GetGameTime()+0.1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int amm = GetEntProp(client,Prop_Send,"m_iAmmo",_,9);
								if (amm > 0)
								{
									int mdlseq = 1;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_9mmAR.mdl",false)) mdlseq = 5;
									else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
									{
										mdlseq = 6;
										EmitSoundToAll("weapons\\m4\\m4_altfire.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									}
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									}
									CreateTimer(0.5,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								}
								else
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
					}
					setbuttons = false;
				}
				else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
				{
					if (weap != -1)
					{
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if (amm > 0)
						{
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								CreateHornet(client,weap);
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(7,12);
								if (seq == rand)
								{
									if (seq > 11) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
								WeapAttackSpeed[client] = Time+0.2;
							}
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_sl8",false))
				{
					int fov = GetEntProp(client,Prop_Send,"m_iFOV");
					if ((fov > 60) || (fov == 0))
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",30);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)))
						{
							CLInScope[client] = SL8Scope;
							AcceptEntityInput(SL8Scope,"StartOverlays",client);
						}
						else
						{
							SL8Scope = CreateEntityByName("env_screenoverlay");
							if (SL8Scope != -1)
							{
								DispatchKeyValue(SL8Scope,"spawnflags","1");
								DispatchKeyValue(SL8Scope,"OverlayName1","sprites/scope01");
								DispatchSpawn(SL8Scope);
								ActivateEntity(SL8Scope);
								CLInScope[client] = SL8Scope;
								AcceptEntityInput(SL8Scope,"StartOverlays",client);
							}
						}
					}
					else
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",90);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)))
						{
							AcceptEntityInput(SL8Scope,"StopOverlays",client);
							CLInScope[client] = 0;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_oicw",false))
				{
					int fov = GetEntProp(client,Prop_Send,"m_iFOV");
					if ((fov > 60) || (fov == 0))
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",36);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((OICWScope != 0) && (IsValidEntity(OICWScope)))
						{
							CLInScope[client] = OICWScope;
							AcceptEntityInput(OICWScope,"StartOverlays",client);
						}
						else
						{
							OICWScope = CreateEntityByName("env_screenoverlay");
							if (OICWScope != -1)
							{
								DispatchKeyValue(OICWScope,"spawnflags","1");
								DispatchKeyValue(OICWScope,"OverlayName1","overlays/weapons/oicw/scope_lens");
								DispatchSpawn(OICWScope);
								ActivateEntity(OICWScope);
								CLInScope[client] = OICWScope;
								AcceptEntityInput(OICWScope,"StartOverlays",client);
							}
						}
					}
					else
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",90);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((OICWScope != 0) && (IsValidEntity(OICWScope)))
						{
							AcceptEntityInput(OICWScope,"StopOverlays",client);
							CLInScope[client] = 0;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_sniperrifle",false))
				{
					int fov = GetEntProp(client,Prop_Send,"m_iFOV");
					if ((fov > 60) || (fov == 0))
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",25);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						EmitSoundToAll("weapons\\sniper\\sniper_zoomin.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",90);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						EmitSoundToAll("weapons\\sniper\\sniper_zoomout.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
				else if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
				{
					setbuttons = false;
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((viewmdl != -1) && (TauCharge[client] < 20))
						{
							float Time = GetTickedTime();
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 4;
							int pitch = 100;
							int flags = SND_NOFLAGS;
							char mdl[64];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\tau\\gauss_spinup.wav");
							if (StrEqual(mdl,"models/v_gauss.mdl",false))
							{
								mdlseq = 3;
								if ((seq == 3) && (TauCharge[client] > 3)) mdlseq = 4;
								pitch+=TauCharge[client]*8;
								if ((WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20)) flags = SND_CHANGEPITCH;
								Format(snd,sizeof(snd),"ambience\\pulsemachine.wav");
							}
							else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
							{
								mdlseq = 2;
								if ((seq == 2) || (TauCharge[client] > 3)) mdlseq = 3;
								pitch+=TauCharge[client]*8;
								if ((WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20)) flags = SND_CHANGEPITCH;
								Format(snd,sizeof(snd),"weapons\\gauss\\chargeloop.wav");
							}
							else
							{
								mdlseq = GetWepAnim(curweap,seq,"ACT_GAUSS_SPINCYCLE");
								if ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)) mdlseq = 4;
								else
								{
									if (mdlseq == 0) mdlseq = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK");
									if (mdlseq == 0) mdlseq = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK_LOW");
									else if ((seq == mdlseq) || (TauCharge[client] > 3)) mdlseq = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK");
								}
								pitch+=TauCharge[client]*8;
								if ((WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20)) flags = SND_CHANGEPITCH;
							}
							if ((EnergyAmm[client] > 0) && (WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20))
							{
								EnergyAmm[client]--;
								TauCharge[client]++;
								//m_flPlaybackRate
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								char sndpathchk[128];
								Format(sndpathchk,sizeof(sndpathchk),"sound\\%s",snd);
								if (!FileExists(sndpathchk,true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\gauss\\chargeloop.wav");
								EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, flags, _, pitch);
								WeapAttackSpeed[client] = Time+0.2;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_uzi",false))
				{
					if (weap != -1)
					{
						if (CLAttachment[client])
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
								CreateTimer(0.2,resetviewmdl,viewmdl);
								CLAttachment[client] = 0;
							}
						}
						else
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 8) SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
								CreateTimer(0.2,resetviewmdl,viewmdl);
								CLAttachment[client] = 1;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					if (weap != -1)
					{
						char mdl[32];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
								CreateTimer(0.5,resetviewmdl,viewmdl);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_satchel",false))
				{
					/*
					int arrsize = GetEntPropArraySize(client,Prop_Send,"m_hViewModel");
					if (arrsize > 1)
					{
						int vModel2 = GetEntPropEnt(client,Prop_Data,"m_hViewModel",1);
						if (!IsValidEntity(vModel2))
						{
							SetEntProp(vModel2,Prop_Send,"m_nSequence",2);
							//Lower and RM
						}
					}
					*/
					DetSatchels(-1,client);
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					if (weap != -1)
					{
						float nextsecondary = GetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack");
						if (nextsecondary < GetGameTime())
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 8)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
									SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+0.5);
									ChangeEdictState(weap);
									CreateTimer(0.2,resetviewmdl,viewmdl);
									int targ = GetClientAimTarget(client,false);
									if ((targ != 0) && (IsValidEntity(targ)))
									{
										char cls[32];
										GetEntityClassname(targ,cls,sizeof(cls));
										if (!CheckNPCAlly(cls,targ))
										{
											float curorgs[3];
											float targorgs[3];
											GetClientAbsOrigin(client,curorgs);
											if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targorgs);
											else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targorgs);
											float chkdist = GetVectorDistance(curorgs,targorgs,false);
											if (chkdist < 100.0)
											{
												float damageForce[3];
												damageForce[0] = 5.0;
												damageForce[1] = 5.0;
												damageForce[2] = 5.0;
												SDKHooks_TakeDamage(targ,client,client,15.0,DMG_CLUB,-1,damageForce,curorgs);
												EmitSoundToAll("npc/zombie/zombie_hit.wav", weap, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
											}
										}
									}
								}
							}
						}
						StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_empty.wav");
					}
				}
			}
		}
		else if (!(buttons & IN_ATTACK))
		{
			if (((StrContains(curweap,"custom_",false) == 0) || (StrContains(custweap,"kzsmodifiedweaps/",false) == 0)) && (weap > MaxClients))
			{
				if (InChargeUp[weap])
				{
					InChargeUp[weap] = false;
					ReleaseCustomWeapon(client,weap,custweap,1);
				}
			}
			else if ((StrEqual(curweap,"weapon_gluon",false)) || (StrEqual(curweap,"weapon_goop",false)))
			{
				setbuttons = false;
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int seqprime = GetWepAnim(curweap,seq,"ACT_VM_PRIMARYATTACK");
						if (seq == seqprime)
						{
							float orgs[3];
							if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
							if (StrEqual(curweap,"weapon_gluon",false)) seqprime = GetWepAnim(curweap,seq,"ACT_TRANSITION");
							else seqprime = GetWepAnim(curweap,seq,"ACT_VM_IDLE");
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqprime);
							char snd[64];
							if (StrEqual(curweap,"weapon_goop",false))
							{
								Format(snd,sizeof(snd),"physics/goop/goop_loop.wav");
								StopSound(weap,SNDCHAN_WEAPON,snd);
								//if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
								//EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
							else
							{
								Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
								StopSound(weap,SNDCHAN_WEAPON,snd);
								if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
								Format(snd,sizeof(snd),"weapons\\gluon\\special2.wav");
								EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
							CreateTimer(0.2,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
							WeapSnd[client] = 0.0;
							if ((EndTarg[client] != 0) && (IsValidEntity(EndTarg[client])))
							{
								if (StrEqual(curweap,"weapon_gluon",false))
								{
									int effect = CreateEntityByName("info_particle_system");
									if (effect != -1)
									{
										float endorg[3];
										if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
										else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
										float angs[3];
										if (HasEntProp(EndTarg[client],Prop_Data,"m_angAbsRotation")) GetEntPropVector(EndTarg[client],Prop_Data,"m_angAbsRotation",angs);
										DispatchKeyValue(effect,"effect_name","gluon_beam_burst");
										DispatchKeyValue(effect,"start_active","1");
										TeleportEntity(effect,endorg,angs,NULL_VECTOR);
										DispatchSpawn(effect);
										ActivateEntity(effect);
										AcceptEntityInput(effect,"Start");
										int entindx = EntIndexToEntRef(effect);
										CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
										int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
										if ((beam != 0) && (IsValidEntity(beam)))
										{
											int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
											if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
											AcceptEntityInput(beam,"kill");
										}
										if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
										{
											int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
											if ((sprite != 0) && (IsValidEntity(sprite)))
											{
												AcceptEntityInput(sprite,"kill");
												AcceptEntityInput(HandAttach[client],"kill");
												HandAttach[client] = 0;
											}
										}
										AcceptEntityInput(EndTarg[client],"kill");
									}
								}
								else
								{
									int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
									if ((beam != 0) && (IsValidEntity(beam)))
									{
										int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
										if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
										AcceptEntityInput(beam,"kill");
									}
									if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
									{
										int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
										if ((sprite != 0) && (IsValidEntity(sprite)))
										{
											AcceptEntityInput(sprite,"kill");
											AcceptEntityInput(HandAttach[client],"kill");
											HandAttach[client] = 0;
										}
									}
									AcceptEntityInput(EndTarg[client],"kill");
								}
								EndTarg[client] = 0;
							}
						}
					}
				}
			}
			else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
			{
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if ((seq != 0) && (seq != 4) && (seq != 3))
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
				}
			}
			else if (StrEqual(curweap,"weapon_molotov",false))
			{
				if ((weap != -1) && (WeapAttackSpeed[client] < GetTickedTime()))
				{
					if (HasEntProp(weap,Prop_Data,"m_nViewModelIndex"))
					{
						if (GetEntProp(weap,Prop_Data,"m_nViewModelIndex") == 1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int hasammo = 0;
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
								if (hasammo)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int mdlseq = GetWepAnim(curweap,seq,"ACT_VM_HAULBACK");
									if (seq == mdlseq)
									{
										SetEntProp(weap,Prop_Data,"m_iClip1",hasammo-1);
										mdlseq = GetWepAnim(curweap,seq,"ACT_VM_THROW");
										WeapAttackSpeed[client] = GetTickedTime()+1.0;
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										CreateTimer(0.75,resetviewmdl,viewmdl);
										float targpos[3];
										float shootvel[3];
										float plyfirepos[3];
										float plyang[3];
										float maxscaler = 600.0;
										float sideadj = -10.0;
										char grenademdl[64];
										GetClientEyeAngles(client,plyang);
										Format(grenademdl,sizeof(grenademdl),"models/weapons/w_molotov.mdl");
										plyang[1]+=sideadj;
										GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
										plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
										plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
										if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
										else plyfirepos[2]+=60.0;
										plyang[1]-=sideadj;
										TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
										TR_GetEndPosition(targpos);
										MakeVectorFromPoints(plyfirepos,targpos,shootvel);
										ScaleVector(shootvel,2.5);
										if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
										{
											while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
											{
												ScaleVector(shootvel,0.95);
											}
										}
										int iMolotov = CreateEntityByName("npc_concussiongrenade");
										if (iMolotov != -1)
										{
											DispatchKeyValue(iMolotov,"classname","grenade_molotov");
											DispatchKeyValue(iMolotov,"model",grenademdl);
											if (!IsModelPrecached(grenademdl)) PrecacheModel(grenademdl,true);
											TeleportEntity(iMolotov,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(iMolotov);
											ActivateEntity(iMolotov);
											SetEntPropEnt(iMolotov,Prop_Data,"m_hThrower",client);
											SetEntProp(iMolotov,Prop_Data,"m_bIsLive",1);
											SetEntPropFloat(iMolotov,Prop_Data,"m_DmgRadius",hMolotovRadius.FloatValue);
											SetEntityModel(iMolotov,grenademdl);
											TeleportEntity(iMolotov,NULL_VECTOR,NULL_VECTOR,shootvel);
											SDKHook(iMolotov, SDKHook_StartTouch, MolotovTouch);
										}
									}
								}
							}
						}
					}
				}
			}
			else if (StrEqual(curweap,"weapon_handgrenade",false))
			{
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int curamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
						if (seq == 2)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(3,5));
							SetEntProp(client,Prop_Data,"m_iAmmo",curamm-1,_,12);
							WeapAttackSpeed[client] = GetTickedTime()+1.0;
							CreateTimer(0.5,resetviewmdl,viewmdl);
							CreateTimer(1.0,resetviewmdl,viewmdl);
							float targpos[3];
							float shootvel[3];
							float plyfirepos[3];
							float plyang[3];
							float maxscaler = 800.0;
							float sideadj = -10.0;
							GetClientEyeAngles(client,plyang);
							plyang[1]+=sideadj;
							GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
							plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
							plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
							if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
							else plyfirepos[2]+=48.0;
							plyang[1]-=sideadj;
							TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(targpos);
							float chkdist = GetVectorDistance(plyfirepos,targpos,false);
							if (chkdist < 200.0) targpos[2]+=60.0;
							else targpos[2]+=20.0;
							MakeVectorFromPoints(plyfirepos,targpos,shootvel);
							ScaleVector(shootvel,2.5);
							if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
							{
								while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
								{
									ScaleVector(shootvel,0.95);
								}
							}
							int grenade = CreateEntityByName("prop_physics_override");
							if (grenade != -1)
							{
								DispatchKeyValue(grenade,"classname","grenade_frag");
								DispatchKeyValue(grenade,"model","models/items/357ammobox.mdl");
								DispatchKeyValue(grenade,"solid","6");
								DispatchKeyValue(grenade,"spawnflags","256");
								TeleportEntity(grenade,plyfirepos,plyang,NULL_VECTOR);
								DispatchSpawn(grenade);
								ActivateEntity(grenade);
								if (!IsModelPrecached("models/w_grenade.mdl")) PrecacheModel("models/w_grenade.mdl",true);
								SetEntityModel(grenade,"models/w_grenade.mdl");
								if (HasEntProp(grenade,Prop_Data,"m_CollisionGroup")) SetEntProp(grenade,Prop_Data,"m_CollisionGroup",5);
								TeleportEntity(grenade,NULL_VECTOR,NULL_VECTOR,shootvel);
								int endpoint = CreateEntityByName("env_explosion");
								if (endpoint != -1)
								{
									char dmgmag[8] = "300";
									char radius[8] = "150";
									Handle cvar = FindConVar("sk_plr_dmg_handgrenade");
									if (cvar != INVALID_HANDLE) GetConVarString(cvar,dmgmag,sizeof(dmgmag));
									cvar = FindConVar("sk_grenade_radius");
									if (cvar != INVALID_HANDLE) GetConVarString(cvar,radius,sizeof(radius));
									CloseHandle(cvar);
									DispatchKeyValue(endpoint,"imagnitude",dmgmag);
									DispatchKeyValue(endpoint,"iRadiusOverride",radius);
									DispatchKeyValue(endpoint,"rendermode","0");
									DispatchKeyValue(endpoint,"OnUser4","!self,Explode,,4,-1");
									plyfirepos[2]+=2.0;
									TeleportEntity(endpoint,plyfirepos,plyang,NULL_VECTOR);
									DispatchSpawn(endpoint);
									ActivateEntity(endpoint);
									SetVariantString("!activator");
									AcceptEntityInput(endpoint,"SetParent",grenade);
									AcceptEntityInput(endpoint,"FireUser4",grenade);
									SetEntPropEnt(grenade,Prop_Data,"m_hOwnerEntity",endpoint);
									SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",client);
									CreateTimer(4.0,GrenadeExpl,grenade,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
			}
			else if ((StrEqual(curweap,"weapon_oicw",false)) || (StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
			{
				if (weap != -1)
				{
					SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
				}
			}
			else if (StrEqual(curweap,"weapon_camera",false))
			{
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq != 1) SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
					}
				}
			}
		}
		if (!(buttons & IN_ATTACK2))
		{
			if ((StrEqual(curweap,"weapon_medkit",false)) || (StrEqual(curweap,"weapon_healer",false)))
			{
				if ((IsValidEntity(Reviving[client])) && (Reviving[client] != 0))
				{
					Reviving[client] = -1;
					ReviveTime[client] = 0.0;
				}
			}
			else if (((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false))) && (TauCharge[client] > 0))
			{
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int mdlseq = 4;
						int mdlseq2 = 4;
						int mdlseqfire = 7;
						int taubeammdl = tauhl2beam;
						int posside = 8;
						float posz = 12.0;
						char mdl[64];
						char snd[64];
						char stopsnd[64];
						char beammdl[64];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						Format(snd,sizeof(snd),"weapons\\tau\\gauss_overcharged.wav");
						Format(stopsnd,sizeof(stopsnd),"weapons\\tau\\gauss_spinup.wav");
						if (FileExists("materials/effects/tau_beam.vmt",true,NULL_STRING))
						{
							Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
							taubeammdl = taubeam;
						}
						else Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
						if (StrEqual(mdl,"models/v_gauss.mdl",false))
						{
							Format(snd,sizeof(snd),"weapons\\gauss2.wav");
							Format(stopsnd,sizeof(stopsnd),"ambience\\pulsemachine.wav");
							mdlseq2 = 3;
							mdlseq = 4;
							mdlseqfire = 5;
							taubeammdl = tauhl1beam;
							Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
						}
						else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
						{
							Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
							Format(stopsnd,sizeof(stopsnd),"weapons\\gauss\\chargeloop.wav");
							taubeammdl = tauhl2beam;
							Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
							posside = 5;
							posz = 8.0;
						}
						else
						{
							if ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)) mdlseq = 4;
							else
							{
								mdlseq = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK");
								mdlseq2 = GetWepAnim(curweap,seq,"ACT_VM_PULLBACK_LOW");
								if ((mdlseq == 0) && (mdlseq2 == 0))
								{
									mdlseq = GetWepAnim(curweap,seq,"ACT_GAUSS_SPINCYCLE");
									mdlseq2 = mdlseq;
								}
								else if (mdlseq2 == mdlseq) mdlseq2++;
							}
							mdlseqfire = GetWepAnim(curweap,seq,"ACT_VM_SECONDARYATTACK");
						}
						if ((seq == mdlseq) || (seq == mdlseq2))
						{
							if (taubeammdl == -1)
							{
								if (tauhl2beam != -1)
								{
									taubeammdl = tauhl2beam;
									Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
								}
								else if (tauhl1beam != -1)
								{
									taubeammdl = tauhl1beam;
									Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
								}
								else if (taubeam != -1)
								{
									taubeammdl = taubeam;
									Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
								}
							}
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseqfire);
							if (FileExists(stopsnd,true,NULL_STRING)) StopSound(weap,SNDCHAN_WEAPON,stopsnd);
							char sndpathchk[128];
							Format(sndpathchk,sizeof(sndpathchk),"sound\\%s",snd);
							if (!FileExists(sndpathchk,true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
							EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
							float endpos[3];
							float plyfirepos[3];
							float plyang[3];
							GetClientEyeAngles(client,plyang);
							GetClientEyePosition(client,plyfirepos);
							TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(endpos);
							int targ = TR_GetEntityIndex();
							float dmg = 20.0;
							Handle cvar = FindConVar("sk_plr_dmg_tau");
							if (cvar != INVALID_HANDLE) dmg = GetConVarFloat(cvar);
							CloseHandle(cvar);
							if (IsValidEntity(targ) && (targ != 0))
							{
								float damageForce[3];
								damageForce[0]+=10.0;
								damageForce[1]+=10.0;
								damageForce[2]+=10.0;
								SDKHooks_TakeDamage(targ,client,client,dmg,DMG_BLAST,-1,damageForce,endpos);
							}
							int beam = CreateEntityByName("beam");
							if (beam != -1)
							{
								DispatchKeyValue(beam,"model",beammdl);
								DispatchKeyValue(beam,"texture",beammdl);
								SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
								SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
								SetVariantString("OnUser4 !self:kill::0.1:-1");
								AcceptEntityInput(beam,"addoutput");
								AcceptEntityInput(beam,"FireUser4");
								plyang[1]-=90.0;
								plyfirepos[0] = (plyfirepos[0] + (posside * Cosine(DegToRad(plyang[1]))));
								plyfirepos[1] = (plyfirepos[1] + (posside * Sine(DegToRad(plyang[1]))));
								plyang[1]+=90.0;
								plyfirepos[0] = (plyfirepos[0] + (8 * Cosine(DegToRad(plyang[1]))));
								plyfirepos[1] = (plyfirepos[1] + (8 * Sine(DegToRad(plyang[1]))));
								plyfirepos[2]-=posz;
								TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
								DispatchSpawn(beam);
								ActivateEntity(beam);
								SetEntityRenderColor(beam,255,255,GetRandomInt(150,220),255);
								SetEntProp(beam,Prop_Data,"m_nBeamType",1);
								SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
								SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
								//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
								//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
								//SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
								SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
								SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",2.0);
								SetEntPropFloat(beam,Prop_Data,"m_fWidth",3.5);
								SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",6.0);
								SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
								SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
								SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
								SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
								SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
								SetEntProp(beam,Prop_Data,"m_nHaloIndex",0);
								SetEntPropFloat(beam,Prop_Data,"m_fHaloScale",10.0);
								for (int i = 0;i<3;i++)
								{
									beam = CreateEntityByName("beam");
									if (beam != -1)
									{
										DispatchKeyValue(beam,"model",beammdl);
										DispatchKeyValue(beam,"texture",beammdl);
										SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
										SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
										TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
										DispatchSpawn(beam);
										ActivateEntity(beam);
										SetVariantString("OnUser4 !self:kill::0.1:-1");
										AcceptEntityInput(beam,"addoutput");
										AcceptEntityInput(beam,"FireUser4");
										SetEntityRenderColor(beam,255,255,GetRandomInt(150,220),255);
										SetEntProp(beam,Prop_Data,"m_nBeamType",1);
										SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
										SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
										SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
										SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",GetRandomFloat(3.0,4.5));
										SetEntPropFloat(beam,Prop_Data,"m_fWidth",GetRandomFloat(1.0,4.0));
										SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",6.0);
										SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
										SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
										SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
										SetEntProp(beam,Prop_Data,"m_nHaloIndex",0);
										SetEntPropFloat(beam,Prop_Data,"m_fHaloScale",10.0);
									}
								}
								int ent = CreateEntityByName("env_physexplosion");
								if (ent != -1)
								{
									float magnitude = dmg*TauCharge[client];
									DispatchKeyValueFloat(ent,"magnitude",magnitude);
									DispatchKeyValue(ent,"radius","256");
									DispatchKeyValue(ent,"inner_radius","0");
									DispatchKeyValue(ent,"spawnflags","10");
									TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(ent);
									SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
									AcceptEntityInput(ent,"Explode");
									AcceptEntityInput(ent,"Kill");
								}
								int decal = CreateEntityByName("infodecal");
								if (decal != -1)
								{
									DispatchKeyValue(decal,"texture","decals/scorch2");
									DispatchKeyValue(decal,"LowPriority","1");
									TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(decal);
									ActivateEntity(decal);
									AcceptEntityInput(decal,"Activate");
								}
								int effect = CreateEntityByName("env_sprite");
								if (effect != -1)
								{
									DispatchKeyValue(effect,"model","sprites/glow01.spr");
									DispatchKeyValue(effect,"scale","1.0");
									DispatchKeyValue(effect,"GlowProxySize","9");
									DispatchKeyValue(effect,"rendermode","9");
									DispatchKeyValue(effect,"rendercolor","200 200 0");
									TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
									DispatchSpawn(effect);
									ActivateEntity(effect);
									AcceptEntityInput(effect,"Activate");
									SetVariantString("OnUser4 !self:kill::0.1:-1");
									AcceptEntityInput(effect,"addoutput");
									AcceptEntityInput(effect,"FireUser4");
								}
							}
							if (tauknockback)
							{
								float launch[3];
								GetAngleVectors(plyang, launch, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(launch,-(dmg*TauCharge[client]));
								launch[2]+=(dmg/2)*TauCharge[client];
								TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,launch);
							}
							TauCharge[client] = 0;
							WeapAttackSpeed[client] = GetTickedTime()+1.0;
						}
					}
				}
			}
		}
		if (buttons & IN_RELOAD)
		{
			if (!(g_LastButtons[client] & IN_RELOAD))
			{
				if ((StrContains(curweap,"custom_",false) == 0) || (StrContains(custweap,"kzsmodifiedweaps/",false) == 0))
				{
					int inreload = 0;
					if (HasEntProp(weap,Prop_Data,"m_bInReload")) inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
					if (inreload == 0)
					{
						ReloadCustomWeap(client,weap,custweap,false);
					}
				}
				else if (StrEqual(curweap,"weapon_flaregun",false))
				{
					if (weap != -1)
					{
						if ((GetEntProp(weap,Prop_Data,"m_iClip1") < 1) && (flareammo[client] > 0))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 1;
								char mdl[64];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
									mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									ChangeEdictState(viewmdl);
									CreateTimer(2.2,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
									if (FileExists("sound/weapons/flaregun/flaregun_reload.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\flaregun\\flaregun_reload.wav", weap, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					if (weap != -1)
					{
						if (GetEntProp(client,Prop_Send,"m_iAmmo",_,3) > 0)
						{
							int maxclip = 17;
							if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0)) maxclip = 15;
							if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if ((seq != 5) && (seq != 6))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										}
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
										if (FileExists("sound/weapons/pistol/glock_reload1.wav",true,NULL_STRING))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload1.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
									else if ((seq != 6) && (seq != 7))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
										if (FileExists("sound/weapons/glock/reload.wav",true,NULL_STRING))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
								}
							}
							else
							{
								StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
								SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
								SetEntProp(weap,Prop_Data,"m_bInReload",0);
								CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
							}
							setbuttons = false;
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
				{
					if (weap != -1)
					{
						if (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0)
						{
							int mdlseq = 2;
							int maxclip = 30;
							char snd[64];
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
							{
								mdlseq = 3;
								maxclip = 50;
								Format(snd,sizeof(snd),"weapons\\reload3.wav");
							}
							else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
							{
								mdlseq = 7;
								Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
							}
							else if (StrEqual(curweap,"weapon_g36c",false))
							{
								mdlseq = 9;
								Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
							}
							else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
							{
								mdlseq = 9;
								Format(snd,sizeof(snd),"weapons\\mp5\\mp5_reload.wav");
							}
							else if (FileExists("sound/weapons/mp5/reload.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\mp5\\reload.wav");
							if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										//StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
										if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										if ((flWeapReloadTime[weap] != 0.0) && (flWeapReloadTime[weap] <= GetTickedTime()))
										{
											flWeapReloadTime[weap] = 0.0;
											if (viewmdl != -1)
											{
												SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
												SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
												SetEntProp(weap,Prop_Data,"m_bInReload",0);
												//CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
												//SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
											}
										}
										else
										{
											flWeapReloadTime[weap] = GetTickedTime()+1.7;
											SetEntProp(weap,Prop_Data,"m_bInReload",1);
										}
									}
								}
							}
							else
							{
								SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
								SetEntProp(weap,Prop_Data,"m_bInReload",0);
								CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_sniperrifle",false))
				{
					if (weap != -1)
					{
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if ((GetEntProp(client,Prop_Send,"m_iAmmo",_,10) > 0) && (!inreload) && (amm == 0))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 4)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									CreateTimer(2.8,resetviewmdl,viewmdl);
									EmitSoundToAll("weapons\\sniper\\sniper_reload.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_hivehand",false))
				{
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if (seq != 4)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
								CreateTimer(21.0,resetviewmdl,viewmdl);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					if (GetEntProp(client,Prop_Send,"m_iAmmo",_,3) > 0)
					{
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
								int maxclip = 8;
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if ((seq != 4) && (clip < maxclip))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									CreateTimer(2.0,resetviewmdl,viewmdl);
								}
								else if (seq != 4)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
									SetEntProp(weap,Prop_Data,"m_bInReload",0);
									CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
									StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
									setbuttons = false;
								}
								
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_dualmp5k",false))
				{
					if (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0)
					{
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
								int maxclip = 64;
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if ((seq != 8) && (clip < maxclip))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
								}
								else if (seq != 8)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
									SetEntProp(weap,Prop_Data,"m_bInReload",0);
									CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
									StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
									setbuttons = false;
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_uzi",false))
				{
					if (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0)
					{
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
								int maxclip = 30;
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 9;
								if (CLAttachment[client]) mdlseq = 10;
								if ((seq != mdlseq) && (clip < maxclip))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								}
								else if (seq != mdlseq)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
									SetEntProp(weap,Prop_Data,"m_bInReload",0);
									CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
									StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
									setbuttons = false;
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_bhg",false))
				{
					int bInReload = 0;
					if (HasEntProp(weap,Prop_Data,"m_bInReload")) bInReload = GetEntProp(weap,Prop_Data,"m_bInReload");
					if (AmmArr[client][1] != GetEntProp(client,Prop_Send,"m_iAmmo",_,12)) AmmArr[client][1] = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
					if ((AmmArr[client][1] > 0) && (AmmArr[client][0] < 3) && (!bInReload))
					{
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int seqmdl = GetWepAnim(curweap,seq,"ACT_VM_RELOAD");
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqmdl);
								SetEntProp(weap,Prop_Data,"m_bInReload",1);
								CreateTimer(0.5,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								WeapAttackSpeed[client] = GetTickedTime()+0.6;
								EmitGameSoundToAll("Weapon_Pistol.Reload",client);
							}
						}
					}
				}
			}
		}
		if (buttons & IN_USE)
		{
			if (!(g_LastButtons[client] & IN_RELOAD))
			{
				int targ = GetClientAimTarget(client,false);
				if (targ != -1)
				{
					char cls[32];
					GetEntityClassname(targ,cls,sizeof(cls));
					if (StrEqual(cls,"grenade_satchel",false))
					{
						int owner = -1;
						int expl = GetEntPropEnt(targ,Prop_Data,"m_hOwnerEntity");
						if (expl != -1) owner = GetEntPropEnt(expl,Prop_Data,"m_hOwnerEntity");
						if (owner == client)
						{
							float orgs[3];
							float proporgs[3];
							if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",proporgs);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",proporgs);
							float chkdist = GetVectorDistance(orgs,proporgs,false);
							if (chkdist < 80.0)
							{
								//plays on same channel as USE EmitGameSoundToAll("HL2Player.PickupWeapon",client);
								int sndlvl,pitch,channel;
								float vol;
								char snd[64];
								if (GetGameSoundParams("HL2Player.PickupWeapon",channel,sndlvl,vol,pitch,snd,sizeof(snd),client))
								{
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, sndlvl, _, vol, pitch);
								}
								Handle pickuph = StartMessageOne("ItemPickup",client);
								BfWriteString(pickuph,"weapon_pistol");
								EndMessage();
								AcceptEntityInput(targ,"kill");
								SatchelAmm[client]++;
								if (StrEqual(curweap,"weapon_satchel",false))
								{
									if (weap != -1)
									{
										SetEntProp(weap,Prop_Data,"m_iClip1",SatchelAmm[client]);
									}
								}
							}
						}
					}
				}
			}
		}
		if (IsValidEntity(weap))
		{
			int inreload = 0;
			if (HasEntProp(weap,Prop_Data,"m_bInReload")) inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
			if ((!inreload) && (!(buttons & IN_ATTACK)) && (!(buttons & IN_ATTACK2)))
			{
				if (buttons & IN_SPEED)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int seqlowered = GetWepAnim(curweap,seq,"ACT_VM_LOWERED");
						if (StrEqual(curweap,"weapon_uzi",false))
						{
							if (CLAttachment[client]) seqlowered = GetWepAnim(curweap,seq,"Uzi_IdleDual");
						}
						else if ((StrEqual(curweap,"weapon_tau",false)) && ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)))
						{
							seqlowered = 9;
						}
						if (seq != seqlowered)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqlowered);
							InIronSights[client] = false;
							flWeapReloadTime[weap] = 0.0;
						}
					}
				}
				else if (!(buttons & IN_SPEED))
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int seqlowered = GetWepAnim(curweap,seq,"ACT_VM_LOWERED");
						if ((StrEqual(curweap,"weapon_tau",false)) && ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)))
						{
							seqlowered = 9;
						}
						if (seq == seqlowered)
						{
							if (CLAttachment[client])
							{
								if (StrEqual(curweap,"weapon_uzi",false)) seqlowered = GetWepAnim(curweap,seq,"Uzi_IdleDual");
								else seqlowered = GetWepAnim(curweap,seq,"ACT_VM_IDLE_SILENCED");
							}
							else
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1"))
								{
									if (GetEntProp(weap,Prop_Data,"m_iClip1") > 0) seqlowered = GetWepAnim(curweap,seq,"ACT_VM_IDLE");
									else
									{
										seqlowered = GetWepAnim(curweap,seq,"ACT_VM_IDLE_EMPTY");
										if (seqlowered == 0)
										{
											seqlowered = GetWepAnim(curweap,seq,"ACT_VM_IDLE");
										}
									}
								}
								else seqlowered = GetWepAnim(curweap,seq,"ACT_VM_IDLE");
							}
							if ((StrEqual(curweap,"weapon_tau",false)) && ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)))
							{
								if (TauCharge[client]) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
								else SetEntProp(viewmdl,Prop_Send,"m_nSequence",10);
							}
							else SetEntProp(viewmdl,Prop_Send,"m_nSequence",seqlowered);
						}
					}
				}
			}
		}
	}
	else if (FindStringInArray(sweps,curweap) != -1)
	{
		int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
		if (viewmdl != -1)
		{
			int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
			//Need to convert all of these to GetWepAnim ACT_VM_LOWERED
			if ((StrEqual(curweap,"weapon_flaregun",false)) || (StrEqual(curweap,"weapon_medkit",false)))
			{
				if (seq != 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
			}
			else if (StrEqual(curweap,"weapon_manhack",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_manhackgun",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_manhacktoss",false))
			{
				int effects = GetEntProp(viewmdl,Prop_Send,"m_fEffects");
				if (!(effects & 32))
				{
					effects |= 32;
					SetEntProp(viewmdl,Prop_Send,"m_fEffects",effects);
				}
			}
			else if (StrEqual(curweap,"weapon_immolator",false))
			{
				int effects = GetEntProp(viewmdl,Prop_Send,"m_fEffects");
				if (!(effects & 32))
				{
					effects |= 32;
					SetEntProp(viewmdl,Prop_Send,"m_fEffects",effects);
				}
			}
			else if (StrEqual(curweap,"weapon_snark",false))
			{
				if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
			}
			else if (StrEqual(curweap,"weapon_mp5",false))
			{
				if (seq != 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
			}
			else if ((StrEqual(curweap,"weapon_sl8",false)) || (StrEqual(curweap,"weapon_cguard",false)) || (StrEqual(curweap,"weapon_g36c",false)))
			{
				int effects = GetEntProp(viewmdl,Prop_Send,"m_fEffects");
				if (!(effects & 32))
				{
					effects |= 32;
					SetEntProp(viewmdl,Prop_Send,"m_fEffects",effects);
				}
			}
			else if (StrEqual(curweap,"weapon_m4",false))
			{
				SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
			}
			else if (StrEqual(curweap,"weapon_oicw",false))
			{
				if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
			}
			else if (StrEqual(curweap,"weapon_glock",false))
			{
				if (weap != -1)
				{
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
					{
						if (seq != 8) SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
					}
					else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
					{
						if (seq != 10) SetEntProp(viewmdl,Prop_Send,"m_nSequence",10);
					}
					else
					{
						if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
					}
				}
			}
			else if (StrEqual(curweap,"weapon_tripmine",false))
			{
				if (weap != -1)
				{
					int mdlseq = 7;
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_tripmine.mdl",false)) mdlseq = 5;
					if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
				}
			}
			else if (StrEqual(curweap,"weapon_satchel",false))
			{
				if (weap != -1)
				{
					int mdlseq = 5;
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_satchel.mdl",false)) mdlseq = 3;
					if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
				}
			}
			else if (StrEqual(curweap,"weapon_handgrenade",false))
			{
				int mdlseq = 6;
				if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
			}
			else if (StrEqual(curweap,"weapon_gauss",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_tau",false))
			{
				if ((StrEqual(curweap,"weapon_tau",false)) && ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c4",false) != -1)))
				{
					if (seq != 10) SetEntProp(viewmdl,Prop_Send,"m_nSequence",10);
				}
				else if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if ((StrEqual(curweap,"weapon_gluon",false)) || (StrEqual(curweap,"weapon_goop",false)))
			{
				if (seq != 3) SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
			}
			else if ((StrContains(curweap,"custom_",false) == 0) || (StrContains(custweap,"kzsmodifiedweaps/",false) == 0))
			{
				int effects = GetEntProp(viewmdl,Prop_Send,"m_fEffects");
				if (!(effects & 32))
				{
					effects |= 32;
					SetEntProp(viewmdl,Prop_Send,"m_fEffects",effects);
				}
			}
		}
	}
	if (setbuttons) g_LastButtons[client] = buttons;
	return Plugin_Continue;
}

public Action resetinreload(Handle timer, int weap)
{
	if (IsValidEntity(weap))
	{
		char curweap[64];
		GetEntityClassname(weap,curweap,sizeof(curweap));
		if (HasEntProp(weap,Prop_Data,"m_bInReload")) SetEntProp(weap,Prop_Data,"m_bInReload",0);
		if (StrEqual(curweap,"weapon_mp5",false))
		{
			SetEntProp(weap,Prop_Data,"m_iClip1",30);
			int owner = GetEntPropEnt(weap,Prop_Data,"m_hOwner");
			if ((owner > 0) && (owner < MaxClients+1) && (IsValidEntity(owner)))
			{
				int viewmdl = GetEntPropEnt(owner,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
				{
					SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				}
			}
		}
		else if (StrEqual(curweap,"weapon_bhg",false))
		{
			int owner = GetEntPropEnt(weap,Prop_Data,"m_hOwner");
			if ((owner > 0) && (owner < MaxClients+1) && (IsValidEntity(owner)))
			{
				if (AmmArr[owner][1] != GetEntProp(owner,Prop_Send,"m_iAmmo",_,12)) AmmArr[owner][1] = GetEntProp(owner,Prop_Send,"m_iAmmo",_,12);
				if (AmmArr[owner][1]-1 > -1)
				{
					AmmArr[owner][0] = GetEntProp(weap,Prop_Data,"m_iClip1")+1;
					AmmArr[owner][1]--;
					SetEntProp(weap,Prop_Data,"m_iClip1",AmmArr[owner][0]);
					SetEntProp(owner,Prop_Data,"m_iAmmo",AmmArr[owner][1],_,12);
				}
				int viewmdl = GetEntPropEnt(owner,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
				{
					SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				}
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponUse);
		flareammo[client] = 5;
		ManHackAmmo[client] = 1;
		CGuardAmm[client] = 5;
		if (StrContains(mapbuf,"ptsd_2_",false) == 0) EnergyAmm[client] = 100;
		else EnergyAmm[client] = 50;
		HiveAmm[client] = 100;
		SnarkAmm[client] = 5;
		SatchelAmm[client] = 2;
		TripMineAmm[client] = 2;
		Ammo12Reset[client] = 0;
		Ammo24Reset[client] = 0;
		GetClientAuthId(client,AuthId_Steam2,SteamID[client],32-1);
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if ((client > 0) && (client < MaxClients+1))
	{
		flareammo[client] = 5;
		ManHackAmmo[client] = 1;
		CGuardAmm[client] = 5;
		EnergyAmm[client] = 40;
		HiveAmm[client] = 100;
		SnarkAmm[client] = 5;
		SatchelAmm[client] = 2;
		TripMineAmm[client] = 2;
		Ammo3Reset[client] = 0;
		Ammo12Reset[client] = 0;
		Ammo24Reset[client] = 0;
		AmmArr[client][1] = 3;
		if (IsValidEntity(client)) CreateTimer(1.0,spawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action spawnpost(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		if (IsPlayerAlive(client))
		{
			int weapon = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(weapon)) OnWeaponUse(client,weapon);
		}
		else if (IsClientConnected(client)) CreateTimer(0.5,spawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action OnWeaponUse(int client, int weapon)
{
	if (IsValidEntity(client))
	{
		if (Ammo3Reset[client] > 0)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo3Reset[client],_,3);
			Ammo3Reset[client] = 0;
		}
		if (Ammo12Reset[client] > 0)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo12Reset[client],_,12);
			Ammo12Reset[client] = 0;
		}
		if (Ammo24Reset[client] > -1)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo24Reset[client],_,24);
			Ammo24Reset[client] = -1;
		}
		if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)) && (CLInScope[client] == SL8Scope))
		{
			AcceptEntityInput(SL8Scope,"StopOverlays",client);
			CLInScope[client] = 0;
		}
		if ((OICWScope != 0) && (IsValidEntity(OICWScope)) && (CLInScope[client] == OICWScope))
		{
			AcceptEntityInput(OICWScope,"StopOverlays",client);
			CLInScope[client] = 0;
		}
		TauCharge[client] = 0;
		InIronSights[client] = false;
		if (iWeapList == -1) iWeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (iWeapList != -1)
		{
			int nIndx = 1;
			if (bCSS) nIndx = 2;
			char szWeapCls[64];
			for (int j; j<104; j += 4)
			{
				int tmpi = GetEntDataEnt2(client,iWeapList + j);
				if (tmpi != -1)
				{
					if (HasEntProp(tmpi,Prop_Data,"m_nViewModelIndex"))
					{
						if (GetEntProp(tmpi,Prop_Data,"m_nViewModelIndex") == nIndx)
						{
							SetEntProp(tmpi,Prop_Data,"m_nViewModelIndex",0);
							ChangeEdictState(tmpi);
							GetEntityClassname(tmpi,szWeapCls,sizeof(szWeapCls));
							if (FindStringInArray(sweps,szWeapCls) != -1) SetEntProp(tmpi,Prop_Data,"m_fEffects",161);
						}
					}
				}
			}
		}
		int fov = GetEntProp(client,Prop_Send,"m_iFOV");
		if ((fov < 75) && (fov != 0))
		{
			SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
			SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
			SetEntProp(client,Prop_Send,"m_iFOV",90);
			SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
		}
		if ((IsValidEntity(weapon)) && (weapon != -1))
		{
			char weapname[64];
			char weapresp[64];
			//GetEntityClassname(weapon,weapname,sizeof(weapname));
			GetEntPropString(weapon,Prop_Data,"m_iClassname",weapname,sizeof(weapname));
			GetEntPropString(weapon,Prop_Data,"m_iszResponseContext",weapresp,sizeof(weapresp));
			if ((FindStringInArray(hBaseWeapons,weapname) != -1) && (strlen(weapresp) < 7)) return Plugin_Continue;
			if ((StrEqual(weapname,"weapon_snark",false)) || (StrEqual(weapname,"weapon_satchel",false)) || (StrEqual(weapname,"weapon_frag",false)) || (StrEqual(weapname,"weapon_tripmine",false)))
			{
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1) SetEntProp(viewmdl,Prop_Send,"m_nBody",1);
			}
			if (StrEqual(weapname,"weapon_flaregun",false))
			{
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",0);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				//flSetupWeapon[weapon] = GetGameTime()+0.1;
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,3);
				if (ammover > 0)
				{
					Ammo3Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",flareammo[client],_,3);
				}
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				//SetEntProp(weapon,Prop_Data,"m_iParentAttachment",3);
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
				{
					float angset[3];
					angset[0] = -90.0;
					angset[1] = 90.0;
					SetEntPropVector(weapon,Prop_Data,"m_angRotation",angset);
				}
			}
			else if ((StrEqual(weapname,"weapon_manhacktoss",false)) || (StrEqual(weapname,"weapon_manhack",false)))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",0);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				//SetEntProp(weapon,Prop_Data,"m_iParentAttachment",3);
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				float angset[3];
				angset[0] = 90.0;
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if ((CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
						CreateTimer(0.1,resetviewmdl,viewmdl);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
			}
			else if ((StrEqual(weapname,"weapon_medkit",false)) || (StrEqual(weapname,"weapon_healer",false)))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",1);
				SetEntProp(weapon,Prop_Data,"m_bFireOnEmpty",1);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				SetEntProp(weapon,Prop_Data,"m_iClip1",1);
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Send,"m_iAmmo",1,_,24);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_cguard",false))
			{
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_gluon",false))
			{
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",0);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 35.0;
				orgreset[1] = 22.0;
				orgreset[2] = -20.0;
				angreset[0] = -50.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.2,resetviewmdl,viewmdl);
				if (FindStringInArray(precachedarr,"weapon_gluon") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/gluon/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_gluon");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
			}
			else if (StrEqual(weapname,"weapon_molotov",false))
			{
				WeapAttackSpeed[client] = GetTickedTime()+0.2;
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",0);
				float orgreset[3];
				orgreset[2] = 2.5;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.2,resetviewmdl,viewmdl);
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
			}
			else if (StrEqual(weapname,"weapon_goop",false))
			{
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.7);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.2,resetviewmdl,viewmdl);
				if (FindStringInArray(precachedarr,"weapon_goop") == -1)
				{
					PrecacheSound("physics/goop/goop_loop.wav",true);
					PushArrayString(precachedarr,"weapon_goop");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
			}
			else if (StrEqual(weapname,"weapon_bhg",false))
			{
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.7);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.2,resetviewmdl,viewmdl);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",AmmArr[client][1]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",AmmArr[client][1]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",AmmArr[client][0],_,12);
				}
				if (FindStringInArray(precachedarr,"weapon_bhg") == -1)
				{
					PrecacheSound("weapons/smg1/switch_single.wav",true);
					PrecacheSound("weapons/crossbow/hit1.wav",true);
					PushArrayString(precachedarr,"weapon_bhg");
				}
			}
			else if ((StrEqual(weapname,"weapon_tau",false)) || (StrEqual(weapname,"weapon_gauss",false)))
			{
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				float orgreset[3];
				float angreset[3];
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (StrEqual(mdl,"models/v_gauss.mdl",false))
				{
					orgreset[2] = -5.0;
					angreset[0] = 10.0;
					angreset[1] = 180.0;
					SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.9);
				}
				else
				{
					orgreset[2] = -5.0;
					angreset[0] = -20.0;
				}
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if (FindStringInArray(precachedarr,"weapon_tau") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/tau/");
					recursion(searchprecache);
					if (FileExists("sound/ambience/pulsemachine.wav",true,NULL_STRING)) PrecacheSound("ambience\\pulsemachine.wav",true);
					if (FileExists("sound/weapons/gauss2.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss2.wav",true);
					if (FileExists("sound/weapons/gauss/fire1.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss\\fire1.wav",true);
					if (FileExists("sound/weapons/gauss/chargeloop.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss\\chargeloop.wav",true);
					if (FileExists("sound/weapons/tau/single.wav",true,NULL_STRING)) PrecacheSound("weapons\\tau\\single.wav",true);
					if (FileExists("sound/weapons/tau/single2.wav",true,NULL_STRING)) PrecacheSound("weapons\\tau\\single2.wav",true);
					PushArrayString(precachedarr,"weapon_tau");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
			}
			else if (StrEqual(weapname,"weapon_glock",false))
			{
				if (FindStringInArray(precachedarr,"weapon_glock") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
					recursion(searchprecache);
					PrecacheSound("weapons/pistol/pistol_fire2.wav",true);
					PrecacheSound("weapons/pistol/pistol_reload1.wav",true);
					if (FileExists("sound/weapons/pl_gun1.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun1.wav",true);
					if (FileExists("sound/weapons/pl_gun2.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun2.wav",true);
					if (FileExists("sound/weapons/pl_gun3.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun3.wav",true);
					if (FileExists("sound/weapons/reload1.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\reload1.wav",true);
						PrecacheSound("weapons\\reload2.wav",true);
						PrecacheSound("weapons\\reload3.wav",true);
					}
					if (FileExists("sound/weapons/pistol/glock_fire.wav",true,NULL_STRING))
					{
						Format(searchprecache,sizeof(searchprecache),"sound/weapons/pistol/");
						recursion(searchprecache);
					}
					PushArrayString(precachedarr,"weapon_glock");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int bodygrp = GetEntProp(viewmdl,Prop_Send,"m_nBody");
						if (bodygrp != CLAttachment[client])
						{
							SetEntProp(viewmdl,Prop_Send,"m_nBody",CLAttachment[client]);
						}
					}
				}
			}
			else if ((StrEqual(weapname,"weapon_mp5",false)) || (StrEqual(weapname,"weapon_m4",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_mp5") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/mp5/");
					recursion(searchprecache);
					PrecacheSound("weapons/smg1/smg1_fire1.wav",true);
					PrecacheSound("weapons/smg1/smg1_reload.wav",true);
					if (FileExists("sound/weapons/hks1.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\hks1.wav",true);
						PrecacheSound("weapons\\hks2.wav",true);
						PrecacheSound("weapons\\hks3.wav",true);
						PrecacheSound("weapons\\reload3.wav",true);
					}
					if (FileExists("sound/weapons/m4/m4_fire.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\m4\\m4_reload.wav",true);
						PrecacheSound("weapons\\m4\\m4_altfire.wav",true);
						PrecacheSound("weapons\\m4\\m4_fire.wav",true);
					}
					PushArrayString(precachedarr,"weapon_mp5");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",4);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",9);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_g36c",false))
			{
				if (FindStringInArray(precachedarr,"weapon_g36c") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/g36c/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_g36c");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",1);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",-1);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.3,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_sniperrifle",false))
			{
				if (FindStringInArray(precachedarr,"weapon_sniperrifle") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/sniper/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_sniperrifle");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if ((StrEqual(weapname,"weapon_sl8",false)) || (StrEqual(weapname,"weapon_oicw",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_sl8") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/sl8/");
					recursion(searchprecache);
					PrecacheSound("weapons/smg1/smg1_fire1.wav",true);
					PushArrayString(precachedarr,"weapon_sl8");
				}
				if (FindStringInArray(precachedarr,"weapon_oicw") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/oicw/");
					recursion(searchprecache);
					PrecacheSound("weapons/smg1/smg1_fire1.wav",true);
					PushArrayString(precachedarr,"weapon_oicw");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",4);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",-1);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if ((StrEqual(weapname,"weapon_hivehand",false)) || (StrEqual(weapname,"weapon_hornetgun",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_hivehand") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
					recursion(searchprecache);
					Format(searchprecache,sizeof(searchprecache),"sound/hornet/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_hivehand");
				}
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",HiveAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",HiveAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",1);
				SetEntProp(weapon,Prop_Data,"m_bFireOnEmpty",1);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,24);
				if (ammover > -1)
				{
					Ammo24Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				}
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 5.0;
				orgreset[1] = 3.0;
				angreset[1] = 30.0;
				if (StrEqual(weapname,"weapon_hornetgun",false))
				{
					angreset[1] = 215.0;
					orgreset[0] = 4.0;
					orgreset[1] = 1.0;
					orgreset[2] = -4.0;
					SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.6);
				}
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_snark",false))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",SnarkAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",SnarkAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntPropFloat(weapon,Prop_Data,"m_flTimeWeaponIdle",0.0);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				orgreset[1] = 2.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_satchel",false))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",SatchelAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",SatchelAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				SetVariantString("anim_attachment_LH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 2.7;
				orgreset[1] = 1.0;
				angreset[0] = 90.0;
				angreset[1] = -45.0;
				angreset[2] = 45.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
			}
			else if (StrEqual(weapname,"weapon_tripmine",false))
			{
				if (FindStringInArray(precachedarr,weapname) == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/tripmine/");
					recursion(searchprecache);
					PrecacheSound("weapons\\mine_activate.wav",true);
					PrecacheSound("weapons\\mine_charge.wav",true);
					PrecacheSound("weapons\\mine_deploy.wav",true);
					PushArrayString(precachedarr,weapname);
				}
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",TripMineAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",TripMineAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 2.0;
				orgreset[1] = 3.0;
				orgreset[2] = 1.0;
				angreset[1] = 180.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
			}
			else if (StrEqual(weapname,"weapon_handgrenade",false))
			{
				if (FindStringInArray(precachedarr,weapname) == -1)
				{
					PrecacheSound("weapons\\g_bounce1.wav",true);
					PrecacheSound("weapons\\g_bounce2.wav",true);
					PrecacheSound("weapons\\g_bounce3.wav",true);
					PrecacheSound("weapons\\g_bounce4.wav",true);
					PrecacheSound("weapons\\g_bounce5.wav",true);
					PushArrayString(precachedarr,weapname);
				}
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				SetVariantString("!activator");
				AcceptEntityInput(weapon,"SetParent",client);
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.8);
				float orgreset[3];
				float angreset[3];
				orgreset[1] = 5.0;
				angreset[0] = 30.0;
				angreset[2] = 90.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_357",false))
			{
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",5);
			}
			else if (StrEqual(weapname,"weapon_axe",false))
			{
				if (!bCSS)
				{
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(weapon,"SetParentAttachment");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				float angreset[3];
				angreset[1] = 180.0;
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_colt",false))
			{
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if ((StrEqual(weapname,"weapon_dualmp5k",false)) || (StrEqual(weapname,"weapon_uzi",false)))
			{
				if (StrEqual(weapname,"weapon_uzi",false))
				{
					if (FindStringInArray(precachedarr,"weapon_uzi") == -1)
					{
						char searchprecache[128];
						Format(searchprecache,sizeof(searchprecache),"sound/weapons/uzi/");
						recursion(searchprecache);
						PushArrayString(precachedarr,"weapon_uzi");
					}
				}
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if ((StrContains(weapname,"custom_",false) == 0) || (StrContains(weapresp,"kzsmodifiedweaps/",false) == 0))
			{
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				//m_szAnimExtension on cl
				char basetype[24];
				GetEntPropString(client,Prop_Data,"m_szAnimExtension",basetype,sizeof(basetype));
				if (StrEqual(basetype,"pistol",false))
				{
					if (HasEntProp(weapon,Prop_Data,"m_bLowered")) SetEntProp(weapon,Prop_Data,"m_bLowered",1);
				}
				GetEntPropString(weapon,Prop_Data,"m_iszResponseContext",weapname,sizeof(weapname));
				int findweap = FindStringInArray(swepsweap,weapname);
				if (findweap != -1)
				{
					Handle dp = GetArrayCell(swepsinfo,findweap);
					if (dp != INVALID_HANDLE)
					{
						int read = 0;
						char weapdata[64];
						ResetPack(dp);
						ReadPackString(dp,weapdata,sizeof(weapdata));
						while (!StrEqual(weapdata,"endofpack",false))
						{
							if (StrContains(weapdata,"primary_ammo",false) != -1)
							{
								char tmp[64];
								Format(tmp,sizeof(tmp),"%s",weapdata);
								ReplaceString(tmp,sizeof(tmp),"\"","");
								ReplaceString(tmp,sizeof(tmp),"	"," ");
								TrimString(tmp);
								char fixuptmp[32][128];
								ExplodeString(tmp," ",fixuptmp,32,128,true);
								for (int i = 0;i<5;i++)
								{
									TrimString(fixuptmp[i]);
									if ((strlen(fixuptmp[i]) > 0) && (i > 1))
									{
										Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
									}
								}
								if (StrEqual(fixuptmp[1],"SniperRound",false))
								{
									if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",10);
								}
								else if ((!StrEqual(fixuptmp[1],"None",false)) && (!StrEqual(fixuptmp[1],"Buckshot",false)) && (!StrEqual(fixuptmp[1],"357",false)) && (!StrEqual(fixuptmp[1],"Pistol",false)) && (!StrEqual(fixuptmp[1],"XBowBolt",false)) && (!StrEqual(fixuptmp[1],"AR2",false)) && (!StrEqual(fixuptmp[1],"AR2AltFire",false)) && (!StrEqual(fixuptmp[1],"grenade",false)) && (!StrEqual(fixuptmp[1],"SMG1",false)) && (!StrEqual(fixuptmp[1],"SMG1_Grenade",false)) && (!StrEqual(fixuptmp[1],"rpg_round",false)) && (!StrEqual(fixuptmp[1],"slam",false)))
								{
									if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
								}
								Format(custammtype[weapon],sizeof(custammtype[]),fixuptmp[1]);
								read++;
							}
							else if (StrContains(weapdata,"secondary_ammo",false) != -1)
							{
								char tmp[64];
								Format(tmp,sizeof(tmp),"%s",weapdata);
								ReplaceString(tmp,sizeof(tmp),"\"","");
								ReplaceString(tmp,sizeof(tmp),"	"," ");
								TrimString(tmp);
								char fixuptmp[32][128];
								ExplodeString(tmp," ",fixuptmp,32,128,true);
								for (int i = 0;i<5;i++)
								{
									TrimString(fixuptmp[i]);
									if ((strlen(fixuptmp[i]) > 0) && (i > 1))
									{
										Format(fixuptmp[1],sizeof(fixuptmp[]),"%s",fixuptmp[i]);
									}
								}
								if (StrEqual(fixuptmp[1],"SniperRound",false))
								{
									if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",10);
								}
								else if ((!StrEqual(fixuptmp[1],"None",false)) && (!StrEqual(fixuptmp[1],"Buckshot",false)) && (!StrEqual(fixuptmp[1],"357",false)) && (!StrEqual(fixuptmp[1],"Pistol",false)) && (!StrEqual(fixuptmp[1],"XBowBolt",false)) && (!StrEqual(fixuptmp[1],"AR2",false)) && (!StrEqual(fixuptmp[1],"AR2AltFire",false)) && (!StrEqual(fixuptmp[1],"grenade",false)) && (!StrEqual(fixuptmp[1],"SMG1",false)) && (!StrEqual(fixuptmp[1],"SMG1_Grenade",false)) && (!StrEqual(fixuptmp[1],"rpg_round",false)) && (!StrEqual(fixuptmp[1],"slam",false)))
								{
									if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
								}
								Format(custammtype2[weapon],sizeof(custammtype2[]),fixuptmp[1]);
								read++;
							}
							if (read == 2) break;
							ReadPackString(dp,weapdata,sizeof(weapdata));
						}
					}
				}
			}
			else if (StrEqual(weapname,"weapon_camera",false))
			{
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_immolator",false))
			{
				
			}
			ChangeEdictState(weapon);
		}
	}
	return Plugin_Continue;
}

public Action resetviewmdl(Handle timer, int viewmdl)
{
	if ((IsValidEntity(viewmdl)) && (viewmdl != 0))
	{
		if (HasEntProp(viewmdl,Prop_Data,"m_hOwner"))
		{
			int client = GetEntPropEnt(viewmdl,Prop_Data,"m_hOwner");
			if (IsValidEntity(client))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (IsValidEntity(weap))
				{
					char curweap[24];
					//GetClientWeapon(client,curweap,sizeof(curweap));
					GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
					if (StrEqual(curweap,"weapon_flaregun",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 3)
						{
							flareammo[client]--;
							SetEntProp(weap,Prop_Data,"m_iClip1",1);
							SetEntProp(client,Prop_Data,"m_iAmmo",flareammo[client],_,3);
						}
					}
					if (StrEqual(curweap,"weapon_medkit",false))
					{
						char mdlchk[64];
						GetEntPropString(viewmdl,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
						if (!StrEqual(mdlchk,"models/weapons/v_medkit.mdl",false))
						{
							if (!IsModelPrecached("models/weapons/v_medkit.mdl")) PrecacheModel("models/weapons/v_medkit.mdl",true);
							SetEntityModel(viewmdl,"models/weapons/v_medkit.mdl");
							SetEntityModel(weap,"models/weapons/v_medkit.mdl");
						}
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if ((StrEqual(curweap,"weapon_manhacktoss",false)) || (StrEqual(curweap,"weapon_manhackgun",false)) || (StrEqual(curweap,"weapon_manhack",false)))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 2)
						{
							ManHackAmmo[client]--;
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
							CreateTimer(0.5,resetviewmdl,viewmdl);
							if ((CLManhack[client] == 0) || (!IsValidEntity(CLManhack[client])))
							{
								float Time = GetTickedTime();
								clsummoncdc[client] = Time + 0.5;
								float PlayerOrigin[3];
								float clangles[3];
								GetClientEyeAngles(client, clangles);
								GetClientAbsOrigin(client, PlayerOrigin);
								PlayerOrigin[0] = (PlayerOrigin[0] + (40 * Cosine(DegToRad(clangles[1]))));
								PlayerOrigin[1] = (PlayerOrigin[1] + (40 * Sine(DegToRad(clangles[1]))));
								PlayerOrigin[2] = (PlayerOrigin[2] + 40);
								if ((clsummonfil == 0) || (!IsValidEntity(clsummonfil)))
								{
									clsummonfil = CreateEntityByName("filter_activator_class");
									DispatchKeyValue(clsummonfil,"filterclass","player");
									DispatchKeyValue(clsummonfil,"Negated","1");
									DispatchKeyValue(clsummonfil,"targetname","noplayer");
									DispatchSpawn(clsummonfil);
									ActivateEntity(clsummonfil);
								}
								int stuff = CreateEntityByName("npc_manhack");
								if (stuff != -1)
								{
									TeleportEntity(stuff, PlayerOrigin, clangles, NULL_VECTOR);
									DispatchKeyValue(stuff,"targetname",SteamID[client]);
									DispatchKeyValue(stuff,"spawnflags","65536");
									DispatchKeyValue(stuff,"ignoreclipbrushes","0");
									DispatchKeyValue(stuff,"damagefilter","noplrdmg");
									DispatchSpawn(stuff);
									ActivateEntity(stuff);
									if ((CLManhackRel == 0) || (!IsValidEntity(CLManhackRel)))
									{
										CLManhackRel = CreateEntityByName("ai_relationship");
										DispatchKeyValue(CLManhackRel,"disposition","3");
										DispatchKeyValue(CLManhackRel,"subject",SteamID[client]);
										DispatchKeyValue(CLManhackRel,"target","player");
										DispatchKeyValue(CLManhackRel,"rank","99");
										DispatchKeyValue(CLManhackRel,"reciprocal","1");
										DispatchKeyValue(CLManhackRel,"StartActive","1");
										DispatchSpawn(CLManhackRel);
										ActivateEntity(CLManhackRel);
										AcceptEntityInput(CLManhackRel,"ApplyRelationship");
									}
									else AcceptEntityInput(CLManhackRel,"ApplyRelationship");
									CreateTimer(0.5,unpack,stuff);
									CLManhack[client] = stuff;
								}
							}
						}
						if ((seq >= 4) && (seq <= 6))
						{
							if ((CLManhack[client] == 0) || (!IsValidEntity(CLManhack[client]))) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
							else SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
						}
						if ((seq == 0) && (CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
						}
					}
					else if (StrEqual(curweap,"weapon_gluon",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if ((seq == 0) || (seq == 2))
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
						}
						else SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_handgrenade",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq != 7)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
							//models/grenade.mdl -- starttouch bounce sounds -- env_explosion with ownerset
							//TR, shootvel, clamp max vel
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_satchel",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (SatchelAmm[client] == 0)
						{
							if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
						}
						else if (seq == 2)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_tripmine",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int mdlseq = 6;
						int mdlreset = 9;
						int mdlout = 7;
						char mdl[32];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (StrEqual(mdl,"models/v_tripmine.mdl",false))
						{
							mdlseq = 3;
							mdlreset = 6;
							mdlout = 5;
						}
						if (TripMineAmm[client] == 0)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlout);
						}
						else if (seq == mdlseq)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlreset);
							CreateTripMine(client);
						}
					}
					else if (StrEqual(curweap,"weapon_sl8",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						float Time = GetTickedTime();
						if ((seq == 2) && (WeapSnd[client] < Time))
						{
							EmitSoundToAll("weapons\\sl8\\sl8_magin.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							CreateTimer(0.95,resetviewmdl,viewmdl);
							WeapSnd[client] = Time+1.0;
						}
						else
						{
							EmitSoundToAll("weapons\\sl8\\sl8_boltback.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							SetEntProp(weap,Prop_Data,"m_bInReload",0);
							int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
							SetEntProp(weap,Prop_Data,"m_iClip1",20);
							int ammo = GetEntProp(client,Prop_Send,"m_iAmmo",_,4);
							SetEntProp(client,Prop_Data,"m_iAmmo",ammo-(20-clip),_,4);
						}
					}
					else if (StrEqual(curweap,"weapon_oicw",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 5)
						{
							SetEntProp(weap,Prop_Data,"m_bInReload",0);
							int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
							SetEntProp(weap,Prop_Data,"m_iClip1",20);
							int ammo = GetEntProp(client,Prop_Send,"m_iAmmo",_,4);
							SetEntProp(client,Prop_Data,"m_iAmmo",ammo-(20-clip),_,4);
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_sniperrifle",false))
					{
						SetEntProp(weap,Prop_Data,"m_bInReload",0);
						SetEntProp(weap,Prop_Data,"m_iClip1",1);
						int ammo = GetEntProp(client,Prop_Send,"m_iAmmo",_,10);
						SetEntProp(client,Prop_Data,"m_iAmmo",ammo-1,_,10);
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_m4",false))
					{
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
					}
					else if (StrEqual(curweap,"weapon_tau",false))
					{
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
					}
					else if (StrEqual(curweap,"weapon_glock",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						char mdl[64];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if ((seq == 9) && (StrEqual(mdl,"models/v_9mmhandgun.mdl",false)))
						{
							int bodygrp = GetEntProp(viewmdl,Prop_Send,"m_nBody");
							if (bodygrp == 1)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nBody",0);
								CLAttachment[client] = 0;
							}
							else
							{
								SetEntProp(viewmdl,Prop_Send,"m_nBody",1);
								CLAttachment[client] = 1;
							}
						}
						else SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_uzi",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						else if ((seq == 8) || (seq == 10)) SetEntProp(viewmdl,Prop_Send,"m_nSequence",2);
						else SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_snark",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (SnarkAmm[client] == 0)
						{
							if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_colt",false))
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_empty.wav");
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				}
			}
		}
	}
}

public Action resetvmspec(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int viewmdl = ReadPackCell(dp);
		int seq = ReadPackCell(dp);
		int weap = ReadPackCell(dp);
		int maxclip = ReadPackCell(dp);
		char passedweap[64];
		ReadPackString(dp,passedweap,sizeof(passedweap));
		int singlereload = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(viewmdl)) && (IsValidEntity(weap)))
		{
			char curweap[64];
			GetEntPropString(weap,Prop_Data,"m_iszResponseContext",curweap,sizeof(curweap));
			if (StrEqual(curweap,passedweap,false))
			{
				SetEntProp(viewmdl,Prop_Send,"m_nSequence",seq);
				int client = GetEntPropEnt(viewmdl,Prop_Data,"m_hOwner");
				if (IsValidEntity(client))
				{
					int ammtype = GetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType");
					int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
					int ammset = GetEntProp(client,Prop_Send,"m_iAmmo",_,ammtype)-maxclip+curclip;
					if (ammset < 0)
					{
						maxclip+=ammset;
						ammset = 0;
					}
					SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
					if (HasEntProp(weap,Prop_Data,"m_bInReload")) SetEntProp(weap,Prop_Data,"m_bInReload",0);
					SetEntProp(client,Prop_Data,"m_iAmmo",ammset,_,ammtype);
					if (singlereload) ReloadCustomWeap(client,weap,curweap,true);
				}
			}
		}
	}
}

public Action resetvmtoidle(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int viewmdl = ReadPackCell(dp);
		int seq = ReadPackCell(dp);
		int weap = ReadPackCell(dp);
		char passedweap[64];
		ReadPackString(dp,passedweap,sizeof(passedweap));
		CloseHandle(dp);
		if ((IsValidEntity(viewmdl)) && (IsValidEntity(weap)))
		{
			char curweap[64];
			GetEntPropString(weap,Prop_Data,"m_iszResponseContext",curweap,sizeof(curweap));
			if (StrEqual(curweap,passedweap,false))
			{
				SetEntProp(viewmdl,Prop_Send,"m_nSequence",seq);
			}
		}
	}
}

public Action resetviewindex(Handle timer, int weapon)
{
	if (IsValidEntity(weapon))
	{
		if (HasEntProp(weapon,Prop_Data,"m_nViewModelIndex"))
		{
			if (bCSS) SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",2);
			else SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",1);
			char szWeapCls[32];
			GetEntityClassname(weapon,szWeapCls,sizeof(szWeapCls));
			if (StrEqual(szWeapCls,"weapon_tau",false))
			{
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
			}
			else if (StrEqual(szWeapCls,"weapon_gauss",false))
			{
				if (StrContains(mapbuf,"ptsd_2",false) == 0)
				{
					if (HasEntProp(weapon,Prop_Data,"m_hOwner"))
					{
						int iEnt = GetEntPropEnt(weapon,Prop_Data,"m_hOwner");
						if ((IsValidEntity(iEnt)) && (iEnt > 0) && (iEnt < MaxClients+1))
						{
							iEnt = GetEntPropEnt(iEnt,Prop_Data,"m_hViewModel");
							if (iEnt != -1) SetEntProp(iEnt,Prop_Send,"m_nSequence",0);
						}
					}
				}
			}
			ChangeEdictState(weapon);
		}
	}
}

public Action cstr(int client)
{
	if (client == 0)
		return Plugin_Handled;
	float Location[3];
	float fhitpos[3];
	float clangles[3];
	GetClientEyeAngles(client, clangles);
	GetClientEyePosition(client, Location);
	Location[0] = (Location[0] + (25 * Cosine(DegToRad(clangles[1]))));
	Location[1] = (Location[1] + (25 * Sine(DegToRad(clangles[1]))));
	//Location[2] = (Location[2] + 10);
	Handle hhitpos = INVALID_HANDLE;
	TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
	TR_GetEndPosition(fhitpos,hhitpos);
	fhitpos[2] = (fhitpos[2] + 15);
	CloseHandle(hhitpos);
	TE_SetupBeamPoints(Location, fhitpos, beamindx, haloindx, 1, 1, 1.2, 10.0, 10.0, 5, 20.0, {255, 255, 255, 255}, 1);
	TE_SendToAll();
	PrecacheSound("npc/strider/charging.wav");
	EmitSoundToAll("npc/strider/charging.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	TE_SetupBeamRingPoint(Location, 1.0, 100.0, mdlus, mdlus3, 0, 10, 1.2, 20.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	int endpointe = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(endpointe,Location,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpointe,"scale","2.0");
	DispatchKeyValue(endpointe,"spawnflags","2");
	DispatchSpawn(endpointe);
	ActivateEntity(endpointe);
	SetVariantFloat(0.5);
	AcceptEntityInput(endpointe,"StartCharge");
	int entindx = EntIndexToEntRef(endpointe);
	CreateTimer(1.0,cleanup,entindx);
	Handle dp = CreateDataPack();
	WritePackCell(dp,client);
	WritePackFloat(dp,fhitpos[0]);
	WritePackFloat(dp,fhitpos[1]);
	WritePackFloat(dp,fhitpos[2]);
	CreateTimer(1.2,explcstr,dp);
	return Plugin_Handled;
}

public Action explcstr(Handle timer, Handle dp)
{
	if (dp == INVALID_HANDLE) return Plugin_Handled;
	ResetPack(dp);
	int client = ReadPackCell(dp);
	float fhitpos[3];
	fhitpos[0] = ReadPackFloat(dp);
	fhitpos[1] = ReadPackFloat(dp);
	fhitpos[2] = ReadPackFloat(dp);
	CloseHandle(dp);
	//TE_SetupGlowSprite(fhitpos,mdlus,0.5,10.0,50)
	//TE_SendToAll();
	TE_SetupBeamRingPoint(fhitpos, 16.0, 300.0, mdlus, mdlus3, 0, 2, 0.3, 128.0, 0.0, {255, 255, 255, 24}, 128, FBEAM_SHADEOUT);
	TE_SendToAll();
	float damageForce[3];
	damageForce[0]+=40.0;
	damageForce[1]+=40.0;
	damageForce[2]+=40.0;
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_dynamic",false) != -1) || (StrContains(clsname,"prop_physics",false) != -1))
			{
				float entpos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				float chkdist = GetVectorDistance(entpos,fhitpos,false);
				if ((RoundFloat(chkdist) < 150) && (!CheckNPCAlly(clsname,i)) && (IsValidEntity(i)))
				{
					SDKHooks_TakeDamage(i,client,client,300.0,DMG_BLAST|DMG_DISSOLVE,-1,damageForce,fhitpos);
				}
				else if (CheckNPCAlly(clsname,i))
				{
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				}
			}
			else if (StrEqual(clsname,"player",false))
			{
				float entpos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				float chkdist = GetVectorDistance(entpos,fhitpos,false);
				if ((RoundFloat(chkdist) < 150) && (IsValidEntity(i)) && (IsPlayerAlive(i)))
				{
					if (friendlyfire)
						SDKHooks_TakeDamage(i,client,client,300.0,DMG_BLAST|DMG_DISSOLVE,-1,damageForce,fhitpos);
				}
			}
		}
	}
	int endpointe = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(endpointe,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpointe,"scale","3.5");
	DispatchKeyValue(endpointe,"spawnflags","2");
	DispatchSpawn(endpointe);
	ActivateEntity(endpointe);
	int entindx = EntIndexToEntRef(endpointe);
	CreateTimer(0.4,cleanup,entindx);
	int endpoint = CreateEntityByName("env_explosion");
	TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpoint,"imagnitude","300");
	DispatchKeyValue(endpoint,"targetname","syn_stricann");
	DispatchKeyValue(endpoint,"iradiusoverride","150");
	DispatchKeyValue(endpoint,"spawnflags","348");
	DispatchKeyValue(endpoint,"fireballsprite","effects/strider_pinch_dudv.vmt");
	DispatchSpawn(endpoint);
	ActivateEntity(endpoint);
	AcceptEntityInput(endpoint,"Explode");
	PrecacheSound("npc/strider/fire.wav");
	EmitSoundToAll("npc/strider/fire.wav", endpoint, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	AcceptEntityInput(endpoint,"kill");
	return Plugin_Handled;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	char targn[32];
	GetEntPropString(attacker,Prop_Data,"m_iName",targn,sizeof(targn));
	if (StrEqual(targn,"syn_stricann",false))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool ManHackGo(int client)
{
	if ((CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
	{
		float Time = GetTickedTime();
		if (clsummoncdc[client] >= Time) return false;
		float PlayerOrigin[3];
		float clangles[3];
		float fhitpos[3];
		GetClientEyeAngles(client, clangles);
		GetClientAbsOrigin(client, PlayerOrigin);
		PlayerOrigin[0] = (PlayerOrigin[0] + (40 * Cosine(DegToRad(clangles[1]))));
		PlayerOrigin[1] = (PlayerOrigin[1] + (40 * Sine(DegToRad(clangles[1]))));
		PlayerOrigin[2] = (PlayerOrigin[2] + 40);
		Handle hhitpos = INVALID_HANDLE;
		TR_TraceRay(PlayerOrigin,clangles,MASK_SHOT,RayType_Infinite);
		TR_GetEndPosition(fhitpos,hhitpos);
		float chkdist = GetVectorDistance(PlayerOrigin,fhitpos,false);
		int cltarg = GetClientAimTarget(client, false);
		if ((RoundFloat(chkdist) <= 1000) && (IsValidEntity(cltarg)) && (cltarg > MaxClients))
		{
			char clsnam[32];
			GetEntityClassname(cltarg, clsnam, sizeof(clsnam));
			if (StrContains(clsnam,"npc_",false) != -1)
			{
				findsummonstargs(MaxClients+1,"npc_bullseye",client);
				if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
					AcceptEntityInput(clsummontarg[client],"kill");
				char authstrtarg[36];
				Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
				if (clsummonfil == 0)
				{
					clsummonfil = CreateEntityByName("filter_activator_class");
					DispatchKeyValue(clsummonfil,"filterclass","player");
					DispatchKeyValue(clsummonfil,"Negated","1");
					DispatchKeyValue(clsummonfil,"targetname","noplayer");
					DispatchSpawn(clsummonfil);
					ActivateEntity(clsummonfil);
				}
				char targn[64];
				GetEntPropString(cltarg,Prop_Data,"m_iName",targn,sizeof(targn));
				if (strlen(targn) < 1)
				{
					SetVariantString("targetname sxpmtemp");
					AcceptEntityInput(cltarg,"AddOutput");
					Format(targn,sizeof(targn),"sxpmtemp");
				}
				int gototarg = CreateEntityByName("aiscripted_schedule");
				DispatchKeyValue(gototarg,"targetname",authstrtarg);
				DispatchKeyValue(gototarg,"m_iszEntity",SteamID[client]);
				DispatchKeyValue(gototarg,"m_flRadius","0");
				DispatchKeyValue(gototarg,"forcestate","3");
				DispatchKeyValue(gototarg,"schedule","6");
				DispatchKeyValue(gototarg,"goalent",targn);
				DispatchSpawn(gototarg);
				ActivateEntity(gototarg);
				AcceptEntityInput(gototarg,"StartSchedule");
				//npc_enemyfinder
			}
		}
		else if (RoundFloat(chkdist) <= 1000)
		{
			findsummonstargs(MaxClients+1,"npc_bullseye",client);
			if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
				AcceptEntityInput(clsummontarg[client],"kill");
			char authstrtarg[36];
			Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
			if (clsummonfil == 0)
			{
				clsummonfil = CreateEntityByName("filter_activator_class");
				DispatchKeyValue(clsummonfil,"filterclass","player");
				DispatchKeyValue(clsummonfil,"Negated","1");
				DispatchKeyValue(clsummonfil,"targetname","noplayer");
				DispatchSpawn(clsummonfil);
				ActivateEntity(clsummonfil);
			}
			int gototarg = CreateEntityByName("npc_bullseye");
			TeleportEntity(gototarg, fhitpos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(gototarg,"targetname",authstrtarg);
			DispatchKeyValue(gototarg,"health","1");
			DispatchKeyValue(gototarg,"spawnflags","65536");
			DispatchKeyValue(gototarg,"damagefilter","noplayer");
			DispatchSpawn(gototarg);
			ActivateEntity(gototarg);
			int changetarg = CreateEntityByName("ai_changetarget");
			DispatchKeyValue(changetarg,"target",SteamID[client]);
			DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
			DispatchSpawn(changetarg);
			ActivateEntity(changetarg);
			AcceptEntityInput(changetarg,"Activate");
			int stuffrel = CreateEntityByName("ai_relationship");
			DispatchKeyValue(stuffrel,"disposition","1");
			DispatchKeyValue(stuffrel,"subject",SteamID[client]);
			DispatchKeyValue(stuffrel,"target",authstrtarg);
			DispatchKeyValue(stuffrel,"rank","99");
			DispatchKeyValue(stuffrel,"reciprocal","1");
			DispatchKeyValue(stuffrel,"StartActive","1");
			DispatchSpawn(stuffrel);
			ActivateEntity(stuffrel);
			AcceptEntityInput(stuffrel,"ApplyRelationship");
			int entindx = EntIndexToEntRef(changetarg);
			CreateTimer(0.1,cleanup,entindx);
			clsummontarg[client] = gototarg;
		}
		else
		{
			if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
				AcceptEntityInput(clsummontarg[client],"kill");
			char authstrtarg[36];
			Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
			if (clsummonfil == 0)
			{
				clsummonfil = CreateEntityByName("filter_activator_class");
				DispatchKeyValue(clsummonfil,"filterclass","player");
				DispatchKeyValue(clsummonfil,"Negated","1");
				DispatchKeyValue(clsummonfil,"targetname","noplayer");
				DispatchSpawn(clsummonfil);
				ActivateEntity(clsummonfil);
			}
			int gototarg = CreateEntityByName("npc_bullseye");
			TeleportEntity(gototarg, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(gototarg,"targetname",authstrtarg);
			DispatchKeyValue(gototarg,"health","1");
			DispatchKeyValue(gototarg,"spawnflags","65536");
			DispatchKeyValue(gototarg,"damagefilter","noplayer");
			DispatchSpawn(gototarg);
			ActivateEntity(gototarg);
			int changetarg = CreateEntityByName("ai_changetarget");
			DispatchKeyValue(changetarg,"target",SteamID[client]);
			DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
			DispatchSpawn(changetarg);
			ActivateEntity(changetarg);
			AcceptEntityInput(changetarg,"Activate");
			int stuffrel = CreateEntityByName("ai_relationship");
			DispatchKeyValue(stuffrel,"disposition","1");
			DispatchKeyValue(stuffrel,"subject",SteamID[client]);
			DispatchKeyValue(stuffrel,"target",authstrtarg);
			DispatchKeyValue(stuffrel,"rank","99");
			DispatchKeyValue(stuffrel,"reciprocal","1");
			DispatchKeyValue(stuffrel,"StartActive","1");
			DispatchSpawn(stuffrel);
			ActivateEntity(stuffrel);
			AcceptEntityInput(stuffrel,"ApplyRelationship");
			int entindx = EntIndexToEntRef(changetarg);
			CreateTimer(0.1,cleanup,entindx);
			clsummontarg[client] = gototarg;
		}
		clsummoncdc[client] = Time + 1.0;
	}
	return true;
}

public Action findsummonstargs(int ent, char[] clsname, int client)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char prevtmp[48];
		GetEntPropString(thisent,Prop_Data,"m_iName",prevtmp,sizeof(prevtmp));
		if (StrContains(prevtmp,SteamID[client],false) != -1)
		{
			AcceptEntityInput(thisent,"kill");
			clsummontarg[client] = 0;
		}
		findsummonstargs(thisent++,clsname,client++);
	}
	return Plugin_Handled;
}

public Action unpack(Handle timer,any stuff)
{
	if (IsValidEntity(stuff))
		AcceptEntityInput(stuff,"Unpack");
}

public Action cleanup(Handle timer, int changetarg)
{
	int entindx = EntRefToEntIndex(changetarg);
	if ((IsValidEntity(entindx)) && (entindx != 0) && (entindx > MaxClients))
		AcceptEntityInput(entindx,"kill");
}

public Action chkdisttargs(Handle timer)
{
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientInGame(i))
			{
				char curweap[32];
				GetClientWeapon(i,curweap,sizeof(curweap));
				if (FindStringInArray(sweps,curweap) != -1)
				{
					if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
					{
						int weap = GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char mdl[64];
							float orgreset[3];
							float angreset[3];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_gauss.mdl",false))
							{
								orgreset[2] = -5.0;
								angreset[0] = 10.0;
								angreset[1] = 180.0;
							}
							else
							{
								orgreset[2] = -5.0;
								angreset[0] = -20.0;
							}
							if (!bCSS)
							{
								SetVariantString("anim_attachment_RH");
								AcceptEntityInput(weap,"SetParentAttachment");
							}
							SetEntPropVector(weap,Prop_Data,"m_vecOrigin",orgreset);
							SetEntPropVector(weap,Prop_Data,"m_angRotation",angreset);
						}
					}
				}
				if ((CLManhack[i] != 0) && (IsValidEntity(CLManhack[i])) && (clsummontarg[i] != 0) && (IsValidEntity(clsummontarg[i])))
				{
					char summoncls[32];
					GetEntityClassname(CLManhack[i],summoncls, sizeof(summoncls));
					char summontcls[32];
					GetEntityClassname(clsummontarg[i],summontcls, sizeof(summontcls));
					if ((StrEqual(summoncls,"npc_manhack",false)) && (StrEqual(summontcls,"npc_bullseye",false)))
					{
						float manhack[3];
						float target[3];
						GetEntPropVector(CLManhack[i],Prop_Send,"m_vecOrigin",manhack);
						GetEntPropVector(clsummontarg[i],Prop_Send,"m_vecOrigin",target);
						float chkdist = GetVectorDistance(manhack,target,false);
						int held = GetEntProp(CLManhack[i],Prop_Data,"m_bHeld");
						if ((RoundFloat(chkdist) <= 100) || (held != 0))
						{
							AcceptEntityInput(clsummontarg[i],"kill");
							clsummontarg[i] = 0;
						}
					}
					else
					{
						CLManhack[i] = 0;
						clsummontarg[i] = 0;
					}
				}
				else if ((CLManhack[i] != 0) && (IsValidEntity(CLManhack[i])))
				{
					char summoncls[32];
					GetEntityClassname(CLManhack[i],summoncls, sizeof(summoncls));
					if (StrEqual(summoncls,"npc_manhack",false))
					{
						float PlayerOrigin[3];
						float manhack[3];
						GetClientAbsOrigin(i, PlayerOrigin);
						GetEntPropVector(CLManhack[i],Prop_Send,"m_vecOrigin",manhack);
						float chkdist = GetVectorDistance(manhack,PlayerOrigin,false);
						int held = GetEntProp(CLManhack[i],Prop_Data,"m_bHeld");
						int hasenemy = GetEntPropEnt(CLManhack[i],Prop_Data,"m_hEnemy");
						if ((RoundFloat(chkdist) >= 1000) && (held == 0) && (hasenemy == -1))
						{
							if (IsValidEntity(clsummontarg[i]) && (clsummontarg[i] != 0))
								AcceptEntityInput(clsummontarg[i],"kill");
							char authstrtarg[36];
							Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[i]);
							if (clsummonfil == 0)
							{
								clsummonfil = CreateEntityByName("filter_activator_class");
								DispatchKeyValue(clsummonfil,"filterclass","player");
								DispatchKeyValue(clsummonfil,"Negated","1");
								DispatchKeyValue(clsummonfil,"targetname","noplayer");
								DispatchSpawn(clsummonfil);
								ActivateEntity(clsummonfil);
							}
							int gototarg = CreateEntityByName("npc_bullseye");
							TeleportEntity(gototarg, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
							DispatchKeyValue(gototarg,"targetname",authstrtarg);
							DispatchKeyValue(gototarg,"health","1");
							DispatchKeyValue(gototarg,"spawnflags","65536");
							DispatchKeyValue(gototarg,"damagefilter","noplayer");
							DispatchSpawn(gototarg);
							ActivateEntity(gototarg);
							int changetarg = CreateEntityByName("ai_changetarget");
							DispatchKeyValue(changetarg,"target",SteamID[i]);
							DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
							DispatchSpawn(changetarg);
							ActivateEntity(changetarg);
							AcceptEntityInput(changetarg,"Activate");
							int stuffrel = CreateEntityByName("ai_relationship");
							DispatchKeyValue(stuffrel,"disposition","1");
							DispatchKeyValue(stuffrel,"subject",SteamID[i]);
							DispatchKeyValue(stuffrel,"target",authstrtarg);
							DispatchKeyValue(stuffrel,"rank","99");
							DispatchKeyValue(stuffrel,"reciprocal","1");
							DispatchKeyValue(stuffrel,"StartActive","1");
							DispatchSpawn(stuffrel);
							ActivateEntity(stuffrel);
							AcceptEntityInput(stuffrel,"ApplyRelationship");
							int entindx = EntIndexToEntRef(changetarg);
							CreateTimer(0.1,cleanup,entindx);
							clsummontarg[i] = gototarg;
						}
					}
					else
					{
						CLManhack[i] = 0;
					}
				}
			}
		}
	}
}

void recursion(char sbuf[128])
{
	char buff[128];
	Handle msubdirlisting = OpenDirectory(sbuf,true,NULL_STRING);
	if (msubdirlisting != INVALID_HANDLE)
	{
		while (ReadDirEntry(msubdirlisting, buff, sizeof(buff)))
		{
			if ((!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))) && (!(msubdirlisting == INVALID_HANDLE)))
			{
				if ((!(StrContains(buff, ".ztmp") != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
				{
					char buff2[128];
					Format(buff2,sizeof(buff2),"%s/%s",sbuf,buff);
					if (StrContains(buff2,"//",false) != -1)
						ReplaceString(buff2,sizeof(buff2),"//","/",false);
					if (StrContains(buff2, ".wav", false) != -1)
					{
						char tmpbuf[128];
						Format(tmpbuf,sizeof(tmpbuf),"%s",buff2);
						ReplaceString(tmpbuf,sizeof(tmpbuf),"sound/","");
						ReplaceString(tmpbuf,sizeof(tmpbuf),"/","\\");
						PrecacheSound(tmpbuf,true);
						Format(tmpbuf,sizeof(tmpbuf),"*%s",tmpbuf);
						PrecacheSound(tmpbuf,true);
					}
					if (!(StrContains(buff2, ".", false) != -1))
					{
						recursion(buff2);
					}
				}
			}
		}
	}
	CloseHandle(msubdirlisting);
}

public Action StartTouchHornet(int entity, int other)
{
	if (IsValidEntity(other))
	{
		int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if (client != other)
		{
			if (((other > MaxClients) || (friendlyfire)) && (other != 0))
			{
				float damageForce[3];
				float dmgset = 5.0;
				float dmgforce = 5.0;
				damageForce[0] = dmgforce;
				damageForce[1] = dmgforce;
				damageForce[2] = dmgforce;
				if (IsValidEntity(client)) SDKHooks_TakeDamage(other,client,client,dmgset,DMG_CLUB,-1,damageForce);
				else SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
				if (FileExists("sound/weapons/hivehand/bug_impact.wav",true,NULL_STRING))
				{
					int rand = GetRandomInt(1,2);
					switch(rand)
					{
						case 1:
						{
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\hivehand\\bug_impact.wav");
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						}
						case 2:
						{
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						}
					}
					int effect = CreateEntityByName("info_particle_system");
					if (effect != -1)
					{
						float curorg[3];
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
						float angs[3];
						if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
						DispatchKeyValue(effect,"effect_name","grenade_hornet_detonate");
						DispatchKeyValue(effect,"start_active","1");
						TeleportEntity(effect,curorg,angs,NULL_VECTOR);
						DispatchSpawn(effect);
						ActivateEntity(effect);
						AcceptEntityInput(effect,"Start");
						int entindx = EntIndexToEntRef(effect);
						CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if (FileExists("sound/hornet/ag_hornethit1.wav",true,NULL_STRING))
				{
					char snd[64];
					Format(snd,sizeof(snd),"hornet\\ag_hornethit%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
			AcceptEntityInput(entity,"kill");
		}
	}
}

void CreateHornet(int client, int weap)
{
	if ((IsValidEntity(client)) && (IsValidEntity(weap)))
	{
		float targpos[3];
		float shootvel[3];
		float plyfirepos[3];
		float plyang[3];
		GetClientEyeAngles(client,plyang);
		plyang[1]-=10.0;
		GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
		plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
		plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
		if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
		else plyfirepos[2]+=48.0;
		plyang[1]+=10.0;
		TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
		TR_GetEndPosition(targpos);
		MakeVectorFromPoints(plyfirepos,targpos,shootvel);
		ScaleVector(shootvel,1.25);
		if (((shootvel[0] < 500.0) && (shootvel[0] > -500.0)) || ((shootvel[1] < 500.0) && (shootvel[1] > -500.0)))
			ScaleVector(shootvel,3.0);
		int spitball = CreateEntityByName("generic_actor");
		if (spitball != -1)
		{
			if (FileExists("models/weapons/w_hornet.mdl",true,NULL_STRING)) DispatchKeyValue(spitball,"model","models/weapons/w_hornet.mdl");
			else DispatchKeyValue(spitball,"model","models/hornet.mdl");
			DispatchKeyValue(spitball,"classname","npc_hornet");
			DispatchKeyValue(spitball,"OnDeath","!self,kill,,0,-1");
			TeleportEntity(spitball,plyfirepos,plyang,NULL_VECTOR);
			DispatchSpawn(spitball);
			ActivateEntity(spitball);
			SetEntityMoveType(spitball,MOVETYPE_FLY);
			if (HasEntProp(spitball,Prop_Data,"m_CollisionGroup")) SetEntProp(spitball,Prop_Data,"m_CollisionGroup",5);
			Handle dp = CreateDataPack();
			WritePackCell(dp,spitball);
			WritePackCell(dp,10);
			CreateTimer(0.25,resetcoll,dp,TIMER_FLAG_NO_MAPCHANGE);
			SDKHook(spitball, SDKHook_StartTouch, StartTouchHornet);
			SetEntPropEnt(spitball,Prop_Data,"m_hEffectEntity",client);
			if (HasEntProp(spitball,Prop_Data,"m_bloodColor")) SetEntProp(spitball,Prop_Data,"m_bloodColor",2);
			char mdl[64];
			GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (!StrEqual(mdl,"models/v_hgun.mdl"))
			{
				int effect = CreateEntityByName("info_particle_system");
				if (effect != -1)
				{
					DispatchKeyValue(effect,"effect_name","hornet_trail");
					DispatchKeyValue(effect,"start_active","1");
					TeleportEntity(effect,plyfirepos,plyang,NULL_VECTOR);
					DispatchSpawn(effect);
					ActivateEntity(effect);
					SetVariantString("!activator");
					AcceptEntityInput(effect,"SetParent",spitball);
					AcceptEntityInput(effect,"Start");
					int entindx = EntIndexToEntRef(effect);
					CreateTimer(2.0,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
			{
				int trail = CreateEntityByName("env_spritetrail");
				DispatchKeyValue(trail,"lifetime","0.2");
				DispatchKeyValue(trail,"startwidth","2.0");
				DispatchKeyValue(trail,"endwidth","1.0");
				DispatchKeyValue(trail,"spritename","sprites/bluelaser1.vmt");
				DispatchKeyValue(trail,"renderamt","255");
				DispatchKeyValue(trail,"rendermode","5");
				DispatchKeyValue(trail,"rendercolor","255 50 10");
				TeleportEntity(trail,plyfirepos,plyang,NULL_VECTOR);
				DispatchSpawn(trail);
				ActivateEntity(trail);
				SetVariantString("!activator");
				AcceptEntityInput(trail,"SetParent",spitball);
			}
			SetEntProp(spitball,Prop_Data,"m_MoveType",4);
			TeleportEntity(spitball,NULL_VECTOR,NULL_VECTOR,shootvel);
		}
		HiveAmm[client]--;
		SetEntProp(weap,Prop_Send,"m_iClip1",HiveAmm[client]);
	}
}

void CreateSnark(int client, int type)
{
	if (IsValidEntity(client))
	{
		float targpos[3];
		float shootvel[3];
		float plyfirepos[3];
		float plyang[3];
		GetClientEyeAngles(client,plyang);
		plyang[1]-=10.0;
		GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
		plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
		plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
		if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
		else plyfirepos[2]+=48.0;
		plyang[1]+=10.0;
		targpos[0] = (plyfirepos[0] + (200 * Cosine(DegToRad(plyang[1]))));
		targpos[1] = (plyfirepos[1] + (200 * Sine(DegToRad(plyang[1]))));
		targpos[2] = plyfirepos[2];
		MakeVectorFromPoints(plyfirepos,targpos,shootvel);
		int snark = CreateEntityByName("npc_headcrab_fast");
		if (snark != -1)
		{
			char clsnark[64];
			Format(clsnark,sizeof(clsnark),"%ssnark",SteamID[client]);
			if (type == 1) DispatchKeyValue(snark,"classname","npc_snark");
			else DispatchKeyValue(snark,"classname","monster_snark");
			DispatchKeyValue(snark,"targetname",clsnark);
			DispatchKeyValue(snark,"rendermode","10");
			DispatchKeyValue(snark,"renderfx","6");
			TeleportEntity(snark,plyfirepos,plyang,NULL_VECTOR);
			DispatchSpawn(snark);
			ActivateEntity(snark);
			TeleportEntity(snark,NULL_VECTOR,NULL_VECTOR,shootvel);
			MakeAlly(clsnark);
		}
	}
}

void MakeAlly(char[] clsnark)
{
	Handle liarr = GetLIList();
	Handle htarr = GetHTList();
	if (GetArraySize(liarr) > 0)
	{
		for (int i = 0;i<GetArraySize(liarr);i++)
		{
			char targ[64];
			GetArrayString(liarr,i,targ,sizeof(targ));
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","3");
			DispatchKeyValue(aidisp,"subject",clsnark);
			DispatchKeyValue(aidisp,"target",targ);
			DispatchKeyValue(aidisp,"targetname","syn_relations");
			DispatchKeyValue(aidisp,"rank","99");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			AcceptEntityInput(aidisp,"kill");
		}
	}
	if (GetArraySize(htarr) > 0)
	{
		for (int i = 0;i<GetArraySize(htarr);i++)
		{
			char targ[64];
			GetArrayString(htarr,i,targ,sizeof(targ));
			//Can't include self in HT or it will attack any, friend or enemy.
			if ((!StrEqual(targ,"npc_snark",false)) && (!StrEqual(targ,"monster_snark",false)))
			{
				int aidisp = CreateEntityByName("ai_relationship");
				DispatchKeyValue(aidisp,"disposition","1");
				DispatchKeyValue(aidisp,"subject",clsnark);
				DispatchKeyValue(aidisp,"target",targ);
				DispatchKeyValue(aidisp,"targetname","syn_relations");
				DispatchKeyValue(aidisp,"rank","99");
				DispatchKeyValue(aidisp,"reciprocal","1");
				DispatchKeyValue(aidisp,"StartActive","1");
				DispatchSpawn(aidisp);
				ActivateEntity(aidisp);
				AcceptEntityInput(aidisp,"ApplyRelationship");
				AcceptEntityInput(aidisp,"kill");
			}
		}
	}
	CloseHandle(liarr);
	CloseHandle(htarr);
}

void DetSatchels(int ent, int client)
{
	int thisent = FindEntityByClassname(ent,"grenade_satchel");
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		int owner = -1;
		int endpoint = GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity");
		if (endpoint != -1) owner = GetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity");
		if (owner == client)
		{
			if ((endpoint != 0) && (IsValidEntity(endpoint)) && (endpoint > MaxClients))
			{
				AcceptEntityInput(endpoint,"ClearParent");
				CreateTimer(0.1,explodedelay,endpoint,TIMER_FLAG_NO_MAPCHANGE);
			}
			AcceptEntityInput(thisent,"kill");
		}
		DetSatchels(thisent++,client);
	}
}

public Action grenademinetkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((victim != 0) && (IsValidEntity(victim)) && (damage > 0.1))
	{
		int endpoint = GetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity");
		if ((endpoint != 0) && (IsValidEntity(endpoint)))
		{
			SetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity",-1);
			AcceptEntityInput(endpoint,"ClearParent");
			CreateTimer(0.1,explodedelay,endpoint,TIMER_FLAG_NO_MAPCHANGE);
		}
		AcceptEntityInput(victim,"kill");
	}
}

public Action explodedelay(Handle timer, int expl)
{
	if ((IsValidEntity(expl)) && (expl != 0))
	{
		if (HasEntProp(expl,Prop_Data,"m_hParent"))
		{
			if (GetEntPropEnt(expl,Prop_Data,"m_hParent") != -1)
			{
				AcceptEntityInput(expl,"ClearParent");
			}
		}
		float orgs[3];
		if (HasEntProp(expl,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(expl,Prop_Data,"m_vecAbsOrigin",orgs);
		else if (HasEntProp(expl,Prop_Send,"m_vecOrigin")) GetEntPropVector(expl,Prop_Send,"m_vecOrigin",orgs);
		orgs[2]+=10.0;
		char mag[8];
		char radius[8];
		Format(mag,sizeof(mag),"%i",GetEntProp(expl,Prop_Data,"m_iMagnitude"));
		Format(radius,sizeof(radius),"%i",GetEntProp(expl,Prop_Data,"m_iRadiusOverride"));
		TeleportEntity(expl,orgs,NULL_VECTOR,NULL_VECTOR);
		AcceptEntityInput(expl,"Explode");
	}
}

void CreateTripMine(int client)
{
	if (IsValidEntity(client))
	{
		float plyfirepos[3];
		float angs[3];
		float mineang[3];
		GetClientEyePosition(client,plyfirepos);
		GetClientEyeAngles(client,angs);
		plyfirepos[0] = (plyfirepos[0] + (10 * Cosine(DegToRad(angs[1]))));
		plyfirepos[1] = (plyfirepos[1] + (10 * Sine(DegToRad(angs[1]))));
		float fhitpos[3];
		TR_TraceRayFilter(plyfirepos,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,client);
		int targchk = TR_GetEntityIndex();
		if ((targchk > MaxClients) || (targchk < 1))
		{
			char cls[32];
			if (IsValidEntity(targchk))
				GetEntityClassname(targchk,cls,sizeof(cls));
			if ((!StrEqual(cls,"npc_human_scientist",false)) && (!StrEqual(cls,"npc_human_security",false)))
			{
				TR_GetEndPosition(fhitpos);
				TR_GetPlaneNormal(INVALID_HANDLE,mineang);
				GetVectorAngles(mineang,angs);
				int mine = CreateEntityByName("prop_physics");
				if (mine != -1)
				{
					char minemdl[64];
					Format(minemdl,sizeof(minemdl),"models/weapons/w_tripmine.mdl");
					TripMineAmm[client]--;
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						char szWeapCls[32];
						GetEntityClassname(weap,szWeapCls,sizeof(szWeapCls));
						if (StrEqual(szWeapCls,"weapon_tripmine",false))
						{
							SetEntProp(weap,Prop_Data,"m_iClip1",TripMineAmm[client]);
							if (TripMineAmm[client] == 0)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
							}
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_tripmine.mdl",false))
							{
								Format(minemdl,sizeof(minemdl),"models/w_tripmine.mdl");
								fhitpos[0] = (fhitpos[0] + (5 * Cosine(DegToRad(angs[1]))));
								fhitpos[1] = (fhitpos[1] + (5 * Sine(DegToRad(angs[1]))));
							}
						}
					}
					DispatchKeyValue(mine,"model",minemdl);
					DispatchKeyValue(mine,"spawnflags","8");
					DispatchKeyValue(mine,"classname","grenade_tripmine");
					TeleportEntity(mine,fhitpos,angs,NULL_VECTOR);
					DispatchSpawn(mine);
					ActivateEntity(mine);
					if (FileExists("sound/weapons/tripmine/warmup.wav",true,NULL_STRING))
					{
						EmitSoundToAll("weapons\\tripmine\\warmup.wav", mine, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						CreateTimer(1.5,SetupMine,mine,TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (FileExists("sound/weapons/mine_deploy.wav",true,NULL_STRING))
					{
						EmitSoundToAll("weapons\\mine_deploy.wav", mine, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						CreateTimer(0.2,ChargeUpSnd,mine,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(2.25,SetupMine,mine,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

public Action ChargeUpSnd(Handle timer, int mine)
{
	if (IsValidEntity(mine))
	{
		if (FileExists("sound/weapons/mine_charge.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\mine_charge.wav", mine, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}

public Action SetupMine(Handle timer, int mine)
{
	if (IsValidEntity(mine))
	{
		float loc[3];
		float angs[3];
		if (HasEntProp(mine,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(mine,Prop_Data,"m_vecAbsOrigin",loc);
		else if (HasEntProp(mine,Prop_Send,"m_vecOrigin")) GetEntPropVector(mine,Prop_Send,"m_vecOrigin",loc);
		if (HasEntProp(mine,Prop_Data,"m_angAbsRotation")) GetEntPropVector(mine,Prop_Data,"m_angAbsRotation",angs);
		loc[0] = (loc[0] + (1 * Cosine(DegToRad(angs[1]))));
		loc[1] = (loc[1] + (1 * Sine(DegToRad(angs[1]))));
		float fhitpos[3];
		TR_TraceRayFilter(loc,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,mine);
		TR_GetEndPosition(fhitpos);
		int beam = CreateEntityByName("env_beam");
		if (beam != -1)
		{
			DispatchKeyValue(beam,"spawnflags","3");
			DispatchKeyValue(beam,"life","0");
			DispatchKeyValue(beam,"texture","sprites/laserbeam.spr");
			DispatchKeyValue(beam,"model","sprites/laserbeam.spr");
			DispatchKeyValue(beam,"TextureScroll","35");
			DispatchKeyValue(beam,"framerate","10");
			DispatchKeyValue(beam,"rendercolor","0 200 200");
			DispatchKeyValue(beam,"BoltWidth","0.5");
			DispatchKeyValue(beam,"TouchType","4");
			TeleportEntity(beam,loc,angs,NULL_VECTOR);
			SetEntPropVector(beam,Prop_Data,"m_vecEndPos",fhitpos);
			SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",mine,0);
			SetEntProp(beam,Prop_Data,"m_nModelIndex",tauhl2beam);
			DispatchSpawn(beam);
			ActivateEntity(beam);
			int expl = CreateEntityByName("env_explosion");
			if (expl != -1)
			{
				char radius[8] = "250";
				char dmgmag[8] = "300";
				Handle cvar = FindConVar("sk_tripmine_radius");
				if (cvar != INVALID_HANDLE)
				{
					if (GetConVarInt(cvar) < 1) SetConVarInt(cvar,250,false,false);
					GetConVarString(cvar,radius,sizeof(radius));
				}
				cvar = FindConVar("sk_plr_dmg_tripmine");
				if (cvar != INVALID_HANDLE)
				{
					if (GetConVarInt(cvar) < 1) SetConVarInt(cvar,300,false,false);
					GetConVarString(cvar,dmgmag,sizeof(dmgmag));
				}
				CloseHandle(cvar);
				TeleportEntity(expl,loc,angs,NULL_VECTOR);
				DispatchKeyValue(expl,"imagnitude",dmgmag);
				DispatchKeyValue(expl,"iradiusoverride",radius);
				DispatchKeyValue(expl,"rendermode","0");
				DispatchKeyValue(expl,"targetname","syn_tripmineexpl");
				DispatchSpawn(expl);
				ActivateEntity(expl);
				SetEntPropEnt(beam,Prop_Data,"m_hOwnerEntity",mine);
				SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",expl);
				SetEntPropEnt(mine,Prop_Data,"m_hOwnerEntity",beam);
				SetEntPropEnt(mine,Prop_Data,"m_hEffectEntity",expl);
				HookSingleEntityOutput(beam,"OnTouchedByEntity",TripMineExpl);
				ChangeEdictState(mine);
			}
		}
		SDKHookEx(mine,SDKHook_OnTakeDamage,TripMineTKdmg);
		if (FileExists("sound/weapons/tripmine/activate.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\tripmine\\activate.wav", mine, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		else if (FileExists("sound/weapons/mine_activate.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\mine_activate.wav", mine, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}

public Action TripMineTKdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidEntity(victim))
	{
		int beam = GetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity");
		if ((IsValidEntity(beam)) && (beam != 0))
		{
			AcceptEntityInput(beam,"kill");
			SetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity",-1);
		}
		int expl = GetEntPropEnt(victim,Prop_Data,"m_hEffectEntity");
		if ((IsValidEntity(expl)) && (expl != 0))
		{
			SetEntPropEnt(victim,Prop_Data,"m_hEffectEntity",-1);
			CreateTimer(0.1,explodedelay,expl,TIMER_FLAG_NO_MAPCHANGE);
		}
		SDKUnhook(victim, SDKHook_OnTakeDamage, TripMineTKdmg);
		AcceptEntityInput(victim,"kill");
	}
}

public Action TripMineExpl(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		int tripmine = GetEntPropEnt(caller,Prop_Data,"m_hOwnerEntity");
		if (IsValidEntity(tripmine))
		{
			int parexpl = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if ((parexpl != -1) && (IsValidEntity(parexpl))) AcceptEntityInput(parexpl,"Explode");
			AcceptEntityInput(tripmine,"kill");
			UnhookSingleEntityOutput(caller,"OnTouchedByEntity",TripMineExpl);
			AcceptEntityInput(caller,"kill");
		}
	}
}

public Action GrenadeExpl(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		AcceptEntityInput(entity,"kill");
	}
}

public void BHGTouch(int entity)
{
	if ((HasEntProp(entity,Prop_Data,"m_nBounceCount")) && (HasEntProp(entity,Prop_Data,"m_bStruckEntity")))
	{
		if ((GetEntProp(entity,Prop_Data,"m_nBounceCount") > 0) || (GetEntProp(entity,Prop_Data,"m_bStruckEntity")))
		{
			SDKUnhook(entity, SDKHook_VPhysicsUpdate, BHGTouch);
			if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity"))
			{
				int hThrower = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
				float vecOrigin[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",vecOrigin);
				EmitSoundToAll("weapons/crossbow/hit1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
				AcceptEntityInput(entity,"Explode");
				int endpoint = CreateEntityByName("env_explosion");
				if (endpoint != -1)
				{
					DispatchKeyValue(endpoint,"imagnitude","300");
					DispatchKeyValue(endpoint,"iRadiusOverride","150");
					DispatchKeyValue(endpoint,"rendermode","0");
					DispatchKeyValue(endpoint,"spawnflags","9084");
					TeleportEntity(endpoint,vecOrigin,NULL_VECTOR,NULL_VECTOR);
					DispatchSpawn(endpoint);
					ActivateEntity(endpoint);
					SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",hThrower);
					SetEntPropEnt(endpoint,Prop_Data,"m_hEffectEntity",hThrower);
					AcceptEntityInput(endpoint,"Explode");
				}
			}
		}
	}
	else SDKUnhook(entity, SDKHook_VPhysicsUpdate, BHGTouch);
}

public Action MolotovTouch(int entity, int other)
{
	if (HasEntProp(entity,Prop_Data,"m_hThrower"))
	{
		int hThrower = GetEntPropEnt(entity,Prop_Data,"m_hThrower");
		float vecOffspos[3];
		float vecLocation[3];
		if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",vecLocation);
		float startang = 0.0;
		float randang = 0.0;
		int runmax = RoundFloat(hMolotovRadius.FloatValue)/15;
		for (int i = 0;i<runmax;i++)
		{
			randang = startang+GetRandomFloat(5.0,12.0);
			startang = randang;
			vecOffspos[2] = vecLocation[2];
			if (startang > 360.0) startang = -360.0;
			vecOffspos[0] = (vecLocation[0] + ((5.0 + GetRandomFloat(1.0,hMolotovRadius.FloatValue)) * Cosine(DegToRad(randang))));
			vecOffspos[1] = (vecLocation[1] + ((5.0 + GetRandomFloat(1.0,hMolotovRadius.FloatValue)) * Sine(DegToRad(randang))));
			if (TR_PointOutsideWorld(vecOffspos))
			{
				vecOffspos[2]+=15.0;
				TR_TraceRayFilter(vecOffspos, view_as<float>({90.0,0.0,0.0}), MASK_SHOT, RayType_Infinite, TraceEntityFilter, entity);
				TR_GetEndPosition(vecOffspos);
			}
			int iEnvFire = CreateEntityByName("env_fire");
			if (iEnvFire != -1)
			{
				DispatchKeyValue(iEnvFire,"health","10");
				DispatchKeyValue(iEnvFire,"firesize","40");
				DispatchKeyValue(iEnvFire,"fireattack","1");
				DispatchKeyValue(iEnvFire,"firetype","0");
				DispatchKeyValue(iEnvFire,"spawnflags","136");
				DispatchKeyValue(iEnvFire,"damagescale","30.0");
				TeleportEntity(iEnvFire,vecOffspos,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(iEnvFire);
				ActivateEntity(iEnvFire);
				SetEntPropEnt(iEnvFire,Prop_Data,"m_hOwner",hThrower);
				AcceptEntityInput(iEnvFire,"StartFire");
			}
		}
	}
}

void ShootBullet(int client, int weap, int atktype, char[] curweap, float orgs[3], float angs[3], int sideoffs, float maxspread)
{
	if (IsValidEntity(client))
	{
		float endpos[3];
		float shootvel[3];
		float originalorgs[3];
		originalorgs[0] = orgs[0];
		originalorgs[1] = orgs[1];
		originalorgs[2] = orgs[2];
		//orgs[2]+=13.0;
		//if (GetEntProp(client,Prop_Data,"m_bDucked")) orgs[2]-=28.0;
		TE_Start("Shotgun Shot");
		angs[1]+=90.0;
		orgs[0] = (orgs[0] + (sideoffs * Cosine(DegToRad(angs[1]))));
		orgs[1] = (orgs[1] + (sideoffs * Sine(DegToRad(angs[1]))));
		angs[1]-=90.0;
		TE_WriteVector("m_vecOrigin", orgs);
		float spread = GetRandomFloat(-maxspread,maxspread);
		angs[0] = angs[0]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[1] = angs[1]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[2] = angs[2]+spread;
		TR_TraceRayFilter(originalorgs, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
		TR_GetEndPosition(endpos);
		int hitgroup = TR_GetHitGroup();
		int targ = TR_GetEntityIndex();
		MakeVectorFromPoints(originalorgs,endpos,shootvel);
		ScaleVector(shootvel,8.0);
		TE_WriteVector("m_vecDir", shootvel);
		TE_WriteNum("m_iAmmoID", 1);
		TE_WriteNum("m_iSeed", 0);
		TE_WriteNum("m_iShots", 1);
		TE_WriteNum("m_iPlayer", client);
		TE_WriteFloat("m_flSpread", 0.0);
		TE_WriteNum("m_bDoImpacts", 1);
		TE_WriteNum("m_bDoTracers", 1);
		TE_SendToAll(0.0);
		SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
		if ((targ != 0) && (IsValidEntity(targ)))
		{
			char clsname[32];
			GetEntityClassname(targ,clsname,sizeof(clsname));
			float damage = 1.0;
			char weapdmg[32];
			Format(weapdmg,sizeof(weapdmg),"%s",curweap);
			if ((atktype > 0) && (weap > MaxClients))
			{
				if (atktype == 1)
				{
					if (strlen(custammtype[weap]) > 0)
					{
						Format(weapdmg,sizeof(weapdmg),"sk_plr_dmg_%s",custammtype[weap]);
					}
				}
				else if (atktype == 2)
				{
					if (strlen(custammtype2[weap]) > 0)
					{
						Format(weapdmg,sizeof(weapdmg),"sk_plr_dmg_%s",custammtype2[weap]);
					}
				}
			}
			ReplaceStringEx(weapdmg,sizeof(weapdmg),"weapon_","sk_plr_dmg_");
			Handle cvar = FindConVar(weapdmg);
			if (cvar != INVALID_HANDLE)
			{
				damage = GetConVarFloat(cvar);
				float inflictscale = 1.0;
				char scalechk[32];
				Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
				Handle scaleh = FindConVar(scalechk);
				if (scaleh != INVALID_HANDLE) inflictscale = GetConVarFloat(scaleh);
				CloseHandle(scaleh);
				damage = damage/inflictscale;
				if (hitgroup == headgroup) damage = damage*2.0;
			}
			CloseHandle(cvar);
			if (StrEqual(clsname,"generic_actor",false))
			{
				if (HasEntProp(targ,Prop_Data,"m_hParent"))
				{
					int iParent = GetEntPropEnt(targ,Prop_Data,"m_hParent");
					if (IsValidEntity(iParent))
					{
						GetEntityClassname(iParent,clsname,sizeof(clsname));
						targ = iParent;
					}
				}
			}
			if ((!CheckNPCAlly(clsname,targ)) || ((targ < MaxClients+1) && (targ > 0) && (friendlyfire)))
			{
				ScaleVector(shootvel,2.0);
				SDKHooks_TakeDamage(targ,client,client,damage,DMG_BULLET,-1,shootvel,orgs);
			}
			else if ((StrContains(clsname,"prop_",false) != -1) || (StrEqual(clsname,"func_breakable",false)) || (StrContains(clsname,"item_",false) == 0))
			{
				SDKHooks_TakeDamage(targ,client,client,damage,DMG_BULLET,-1,shootvel,orgs);
				ScaleVector(shootvel,1.5);
				float maxscaler = damage*2.0;
				if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
				{
					while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
					{
						ScaleVector(shootvel,0.95);
					}
				}
				TeleportEntity(targ,NULL_VECTOR,NULL_VECTOR,shootvel);
			}
		}
	}
}

void ReleaseFire(int client, int atktype, float orgs[3], float angs[3], int sideoffs, float maxspread, char[] weapworldmdl, int dmgpass)
{
	if (IsValidEntity(client))
	{
		float endpos[3];
		float shootvel[3];
		float originalorgs[3];
		originalorgs[0] = orgs[0];
		originalorgs[1] = orgs[1];
		originalorgs[2] = orgs[2];
		orgs[2]+=13.0;
		if (GetEntProp(client,Prop_Data,"m_bDucked")) orgs[2]-=28.0;
		if (atktype == 7)
		{
			orgs[0] = (orgs[0] + (sideoffs * Cosine(DegToRad(angs[1]))));
			orgs[1] = (orgs[1] + (sideoffs * Sine(DegToRad(angs[1]))));
		}
		angs[1]+=90.0;
		orgs[0] = (orgs[0] + (sideoffs * Cosine(DegToRad(angs[1]))));
		orgs[1] = (orgs[1] + (sideoffs * Sine(DegToRad(angs[1]))));
		angs[1]-=90.0;
		float spread = GetRandomFloat(-maxspread,maxspread);
		angs[0] = angs[0]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[1] = angs[1]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[2] = angs[2]+spread;
		float adddist = 400 * Sine(DegToRad(angs[0]));
		endpos[0] = (originalorgs[0] + (500 * Cosine(DegToRad(angs[1]))));
		endpos[1] = (originalorgs[1] + (500 * Sine(DegToRad(angs[1]))));
		endpos[2] = (originalorgs[2] - (500 * Sine(DegToRad(angs[0]))))-adddist;
		MakeVectorFromPoints(originalorgs,endpos,shootvel);
		SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
		if (atktype == 7)
		{
			if (strlen(weapworldmdl) > 0)
			{
				int grenade = CreateEntityByName("prop_physics_override");
				if (grenade != -1)
				{
					DispatchKeyValue(grenade,"classname","grenade_satchel");
					DispatchKeyValue(grenade,"model",weapworldmdl);
					DispatchKeyValue(grenade,"solid","6");
					DispatchKeyValue(grenade,"spawnflags","256");
					angs[0]+=GetRandomFloat(-10.0,10.0);
					angs[2]+=GetRandomFloat(-10.0,10.0);
					TeleportEntity(grenade,orgs,angs,NULL_VECTOR);
					DispatchSpawn(grenade);
					ActivateEntity(grenade);
					if (HasEntProp(grenade,Prop_Data,"m_CollisionGroup"))
					{
						SetEntProp(grenade,Prop_Data,"m_CollisionGroup",5);
						Handle dp = CreateDataPack();
						WritePackCell(dp,grenade);
						WritePackCell(dp,5);
						CreateTimer(0.1,resetcoll,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
					TeleportEntity(grenade,NULL_VECTOR,NULL_VECTOR,shootvel);
					int endpoint = CreateEntityByName("env_explosion");
					if (endpoint != -1)
					{
						char dmgmag[8];
						Format(dmgmag,sizeof(dmgmag),"%i",dmgpass);
						DispatchKeyValue(endpoint,"imagnitude",dmgmag);
						DispatchKeyValue(endpoint,"iRadiusOverride","150");
						DispatchKeyValue(endpoint,"rendermode","0");
						TeleportEntity(endpoint,orgs,angs,NULL_VECTOR);
						DispatchSpawn(endpoint);
						ActivateEntity(endpoint);
						SetVariantString("!activator");
						AcceptEntityInput(endpoint,"SetParent",grenade);
						SetEntPropEnt(grenade,Prop_Data,"m_hOwnerEntity",endpoint);
						SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",client);
						int entindx = EntIndexToEntRef(grenade);
						CreateTimer(4.0,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(4.0,explodedelay,endpoint,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

void FireCustomWeap(int client, int weap, char[] curweap, int mode)
{
	if (IsValidEntity(client))
	{
		if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
		{
			if (HasEntProp(weap,Prop_Data,"m_bInReload"))
			{
				if (GetEntProp(weap,Prop_Data,"m_bInReload") > 0) return;
			}
			int fireunderwater = 1;
			if (HasEntProp(client,Prop_Data,"m_nWaterLevel"))
			{
				int waterlv = GetEntProp(client,Prop_Data,"m_nWaterLevel");
				if (waterlv > 2)
				{
					if (HasEntProp(weap,Prop_Data,"m_bFiresUnderwater")) fireunderwater = GetEntProp(weap,Prop_Data,"m_bFiresUnderwater");
				}
			}
			//if (HasEntProp(client,Prop_Data,"m_szAnimExtension"))
			if (fireunderwater)
			{
				int findweap = FindStringInArray(swepsweap,curweap);
				if (findweap != -1)
				{
					bool fastfire = false;
					int atkanim[10];
					int bullettype,lefthanded,resetanim;
					int emptyanim = -1;
					int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
					if (HasEntProp(weap,Prop_Data,"m_iPrimaryAmmoType"))
					{
						if (StrContains(custammtype[weap],"grenade",false) != -1)
						{
							if (GetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType") == 12)
							{
								curclip = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
							}
						}
					}
					//if (curclip < 1) return;
					int maxburst = 3;
					float firerate,startspread,maxspread;
					float bursttime = 0.2;
					Handle dp = GetArrayCell(swepsinfo,findweap);
					if (dp != INVALID_HANDLE)
					{
						char weapdata[80];
						ResetPack(dp);
						ReadPackString(dp,weapdata,sizeof(weapdata));
						while (!StrEqual(weapdata,"endofpack",false))
						{
							if (StrContains(weapdata,"empty",false) == 0)
							{
								if (curclip < 1)
								{
									char tmp[4][64];
									ExplodeString(weapdata," ",tmp,4,64);
									EmitGameSoundToAll(tmp[1],client);
									if (emptyanim != -1)
									{
										int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
										if (viewmdl != -1)
										{
											int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
											if (seq != emptyanim) SetEntProp(viewmdl,Prop_Send,"m_nSequence",emptyanim);
										}
									}
									g_LastButtons[client] = IN_ATTACK;
									g_LastButtons[client] |= IN_ATTACK2;
									return;
								}
							}
							else if (StrContains(weapdata,"single_shot",false) == 0)
							{
								char tmp[4][64];
								ExplodeString(weapdata," ",tmp,4,64);
								if (curclip > 0)
								{
									int tmpi;
									float tmpf;
									char snd[64];
									if (GetGameSoundParams(tmp[1],tmpi,tmpi,tmpf,tmpi,snd,sizeof(snd)))
									{
										char sndch[80];
										Format(sndch,sizeof(sndch),"sound/%s",snd);
										if (FileExists(sndch,true,NULL_STRING)) EmitGameSoundToAll(tmp[1],client);
									}
								}
							}
							if (mode == 1)
							{
								if (StrContains(weapdata,"FireType1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									bullettype = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"primary_ammo",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									if (StrEqual(tmp[1],"grenade",false)) bullettype = 7;
								}
								else if (StrContains(weapdata,"FireRate1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									firerate = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FastFire1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									if (StringToInt(tmp[1]) == 0)
									{
										fastfire = false;
										//g_LastButtons[client] = IN_ATTACK;
									}
									else fastfire = true;
								}
								else if (StrContains(weapdata,"FireCone1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									startspread = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FireConeLerpto1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									maxspread = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"BurstAmount1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									maxburst = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"BetweenBurstTime1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									bursttime = StringToFloat(tmp[1]);
								}
								else if ((StrContains(weapdata,"ACT_VM_PRIMARYATTACK",false) >= 2) || (StrContains(weapdata,"ACT_VM_PULLBACK",false) >= 2) || (StrContains(weapdata,"ACT_VM_RECOIL",false) >= 2))
								{
									char tmp[4][64];
									ExplodeString(weapdata," ",tmp,4,64);
									if (InIronSights[client])
									{
										if ((StrContains(tmp[1],"IRONSIGHT",false) != -1) || (StrContains(tmp[1],"IRONSHOOT",false) != -1))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
									else if (!CLAttachment[client])
									{
										if ((!StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_SILENCED",false)) && (StrContains(tmp[1],"IRONSIGHT",false) == -1) && (StrContains(tmp[1],"IRONSHOOT",false) == -1) && (!StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_EMPTY",false)) && (!StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_DEPLOYED",false)))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
									else if (CLAttachment[client])
									{
										if (StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_SILENCED",false))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
									else if (StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_EMPTY",false))
									{
										emptyanim = StringToInt(tmp[0]);
									}
								}
							}
							else if (mode == 2)
							{
								if (StrContains(weapdata,"FireType2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									bullettype = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"FireRate2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									firerate = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FastFire2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									if (StringToInt(tmp[1]) == 0)
									{
										fastfire = false;
										//g_LastButtons[client] = IN_ATTACK;
									}
									else fastfire = true;
								}
								else if (StrContains(weapdata,"FireCone2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									startspread = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FireConeLerpto2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									maxspread = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"BurstAmount2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									maxburst = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"BetweenBurstTime2",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									bursttime = StringToFloat(tmp[1]);
								}
								else if ((StrContains(weapdata,"ACT_VM_SECONDARYATTACK",false) == 2) || (StrContains(weapdata,"ACT_VM_RECOIL",false) == 2))
								{
									char tmp[32][32];
									ExplodeString(weapdata," ",tmp,32,32);
									if (!CLAttachment[client])
									{
										if ((!StrEqual(tmp[1],"ACT_VM_SECONDARYATTACK_SILENCED",false)) && (!StrEqual(tmp[1],"ACT_VM_SECONDARYATTACK_EMPTY",false)) && (!StrEqual(tmp[1],"ACT_VM_SECONDARYATTACK_DEPLOYED",false)))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
									else if (CLAttachment[client])
									{
										if (StrEqual(tmp[1],"ACT_VM_SECONDARYATTACK_SILENCED",false))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
								}
							}
							if (StrContains(weapdata,"BuiltRightHanded",false) == 0)
							{
								char tmp[16][16];
								ExplodeString(weapdata," ",tmp,16,16);
								lefthanded = StringToInt(tmp[1]);
							}
							else if ((StrContains(weapdata,"ACT_VM_IDLE",false) != -1) && (StrContains(weapdata,"_LOWERED",false) == -1))
							{
								char tmp[4][64];
								ExplodeString(weapdata," ",tmp,4,64);
								if (StrContains(weapdata,"ACT_VM_IDLE_EMPTY",false) != -1)
								{
									if (curclip < 1) resetanim = StringToInt(tmp[0]);
								}
								else if ((!CLAttachment[client]) && (StrContains(tmp[1],"SIGHTS_IN",false) == -1))
								{
									if (!StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
									{
										resetanim = StringToInt(tmp[0]);
									}
								}
								else if ((CLAttachment[client]) && (StrContains(tmp[1],"SIGHTS_IN",false) == -1))
								{
									if (StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
									{
										resetanim = StringToInt(tmp[0]);
									}
								}
							}
							ReadPackString(dp,weapdata,sizeof(weapdata));
						}
					}
					if (StrContains(curweap,"weapon_pistol1",false) != -1)
					{
						if (mode == 1)
						{
							bullettype = 1;
							firerate = 0.5;
						}
						else if (mode == 2)
						{
							ironsights(client,0);
							g_LastButtons[client] = IN_ATTACK2;
							return;
						}
					}
					else if (StrContains(curweap,"weapon_pistol2",false) != -1)
					{
						if (mode == 1)
						{
							bullettype = 1;
							firerate = 0.5;
						}
						else if (mode == 2)
						{
							ironsights(client,0);
							g_LastButtons[client] = IN_ATTACK2;
							return;
						}
					}
					else if ((StrContains(curweap,"weapon_ls13",false) != -1) && (mode == 1)) bullettype = 1;
					else if ((StrContains(curweap,"weapon_lugergun",false) != -1) && (mode == 1)) bullettype = 1;
					else if ((StrContains(curweap,"weapon_rifle1",false) != -1) && (mode == 1))
					{
						bullettype = 1;
						firerate = 0.7;
					}
					else if ((StrContains(curweap,"weapon_smg3",false) != -1) && (mode == 1))
					{
						if (mode == 1)
						{
							bullettype = 1;
							fastfire = true;
							firerate = 0.05;
						}
						else if (mode == 2)
						{
							ironsights(client,0);
							g_LastButtons[client] = IN_ATTACK2;
							return;
						}
					}
					else if ((StrContains(curweap,"weapon_smg4",false) != -1) && (mode == 1)) bullettype = 1;
					else if ((StrContains(curweap,"weapon_vc32sniperrifle",false) != -1) && (mode == 1)) bullettype = 1;
					if (curclip < 1)
					{
						if (mode == 1) g_LastButtons[client] = IN_ATTACK;
						else g_LastButtons[client] = IN_ATTACK2;
						EmitGameSoundToAll("Weapon_Pistol.Empty",client);
						return;
					}
					if (bullettype == 1)
					{
						int shotsfired = 0;
						if (curclip-1 > -1) SetEntProp(weap,Prop_Data,"m_iClip1",curclip-1);
						else SetEntProp(weap,Prop_Data,"m_iClip1",0);
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
						float spread = startspread+(shotsfired/2);
						if (spread > maxspread) spread = maxspread;
						if (startspread > maxspread) spread = startspread;
						int sideoffs = 0;
						if (lefthanded) sideoffs = -4;
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
						float orgs[3];
						float angs[3];
						GetClientEyePosition(client,orgs);
						//orgs[2]-=12.0;
						GetClientEyeAngles(client,angs);
						ShootBullet(client,weap,1,curweap,orgs,angs,sideoffs,spread);
						if (fastfire)
						{
							CreateTimer(firerate,clearlast,client,TIMER_FLAG_NO_MAPCHANGE);
							firerate = 0.1;
							if (mode == 1) g_LastButtons[client] = IN_ATTACK;
							else g_LastButtons[client] = IN_ATTACK2;
						}
						if (mode == 1) centnextatk[weap] = GetGameTime()+firerate;
						else centnextatk2[weap] = GetGameTime()+firerate;
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int randanim;
							for (int i = 0;i<10;i++)
							{
								if (atkanim[i] != 0) randanim = atkanim[i];
								else break;
							}
							int rand = GetRandomInt(atkanim[0],randanim);
							if (InIronSights[client])
							{
								resetanim = rand;
							}
							if (atkanim[0] == randanim)
							{
								Handle vmdp = CreateDataPack();
								WritePackCell(vmdp,viewmdl);
								WritePackCell(vmdp,resetanim);
								WritePackCell(vmdp,weap);
								WritePackString(vmdp,curweap);
								CreateTimer(firerate-0.01,resetvmtoidle,vmdp,TIMER_FLAG_NO_MAPCHANGE);
							}
							else if (seq == rand)
							{
								if ((rand > atkanim[0]) && (rand-1 >= atkanim[0])) rand--;
								else if (rand < randanim) rand++;
							}
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
						}
					}
					else if (bullettype == 2)
					{
						int shotsfired = 0;
						SetEntProp(weap,Prop_Data,"m_iClip1",curclip-1);
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
						float spread = startspread;
						if (spread > maxspread) spread = maxspread;
						if (startspread > maxspread) spread = startspread;
						int sideoffs = 0;
						if (lefthanded) sideoffs = -4;
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
						float orgs[3];
						float angs[3];
						GetClientEyePosition(client,orgs);
						//orgs[2]-=12.0;
						GetClientEyeAngles(client,angs);
						ShootBullet(client,weap,1,curweap,orgs,angs,sideoffs,spread);
						Handle dpref = CreateDataPack();
						WritePackCell(dpref,client);
						WritePackCell(dpref,weap);
						WritePackString(dpref,curweap);
						WritePackCell(dp,sideoffs);
						WritePackFloat(dp,startspread);
						WritePackFloat(dp,maxspread);
						WritePackCell(dp,maxburst);
						CreateTimer(bursttime,refire,dpref,TIMER_FLAG_NO_MAPCHANGE);
						if (mode == 1) centnextatk[weap] = GetGameTime()+firerate;
						else centnextatk2[weap] = GetGameTime()+firerate;
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int randanim;
							for (int i = 0;i<10;i++)
							{
								if (atkanim[i] != 0) randanim = atkanim[i];
								else break;
							}
							int rand = GetRandomInt(atkanim[0],randanim);
							if (atkanim[0] == randanim)
							{
								Handle vmdp = CreateDataPack();
								WritePackCell(vmdp,viewmdl);
								WritePackCell(vmdp,resetanim);
								WritePackCell(vmdp,weap);
								WritePackString(vmdp,curweap);
								CreateTimer(firerate-0.01,resetvmtoidle,vmdp,TIMER_FLAG_NO_MAPCHANGE);
							}
							if (seq == rand)
							{
								if (rand == randanim) rand--;
								else rand++;
							}
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
						}
					}
					else if ((bullettype == 3) || (bullettype == 4))
					{
						int shotsfired = 0;
						SetEntProp(weap,Prop_Data,"m_iClip1",curclip-1);
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
						int sideoffs = 0;
						if (lefthanded) sideoffs = -4;
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
						float orgs[3];
						float angs[3];
						GetClientEyePosition(client,orgs);
						//orgs[2]-=12.0;
						GetClientEyeAngles(client,angs);
						for (int i = 0;i<10;i++)
						{
							float spread = startspread+(shotsfired/2);
							if (spread > maxspread) spread = maxspread;
							if ((startspread > maxspread) && (i != 0)) spread = startspread/4.0;
							ShootBullet(client,weap,1,curweap,orgs,angs,sideoffs,spread);
						}
						if ((fastfire) && (bullettype != 4))
						{
							CreateTimer(firerate,clearlast,client,TIMER_FLAG_NO_MAPCHANGE);
							firerate = 0.1;
							if (mode == 1) g_LastButtons[client] = IN_ATTACK;
							else g_LastButtons[client] = IN_ATTACK2;
						}
						if (mode == 1) centnextatk[weap] = GetGameTime()+firerate;
						else centnextatk2[weap] = GetGameTime()+firerate;
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int randanim;
							for (int i = 0;i<10;i++)
							{
								if (atkanim[i] != 0) randanim = atkanim[i];
								else break;
							}
							int rand = GetRandomInt(atkanim[0],randanim);
							if (atkanim[0] == randanim)
							{
								Handle vmdp = CreateDataPack();
								WritePackCell(vmdp,viewmdl);
								WritePackCell(vmdp,resetanim);
								WritePackCell(vmdp,weap);
								WritePackString(vmdp,curweap);
								CreateTimer(firerate-0.01,resetvmtoidle,vmdp,TIMER_FLAG_NO_MAPCHANGE);
							}
							if (seq == rand)
							{
								if (rand == randanim) rand--;
								else rand++;
							}
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
						}
					}
					else if (bullettype == 7)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int randanim;
							for (int i = 0;i<10;i++)
							{
								if (atkanim[i] != 0) randanim = atkanim[i];
								else break;
							}
							int rand = GetRandomInt(atkanim[0],randanim);
							if ((seq >= atkanim[0]) && (seq <= randanim))
							{
								//In Pullback
								InChargeUp[weap] = true;
							}
							else
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
						}
					}
				}
			}
			else
			{
				if (mode == 1) g_LastButtons[client] = IN_ATTACK;
				else g_LastButtons[client] = IN_ATTACK2;
				EmitGameSoundToAll("Weapon_Pistol.Empty",client);
				return;
			}
		}
	}
	return;
}

void ReleaseCustomWeapon(int client, int weap, char[] curweap, int mode)
{
	if (IsValidEntity(client))
	{
		if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
		{
			if (HasEntProp(weap,Prop_Data,"m_bInReload"))
			{
				if (GetEntProp(weap,Prop_Data,"m_bInReload") > 0) return;
			}
			int fireunderwater = 1;
			if (HasEntProp(client,Prop_Data,"m_nWaterLevel"))
			{
				int waterlv = GetEntProp(client,Prop_Data,"m_nWaterLevel");
				if (waterlv > 2)
				{
					if (HasEntProp(weap,Prop_Data,"m_bFiresUnderwater")) fireunderwater = GetEntProp(weap,Prop_Data,"m_bFiresUnderwater");
				}
			}
			//if (HasEntProp(client,Prop_Data,"m_szAnimExtension"))
			if (fireunderwater)
			{
				int findweap = FindStringInArray(swepsweap,curweap);
				if (findweap != -1)
				{
					bool fastfire = false;
					char weapworldmdl[64];
					int atkanim[10];
					int bullettype,lefthanded,resetanim,dmgpass;
					int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
					if (HasEntProp(weap,Prop_Data,"m_iPrimaryAmmoType"))
					{
						if (GetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType") == 12)
						{
							curclip = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
						}
					}
					//int maxburst = 3;
					float firerate,startspread,maxspread;
					//float bursttime = 0.2;
					Handle dp = GetArrayCell(swepsinfo,findweap);
					if (dp != INVALID_HANDLE)
					{
						char weapdata[64];
						ResetPack(dp);
						ReadPackString(dp,weapdata,sizeof(weapdata));
						while (!StrEqual(weapdata,"endofpack",false))
						{
							if ((StrContains(weapdata,"single_shot",false) == 0) || (StrContains(weapdata,"special1",false) == 0))
							{
								char tmp[4][64];
								ExplodeString(weapdata," ",tmp,4,64);
								EmitGameSoundToAll(tmp[1],client);
							}
							if (mode == 1)
							{
								if (StrContains(weapdata,"FireType1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									bullettype = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"primary_ammo",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									if (StrEqual(tmp[1],"grenade",false)) bullettype = 7;
								}
								else if (StrContains(weapdata,"damage",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									dmgpass = StringToInt(tmp[1]);
								}
								else if (StrContains(weapdata,"playermodel",false) == 0)
								{
									char tmp[16][64];
									ExplodeString(weapdata," ",tmp,16,64);
									Format(weapworldmdl,sizeof(weapworldmdl),"%s",tmp[1]);
								}
								else if (StrContains(weapdata,"FireRate1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									firerate = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FastFire1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									if (StringToInt(tmp[1]) == 0)
									{
										fastfire = false;
										//g_LastButtons[client] = IN_ATTACK;
									}
									else fastfire = true;
								}
								else if (StrContains(weapdata,"FireCone1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									startspread = StringToFloat(tmp[1]);
								}
								else if (StrContains(weapdata,"FireConeLerpto1",false) == 0)
								{
									char tmp[16][16];
									ExplodeString(weapdata," ",tmp,16,16);
									maxspread = StringToFloat(tmp[1]);
								}
								else if ((StrContains(weapdata,"ACT_VM_THROW",false) == 2) || (StrContains(weapdata,"ACT_VM_RECOIL",false) == 2))
								{
									char tmp[32][32];
									ExplodeString(weapdata," ",tmp,32,32);
									if (!CLAttachment[client])
									{
										if ((!StrEqual(tmp[1],"ACT_VM_THROW_SILENCED",false)) && (!StrEqual(tmp[1],"ACT_VM_THROW_EMPTY",false)) && (!StrEqual(tmp[1],"ACT_VM_PRIMARYATTACK_DEPLOYED",false)))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
									else if (CLAttachment[client])
									{
										if (StrEqual(tmp[1],"ACT_VM_THROW_SILENCED",false))
										{
											int prev;
											for (int i = 0;i<10;i++)
											{
												if ((atkanim[i] == 0) && (StringToInt(tmp[0]) != prev))
												{
													atkanim[i] = StringToInt(tmp[0]);
													prev = atkanim[i];
												}
											}
										}
									}
								}
								else if (StrContains(weapdata,"ACT_VM_IDLE",false) != -1)
								{
									char tmp[32][32];
									ExplodeString(weapdata," ",tmp,32,32);
									if (!CLAttachment[client])
									{
										if (!StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
										{
											resetanim = StringToInt(tmp[0]);
										}
									}
									else if (CLAttachment[client])
									{
										if (StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
										{
											resetanim = StringToInt(tmp[0]);
										}
									}
								}
							}
							ReadPackString(dp,weapdata,sizeof(weapdata));
						}
					}
					if (bullettype == 7)
					{
						int shotsfired = 0;
						curclip--;
						SetEntProp(client,Prop_Data,"m_iAmmo",curclip,_,12);
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
						float spread = startspread+(shotsfired/2);
						if (spread > maxspread) spread = maxspread;
						if (startspread > maxspread) spread = startspread;
						int sideoffs = 0;
						if (lefthanded) sideoffs = -4;
						if (HasEntProp(weap,Prop_Data,"m_nShotsFired")) SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
						float orgs[3];
						float angs[3];
						GetClientEyePosition(client,orgs);
						orgs[2]-=12.0;
						GetClientEyeAngles(client,angs);
						ReleaseFire(client,bullettype,orgs,angs,sideoffs,spread,weapworldmdl,dmgpass);
						if (fastfire)
						{
							CreateTimer(firerate,clearlast,client,TIMER_FLAG_NO_MAPCHANGE);
							firerate = 0.1;
							if (mode == 1) g_LastButtons[client] = IN_ATTACK;
							else g_LastButtons[client] = IN_ATTACK2;
						}
						if (mode == 1) centnextatk[weap] = GetGameTime()+firerate;
						else centnextatk2[weap] = GetGameTime()+firerate;
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							//int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((firerate+0.01 > 0.1) && (curclip > 0))
							{
								Handle vmdp = CreateDataPack();
								WritePackCell(vmdp,viewmdl);
								WritePackCell(vmdp,resetanim);
								WritePackCell(vmdp,weap);
								WritePackString(vmdp,curweap);
								CreateTimer(firerate+0.01,resetvmtoidle,vmdp,TIMER_FLAG_NO_MAPCHANGE);
							}
							else if (curclip <= 0)
							{
								if (iWeapList == -1) iWeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
								if (iWeapList != -1)
								{
									for (int j; j<104; j += 4)
									{
										int tmpi = GetEntDataEnt2(client,iWeapList + j);
										if (tmpi != -1)
										{
											char szWeapCls[64];
											GetEntityClassname(tmpi,szWeapCls,sizeof(szWeapCls));
											if (strlen(szWeapCls) > 0)
											{
												if (HasEntProp(tmpi,Prop_Data,"m_iClip1"))
												{
													if ((GetEntProp(tmpi,Prop_Data,"m_iClip1") > 0) || (GetEntProp(tmpi,Prop_Data,"m_iClip1") == -1))
													{
														Handle changedp = CreateDataPack();
														WritePackCell(changedp,client);
														WritePackString(changedp,szWeapCls);
														CreateTimer(0.15,useweap,changedp,TIMER_FLAG_NO_MAPCHANGE);
													}
												}
											}
										}
									}
								}
							}
							int randanim;
							for (int i = 0;i<10;i++)
							{
								if (atkanim[i] != 0) randanim = atkanim[i];
								else break;
							}
							int rand = GetRandomInt(atkanim[0],randanim);
							//PrintToServer("SetRand %i from %i",rand,seq);
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
						}
					}
				}
			}
		}
	}
	return;
}

public Action refire(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int client = ReadPackCell(dp);
		int weap = ReadPackCell(dp);
		char passedweap[64];
		ReadPackString(dp,passedweap,sizeof(passedweap));
		int sideoffs = ReadPackCell(dp);
		float startspread = ReadPackFloat(dp);
		float maxspread = ReadPackFloat(dp);
		int maxburst = ReadPackCell(dp);
		char curweap[64];
		if (IsValidEntity(weap)) GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
		if ((IsValidEntity(client)) && (StrEqual(curweap,passedweap,false)))
		{
			int shotsfired = 1;
			if (HasEntProp(weap,Prop_Data,"m_nShotsFired"))
			{
				shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
				SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
			}
			else shotsfired = maxburst;
			float spread = startspread+(shotsfired/2);
			if (spread > maxspread) spread = maxspread;
			float orgs[3];
			float angs[3];
			GetClientEyePosition(client,orgs);
			//orgs[2]-=12.0;
			GetClientEyeAngles(client,angs);
			ShootBullet(client,weap,1,curweap,orgs,angs,sideoffs,spread);
			if (shotsfired < maxburst) CreateTimer(0.2,refire,dp,TIMER_FLAG_NO_MAPCHANGE);
			else CloseHandle(dp);
		}
	}
}

public Action clearlast(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		g_LastButtons[client] &= ~IN_ATTACK;
		g_LastButtons[client] &= ~IN_ATTACK2;
	}
}

void ReloadCustomWeap(int client, int weap, char[] curweap, bool passedreload)
{
	if (IsValidEntity(client))
	{
		int findweap = FindStringInArray(swepsweap,curweap);
		if (findweap != -1)
		{
			int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
			Handle dp = GetArrayCell(swepsinfo,findweap);
			if (dp != INVALID_HANDLE)
			{
				bool singlereload = false;
				char weapdata[64];
				char snd[64];
				int relanim, resetanim, endanim;
				int maxclip = curclip;
				ResetPack(dp);
				ReadPackString(dp,weapdata,sizeof(weapdata));
				while (!StrEqual(weapdata,"endofpack",false))
				{
					if (StrContains(weapdata,"reload",false) == 0)
					{
						char tmp[4][64];
						ExplodeString(weapdata," ",tmp,4,64);
						Format(snd,sizeof(snd),"%s",tmp[1]);
					}
					else if (StrContains(weapdata,"clip_size",false) == 0)
					{
						char tmp[16][16];
						ExplodeString(weapdata," ",tmp,16,16);
						maxclip = StringToInt(tmp[1]);
					}
					else if (StrContains(weapdata,"default_clip",false) == 0)
					{
						char tmp[16][16];
						ExplodeString(weapdata," ",tmp,16,16);
						if (StringToInt(tmp[1]) > 0)
						{
							if (HasEntProp(weap,Prop_Data,"m_iMaxHealth")) SetEntProp(weap,Prop_Data,"m_iMaxHealth",StringToInt(tmp[1]));
						}
					}
					else if (StrContains(weapdata,"ACT_VM_RELOAD",false) != -1)
					{
						char tmp[32][32];
						ExplodeString(weapdata," ",tmp,32,32);
						if (!CLAttachment[client])
						{
							if (!StrEqual(tmp[1],"ACT_VM_RELOAD_SILENCED",false))
							{
								relanim = StringToInt(tmp[0]);
							}
						}
						else if (CLAttachment[client])
						{
							if (StrEqual(tmp[1],"ACT_VM_RELOAD_SILENCED",false))
							{
								relanim = StringToInt(tmp[0]);
							}
						}
					}
					else if (StrContains(weapdata,"ACT_SHOTGUN_",false) != -1)
					{
						char tmp[32][32];
						ExplodeString(weapdata," ",tmp,32,32);
						if (!CLAttachment[client])
						{
							if (!StrEqual(tmp[1],"ACT_SHOTGUN_RELOAD_SILENCED",false))
							{
								if (StrEqual(tmp[1],"ACT_SHOTGUN_RELOAD_START",false)) resetanim = StringToInt(tmp[0]);
								else if (StrEqual(tmp[1],"ACT_SHOTGUN_RELOAD_FINISH",false)) endanim = StringToInt(tmp[0]);
								singlereload = true;
							}
						}
						else if (CLAttachment[client])
						{
							if (StrContains(tmp[1],"ACT_SHOTGUN_RELOAD_SILENCED",false) == 0)
							{
								if (StrEqual(tmp[1],"ACT_SHOTGUN_RELOAD_SILENCED_START",false)) resetanim = StringToInt(tmp[0]);
								else if (StrEqual(tmp[1],"ACT_SHOTGUN_RELOAD_SILENCED_FINISH",false)) endanim = StringToInt(tmp[0]);
								singlereload = true;
							}
						}
					}
					else if ((StrContains(weapdata,"ACT_VM_IDLE",false) != -1) && (resetanim == 0))
					{
						char tmp[32][32];
						ExplodeString(weapdata," ",tmp,32,32);
						if (!CLAttachment[client])
						{
							if (!StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
							{
								resetanim = StringToInt(tmp[0]);
							}
						}
						else if (CLAttachment[client])
						{
							if (StrEqual(tmp[1],"ACT_VM_IDLE_SILENCED",false))
							{
								resetanim = StringToInt(tmp[0]);
							}
						}
					}
					ReadPackString(dp,weapdata,sizeof(weapdata));
				}
				if ((strlen(snd) > 0) && ((curclip < maxclip) || (passedreload)))
				{
					int ammtype = 0;
					if (HasEntProp(weap,Prop_Send,"m_iPrimaryAmmoType")) ammtype = GetEntProp(weap,Prop_Send,"m_iPrimaryAmmoType");
					else if (HasEntProp(weap,Prop_Data,"m_iPrimaryAmmoType")) ammtype = GetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType");
					int curamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,ammtype);
					if (curamm > 0)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							float reloadtime = 2.6;
							if (singlereload)
							{
								if (curclip < maxclip) maxclip = curclip+1;
								else
								{
									relanim = endanim;
									resetanim = endanim;
									singlereload = false;
								}
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == resetanim)
								{
									int tmp = relanim;
									relanim = resetanim;
									resetanim = tmp;
									reloadtime = 0.1;
									maxclip = curclip;
								}
								else reloadtime = 0.6;
							}
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",relanim);
							Handle vmdp = CreateDataPack();
							WritePackCell(vmdp,viewmdl);
							WritePackCell(vmdp,resetanim);
							WritePackCell(vmdp,weap);
							WritePackCell(vmdp,maxclip);
							WritePackString(vmdp,curweap);
							WritePackCell(vmdp,singlereload);
							CreateTimer(reloadtime,resetvmspec,vmdp,TIMER_FLAG_NO_MAPCHANGE);
						}
						EmitGameSoundToAll(snd,client);
						if (HasEntProp(weap,Prop_Data,"m_bInReload")) SetEntProp(weap,Prop_Data,"m_bInReload",1);
						g_LastButtons[client] |= IN_RELOAD;
					}
					else
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
						g_LastButtons[client] |= IN_RELOAD;
					}
				}
			}
		}
	}
	return;
}

void FireCamOutp(int client, int targ, char[] targn)
{
	Handle arr = CreateArray(32);
	FindAllByClassname(arr,-1,"hlss_camera_output");
	if (GetArraySize(arr) > 0)
	{
		for (int i = 0;i<GetArraySize(arr);i++)
		{
			int outp = GetArrayCell(arr,i);
			if (IsValidEntity(outp))
			{
				if (HasEntProp(outp,Prop_Data,"m_bDisabled"))
				{
					int disabled = GetEntProp(outp,Prop_Data,"m_bDisabled");
					if (!disabled)
					{
						char targchk[64];
						GetEntPropString(outp,Prop_Data,"m_target",targchk,sizeof(targchk));
						if (StrEqual(targchk,targn,false))
						{
							AcceptEntityInput(outp,"Trigger",client,targ);
						}
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

void FindAllByClassname(Handle arr, int ent, char[] classname)
{
	int thisent = FindEntityByClassname(ent,classname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		PushArrayCell(arr,thisent);
		FindAllByClassname(arr,thisent++,classname);
	}
}

int HasWeapon(int client, char[] cls)
{
	if ((IsValidEntity(client)) && (client != 0) && (strlen(cls) > 0))
	{
		if (iWeapList == -1) iWeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (iWeapList != -1)
		{
			for (int j; j<104; j += 4)
			{
				int tmpi = GetEntDataEnt2(client,iWeapList + j);
				if (tmpi != -1)
				{
					char szWeapCls[64];
					GetEntityClassname(tmpi,szWeapCls,sizeof(szWeapCls));
					if (StrEqual(szWeapCls,cls,false)) return tmpi;
				}
			}
		}
	}
	return 0;
}

public Action resetcoll(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int entity = ReadPackCell(dp);
		int collgrp = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(entity))
		{
			if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",collgrp);
		}
	}
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (IsValidEntity(entity))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if ((StrEqual(cls,"npc_hornet",false)) || (StrEqual(cls,"func_vehicleclip",false))) return false;
	}
	return true;
}