#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Interactive dialog for hacking a jammer.
 * 
 * Arguments:
 * 0: Jammer object <OBJECT>
 */
params ["_obj"];

private _idx = GVAR(jammers) findIf { (_x select 0) isEqualTo _obj };
if (_idx < 0) exitWith { if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Cannot hack: jammer not registered."; }; };

private _entry = GVAR(jammers) select _idx;
private _sides = _entry select 4;
private _enabled = _entry select 5;

// The default _sides might be a single side (e.g. west). Cast to array for 'in' checks.
if !(_sides isEqualType []) then { _sides = [_sides]; };

disableSerialization;
createDialog "ACRE2_Jammer_HackDialog";
private _display = findDisplay 8473;
if (isNull _display) exitWith { if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Failed to open hack dialog."; }; };

// Make the dialog persistent in a variable so controls can access _obj
_display setVariable ["hackObj", _obj];

// Base positions
private _w = 0.35 * safezoneW;
private _h = 0.55 * safezoneH;
private _xPos = 0.5 - _w / 2;
private _yPos = 0.5 - _h / 2;
private _spacingY = 0.04 * safezoneH;
private _curY = _yPos + _spacingY;

// Background
private _bg = _display ctrlCreate ["IGUIBack", -1];
_bg ctrlSetPosition [_xPos, _yPos, _w, _h];
_bg ctrlSetBackgroundColor [0.15, 0.15, 0.15, 0.9];
_bg ctrlCommit 0;

// Title
private _title = _display ctrlCreate ["RscText", -1];
_title ctrlSetPosition [_xPos, _yPos, _w, _spacingY];
_title ctrlSetBackgroundColor [0.8, 0.2, 0.2, 1];
_title ctrlSetText "HACK ACRE2 JAMMER";
_title ctrlCommit 0;

_curY = _curY + _spacingY * 0.5;

// Function to create a checkbox with a label
private _fnc_createCheckbox = {
    params ["_labelStr", "_default", "_curY"];
    
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition [_xPos + 0.01 * safezoneW, _curY, _w * 0.5, _spacingY];
    _label ctrlSetText _labelStr;
    _label ctrlCommit 0;

    private _cb = _display ctrlCreate ["RscCheckbox", -1];
    _cb ctrlSetPosition [_xPos + 0.2 * safezoneW, _curY + 0.005 * safezoneH, 0.02 * safezoneW, 0.03 * safezoneH];
    _cb cbSetChecked _default;
    _cb ctrlCommit 0;
    
    _cb
};

// Checkboxes
private _cbEnabled = ["Jammer Enabled", _enabled, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;

_curY = _curY + _spacingY * 0.5;
private _subtitle = _display ctrlCreate ["RscText", -1];
_subtitle ctrlSetPosition [_xPos + 0.01 * safezoneW, _curY, _w, _spacingY];
_subtitle ctrlSetText "Jammed Factions:";
_subtitle ctrlCommit 0;
_curY = _curY + _spacingY;

private _cbWest = ["Jam BLUFOR", west in _sides, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbEast = ["Jam OPFOR", east in _sides, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbGuer = ["Jam Independent", independent in _sides, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbCiv = ["Jam Civilian", civilian in _sides, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;

_curY = _curY + _spacingY * 0.5;

// Save controls to display
_display setVariable ["cbEnabled", _cbEnabled];
_display setVariable ["cbWest", _cbWest];
_display setVariable ["cbEast", _cbEast];
_display setVariable ["cbGuer", _cbGuer];
_display setVariable ["cbCiv", _cbCiv];

// OK Button
private _btnOk = _display ctrlCreate ["RscButtonMenuOK", 1];
_btnOk ctrlSetPosition [_xPos + _w - 0.1 * safezoneW, _yPos + _h - _spacingY, 0.1 * safezoneW, _spacingY];
_btnOk ctrlCommit 0;

_btnOk ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;
    private _obj = _disp getVariable ["hackObj", objNull];
    
    private _cbEnabled = _disp getVariable ["cbEnabled", controlNull];
    private _cbWest = _disp getVariable ["cbWest", controlNull];
    private _cbEast = _disp getVariable ["cbEast", controlNull];
    private _cbGuer = _disp getVariable ["cbGuer", controlNull];
    private _cbCiv = _disp getVariable ["cbCiv", controlNull];
    
    private _newEnabled = cbChecked _cbEnabled;
    private _newSides = [];
    if (cbChecked _cbWest) then { _newSides pushBack west; };
    if (cbChecked _cbEast) then { _newSides pushBack east; };
    if (cbChecked _cbGuer) then { _newSides pushBack independent; };
    if (cbChecked _cbCiv) then { _newSides pushBack civilian; };
    
    _disp closeDisplay 1;
    
    // Launch hacking progress bar
    private _hackTime = acre2_jammer_hackTime;
    private _onSuccess = {
        params ["_args"];
        _args params ["_obj", "_newEnabled", "_newSides"];
        
        [_obj, _newEnabled, _newSides] remoteExecCall ["acre2_jammer_fnc_applyHack", 2];
        if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Hack complete!"; };
    };
    private _onFail = {
        if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Hack interrupted!"; };
    };
    
    if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
        // ACE Progress bar
        [_hackTime, [_obj, _newEnabled, _newSides], _onSuccess, _onFail, "Hacking Jammer..."] call ace_common_fnc_progressBar;
    } else {
        // CBA Progress bar (Vanilla fallback)
        if (isNil "CBA_fnc_progressBar") then {
            // Very old CBA or somehow missing, fallback to waitAndExecute
            if (GVAR(debugEnabled)) then { systemChat "Hacking jammer..."; };
            [[_obj, _newEnabled, _newSides], _onSuccess, _hackTime] call CBA_fnc_waitAndExecute;
        } else {
            ["Hacking Jammer...", _hackTime, {true}, _onSuccess, _onFail, [_obj, _newEnabled, _newSides]] call CBA_fnc_progressBar;
        };
    };
}];

// Cancel Button
private _btnCancel = _display ctrlCreate ["RscButtonMenuCancel", 2];
_btnCancel ctrlSetPosition [_xPos, _yPos + _h - _spacingY, 0.1 * safezoneW, _spacingY];
_btnCancel ctrlCommit 0;
