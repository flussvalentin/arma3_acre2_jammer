class CfgPatches {
    class acre2_jammer {
        name = "ACRE2 - Radio Jammer";
        units[] = {"acre2_jammer_module_eden", "acre2_jammer_module_zeus"};
        weapons[] = {};
        requiredVersion = 2.14;
        requiredAddons[] = {
            "cba_main",
            "acre_main",
            "acre_api",
            "acre_sys_signal",
            "acre_sys_radio"
        };
        author = "fluss";
        url = "";
        version = 1.0;
        versionStr = "1.0.0";
        versionAr[] = {1,0,0};
    };
};

#include "CfgEventHandlers.hpp"

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Category for both Eden and Zeus
// ═══════════════════════════════════════════════════════════════════════════════

class CfgFactionClasses {
    class NO_CATEGORY;
    class acre2_jammer_category: NO_CATEGORY {
        displayName = "ACRE2 Jammer";
        priority = 2;
        side = 7;
    };
};

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Vanilla Dialog (Empty canvas for SQF UI)
// ═══════════════════════════════════════════════════════════════════════════════
class ACRE2_Jammer_VanillaDialog {
    idd = 8472;
    movingEnable = 0;
    enableSimulation = 1;
    controlsBackground[] = {};
    objects[] = {};
    controls[] = {};
};

class ACRE2_Jammer_HackDialog {
    idd = 8473;
    movingEnable = 0;
    enableSimulation = 1;
    controlsBackground[] = {};
    objects[] = {};
    controls[] = {};
};

// ═══════════════════════════════════════════════════════════════════════════════
// Module classes — Eden (3D Editor) and Zeus (Curator)
// ═══════════════════════════════════════════════════════════════════════════════

class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Default;
            class Edit;
            class Combo;
            class Checkbox;
            class CheckboxNumber;
            class ModuleDescription;
            class Units;
        };
        class ModuleDescription {
            class AnyBrain;
        };
    };

    // Eden Module
    class acre2_jammer_module_eden: Module_F {
        scope = 2;               // Visible in Eden Editor
        scopeCurator = 0;        // Hidden in Zeus
        displayName = "ACRE2 Jammer";
        icon = "\a3\modules_f\data\iconModule_ca.paa";
        category = "acre2_jammer_category";
        function = "acre2_jammer_fnc_moduleInit";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;

        class Attributes: AttributesBase {
            class acre2_jammer_radius: Edit {
                property = "acre2_jammer_radius";
                displayName = "Radius (m)";
                tooltip = "Spherical jamming radius in metres.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_strength: Edit {
                property = "acre2_jammer_strength";
                displayName = "Strength (0-1)";
                tooltip = "Jamming intensity. 1.0 = maximum distortion, 0.0 = no effect.";
                typeName = "NUMBER";
                defaultValue = "1.0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_reliability: Edit {
                property = "acre2_jammer_reliability";
                displayName = "Reliability (0-1)";
                tooltip = "Uptime fraction. 1.0 = always on. 0.5 = 50% uptime (flickers on/off).";
                typeName = "NUMBER";
                defaultValue = "1.0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_west: CheckboxNumber {
                property = "acre2_jammer_side_west";
                displayName = "Jam BLUFOR";
                tooltip = "Jam BLUFOR (west) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_east: CheckboxNumber {
                property = "acre2_jammer_side_east";
                displayName = "Jam OPFOR";
                tooltip = "Jam OPFOR (east) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_guer: CheckboxNumber {
                property = "acre2_jammer_side_guer";
                displayName = "Jam Independent";
                tooltip = "Jam Independent (resistance) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_civ: CheckboxNumber {
                property = "acre2_jammer_side_civ";
                displayName = "Jam Civilian";
                tooltip = "Jam Civilian radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class ModuleDescription: ModuleDescription {};
        };

        class ModuleDescription: ModuleDescription {
            description = "Registers the synced object as an ACRE2 radio jammer.\nSync this module to the object you want to become a jammer.";
        };
    };

    // Zeus Module
    class acre2_jammer_module_zeus: Module_F {
        scope = 1;               // Hidden in Eden Editor
        scopeCurator = 2;        // Visible in Zeus
        displayName = "ACRE2 Jammer";
        icon = "\a3\modules_f\data\iconModule_ca.paa";
        category = "acre2_jammer_category";
        function = "acre2_jammer_fnc_moduleZeus";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        curatorCanAttach = 1;    // Can be dropped onto objects

        class Arguments {
            class acre2_jammer_radius {
                displayName = "Radius (m)";
                description = "Spherical jamming radius in metres.";
                typeName = "NUMBER";
                defaultValue = "300";
            };
            class acre2_jammer_strength {
                displayName = "Strength (0-1)";
                description = "Jamming intensity. 1.0 = maximum distortion, 0.0 = no effect.";
                typeName = "NUMBER";
                defaultValue = "1.0";
            };
            class acre2_jammer_reliability {
                displayName = "Reliability (0-1)";
                description = "Uptime fraction. 1.0 = always on. 0.5 = 50% uptime (flickers on/off).";
                typeName = "NUMBER";
                defaultValue = "1.0";
            };
            // Note: Checkboxes for sides are not natively supported in legacy Arguments as easily,
            // but ZEN can fallback to class Attributes below.
        };

        class Attributes: AttributesBase {
            class acre2_jammer_radius: Edit {
                property = "acre2_jammer_radius";
                displayName = "Radius (m)";
                tooltip = "Spherical jamming radius in metres.";
                typeName = "NUMBER";
                defaultValue = "300";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_strength: Edit {
                property = "acre2_jammer_strength";
                displayName = "Strength (0-1)";
                tooltip = "Jamming intensity. 1.0 = maximum distortion, 0.0 = no effect.";
                typeName = "NUMBER";
                defaultValue = "1.0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_reliability: Edit {
                property = "acre2_jammer_reliability";
                displayName = "Reliability (0-1)";
                tooltip = "Uptime fraction. 1.0 = always on. 0.5 = 50% uptime (flickers on/off).";
                typeName = "NUMBER";
                defaultValue = "1.0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_west: CheckboxNumber {
                property = "acre2_jammer_side_west";
                displayName = "Jam BLUFOR";
                tooltip = "Jam BLUFOR (west) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_east: CheckboxNumber {
                property = "acre2_jammer_side_east";
                displayName = "Jam OPFOR";
                tooltip = "Jam OPFOR (east) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_guer: CheckboxNumber {
                property = "acre2_jammer_side_guer";
                displayName = "Jam Independent";
                tooltip = "Jam Independent (resistance) radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class acre2_jammer_side_civ: CheckboxNumber {
                property = "acre2_jammer_side_civ";
                displayName = "Jam Civilian";
                tooltip = "Jam Civilian radio receivers.";
                typeName = "NUMBER";
                defaultValue = "0";
                expression = "_this setVariable ['%s',_value,true];";
            };
            class ModuleDescription: ModuleDescription {};
        };

        class ModuleDescription: ModuleDescription {
            description = "Click on an object to register it as an ACRE2 radio jammer.\nDrop on it again with Strength 0.0 to disable an invincible jammer.";
        };
    };
};
