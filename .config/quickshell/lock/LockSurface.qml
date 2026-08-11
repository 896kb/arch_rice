// The lock visuals — a faithful port of hyprlock.conf's layout so the switch to
// Quickshell isn't a visual change, only a capability one (the background is now
// a looping video instead of a blurred still).
//
// Colours are written as the CANONICAL accents (#b5bd68 / #1d1f21 / #cc6666).
// lib/theme.sh's mirror recolours every text file under .config, so this file
// becomes pink on the Xiaomi automatically — no per-host QML, no extra machinery.

import QtQuick
import QtMultimedia
import Quickshell

Item {
    id: root

    required property var context

    // --- knobs -------------------------------------------------------------
    // hyprlock dimmed its still wallpaper to brightness 0.55 and blurred it hard.
    // A video wants to be seen, so this only dims enough to keep text legible —
    // and how much that needs to be depends entirely on the clip. The Z13's
    // bus-stop scene is dark and wants none of the widgets fighting it; the
    // Xiaomi's train-bridge clip is bright and is set to 0 (no dim at all).
    // Set per host via RICE_LOCK_DIM in .config/hypr/profile.d/<profile>.conf.
    readonly property real backgroundDim: {
        const v = Quickshell.env("RICE_LOCK_DIM");
        if (v === null || v === undefined || v === "")
            return 0.45;
        const n = parseFloat(v);
        return isNaN(n) ? 0.45 : Math.max(0, Math.min(1, n));
    }
    readonly property color accent: "#b5bd68"
    readonly property color fieldBg: "#1d1f21"
    readonly property color failColor: "#cc6666"
    readonly property string fontFamily: "Departure Mono"

    // --- background --------------------------------------------------------
    // Solid backdrop first, so a missing or undecodable clip degrades to the
    // theme background rather than to something that looks broken.
    Rectangle {
        anchors.fill: parent
        color: root.fieldBg
    }

    // The video is loaded LAZILY and off the critical path. Measured on the Z13:
    // a bare QML window appears in 314ms, but instantiating QtMultimedia and
    // letting ffmpeg open the clip costs ~3.4s — which was the whole "Super+C
    // takes a couple of seconds" delay, since the surface couldn't paint until
    // the media stack was ready. Deferring it means the lock appears essentially
    // as fast as hyprlock did and the clip fades in a moment later over the
    // solid backdrop above. The screen is genuinely locked the whole time.
    Loader {
        id: videoLoader
        anchors.fill: parent
        asynchronous: true
        active: false
        sourceComponent: videoComponent

        // One event-loop turn is enough to guarantee the lock UI paints first.
        Timer {
            interval: 1
            running: true
            onTriggered: videoLoader.active = true
        }
    }

    Component {
        id: videoComponent

        Item {
            // Which clip to play is per-machine. The profile's Hyprland fragment
            // sets RICE_LOCK_VIDEO (see .config/hypr/profile.d/), which the
            // compositor exports into the session so hypridle's child inherits
            // it. Falls back to the Z13 clip if unset.
            property alias player: mediaPlayer

            MediaPlayer {
                id: mediaPlayer
                source: Qt.resolvedUrl(Quickshell.env("RICE_LOCK_VIDEO") ?? "lock-z13.mp4")
                loops: MediaPlayer.Infinite
                videoOutput: videoOut
                Component.onCompleted: play()
            }

            VideoOutput {
                id: videoOut
                anchors.fill: parent
                // Clips are pre-encoded 16:10 to match the panels, but crop
                // rather than letterbox so an odd resolution never shows bars.
                fillMode: VideoOutput.PreserveAspectCrop

                // The clips are pixel art stored at HALF panel resolution
                // (1280x800 for the Z13's 2560x1600, 1440x900 for 2880x1800),
                // so the upscale is an exact 2x. smooth:false asks for
                // nearest-neighbour, which keeps the pixel blocks hard instead
                // of interpolating them into mush. Storing them small cut the
                // two clips from 1.6M to 692K and roughly quarters the decode
                // work. If Qt ignores this on your driver the result is merely
                // slightly soft, never broken.
                smooth: false
                opacity: mediaPlayer.playbackState === MediaPlayer.PlayingState ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }
    }

    // Suspend/resume: the whole system freezes, but the media pipeline's
    // presentation clock is anchored to wall time. On wake it believes it is
    // minutes behind and races through frames to catch up — the fast-forward.
    //
    // Nothing in Qt reports "we just resumed", so infer it: this timer should
    // fire every second, and a far larger gap means time passed while we were
    // frozen. Restarting the player resets the clock instead of letting it
    // chase a deadline it can never meet.
    Timer {
        id: resumeWatch

        property real lastTick: Date.now()
        readonly property int gapThresholdMs: 3000

        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            const now = Date.now();
            if (now - lastTick > gapThresholdMs) {
                const p = videoLoader.item ? videoLoader.item.player : null;
                if (p) {
                    console.log("lock: resumed after " + Math.round((now - lastTick) / 1000)
                                + "s gap — restarting playback");
                    p.stop();
                    p.play();
                }
            }
            lastTick = now;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.backgroundDim)
    }

    // --- clock (hyprlock: font_size 96, position 0,150 above centre) --------
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 150 - height / 2
        text: Qt.formatDateTime(clockTimer.now, "HH:mm")
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: 96
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.6)
    }

    // --- date (font_size 22, accent at 85%, position 0,60) -----------------
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 60 - height / 2
        text: Qt.formatDateTime(clockTimer.now, "dddd, dd MMMM")
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85)
        font.family: root.fontFamily
        font.pixelSize: 22
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

    // --- password field (300x56, rounding 14, outline 2, position 0,-50) ---
    Rectangle {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + 50 - height / 2
        width: 300
        height: 56
        radius: 14
        color: Qt.rgba(root.fieldBg.r, root.fieldBg.g, root.fieldBg.b, 0.85)
        border.width: 2
        border.color: root.context.showFailure ? root.failColor : root.accent

        // Placeholder, shown only while empty (hyprlock: grey italic).
        Text {
            anchors.centerIn: parent
            visible: root.context.currentText.length === 0 && !root.context.unlockInProgress
            text: "Enter password"
            color: "#888888"
            font.family: root.fontFamily
            font.pixelSize: 14
            font.italic: true
        }

        // Dots — hyprlock's dots_size 0.26 of a 56px field, spacing 0.3.
        Row {
            anchors.centerIn: parent
            spacing: 5
            visible: !root.context.unlockInProgress

            Repeater {
                model: Math.min(root.context.currentText.length, 16)

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: root.accent
                }
            }
        }

        // Checking indicator while PAM is in flight.
        Text {
            anchors.centerIn: parent
            visible: root.context.unlockInProgress
            text: "checking //"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: 14
        }
    }

    // --- failure line (hyprlock: fail_text "$FAIL ($ATTEMPTS)") ------------
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: field.y + field.height + 12
        visible: root.context.showFailure
        text: root.context.systemError
              ? "PAM error: " + root.context.errorDetail
              : "Authentication failed  (" + root.context.attempts + ")"
        color: root.failColor
        font.family: root.fontFamily
        font.pixelSize: 14
        font.italic: true
    }

    // --- user (font_size 15, bottom, 45px up) ------------------------------
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 45 - height
        text: Quickshell.env("USER") ?? ""
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: 15
    }

    // --- input capture -----------------------------------------------------
    // A real TextInput rather than hand-rolled Keys handling, so backspace,
    // held keys, paste and IME all behave. It is never drawn; the dots above are
    // the visual representation.
    TextInput {
        id: input
        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        enabled: !root.context.unlockInProgress

        onTextChanged: root.context.currentText = text
        onAccepted: root.context.tryUnlock()

        // Grab focus in the same frame the surface is created. Waiting for the
        // keep-alive timer below (200ms) would silently drop anything typed in
        // that window — unacceptable when someone starts typing the instant the
        // lock appears.
        Component.onCompleted: forceActiveFocus()

        // PAM clears currentText on failure; mirror that back into the field.
        Connections {
            target: root.context
            function onCurrentTextChanged() {
                if (root.context.currentText !== input.text)
                    input.text = root.context.currentText;
            }
        }
    }

    // Keep focus on the input even if something steals it.
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: if (!input.activeFocus) input.forceActiveFocus()
    }
}
