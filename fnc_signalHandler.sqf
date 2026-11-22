#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Custom ACRE2 signal function. Registered via acre_api_fnc_setCustomSignalFunc.
 * Called by ACRE2 every ~0.2 s during active radio transmissions.
 *
 * Arguments:
 * 0: Frequency (MHz)      <NUMBER>
 * 1: Power (mW)           <NUMBER>
 * 2: Receiving Radio ID   <STRING>
 * 3: Transmitting Radio ID<STRING>
 *
 * Return Value:
 * [signalPercent (0-1), signalDBm] <ARRAY>
 *
 * Signal percent controls audio quality/distortion in TeamSpeak.
 * Values:
 *   1.0  = perfect
 *   0.5  = heavy distortion
 *   0.1  = barely intelligible
 *   0.0  = complete silence
 *
 * Public: No
 */

params ["_frequency", "_power", "_rxRadioId", "_txRadioId"];

// 1. Get the default (physical) signal from ACRE2 core
// If chain mode is active and a prior custom function existed, call that instead.
private _defaultSignal = if (!isNil QGVAR(chainedSignalFunc)) then {
    _this call GVAR(chainedSignalFunc)
} else {
    _this call acre_sys_signal_fnc_getSignalCore
};

_defaultSignal params ["_Px", "_dBm"];

// 2. Find the receiver's game object
// acre_sys_radio_fnc_getRadioObject is an internal function but stable since ACRE 2.x
private _rxObject = [_rxRadioId] call acre_sys_radio_fnc_getRadioObject;
if (isNull _rxObject) exitWith { _defaultSignal };

private _rxPos = getPosASL _rxObject;
private _rxSide = side (group _rxObject);

// 3. Calculate combined jamming factor
private _totalJamFactor = 0;
private _activeJammers = GVAR(jammers);

{
    _x params [
        "_jamObj",          // 0: OBJECT
        "_radius",          // 1: NUMBER
        "_strength",        // 2: NUMBER
        "_reliability",     // 3: NUMBER (unused directly — reliabilityState used)
        "_jamSide",         // 4: SIDE or ARRAY of sides
        "_enabled",         // 5: BOOL
        "_reliabilityState" // 6: BOOL (current on/off state from reliability loop)
    ];

    // Skip: disabled, reliability-offline, destroyed object
    if (!_enabled) then { continue };
    if (!_reliabilityState) then { continue };
    if (!alive _jamObj) then { continue };

    // Side filter
    private _jamsSide = if (_jamSide isEqualType []) then {
        _rxSide in _jamSide
    } else {
        _rxSide == _jamSide
    };
    if (!_jamsSide) then { continue };

    // 3D spherical distance check
    private _dist = _rxPos vectorDistance (getPosASL _jamObj);
    if (_dist >= _radius) then { continue };

    // Distance falloff: factor is 0 at edge, _strength at centre
    //   falloff = (dist/radius)^exponent
    //   jamFactor = strength * (1 - falloff)
    private _distRatio = _dist / _radius;
    private _falloff = _distRatio ^ GVAR(falloffExponent);
    private _jamFactor = _strength * (1 - _falloff);

    // Combine: take strongest jammer effect
    if (_jamFactor > _totalJamFactor) then {
        _totalJamFactor = _jamFactor;
    };

} forEach _activeJammers;

// 4. Apply jamming
if (_totalJamFactor <= 0) exitWith { _defaultSignal };

// Degrade Px linearly by jamming factor
// This causes progressive distortion in the TeamSpeak plugin
private _newPx = _Px * (1 - _totalJamFactor);

// Degrade dBm proportionally, pushes signal towards threshold/silence
// A jamming factor of 1.0 drops dBm by 50 dB
private _dBmDegradation = _totalJamFactor * 50;
private _newDBm = _dBm - _dBmDegradation;

[_newPx, _newDBm]
