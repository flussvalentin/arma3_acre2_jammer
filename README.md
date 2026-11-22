# ACRE2 Radio Jammer

A standalone Arma 3 addon that allows any game object or vehicle to act as a radio jammer, actively degrading ACRE2 radio communications within a configurable area. 

Requires: **ACRE2** (`@ACRE2`) and **CBA_A3** (`@CBA_A3`).
**IMPORTANT:** This mod must be loaded on **both the server and all clients**!

---

## Features
- **Dynamic Jamming:** Intercepts ACRE2 signal logic dynamically, applying degradation based on distance, strength, and reliability settings. No ACRE2 files are modified.
- **Distance Falloff:** Jamming intensity smoothly fades out over distance based on an adjustable exponent.
- **Reliability System:** Simulate damaged or failing jammers with configurable uptime. A 50% reliability jammer will flicker on and off unpredictably.
- **Side Targeting:** Jammers can target specific factions (BLUFOR, OPFOR, Independent, Civilian) without affecting others.
- **Destructible:** Jammers automatically disable and unregister themselves if they are destroyed (via explosives, etc).
- **Hacking System:** Players can interact with enemy jammers (via ACE3 or vanilla scroll-wheel) to hack and permanently disable them. The required hacking time is fully configurable.

---

## How To Set Up A Jammer (3 Ways)
There are three different ways to turn an object or vehicle into an active jammer:

**1. Via the 3D Eden Editor (Module Sync)**
Find the **ACRE2 Jammer** category in the Eden Editor modules list. Place the module down and **Right Click -> Connect -> Sync** it to the object you want to become a jammer. Double-click the module to configure its settings (radius, strength, factions, etc.).

**2. Via Zeus (Live Curator)**
While playing as Zeus, open the modules menu and find the **ACRE2 Jammer** category. Simply drop the module directly on top of an existing object or vehicle. A settings window will instantly pop up allowing you to configure the jammer on the fly. 
*Note: ZEN (Zeus Enhanced) is fully supported for a better UI, but it is NOT required. A vanilla fallback UI is included!*

**3. Via Object Init Field (Scripting)**
You can manually turn any object into a jammer by pasting this code into its init field or calling it from a script:
```sqf
[this, 300, 1.0, 1.0, [west], true] call acre2_jammer_fnc_register;
```
*Arguments: `[Object, Radius (m), Strength (0-1), Reliability (0-1), [Factions], Enabled (true/false)]`*

---

## CBA Settings (Addon Options)
You can customize the core behavior of the jammer through **Options -> Game -> Addon Options -> ACRE2 Jammer**.
- **Signal Conflict Mode:** How to handle if another mod also uses the ACRE2 custom signal function. Options: Override, Chain, Disable. *(Default: Override)*
- **Distance Falloff Exponent:** How steeply the jamming strength decreases over distance (1 = linear, 2 = quadratic). *(Default: 2.0 | Range: 0.1 - 4.0)*
- **Hacking Time:** Time in seconds required to hack a jammer. *(Default: 15 | Range: 0 - 300)*
- **Debug Update Interval (s):** How often the on-screen debug hint updates. *(Default: 1.0 | Range: 0.5 - 5.0)*
- **Debug Display:** Show a debug hint on screen with current jamming status. *(Default: Off)*

---

## ACE3 & ZEN Compatibility
This mod has native integrations for **ACE3** (interaction menus for hacking/toggling jammers) and **ZEN** (Zeus configuration menus). However, **neither of them are required!** 
If you play without ACE3 or ZEN, the mod falls back to vanilla Arma 3 scroll-wheel actions and vanilla dialog menus.

---

## Multiplayer / Dedicated Server
- Jammer registration is server-authoritative.
- State is synced seamlessly to all clients.
- JIP-compatible - late-joining players receive the current jammer state automatically.
- Offset calculation runs locally per client (zero network traffic during gameplay).

---

## Public Scripting API

You can still use scripts if you prefer, or if you need to build custom logic.

### `acre2_jammer_fnc_register`
Register any object as a jammer via script or init field.
```sqf
// [object, radius, strength, reliability, sides, enabled]
[this, 400, 1.0, 1.0, [west], true] call acre2_jammer_fnc_register;
```

### `acre2_jammer_fnc_unregister`
Remove a jammer from the registry (object stays alive).
```sqf
[myJammer] call acre2_jammer_fnc_unregister;
```

### Setters for runtime modification
```sqf
[myJammer] call acre2_jammer_fnc_enable;
[myJammer] call acre2_jammer_fnc_disable;
[myJammer, 0.5] call acre2_jammer_fnc_setStrength;
[myJammer, 500] call acre2_jammer_fnc_setRadius;
[myJammer, 0.25] call acre2_jammer_fnc_setReliability;
[myJammer, [east]] call acre2_jammer_fnc_setSide;
```
