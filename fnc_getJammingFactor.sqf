#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * Calculate the jamming factor for a given world position from a single jammer entry.
 * Helper used by fnc_signalHandler and can be called externally for debugging.
 *
 * Arguments:
 * 0: Receiver position (ASL) <ARRAY [x,y,z]>
 * 1: Jammer data entry       <ARRAY> (same format as GVAR(jammers) element)
 *
 * Return Value:
 * Jamming factor 0.0 – 1.0, or -1 if jammer does not apply <NUMBER>
 *   -1 = not applicable (wrong side / disabled / out of range)
 *    0 = no effect
 *    1 = maximum effect
 *
 * Public: No
 */

params ["_receiverPos", "_jammerEntry"];

_jammerEntry params [
    "_jamObj",
    "_radius",
    "_strength",
    "",     // reliability — not used here (reliabilityState handles runtime on/off)
    "",     // side — not used here (caller filters)
    "_enabled",
    "_reliabilityState"
];

if (!_enabled) exitWith { -1 };
if (!_reliabilityState) exitWith { -1 };
if (!alive _jamObj) exitWith { -1 };

private _dist = _receiverPos vectorDistance (getPosASL _jamObj);
if (_dist >= _radius) exitWith { -1 };

private _distRatio = _dist / _radius;
private _falloff = _distRatio ^ GVAR(falloffExponent);
(_strength * (1 - _falloff))
