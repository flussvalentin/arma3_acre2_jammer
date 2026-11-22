#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Change the jamming strength of a registered jammer at runtime.
 *
 * Arguments:
 * 0: Jammer object   <OBJECT>
 * 1: Strength (0–1)  <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer, 0.5] call acre2_jammer_fnc_setStrength;
 *
 * Public: Yes
 */

params [
    ["_obj",      objNull, [objNull]],
    ["_strength", 1.0,     [0]      ]
];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] setStrength: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(setStrength), [_obj, _strength]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    ["[ACRE2 Jammer] setStrength: object not registered."] call CBA_fnc_error;
};

_strength = (_strength max 0.0) min 1.0;
(GVAR(jammers) select _idx) set [2, _strength];
[] call FUNC(syncJammers);
