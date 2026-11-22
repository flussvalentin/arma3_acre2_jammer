#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Fallback interactive dialog for Zeus curators without ZEN.
 * 
 * Creates a native Arma 3 empty display and populates it with sliders
 * and checkboxes entirely through SQF to avoid config footprint.
 */
params ["_logic", "_target"];

disableSerialization;
createDialog "ACRE2_Jammer_VanillaDialog";
private _display = findDisplay 8472;
if (isNull _display) exitWith { 
    if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Failed to open dialog."; }; 
    deleteVehicle _logic; 
};

_display displayAddEventHandler ["Unload", {
    params ["_display", "_exitCode"];
    if (_exitCode == 2) then {
        // Esc was pressed, delete the logic
        private _logic = _display getVariable ["logic", objNull];
        if (!isNull _logic) then { deleteVehicle _logic; };
    };
}];

// Base positions (center screen)
private _w = 0.4 * safezoneW;
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
_title ctrlSetBackgroundColor [0, 0, 0, 1];
_title ctrlSetText " ACRE2 Jammer Settings (Vanilla)";
_title ctrlCommit 0;

// Function to create a slider with a label
private _fnc_createSlider = {
    params ["_labelStr", "_min", "_max", "_default", "_curY"];
    
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition [_xPos + 0.01 * safezoneW, _curY, _w * 0.35, _spacingY];
    _label ctrlSetText _labelStr;
    _label ctrlCommit 0;

    private _slider = _display ctrlCreate ["RscXSliderH", -1];
    _slider ctrlSetPosition [_xPos + _w * 0.35, _curY + 0.01 * safezoneH, _w * 0.5, 0.025 * safezoneH];
    _slider sliderSetRange [_min, _max];
    _slider sliderSetPosition _default;
    _slider ctrlCommit 0;
    
    // Value label
    private _val = _display ctrlCreate ["RscText", -1];
    _val ctrlSetPosition [_xPos + _w * 0.86, _curY, _w * 0.13, _spacingY];
    _val ctrlSetText str _default;
    _val ctrlCommit 0;
    
    // Bind value update
    _slider setVariable ["valCtrl", _val];
    _slider ctrlAddEventHandler ["SliderPosChanged", {
        params ["_ctrl", "_newValue"];
        private _valCtrl = _ctrl getVariable "valCtrl";
        // Round to 2 decimal places
        _valCtrl ctrlSetText str (round (_newValue * 100) / 100);
    }];
    
    _slider
};

// Initial values
private _initRadius = _logic getVariable ["acre2_jammer_radius", 300];
private _initStrength = _logic getVariable ["acre2_jammer_strength", 1.0];
private _initRel = _logic getVariable ["acre2_jammer_reliability", 1.0];

// Sliders
private _slRadius = ["Radius (m):", 10, 5000, _initRadius, _curY] call _fnc_createSlider; _curY = _curY + _spacingY;
private _slStrength = ["Strength (0-1):", 0, 1, _initStrength, _curY] call _fnc_createSlider; _curY = _curY + _spacingY;
private _slReliability = ["Reliability (0-1):", 0, 1, _initRel, _curY] call _fnc_createSlider; _curY = _curY + _spacingY;

_curY = _curY + _spacingY * 0.5;

// Function to create a checkbox with a label
private _fnc_createCheckbox = {
    params ["_labelStr", "_default", "_curY"];
    
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition [_xPos + 0.01 * safezoneW, _curY, _w * 0.35, _spacingY];
    _label ctrlSetText _labelStr;
    _label ctrlCommit 0;

    private _cb = _display ctrlCreate ["RscCheckbox", -1];
    // Position checkbox to the right of the label, slightly further left than before
    _cb ctrlSetPosition [_xPos + 0.18 * safezoneW, _curY + 0.005 * safezoneH, 0.02 * safezoneW, 0.03 * safezoneH];
    _cb cbSetChecked _default;
    _cb ctrlCommit 0;
    
    _cb
};

// Initial side values
private _initWest = (_logic getVariable ["acre2_jammer_side_west", 1]) > 0;
private _initEast = (_logic getVariable ["acre2_jammer_side_east", 0]) > 0;
private _initGuer = (_logic getVariable ["acre2_jammer_side_guer", 0]) > 0;
private _initCiv  = (_logic getVariable ["acre2_jammer_side_civ", 0]) > 0;

private _cbWest = ["Jam BLUFOR", _initWest, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbEast = ["Jam OPFOR", _initEast, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbGuer = ["Jam Independent", _initGuer, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;
private _cbCiv = ["Jam Civilian", _initCiv, _curY] call _fnc_createCheckbox; _curY = _curY + _spacingY;

_curY = _curY + _spacingY * 0.5;

// OK Button
private _btnOk = _display ctrlCreate ["RscButtonMenuOK", -1];
_btnOk ctrlSetPosition [_xPos + _w - 0.15 * safezoneW - 0.01 * safezoneW, _yPos + _h - _spacingY - 0.01 * safezoneH, 0.15 * safezoneW, _spacingY];
_btnOk ctrlCommit 0;

// Cancel Button
private _btnCancel = _display ctrlCreate ["RscButtonMenuCancel", -1];
_btnCancel ctrlSetPosition [_xPos + 0.01 * safezoneW, _yPos + _h - _spacingY - 0.01 * safezoneH, 0.15 * safezoneW, _spacingY];
_btnCancel ctrlCommit 0;

// Save references to display
_display setVariable ["slRadius", _slRadius];
_display setVariable ["slStrength", _slStrength];
_display setVariable ["slReliability", _slReliability];
_display setVariable ["cbWest", _cbWest];
_display setVariable ["cbEast", _cbEast];
_display setVariable ["cbGuer", _cbGuer];
_display setVariable ["cbCiv", _cbCiv];
_display setVariable ["logic", _logic];
_display setVariable ["targetObj", _target];

// OK Event
_btnOk ctrlAddEventHandler ["ButtonClick", {
    params ["_btn"];
    private _disp = ctrlParent _btn;
    
    private _slRadius = _disp getVariable "slRadius";
    private _slStrength = _disp getVariable "slStrength";
    private _slReliability = _disp getVariable "slReliability";
    
    private _cbWest = _disp getVariable "cbWest";
    private _cbEast = _disp getVariable "cbEast";
    private _cbGuer = _disp getVariable "cbGuer";
    private _cbCiv = _disp getVariable "cbCiv";
    
    private _logic = _disp getVariable "logic";
    private _targetObj = _disp getVariable "targetObj";
    
    private _radius = round (sliderPosition _slRadius);
    private _strength = sliderPosition _slStrength;
    private _reliability = sliderPosition _slReliability;
    
    private _sides = [];
    if (cbChecked _cbWest) then { _sides pushBack west; };
    if (cbChecked _cbEast) then { _sides pushBack east; };
    if (cbChecked _cbGuer) then { _sides pushBack independent; };
    if (cbChecked _cbCiv)  then { _sides pushBack civilian; };
    if (count _sides == 0) then { _sides = [west]; };
    
    // Save state back to logic so double-clicking remembers it
    _logic setVariable ["acre2_jammer_radius", _radius, true];
    _logic setVariable ["acre2_jammer_strength", _strength, true];
    _logic setVariable ["acre2_jammer_reliability", _reliability, true];
    _logic setVariable ["acre2_jammer_side_west", if (cbChecked _cbWest) then {1} else {0}, true];
    _logic setVariable ["acre2_jammer_side_east", if (cbChecked _cbEast) then {1} else {0}, true];
    _logic setVariable ["acre2_jammer_side_guer", if (cbChecked _cbGuer) then {1} else {0}, true];
    _logic setVariable ["acre2_jammer_side_civ", if (cbChecked _cbCiv) then {1} else {0}, true];
    
    // Re-run the script with the updated variables to actually register the jammer
    [_logic, [], true, true] spawn acre2_jammer_fnc_moduleZeus;
    
    _disp closeDisplay 1;
}];