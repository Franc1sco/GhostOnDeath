#include <sourcemod>
#include <sdktools>

// NO THIS TIME LOL
//
//#include <SpanishPawn.inc>
//

#pragma newdecls required

#define VERSION "1.0"

// Boolean per client for disable his ghost
bool g_bGhost[MAXPLAYERS+1];

// Boolean for disable ghosts in general
bool g_bGhostsEnabled = true;

public Plugin myinfo = {
	name = "SM CS:GO Ghost on Death",
	author = "Franc1sco franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	// Command for ROOT admins to disable ghosts in general
	RegAdminCmd("sm_ghosts", Command_ToggleForAll, ADMFLAG_ROOT);
	
	// Command for normal users to disable ghost on himself
	RegConsoleCmd("sm_ghost", Command_TogglePerClient);
	
	//Hook Death event where the ghost will appear
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	// Enable ghost for clients on late load by default
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			g_bGhost[i] = true;		
}

public void OnMapStart()
{
	// Download materials/particles and prechache for prevent client crashes
	AddFileToDownloadsTable("particles/ghosts.pcf");
	PrecacheGeneric("particles/ghosts.pcf", true);
	
	AddFileToDownloadsTable("materials/effects/largesmoke.vmt");
	PrecacheModel("materials/effects/largesmoke.vmt");
	
	AddFileToDownloadsTable("materials/effects/largesmoke.vtf");
	AddFileToDownloadsTable("materials/effects/animatedeyes/animated_eyes.vmt");
	
	PrecacheModel("materials/effects/animatedeyes/animated_eyes.vmt");
	AddFileToDownloadsTable("materials/effects/animatedeyes/animated_eyes.vtf");
	
	AddFileToDownloadsTable("materials/effects/softglow_translucent_fog.vmt");
	PrecacheModel("materials/effects/softglow_translucent_fog.vmt");
	
	AddFileToDownloadsTable("materials/effects/outline_translucent.vtf");
	
	// Prechache the particle correcly for prevent client crashes (Thanks Rachnus)
	PrecacheParticleSystem("ghosts");
}

public Action Command_TogglePerClient(int iClient, int iArgs)
{
	// Change the current value
	g_bGhost[iClient] = !g_bGhost[iClient];
	
	PrintToChat(iClient, "[Ghosts] Your Ghost has been %s.", g_bGhost[iClient]?"enabled":"disabled");

	return Plugin_Handled;
}

public Action Command_ToggleForAll(int iClient, int iArgs)
{
	// Change the current value
	g_bGhostsEnabled = !g_bGhostsEnabled;
	
	PrintToChat(iClient, "[Ghosts] Ghosts %s for everyone.", g_bGhostsEnabled?"enabled":"disabled");
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int iClient)
{
	// Enable ghost for new clients by default
	g_bGhost[iClient] = true;
}

public Action Event_PlayerDeath(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	// If ghosts has been disabled by a admin then dont continue with the code
	if (!g_bGhostsEnabled) return;
	
	// We get the client of this event
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	// If ghosts has been disabled by the user then dont continue with the code
	if (!g_bGhost[iClient])return;
	
	float fPos[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPos); // get the current position 

	// We adapt the position a bit better
	fPos[2] += -50.0;
			
	// We set the ghost color depending the client team
	char sGhostColor[32];
	Format(sGhostColor, sizeof(sGhostColor), "%s", GetClientTeam(iClient) == 2 ? "Ghost_Red":"Ghost_Cyan");

	// Spawn the particle effect
	int iGhost = CreateEntityByName("info_particle_system");
	DispatchKeyValue(iGhost, "start_active", "0");
	DispatchKeyValue(iGhost, "effect_name", sGhostColor); // We set the ghost color here
	DispatchSpawn(iGhost); // Spawn the particle on World

	TeleportEntity(iGhost, fPos, NULL_VECTOR, NULL_VECTOR); // Teleport to the correct position

	// Activate the particle
	ActivateEntity(iGhost);
	AcceptEntityInput(iGhost, "Start");
}

/*
		The code starting from here has been taken from https://forums.alliedmods.net/showthread.php?p=2549099
*/
stock int PrecacheParticleSystem(const char[] particleSystem)
{
    static int particleEffectNames = INVALID_STRING_TABLE;

    if (particleEffectNames == INVALID_STRING_TABLE) {
        if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
            return INVALID_STRING_INDEX;
        }
    }

    int index = FindStringIndex2(particleEffectNames, particleSystem);
    if (index == INVALID_STRING_INDEX) {
        int numStrings = GetStringTableNumStrings(particleEffectNames);
        if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
            return INVALID_STRING_INDEX;
        }
        
        AddToStringTable(particleEffectNames, particleSystem);
        index = numStrings;
    }
    
    return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
    char buf[1024];
    
    int numStrings = GetStringTableNumStrings(tableidx);
    for (int i=0; i < numStrings; i++) {
        ReadStringTable(tableidx, i, buf, sizeof(buf));
        
        if (StrEqual(buf, str)) {
            return i;
        }
    }
    
    return INVALID_STRING_INDEX;
}

