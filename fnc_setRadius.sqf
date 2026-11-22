#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Change the jamming radius of a registered jammer at runtime.
 *
 * Arguments:
 * 0: Jammer object  <OBJECT>
 * 1: Radius (m)     <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer, 500] call acre2_jammer_fnc_setRadius;
 *
 * Public: Yes
 */

params [
    ["_obj",    objNull, [objNull]],
    ["_radius", 300,     [0]      ]
];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] setRadius: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(setRadius), [_obj, _radius]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    ["[ACRE2 Jammer] setRadius: object not registered."] call CBA_fnc_error;
};

_radius = _radius max 1;
(GVAR(jammers) select _idx) set [1, _radius];
[] call FUNC(syncJammers);
