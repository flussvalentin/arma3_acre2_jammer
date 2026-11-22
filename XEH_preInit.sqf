#include "script_component.hpp"

// Compile all functions FIRST
#include "XEH_PREP.hpp"

diag_log "[ACRE2 Jammer] preInit started";

/*
 * Author: Gemini, fluss
 * Pre-init: initialise global jammer state and register CBA settings.
 *
 * Called on ALL machines (server, clients, headless clients).
 */

// Jammer registry 
// Array of jammer data-structures. Each element is an array:
//   [object, radius, strength, reliability, side, enabled, reliabilityState]
//
//   INDEX  FIELD              TYPE           DEFAULT
//   0      object             OBJECT         —
//   1      radius             NUMBER         300
//   2      strength           NUMBER         1.0
//   3      reliability        NUMBER         1.0
//   4      side               SIDE           west
//   5      enabled            BOOL           true
//   6      reliabilityState   BOOL           true   (live on/off from reliability loop)
//
GVAR(jammers) = [];

// CBA Settings 

// Signal function conflict resolution mode
[
    QGVAR(signalConflictMode),
    "LIST",
    ["Signal Conflict Mode", "What to do if another mod also overwrites the ACRE2 signal function."],
    "ACRE2 Jammer",
    [
        [0, 1, 2],
        ["Override (default)", "Chain (call existing first)", "Disable (do not install)"],
        0   // Override by default
    ],
    true,
    {
        // No live-update needed, applied at postInit
    }
] call CBA_fnc_addSetting;

// Falloff exponent (controls how steep the distance falloff curve is)
[
    QGVAR(falloffExponent),
    "SLIDER",
    ["Distance Falloff Exponent", "Controls how steep the jamming falloff curve is. Lower values = stronger effect earlier. Higher values = steeper drop-off."],
    "ACRE2 Jammer",
    [0.1, 4.0, 1.0, 2],   // min, max, default, decimals
    true,
    {}
] call CBA_fnc_addSetting;

// Hacking Time (time required to hack a jammer in seconds)
[
    QGVAR(hackTime),
    "SLIDER",
    ["Hacking Time", "Time in seconds required to hack a jammer."],
    "ACRE2 Jammer",
    [0, 300, 15, 0], // min, max, default, decimals
    true,
    {}
] call CBA_fnc_addSetting;

// Debug settings 

// Debug interval, how often (seconds) the hint updates
// Registered BEFORE the toggle so the interval value exists when toggle fires
[
    QGVAR(debugInterval),
    "SLIDER",
    ["Debug Update Interval (s)", "How often the debug hint updates in seconds."],
    "ACRE2 Jammer",
    [0.5, 5.0, 1.0, 1],   // min, max, default, decimals
    false,                  // not server-synced, client-only debug display
    {
        // If debug is currently on, restart the PFH with the new interval
        if (GVAR(debugEnabled)) then {
            [true] call FUNC(debugLoop);
        };
    }
] call CBA_fnc_addSetting;

// Debug toggle on/off checkbox
[
    QGVAR(debugEnabled),
    "CHECKBOX",
    ["Debug Display", "Enables a visual on-screen hint displaying all active jammers."],
    "ACRE2 Jammer",
    false,                   // on by default
    false,                  // not server-synced, client-only
    {
        params ["_value"];
        diag_log text format ["[ACRE2 Jammer] CBA Setting Toggled: %1", _value];
        // Start or stop based on new value
        [_value] call FUNC(debugLoop);
    }
] call CBA_fnc_addSetting;
