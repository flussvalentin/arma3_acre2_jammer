#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Remove a jammer from the registry without destroying the object.
 *
 * Arguments:
 * 0: Jammer object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer] call acre2_jammer_fnc_unregister;
 *
 * Public: Yes
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] unregister: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(unregister), [_obj]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    diag_log "[ACRE2 Jammer] unregister: object not found in jammer registry (likely already deleted).";
};

GVAR(jammers) deleteAt _idx;
[] call FUNC(syncJammers);
