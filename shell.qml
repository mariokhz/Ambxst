//@ pragma UseQApplication
import QtQuick
import Quickshell
import "./modules/bar/"
import "./modules/launcher/"

ShellRoot {
    id: root

    Loader {
        active: true
        sourceComponent: Bar {}
    }

    Loader {
        active: true
        sourceComponent: LauncherWindow {}
    }
}
