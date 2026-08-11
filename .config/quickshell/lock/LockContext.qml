// Authentication state, shared by every lock surface (one per monitor) so all
// screens show the same typed length and the same failure message.
//
// Written against the API as actually shipped in Quickshell 0.3.0
// (/usr/lib/qt6/qml/Quickshell/Services/Pam/quickshell-service-pam.qmltypes):
//   PamResult: Success | Failed | Error | MaxTries
//   PamError:  StartFailed | TryAuthFailed | InternalError
//   pamMessage() takes NO parameters — read the message/responseRequired props.
//
// Security posture:
//   - `unlocked` fires ONLY on PamResult.Success. Everything else, including
//     errors, falls through to the failure path. Fail closed, never open.
//   - EVERY terminating path must clear unlockInProgress, or input stays
//     disabled and the lock wedges on "checking //" with no way to retry.

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property int attempts: 0

    // A PAM *system error* (bad stack, missing service file) is not a wrong
    // password, but both used to render the same red line — which made a broken
    // config look like a typo. Surfaced separately so it can't hide again.
    property bool systemError: false
    property string errorDetail: ""

    signal unlocked

    onCurrentTextChanged: if (currentText !== "") showFailure = false

    function tryUnlock() {
        if (unlockInProgress || currentText === "")
            return;

        showFailure = false;
        systemError = false;
        unlockInProgress = true;

        // start() returns false if the conversation could not even begin —
        // ignoring it was the other way this could wedge on "checking //".
        if (!pam.start()) {
            fail(true, "could not start PAM (is /etc/pam.d/quickshell-lock installed?)");
        }
    }

    function fail(isSystemError, detail) {
        root.currentText = "";
        root.attempts += 1;
        root.systemError = isSystemError;
        root.errorDetail = detail;
        root.showFailure = true;
        root.unlockInProgress = false;
    }

    PamContext {
        id: pam

        // /etc/pam.d/quickshell-lock, deployed by install.sh from
        // system/pam-quickshell-lock. Deliberately NOT a repo-local
        // configDirectory: PAM resolves `include` against that same directory,
        // so "include login" would look for a sibling `login` file and fail the
        // whole stack with PAM_SYSTEM_ERR. hyprlock and swaylock do it this way.
        config: "quickshell-lock"

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked();
                return;
            }

            if (result === PamResult.Failed)
                root.fail(false, "");
            else if (result === PamResult.MaxTries)
                root.fail(true, "too many attempts — locked out by faillock");
            else
                root.fail(true, "PAM returned " + PamResult.toString(result));
        }

        // Separate from `completed`: if this fires, `completed` never will.
        onError: error => {
            root.fail(true, PamError.toString(error));
        }
    }
}
