#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Change the reliability of a registered jammer at runtime.
 * The new value takes effect on the next reliability-loop cycle.
 *
 * Arguments:
 * 0: Jammer object       <OBJECT>
 * 1: Reliability (0–1)   <NUMBER>
 *    1.0 = always on
 *    0.5 = ~50% uptime
 *    0.0 = almost never on
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer, 0.75] call acre2_jammer_fnc_setReliability;
 *
 * Public: Yes
 */

params [
    ["_obj",         objNull, [objNull]],
    ["_reliability", 1.0,     [0]      ]
];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] setReliability: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(setReliability), [_obj, _reliability]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    ["[ACRE2 Jammer] setReliability: object not registered."] call CBA_fnc_error;
};

_reliability = (_reliability max 0.0) min 1.0;
(GVAR(jammers) select _idx) set [3, _reliability];

// If reliability is now 1.0, immediately force reliabilityState on
if (_reliability >= 1.0) then {
    (GVAR(jammers) select _idx) set [6, true];
};

[] call FUNC(syncJammers);
