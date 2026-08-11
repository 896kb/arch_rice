//@ pragma UseQApplication
// Quickshell lock screen — replaces hyprlock so the background can be video.
//
// hyprlock cannot play video: its `background` block accepts only path/screenshot
// and the binary has no ffmpeg/libav. Making it transparent doesn't help either,
// because ext-session-lock hides every other surface, and Hyprland's `abovelock`
// layer rule renders ABOVE the lock (it would cover the clock, not sit behind it).
// The way out is to BE the lock surface: Quickshell implements ext-session-lock
// itself, so the surface is our QML scene and can contain a video player.
//
// Run windowed for development (never touches the real session):
//     quickshell -p ~/.config/quickshell/lock/test.qml
// Run for real:
//     quickshell -p ~/.config/quickshell/lock/shell.qml

import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    LockContext {
        id: ctx

        onUnlocked: {
            // Release the lock BEFORE exiting, or the compositor shows a fallback
            // lock you cannot interact with.
            lock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        // One surface per connected screen.
        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: ctx
            }
        }
    }
}
