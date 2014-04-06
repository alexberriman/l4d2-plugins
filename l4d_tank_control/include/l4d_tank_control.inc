#if defined _l4d_tank_control_included
 #endinput
#endif
#define _l4d_tank_control_included

/**
 * Returns the infected players currently in the tank queue.
 *
 * @return        A handle with the tank players available in the queue.
 */
native Handle:TankControl_GetTankPool();

/**
 * Sets a player to become tank.
 *
 * @param str      Steam id to set as tank.
 * @noreturn
 */
native TankControl_SetTank(String:steamId[]);