#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Change which side(s) a jammer targets.
 *
 * Arguments:
 * 0: Jammer object         <OBJECT>
 * 1: Side or array of sides<SIDE|ARRAY>
 *    Valid single sides: west, east, independent, civilian
 *    Array example: [west, independent]
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer, east] call acre2_jammer_fnc_setSide;
 * [myJammer, [east, independent]] call acre2_jammer_fnc_setSide;
 *
 * Public: Yes
 */

params [
    ["_obj",  objNull, [objNull]],
    ["_side", west,    [west, []]]
];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] setSide: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(setSide), [_obj, _side]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    ["[ACRE2 Jammer] setSide: object not registered."] call CBA_fnc_error;
};

(GVAR(jammers) select _idx) set [4, _side];
[] call FUNC(syncJammers);
