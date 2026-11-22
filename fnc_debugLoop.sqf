#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Debug display loop. Shows a hint with jammer statistics for the local player.
 * Controlled by CBA settings: enable/disable toggle and update interval.
 *
 * Called once from XEH_preInit. When the CBA setting is toggled on, a CBA PFH
 * is registered. When toggled off, the PFH is removed and the hint is cleared.
 *
 * Displayed stats:
 *   - Jammed: YES / NO  (real-time, reflects reliability state)
 *   - Jamming intensity: 0.00 – 1.00  (combined factor at player position)
 *   - Distance to nearest active jammer (m)
 *   - Jammed faction(s) of nearest jammer
 *   - Total registered jammers in scenario
 *
 * Public: No
 */

params ["_enabled"];
diag_log text format ["[ACRE2 Jammer] Debug loop called with: %1", _enabled];

// Initialize handle if it doesn't exist
if (isNil QGVAR(debugPFH)) then {
    GVAR(debugPFH) = -1;
};

// Kill existing PFH if any
if (GVAR(debugPFH) >= 0) then {
    [GVAR(debugPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(debugPFH) = -1;
    hintSilent "";  // clear hint
};

if (!_enabled) exitWith {};
// Start new PFH at the configured interval
GVAR(debugPFH) = [{
    if (!hasInterface) exitWith {};

    // Safely get the local player unit
    private _player = [] call CBA_fnc_currentUnit;
    if (isNull _player) exitWith {
        hintSilent "═══ ACRE2 JAMMER DEBUG ═══\n\nWaiting for player to spawn...";
    };

    private _playerPos = getPosASL _player;
    private _playerSide = side (group _player);
    private _jammers = GVAR(jammers);
        private _totalJammers = count _jammers;

        // Calculate jamming state
        private _bestJamFactor = 0;
        private _nearestDist = 99999;
        private _nearestObj = objNull;
        private _nearestRadius = 0;
        private _nearestStrength = 0;
        private _nearestRel = 0;
        private _nearestSides = "—";
        private _isJammed = false;

        {
            _x params [
                "_jamObj",          // 0
                "_radius",          // 1
                "_strength",        // 2
                "_reliability",     // 3
                "_jamSide",         // 4
                "_enabled",         // 5
                "_reliabilityState" // 6
            ];

            if (!alive _jamObj) then { continue };

            private _dist = _playerPos vectorDistance (getPosASL _jamObj);

            // Track nearest jammer regardless of side/state (useful info)
            if (_dist < _nearestDist) then {
                _nearestDist = _dist;
                _nearestObj = _jamObj;
                _nearestRadius = _radius;
                _nearestStrength = _strength;
                _nearestRel = _reliability;

                // Format side(s) for display
                _nearestSides = if (_jamSide isEqualType []) then {
                    (_jamSide apply { str _x }) joinString ", "
                } else {
                    str _jamSide
                };
            };

            // Only count towards jamming if actually affecting this player
            if (!_enabled) then { continue };
            if (!_reliabilityState) then { continue };

            // Side check
            private _affectsPlayer = if (_jamSide isEqualType []) then {
                _playerSide in _jamSide
            } else {
                _playerSide == _jamSide
            };
            if (!_affectsPlayer) then { continue };

            if (_dist >= _radius) then { continue };

            // Calculate factor
            private _distRatio = _dist / _radius;
            private _falloff = _distRatio ^ GVAR(falloffExponent);
            private _jamFactor = _strength * (1 - _falloff);

            if (_jamFactor > _bestJamFactor) then {
                _bestJamFactor = _jamFactor;
                _isJammed = true;
            };
        } forEach _jammers;

        // Format output
        private _jammedStr = if (_isJammed) then {
            "JAMMED: YES"
        } else {
            "JAMMED: NO"
        };

        private _intensityStr = format ["Intensity on Player: %1", (_bestJamFactor toFixed 2)];

        private _distStr = "";
        if (_nearestDist < 99999) then {
            private _grid = mapGridPosition _nearestObj;
            _distStr = format [
                "--- NEAREST JAMMER ---\nDistance: %1 m\nGrid: %2\nRadius: %3 m\nStrength: %4\nReliability: %5\nTarget faction(s): %6", 
                (round _nearestDist), _grid, _nearestRadius, _nearestStrength, _nearestRel, _nearestSides
            ];
        } else {
            _distStr = "--- NEAREST JAMMER ---\n(none found)";
        };

        private _countStr = format ["Total jammers in scenario: %1", _totalJammers];

        private _txt = format [
            "═══ ACRE2 JAMMER DEBUG ═══\n\n%1\n%2\n\n%3\n\n%4",
            _jammedStr,
            _intensityStr,
            _distStr,
            _countStr
        ];

        hintSilent _txt;

    }, GVAR(debugInterval), []] call CBA_fnc_addPerFrameHandler;
