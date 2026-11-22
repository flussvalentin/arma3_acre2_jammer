#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Module init function for the EDEN (3D Editor) jammer module.
 * Reads attributes from the module logic, builds a side array from
 * the four side checkboxes, then registers each synced object as a jammer.
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
    ["_activated", true,    [true]  ]
];

if (isNull _logic) exitWith {
    diag_log "[ACRE2 Jammer] moduleInit: logic object is null.";
};
if (!isServer) exitWith {};
if (!_activated) exitWith {};

// Read attributes 
private _radius      = _logic getVariable ["acre2_jammer_radius", 300];
private _strength    = _logic getVariable ["acre2_jammer_strength", 1.0];
private _reliability = _logic getVariable ["acre2_jammer_reliability", 1.0];

if (_radius isEqualType "") then { _radius = parseNumber _radius; };
if (_strength isEqualType "") then { _strength = parseNumber _strength; };
if (_reliability isEqualType "") then { _reliability = parseNumber _reliability; };

// Build side array from individual checkboxes
private _sides = [];
if ((_logic getVariable ["acre2_jammer_side_west", 1]) > 0) then { _sides pushBack west; };
if ((_logic getVariable ["acre2_jammer_side_east", 0]) > 0) then { _sides pushBack east; };
if ((_logic getVariable ["acre2_jammer_side_guer", 0]) > 0) then { _sides pushBack independent; };
if ((_logic getVariable ["acre2_jammer_side_civ",  0]) > 0) then { _sides pushBack civilian; };

if (count _sides == 0) then { _sides = [west]; };

// Get synced objects
private _syncedObjs = synchronizedObjects _logic;
if (count _syncedObjs == 0) exitWith {
    private _msg = "[ACRE2 Jammer] Eden module has no synced objects! Sync this module to the object you want to become a jammer.";
    if (GVAR(debugEnabled)) then { systemChat _msg; };
    diag_log _msg;
};

// Register each synced object
{
    diag_log format ["[ACRE2 Jammer] Eden module registering: %1 (r=%2, s=%3, rel=%4, sides=%5)", typeOf _x, _radius, _strength, _reliability, _sides];
    [_x, _radius, _strength, _reliability, _sides] call FUNC(register);
} forEach _syncedObjs;

// Clean up the logic entity
deleteVehicle _logic;
