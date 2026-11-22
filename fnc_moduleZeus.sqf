#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Module init function for the ZEUS (Curator) jammer module.
 * The curator clicks this module in the side panel, then clicks on an object
 * in the 3D world. curatorCanAttach = 1 syncs the module to that object.
 *
 * If the module was double-clicked on an already-registered jammer, it will
 * update the jammer's strength (allowing the Zeus to set strength to 0 to
 * effectively disable an invincible jammer).
 *
 * Arguments (standard module init):
 * 0: Module logic object  <OBJECT>
 * 1: Synced units         <ARRAY>
 * 2: Activated             <BOOL>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [
    ["_logic",     objNull, [objNull]],
    ["_units",     [],      [[]]    ],
    ["_activated", true,    [true]  ],
    ["_isDialogCallback", false, [false]]
];

if (isNull _logic) exitWith {
    diag_log "[ACRE2 Jammer] moduleZeus: logic object is null.";
};

// FIX FOR DEDICATED SERVERS 
if (!local _logic) exitWith {};
if (!hasInterface) exitWith {}; // Headless server shouldn't open UIs

if (!_activated) exitWith {};

// Find the target object 
// curatorCanAttach = 1 syncs the module to the object the curator clicked on
private _syncedObjs = synchronizedObjects _logic;

private _target = objNull;
if (count _syncedObjs > 0) then {
    // Filter out Logic objects (the module itself or other logics)
    private _filtered = _syncedObjs select { !(_x isKindOf "Logic") };
    if (count _filtered > 0) then {
        _target = _filtered select 0;
    } else {
        _target = _syncedObjs select 0;
    };
} else {
    // Fallback: find nearest non-Logic object within 5m of module placement
    private _pos = getPos _logic;
    private _nearObjs = nearestObjects [_pos, [], 5];
    _nearObjs = _nearObjs select { !(_x isKindOf "Logic") };
    if (count _nearObjs > 0) then {
        _target = _nearObjs select 0;
    };
};

if (isNull _target) exitWith {
    if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] No object found! Click directly on the object you want to make a jammer."; };
    diag_log "[ACRE2 Jammer] Zeus module: no target object found.";
    deleteVehicle _logic;
};

private _radius      = _logic getVariable ["acre2_jammer_radius", 300];
private _strength    = _logic getVariable ["acre2_jammer_strength", 1.0];
private _reliability = _logic getVariable ["acre2_jammer_reliability", 1.0];
private _enabled     = _logic getVariable ["acre2_jammer_enabled", true];

if (_radius isEqualType "") then { _radius = parseNumber _radius; };
if (_strength isEqualType "") then { _strength = parseNumber _strength; };
if (_reliability isEqualType "") then { _reliability = parseNumber _reliability; };
if (_enabled isEqualType "") then { _enabled = (parseNumber _enabled) > 0; };

// Build side array from individual checkboxes
private _sides = [];
if ((_logic getVariable ["acre2_jammer_side_west", 1]) > 0) then { _sides pushBack west; };
if ((_logic getVariable ["acre2_jammer_side_east", 0]) > 0) then { _sides pushBack east; };
if ((_logic getVariable ["acre2_jammer_side_guer", 0]) > 0) then { _sides pushBack independent; };
if ((_logic getVariable ["acre2_jammer_side_civ",  0]) > 0) then { _sides pushBack civilian; };

if (count _sides == 0) then { _sides = [west]; };

// Check if this is the initial placement 
// In Zeus, modules execute immediately upon placement with default settings.
// Force the settings UI to open first, and only register AFTER the user clicks OK.
private _isPlaced = _logic getVariable ["acre2_jammer_placed", false];
if (!_isPlaced) exitWith {
    _logic setVariable ["acre2_jammer_placed", true, true];
    
    // If ZEN is loaded, forcefully pop up an interactive dialog right on placement
    if (isClass (configFile >> "CfgPatches" >> "zen_main")) then {
        [
            "ACRE2 Jammer Settings",
            [
                ["SLIDER:RADIUS", ["Radius (m)", "Spherical jamming radius."], [10, 5000, 300, 0, getPos _target, [0.8, 0.2, 0.2, 1.0]]],
                ["SLIDER", ["Strength (0-1)", "Jamming intensity. 1.0 = maximum distortion, 0.0 = no effect."], [0, 1, 1, 2]],
                ["SLIDER", ["Reliability (0-1)", "Uptime fraction. 1.0 = always on. 0.5 = 50% uptime."], [0, 1, 1, 2]],
                ["CHECKBOX", ["Jammer Enabled", "Is the jammer currently active?"], _enabled],
                ["CHECKBOX", ["Jam BLUFOR", "Jam BLUFOR (west) radio receivers."], west in _sides],
                ["CHECKBOX", ["Jam OPFOR", "Jam OPFOR (east) radio receivers."], east in _sides],
                ["CHECKBOX", ["Jam Independent", "Jam Independent (resistance) radio receivers."], independent in _sides],
                ["CHECKBOX", ["Jam Civilian", "Jam Civilian radio receivers."], civilian in _sides]
            ],
            {
                params ["_results", "_args"];
                _args params ["_logic"];
                _results params ["_radius", "_strength", "_reliability", "_enabled", "_jamWest", "_jamEast", "_jamGuer", "_jamCiv"];
                
                // Save the variables to the logic object so they are persistent for next time
                _logic setVariable ["acre2_jammer_radius", _radius, true];
                _logic setVariable ["acre2_jammer_strength", _strength, true];
                _logic setVariable ["acre2_jammer_reliability", _reliability, true];
                _logic setVariable ["acre2_jammer_enabled", _enabled, true];
                _logic setVariable ["acre2_jammer_side_west", if (_jamWest) then {1} else {0}, true];
                _logic setVariable ["acre2_jammer_side_east", if (_jamEast) then {1} else {0}, true];
                _logic setVariable ["acre2_jammer_side_guer", if (_jamGuer) then {1} else {0}, true];
                _logic setVariable ["acre2_jammer_side_civ", if (_jamCiv) then {1} else {0}, true];
                
                // Re-run the script with the updated variables to actually register the jammer
                [_logic, [], true, true] spawn acre2_jammer_fnc_moduleZeus;
            },
            {
                // User cancelled the initial placement dialog, delete the logic object
                params ["_results", "_args"];
                _args params ["_logic"];
                deleteVehicle _logic;
            },
            [_logic]
        ] call zen_dialog_fnc_create;
    } else {
        // Fallback for vanilla Arma 3: 
        // Use custom pure SQF dialog to pop up the window interactively
        [_logic, _target] spawn acre2_jammer_fnc_vanillaDialog;
    };
};

if (!_isDialogCallback) exitWith {};

// Check if target is already registered
private _existingIdx = GVAR(jammers) findIf { (_x select 0) isEqualTo _target };

if (_existingIdx >= 0) then {
    // Update existing jammer entry instead of double-registering
    private _entry = GVAR(jammers) select _existingIdx;
    _entry set [1, _radius];
    _entry set [2, _strength];
    _entry set [3, _reliability];
    _entry set [4, _sides];
    _entry set [5, _enabled];

    [] call FUNC(syncJammers);

    private _msg = format ["[ACRE2 Jammer] Updated existing jammer %1: r=%2m, s=%3, rel=%4, en=%5",
        typeOf _target, _radius, _strength, _reliability, _enabled];
    if (GVAR(debugEnabled)) then { systemChat _msg; };
    diag_log _msg;
    
    // Delete the new logic object so the Zeus interface doesnt get cluttered with duplicates
    // The original logic object remains
    deleteVehicle _logic;
} else {
    // Register as new jammer
    [_target, _radius, _strength, _reliability, _sides, _enabled] call FUNC(register);

    private _msg = format ["[ACRE2 Jammer] Registered %1 as jammer: r=%2m, s=%3, rel=%4, sides=%5, en=%6",
        typeOf _target, _radius, _strength, _reliability, _sides, _enabled];
    if (GVAR(debugEnabled)) then { systemChat _msg; };
    diag_log _msg;
    
    // Persistent logic object in Zeus, do not delete it
    // This allows the curator to double-click or delete the module icon
    _logic setVariable ["acre2_jammer_target", _target];
    _logic addEventHandler ["Deleted", {
        params ["_logic"];
        private _target = _logic getVariable ["acre2_jammer_target", objNull];
        if (!isNull _target) then {
            [_target] remoteExecCall ["acre2_jammer_fnc_unregister", 2];
        };
    }];
};
