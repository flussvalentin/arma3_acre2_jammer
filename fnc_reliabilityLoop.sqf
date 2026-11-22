#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Reliability state machine. Runs on each client as a CBA per-frame handler.
 * Periodically toggles the reliabilityState of each jammer based on its
 * reliability value, producing natural-feeling intermittent jamming.
 *
 * High reliability (1.0)  → always on, no toggling
 * Medium reliability (0.5) → random outages, avg 50% uptime
 * Low reliability (0.1)   → frequent outages, brief active windows
 *
 * Reliability controls:
 *   - Mean active (ON) duration:  reliability * 10 seconds
 *   - Mean inactive (OFF) duration: (1 - reliability) * 10 seconds
 *   Both durations are randomised ±50% to avoid periodic patterns.
 *
 * Public: No
 */

// Per-jammer next-toggle times stored on the jammer object itself to avoid
// polluting missionNamespace. Key: "acre2_jammer_nextToggle"

[{
    private _jammers = GVAR(jammers);
    private _now = time;

    {
        _x params [
            "_jamObj",      // 0
            "",             // 1 radius
            "",             // 2 strength
            "_reliability", // 3
            "",             // 4 side
            "_enabled",     // 5
            "_reliabilityState" // 6
        ];

        // Skip jammer objects that are gone or fully reliable
        if (!alive _jamObj) then { continue };
        if (_reliability >= 1.0) then { continue };

        private _nextToggle = _jamObj getVariable ["acre2_jammer_nextToggle", -1];

        if (_nextToggle < 0) then {
            // First run, schedule first toggle
            private _initialDelay = random 5;
            _jamObj setVariable ["acre2_jammer_nextToggle", _now + _initialDelay];
        } else {
            if (_now >= _nextToggle) then {
                // Toggle the state
                private _newState = !_reliabilityState;
                _x set [6, _newState];

                // Schedule next toggle based on new state
                private _meanDuration = if (_newState) then {
                    _reliability * 10  // mean ON duration
                } else {
                    (1 - _reliability) * 10  // mean OFF duration
                };
                // Randomise ±50% for natural feel
                private _duration = (_meanDuration * 0.5) + random (_meanDuration);
                _duration = _duration max 0.5;  // never less than 0.5 s

                _jamObj setVariable ["acre2_jammer_nextToggle", _now + _duration];

                // Write updated state back into the global array
                GVAR(jammers) set [_forEachIndex, _x];
            };
        };
    } forEach _jammers;

}, 1.0, []] call CBA_fnc_addPerFrameHandler;
