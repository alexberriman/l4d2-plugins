#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <l4d2_direct>
#include <left4downtown>
#include <colors>
#include <l4d_tank_control>
#include <readyup>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

new Handle:h_tankVotes;
new Handle:h_tankVoteSteamIds;
new Handle:h_whosVoted;


public Plugin:myinfo = 
{
    name = "L4D2 Tank Vote",
    author = "arti",
    description = "Allows players to vote on who should be tank during the round",
    version = "0.0.1",
    url = ""
}

enum L4D2Team
{
    L4D2Team_None = 0,
    L4D2Team_Spectator,
    L4D2Team_Survivor,
    L4D2Team_Infected
}


public OnPluginStart()
{
    // Load translations (for targeting player)
    LoadTranslations("common.phrases");
    
    // Initialise the tank data arrays
    h_tankVotes = CreateArray(64);
    h_whosVoted = CreateArray(64);
    h_tankVoteSteamIds = CreateArray(64);
    
    // Vote on who becomes tank
    RegConsoleCmd("sm_tankvote", Tank_Vote, "Vote on who becomes the tank");
    RegConsoleCmd("sm_votetank", Tank_Vote, "Vote on who becomes the tank");
    RegConsoleCmd("sm_votemenu", Vote_Menu, "Display the meny");
    
    // Admin commands
    RegAdminCmd("sm_setvotetank", SetTank_Cmd, ADMFLAG_SLAY, "Manual trigger to send queued tank to l4d_tank_control");
}


/**
 * Initialise the handles (also used to reset handles)
 */
 
public clearHandles()
{
    ClearArray(h_tankVotes);
    ClearArray(h_whosVoted);
    ClearArray(h_tankVoteSteamIds);
}

/**
 * Sets the tank (hooking in to l4d_tank_control)
 */
 
public Action:SetTank_Cmd(client, args)
{
    setTank();    
    return Plugin_Handled;
}


/**
 * When the round goes live (finished with rup), send the queued tank to l4d_tank_control
 */
 
public OnRoundIsLive()
{
    setTank();
}

/**
 * Set the tank.
 *
 * Iterates through the handles to look for the player who has received the
 * most votes, and instructs l4d_tank_control to mark them as tank.
 */
 
public setTank() 
{
    // If nobody has voted on someone to become tank, nothing to do
    if (GetArraySize(h_tankVoteSteamIds) == 0)
    {
        clearHandles();
        return;
    }
    
    decl String:steamId[64];
    new mostVotes = 0;
    new mostVotesIndex = -1;
    new votes;
    
    // Iterate through tank votes and retrieve most voted player
    for (new i = 0; i < GetArraySize(h_tankVoteSteamIds); i++)
    {
        GetArrayString(h_tankVoteSteamIds, i, steamId, sizeof(steamId));
        votes = GetArrayCell(h_tankVotes, i);
        
        // If we have a new leader
        if (votes > mostVotes)
        {
            mostVotes = votes;
            mostVotesIndex = i;
        }
    }
    
    // Instruct l4d_tank_control who the tank is
    GetArrayString(h_tankVoteSteamIds, mostVotesIndex, steamId, sizeof(steamId));
    TankControl_SetTank(steamId);
    
    // Reset the handles
    clearHandles();
}

/**
 * Allow players to vote on who should become tank
 */
 
public Action:Tank_Vote(client, args)
{
    // If not in ready up, unable to vote
    if (IsInReady() == false)
    {
        CPrintToChat(client, "{red}[Tank Vote] {default}You are only able to vote during ready-up");
        return Plugin_Handled;
    }
        
     // Who are we targetting?
    new String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    // If no argument passed through, show the menu
    if (arg1[0] == EOS)
    {
        displayVoteMenu(client);
        return Plugin_Handled;
    }

    // Try and find a matching player
    new target = FindTarget(0, arg1);
    if (target == -1)
    {
        CPrintToChat(client, "{red}[Tank Control] {default}The selected player was not found.");
        return Plugin_Handled;
    }
    
    // Try to register the vote
    registerClientVote(client, target);
    return Plugin_Handled;
}


/**
 * Handler for the vote menu.
 *
 * @param Handle:menu
 *  The menu instantiating the handler.
 * @param MenuAction:action
 *  The menu action (i.e. Select/Cancel etc.)
 * @param param1
 *  The client id for user who made a selection.
 * @param param2
 *  The value for the menu choice (i.e. our case steam id)
 */
 
public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            // Retrieve the target client id
            decl String:targetSteamId[64];
            GetMenuItem(menu, param2, targetSteamId, sizeof(targetSteamId));
            new target = getInfectedPlayerBySteamId(targetSteamId);
            
            // Register the client vote
            registerClientVote(param1, target);
        }
 
        case MenuAction_Cancel:
        {
        }
 
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
     }
 
    return 0;
}

/**
 * Display the vote menu
 *
 * @param client
 *  The client who the vote menu is being rendered for.
 * @param args
 *  Additional command arguments.
 */
 
public Action:Vote_Menu(client, args)
{
    displayVoteMenu(client);    
    return Plugin_Handled;
}

/**
 * Code which actually display the vote menu.
 *
 * @param client
 *  The client who the vote menu is being rendered for.
 */

 public displayVoteMenu(client)
 {
    // Variable declaration to hold our menu/client information
    new clientId;
    decl String:steamId[64];
    decl String:targetName[64];  
    new Handle:infectedPool = TankControl_GetTankPool();
    new Handle:menu = CreateMenu(VoteMenuHandler, MENU_ACTIONS_DEFAULT);
    
    SetMenuTitle(menu, "Select a player to become tank");
   
    // Add menu items (players in tank pool)
    for (new i = 0; i < GetArraySize(infectedPool); i++)
    {
        GetArrayString(infectedPool, i, steamId, sizeof(steamId));
        clientId = getInfectedPlayerBySteamId(steamId);
        GetClientName(clientId, targetName, sizeof(targetName));
        
        AddMenuItem(menu, steamId, targetName);
    }

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 20);
}


/**
 * Registers a client vote.
 *
 * @param client
 *  The client casting the vote.
 * @param target
 *  The client id of the target player (player voted to become tank)
 */
 
public registerClientVote(client, target)
{
    // Retrieve players in the infected pool
    decl String:steamId[64];
    new Handle:infectedPool = TankControl_GetTankPool();
    
    // Get the targetted player's name
    decl String:targetName[64];
    GetClientName(target, targetName, sizeof(targetName));
    
    // Get the client name
    decl String:clientName[64];
    GetClientName(client, clientName, sizeof(clientName));
    
    // Set the tank
    if (IS_VALID_INFECTED(target))
    {
        GetClientAuthString(target, steamId, sizeof(steamId));
        if (inHandle(infectedPool, steamId))
        {
            if (hasVoted(client) == false)
            {
                registerTankVote(client, steamId);
                PrintToInfected("{red}[Tank Vote] {default}{olive}%s {default}has voted for {olive}%s", clientName, targetName);
            }
            else
            {
                CPrintToChat(client, "{red}[Tank Vote] {default}You have already voted this round.");
            }
        }
        else
        {
            CPrintToChat(client, "{red}[Tank Vote] {olive}%s {default}is not in the tank pool", targetName);
        }
    }
    
    // Player not on infected
    else
    {
        CPrintToChat(client, "{red}[Tank Control] {default}{olive}%s {default}is not available to become tank", targetName);
    }
    
    CloseHandle(infectedPool);
}

/**
 * Registers a tank vote
 *
 * @param client
 *     The client registering the vote.
 * @param String:targetSteamId[]
 *     The player the vote is being casted for to become tank.
 */
 
public registerTankVote(client, const String:targetSteamId[])
{    
    // Retrieve the steam id of the client
    decl String:steamId[64];
    GetClientAuthString(client, steamId, sizeof(steamId));
    
    // Retrieve the client of the target steam id
    
    
    // If the client has already voted, do nothing (can not vote twice)
    if (hasVoted(client))
    {
        return;
    }
    
    // If a player has already received a vote, update it
    if (inHandle(h_tankVoteSteamIds, targetSteamId))
    {
        new targetClientId = getInfectedPlayerBySteamId(targetSteamId);
        new index = getVotePlayerIndex(targetClientId);
        new currentVotes = GetArrayCell(h_tankVotes, index);

        SetArrayCell(h_tankVotes, index, ++currentVotes);
    }
    
    // If its the initial vote for a player
    else 
    {
        PushArrayString(h_tankVoteSteamIds, targetSteamId);
        PushArrayCell(h_tankVotes, 1);
    }
    
    // Mark the client as having voted
    PushArrayString(h_whosVoted, steamId);
}


/**
 * Tells you whether a target steam id is in the tank pool
 * 
 * @param Handle:sourceHandle
 *     The pool of potential steam ids to become tank.
 * @param String:searchString
 *     The steam ids of player you are looking for.
 * 
 * @return
 *     TRUE is player is in pool, FALSE if not
 */
 
public bool:inHandle(Handle:sourceHandle, const String:searchString[])
{
    decl String:arrayString[64];
    
    for (new i = 0; i < GetArraySize(sourceHandle); i++)
    {
        GetArrayString(sourceHandle, i, arrayString, sizeof(arrayString));
        if (strcmp(arrayString, searchString) == 0)
        {
            return true;
        }
    }
    
    return false;
}


/**
 * The index in the handle of the player whos trying to be voted on
 
 * @param client
 *    The client whos being checked.
 *
 * @return
 *    The index (-1 if not found)
 */
 
public getVotePlayerIndex(client)
{
    // Retrieve the steam id of the client
    decl String:steamId[64];
    decl String:targetSteamId[64];
    
    GetClientAuthString(client, targetSteamId, sizeof(targetSteamId));    

    // Has the client voted
    for (new i = 0; i < GetArraySize(h_tankVoteSteamIds); i++)
    {
        GetArrayString(h_tankVoteSteamIds, i, steamId, sizeof(steamId));
        if (strcmp(steamId, targetSteamId) == 0)
        {
            return i;
        }
    }
    
    return -1;
}


/**
 * Whether or not a player has already voted for the round.
 
 * @param client
 *    The client whos being checked.
 *
 * @return
 *    TRUE if the player has voted, FALSE if not
 */
 
public bool:hasVoted(client)
{
    return getVotePlayerIndex(client) >= 0;
}


/**
 * Retrieves a player's client index by their steam id.
 * 
 * @param const String:steamId[]
 *     The steam id to look for.
 * 
 * @return
 *     The player's client index.
 */
 
public getInfectedPlayerBySteamId(const String:steamId[]) 
{
    decl String:tmpSteamId[64];
   
    for (new i = 1; i <= MaxClients; i++) 
    {
        if (!IS_VALID_INFECTED(i))
            continue;
        
        GetClientAuthString(i, tmpSteamId, sizeof(tmpSteamId));     
        
        if (StrEqual(steamId, tmpSteamId))
            return i;
    }
    
    return -1;
}


/**
 * Prints a message to the infected team
 *
 * @param String:Message[]
 *  The message to print
 */
 
stock PrintToInfected(const String:Message[], any:... )
{
    decl String:sPrint[256];
    VFormat(sPrint, sizeof(sPrint), Message, 2);

    for (new i = 1; i <= MaxClients; i++) 
    {
        if (!IS_VALID_INFECTED(i)) 
        { 
            continue; 
        }

        CPrintToChat(i, "{default}%s", sPrint);
    }
}