#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Register an object as a radio jammer.
 * Can be called from any machine — automatically deferred to server.
 *
 * Arguments:
 * 0: Jammer object    <OBJECT>              (required)
 * 1: Radius (m)       <NUMBER>  [300]       spherical 3D radius
 * 2: Strength (0-1)   <NUMBER>  [1.0]       jamming intensity
 * 3: Reliability (0-1)<NUMBER>  [1.0]       uptime fraction
 * 4: Jammed side(s)   <SIDE|ARRAY> [west]   single side or array of sides
 *
 * Return Value:
 * None
 *
 * Example:
 * [this, 400, 0.8, 1.0, west] call acre2_jammer_fnc_register;
 * [this, 200, 1.0, 0.5, [west, independent]] call acre2_jammer_fnc_register;
 *
 * Public: Yes
 */

params [
    ["_obj",         objNull, [objNull]],
    ["_radius",      300,     [0]      ],
    ["_strength",    1.0,     [0]      ],
    ["_reliability", 1.0,     [0]      ],
    ["_side",        west,    [west, []]],
    ["_enabled",     true,    [true]   ]
];

if (isNull _obj) exitWith {
    diag_log "[ACRE2 Jammer] register: object is null.";
    if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] register: object is null."; };
};

// Clamp values
_radius      = _radius      max 1;
_strength    = (_strength    max 0.0) min 1.0;
_reliability = (_reliability max 0.0) min 1.0;

// Delegate to server, all mutations are server-authoritative
if (!isServer) exitWith {
    [_obj, _radius, _strength, _reliability, _side, _enabled] remoteExecCall [QFUNC(register), 2];
};

// Destroyability check 
// Allow indestructible objects but warn the user
private _isIndestructible = false;
if (isSimpleObject _obj) then {
    _isIndestructible = true;
} else {
    private _destrType = getNumber (configOf _obj >> "destrType");
    if (_destrType == 0) then {
        _isIndestructible = true;
    };
};

if (_isIndestructible) then {
    private _msg = format [
        "[ACRE2 Jammer] WARNING: %1 (%2) is INDESTRUCTIBLE — this jammer can never be silenced by destroying it! To disable it, drop the Zeus module on it again and set Strength to 0.0.",
        typeOf _obj, _obj
    ];
    if (GVAR(debugEnabled)) then { systemChat _msg; };
    diag_log _msg;
};

// Prevent double-registration
private _existing = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_existing >= 0) exitWith {
    diag_log "[ACRE2 Jammer] register: object already registered. Use setStrength/setRadius etc. to modify.";
    if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] register: object already registered."; };
};

// Build jammer entry
//   [object, radius, strength, reliability, side, enabled, reliabilityState]
private _entry = [_obj, _radius, _strength, _reliability, _side, _enabled, true];
GVAR(jammers) pushBack _entry;

// Auto-unregister when the object is deleted (e.g. by Zeus pressing delete)
_obj addEventHandler ["Deleted", { 
    params ["_entity"];
    [_entity] call FUNC(unregister);
}];

// Destroyed also auto-unregisters (only if object can actually be destroyed)
if (!_isIndestructible) then {
    _obj addEventHandler ["Killed", { 
        params ["_entity"];
        [_entity] call FUNC(onDestroyed);
    }];
};

// Sync
[] call FUNC(syncJammers);

// Add hacking actions to this object globally (all clients + JIP)
[_obj] remoteExecCall [QFUNC(addHackAction), 0, _obj];

