#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Synchronise the jammer array to all clients.
 * Must be called on the SERVER after any change to GVAR(jammers).
 *
 * Clients listen via the "acre2_jammer_sync" CBA event (registered in postInit).
 * Also sets the public variable for JIP compatibility.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!isServer) exitWith {};

// Make a serialisable copy — objects and sides are supported by publicVariable
missionNamespace setVariable [JAMMER_SYNC_VAR, GVAR(jammers), true];

// Broadcast via CBA event for live clients (faster than publicVariable alone)
["acre2_jammer_sync", GVAR(jammers)] call CBA_fnc_globalEvent;
