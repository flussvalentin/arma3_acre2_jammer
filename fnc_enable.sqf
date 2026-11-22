#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Enable a jammer that was previously disabled.
 * The physical object remains untouched.
 *
 * Arguments:
 * 0: Jammer object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [myJammer] call acre2_jammer_fnc_enable;
 *
 * Public: Yes
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj) exitWith {
    ["[ACRE2 Jammer] enable: object is null."] call CBA_fnc_error;
};

if (!isServer) exitWith {
    [FUNC(enable), [_obj]] call CBA_fnc_serverEvent;
};

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith {
    ["[ACRE2 Jammer] enable: object not registered."] call CBA_fnc_error;
};

(GVAR(jammers) select _idx) set [5, true];
[] call FUNC(syncJammers);
