#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Adds the "Hack Jammer" action to a jammer object on the local machine.
 * Supports both ACE3 Interaction Menu and Vanilla Scroll Wheel.
 * 
 * Arguments:
 * 0: Jammer object <OBJECT>
 * 
 * Return Value:
 * None
 * 
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj) exitWith {};

// Prevent adding multiple times
if (_obj getVariable ["acre2_jammer_hasHackAction", false]) exitWith {};
_obj setVariable ["acre2_jammer_hasHackAction", true, false];

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    // ACE Interaction Menu
    private _action = [
        "acre2_jammer_hack",
        "Hack Jammer",
        "", // icon
        {
            params ["_target", "_player", "_params"];
            [_target] spawn acre2_jammer_fnc_hackDialog;
        },
        { true } // condition
    ] call ace_interact_menu_fnc_createAction;
    
    [_obj, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
} else {
    // Vanilla Scroll Wheel Menu
    _obj addAction [
        "<t color='#FF0000'>Hack Jammer</t>",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            [_target] spawn acre2_jammer_fnc_hackDialog;
        },
        nil,
        1.5,
        true,
        true,
        "",
        "alive _target && { _this distance _target < 5 }",
        5
    ];
};
