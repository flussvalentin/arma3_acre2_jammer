/*
 * script_component.hpp
 * Defines MAINPREFIX, PREFIX, and COMPONENT for CBA macro expansion.
 * Produces function names of the form: acre2_jammer_fnc_*
 *
 * CBA macro reference:
 *   GVAR(x)        -> acre2_jammer_x
 *   QGVAR(x)       -> "acre2_jammer_x"
 *   FUNC(x)        -> acre2_jammer_fnc_x
 *   QFUNC(x)       -> "acre2_jammer_fnc_x"
 *   EFUNC(mod,x)   -> mod_fnc_x  (for cross-addon calls)
 *   EGVAR(mod,x)   -> mod_x
 */

#define COMPONENT jammer
#define COMPONENT_BEAUTIFIED Jammer
#define MAINPREFIX acre2
#define PREFIX acre2

// CBA standard macros — required for GVAR, FUNC, EFUNC etc.
#include "\x\cba\addons\main\script_macros_common.hpp"

// Override CBA's PREP macro to use the exact flat PBO prefix path
#undef PREP
#define PREP(fncName) acre2_jammer_fnc_##fncName = compile preProcessFileLineNumbers (format ["\acre2_jammer\fnc_%1.sqf", QUOTE(fncName)])

// Public variable used to sync the jammer array (also used for JIP)
#define JAMMER_SYNC_VAR "acre2_jammer_jammers"

// ACRE2 internal variable that holds the custom signal function
// (from acre2/addons/sys_signal — stable since 2.x)
#define ACRE2_CUSTOM_SIGNAL_VAR "acre_sys_signal_customSignalFunc"
