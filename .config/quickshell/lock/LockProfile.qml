// Per-host lock settings.
//
// This committed copy holds the CANONICAL (Z13) values. install.sh overwrites it
// in the deploy tree with the active profile's values — see rice_write_lock_profile.
//
// Why a generated file instead of environment variables: the values used to come
// from `env =` lines in the Hyprland profile fragment, which only take effect at
// SESSION START. Running install.sh inside a running session left them unset, and
// the QML fell back to hardcoded Z13 defaults — so the Xiaomi showed the Z13's
// clip until a relogin, silently and with no error. Resolving at deploy time
// removes the whole class of failure: whatever install.sh linked is what runs.

import QtQml

QtObject {
    // Filename of the lock animation, resolved relative to this directory.
    readonly property string anim: "lock-z13.gif"

    // How much to dim the animation, 0 (untouched) to 1 (black). Depends entirely
    // on the clip: dark scenes want a little, bright ones none.
    readonly property real dim: 0.45
}
