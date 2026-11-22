#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Applies the results of a jammer hack.
 * Runs on the server.
 * 
 * Arguments:
 * 0: Jammer object <OBJECT>
 * 1: Enabled <BOOL>
 * 2: Jammed sides <ARRAY>
 * 
 * Return Value:
 * None
 * 
 * Public: No
 */

params [
    ["_obj", objNull, [objNull]],
    ["_newEnabled", true, [true]],
    ["_newSides", [], [[]]]
];

if (!isServer) exitWith {
    [_obj, _newEnabled, _newSides] remoteExecCall [QFUNC(applyHack), 2];
};

if (isNull _obj) exitWith {
    diag_log "[ACRE2 Jammer] applyHack: object is null.";
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    diag_log "[ACRE2 Jammer] applyHack: object not registered.";
};

private _entry = GVAR(jammers) select _idx;
_entry set [4, _newSides];
_entry set [5, _newEnabled];

[] call FUNC(syncJammers);
