#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Post-init: installs the custom ACRE2 signal function and
 * registers the JIP-compatible publicVariable event listener.
 *
 * Called on ALL machines that have an interface (clients).
 * The signal function only runs on clients (ACRE2 architecture).
 */

// Only install signal handler on clients — ACRE2 signal calc is client-side
if (!hasInterface) exitWith {};

// Signal function installation 
private _conflictMode = GVAR(signalConflictMode);

// _conflictMode values:
//   0 = Override  — our function replaces any existing one (default)
//   1 = Chain     — call any pre-existing function first, then apply jamming
//   2 = Disable   — do not install, jammer addon inactive

if (_conflictMode == 2) exitWith {
    if (GVAR(debugEnabled)) then { systemChat "[ACRE2 Jammer] Signal conflict mode set to Disable — jammer not installed."; };
};

// Capture any pre-existing custom signal function for chain mode
// Use missionNamespace getVariable, returns nil if no custom function was set
private _existingFunc = missionNamespace getVariable ACRE2_CUSTOM_SIGNAL_VAR;
GVAR(chainedSignalFunc) = if (_conflictMode == 1 && {!isNil "_existingFunc"}) then {
    _existingFunc
} else {
    nil
};

// Install our signal handler
[FUNC(signalHandler)] call acre_api_fnc_setCustomSignalFunc;

// JIP-compatible jammer sync
// Listen for jammer array updates broadcast by the server
GVAR(jammers) = missionNamespace getVariable [JAMMER_SYNC_VAR, []];

["acre2_jammer_sync", {
    GVAR(jammers) = _this;
}] call CBA_fnc_addEventHandler;

// Reliability loop
// Only run reliability state machine on clients (one instance per machine)
[] call FUNC(reliabilityLoop);
