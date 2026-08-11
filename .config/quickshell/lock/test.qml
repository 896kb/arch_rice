// Development harness: renders LockSurface in an ORDINARY WINDOW instead of a
// real session lock. Use this for every iteration — a bug in a real lock surface
// either locks you out or fails open, and neither is worth debugging live.
//
//     quickshell -p ~/.config/quickshell/lock/test.qml
//
// PAM is live here too, so a correct password really does authenticate; it just
// closes the window instead of unlocking the session.

import Quickshell
import QtQuick

ShellRoot {
    LockContext {
        id: ctx
        onUnlocked: Qt.quit()
    }

    FloatingWindow {
        implicitWidth: 1280
        implicitHeight: 800
        visible: true

        LockSurface {
            anchors.fill: parent
            context: ctx
        }
    }
}
