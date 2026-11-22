#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Event handler called when a registered jammer object is killed/destroyed.
 * Permanently removes the jammer from the active registry.
 *
 * Arguments:
 * 0: Killed object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_killedObj"];

// Remove from jammer array (server-authoritative)
if (!isServer) exitWith {};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _killedObj };
if (_idx < 0) exitWith {};

GVAR(jammers) deleteAt _idx;

// Sync removal to all clients
[] call FUNC(syncJammers);
