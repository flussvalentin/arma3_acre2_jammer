#include "script_component.hpp"
/*
 * Author: Gemini, fluss
 * "Hack" a jammer to change its targeted side at runtime.
 * Functionally identical to fnc_setSide — provided as a mission-maker-facing
 * alias that clearly communicates the intent (hacking scenario).
 *
 * Arguments:
 * 0: Jammer object         <OBJECT>
 * 1: New side to jam       <SIDE|ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * // Enemy jammer originally jams west; after hacking, jams east instead:
 * [enemyJammer, east] call acre2_jammer_fnc_hack;
 *
 * Public: Yes
 */

params [
    ["_obj",  objNull, [objNull]],
    ["_side", west,    [west, []]]
];

// Delegate entirely to setSide — same logic, different name
[_obj, _side] call FUNC(setSide);
