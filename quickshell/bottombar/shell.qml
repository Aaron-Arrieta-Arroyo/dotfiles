//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth

ShellRoot {
    id: root

    // Pinned apps (desktop file ids, without .desktop). Edit to taste.
    readonly property var pinned: ["brave-browser", "steam", "equibop", "spotify", "thunar", "foot", "cursor"]

    // Colours follow the Caelestia scheme; fallbacks are the gothic palette.
    property string panel: ""   // "", "net" or "bt"
    function toggle(name) { panel = panel === name ? "" : name; }
    property var scheme: ({})
    function col(key, fallback) { return "#" + (scheme[key] ?? fallback); }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.scheme = JSON.parse(text()).colours; } catch (e) {}
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(name: string): void { root.toggle(name); }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Apps shown: pinned first, then any other running app.
    readonly property var apps: {
        const tl = ToplevelManager.toplevels.values;
        const list = [];
        const seen = {};
        for (const id of pinned) {
            list.push({ id, running: tl.filter(t => t.appId.toLowerCase() === id) });
            seen[id] = true;
        }
        for (const t of tl) {
            const id = t.appId.toLowerCase();
            if (!id || seen[id]) continue;
            seen[id] = true;
            list.push({ id, running: tl.filter(x => x.appId.toLowerCase() === id) });
        }
        return list;
    }

    Variants {
        model: Quickshell.screens
        ConnPanel { shell: root }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { bottom: true; left: true; right: true }
            implicitHeight: 64
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "bottombar"

            // Auto-hide: only a thin strip (or the bar itself, when shown) takes input.
            property bool shown: hover.hovered || hideDelay.running || root.panel !== ""
            mask: Region { item: hitbox }

            Item {
                id: hitbox
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: win.shown ? win.height : 3
                HoverHandler {
                    id: hover
                    onHoveredChanged: if (!hovered) hideDelay.restart()
                }
            }
            Timer { id: hideDelay; interval: 400 }

            // Dock (centred)
            Rectangle {
                id: dock
                parent: hitbox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.shown ? 6 : -60
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                height: 52
                width: row.implicitWidth + 20
                radius: 18
                color: Qt.rgba(0.008, 0.008, 0.024, 0.8)
                border.width: 1
                border.color: Qt.rgba(0.478, 0.471, 1, 0.45)

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 4

                    // Launcher
                    Item {
                        width: 42; height: 42
                        Rectangle {
                            anchors.fill: parent; radius: 12
                            color: lm.containsMouse ? Qt.rgba(0.478, 0.471, 1, 0.3) : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "⊞"
                            font.pixelSize: 24
                            color: root.col("primary", "6d8bff")
                        }
                        MouseArea {
                            id: lm
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: Quickshell.execDetached(["caelestia", "shell", "drawers", "toggle", "launcher"])
                        }
                    }

                    Repeater {
                        model: root.apps

                        Item {
                            id: app
                            required property var modelData
                            readonly property var entry: DesktopEntries.heuristicLookup(modelData.id)
                            readonly property bool running: modelData.running.length > 0
                            readonly property bool active: modelData.running.some(t => t.activated)
                            width: 42; height: 42

                            Rectangle {
                                anchors.fill: parent; radius: 12
                                color: am.containsMouse ? Qt.rgba(0.478, 0.471, 1, 0.3)
                                     : app.active ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            }
                            Image {
                                anchors.centerIn: parent
                                width: 30; height: 30
                                sourceSize: Qt.size(60, 60)
                                source: Quickshell.iconPath(app.entry?.icon ?? app.modelData.id, "application-x-executable")
                            }
                            // running indicator
                            Rectangle {
                                visible: app.running
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                width: app.active ? 16 : 6; height: 3; radius: 2
                                color: root.col("primary", "6d8bff")
                                Behavior on width { NumberAnimation { duration: 120 } }
                            }
                            MouseArea {
                                id: am
                                anchors.fill: parent; hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onClicked: ev => {
                                    if (ev.button === Qt.RightButton && app.running) {
                                        app.modelData.running[0].close();
                                    } else if (ev.button === Qt.LeftButton && app.running) {
                                        const w = app.modelData.running;
                                        const i = w.findIndex(t => t.activated);
                                        w[(i + 1) % w.length].activate();
                                    } else if (app.entry) {
                                        app.entry.execute();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Status area (right)
            Rectangle {
                parent: hitbox
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.shown ? 6 : -60
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                height: 44
                width: status.implicitWidth + 24
                radius: 16
                color: Qt.rgba(0.008, 0.008, 0.024, 0.8)
                border.width: 1
                border.color: Qt.rgba(0.478, 0.471, 1, 0.45)

                Row {
                    id: status
                    anchors.centerIn: parent
                    spacing: 12

                    Repeater {
                        model: SystemTray.items
                        Image {
                            required property var modelData
                            width: 20; height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: ev => ev.button === Qt.LeftButton
                                    ? modelData.activate()
                                    : modelData.display(win, parent.x, win.height)
                            }
                        }
                    }

                    Item {
                        id: netItem
                        anchors.verticalCenter: parent.verticalCenter
                        width: netRow.implicitWidth; height: 24
                        readonly property var wifi: {
                            for (const d of Networking.devices.values)
                                for (const n of (d.networks?.values ?? []))
                                    if (n.connected) return n;
                            return null;
                        }
                        readonly property color tone: wifi ? root.col("onSurface", "eceeff") : root.col("error", "ff5c7a")
                        Row {
                            id: netRow
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                text: !Networking.wifiEnabled ? "wifi_off" : netItem.wifi ? "wifi" : "signal_wifi_bad"
                                color: netItem.tone
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 13; color: netItem.tone
                                text: !Networking.wifiEnabled ? "Wi-Fi apagado" : netItem.wifi ? netItem.wifi.name : "Sin red"
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["caelestia", "shell", "nexus", "open"]) }
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: btRow.implicitWidth; height: 24
                        readonly property int n: Bluetooth.devices.values.filter(d => d.connected).length
                        readonly property bool on: Bluetooth.defaultAdapter?.enabled ?? false
                        Row {
                            id: btRow
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                text: !parent.parent.on ? "bluetooth_disabled" : parent.parent.n > 0 ? "bluetooth_connected" : "bluetooth"
                                color: parent.parent.on ? root.col("onSurface", "eceeff") : root.col("outline", "b8324a")
                            }
                            Text {
                                visible: parent.parent.n > 0
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 13; color: root.col("onSurface", "eceeff")
                                text: parent.parent.n
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["caelestia", "shell", "nexus", "open"])
                        }
                    }

                    Item {
                        id: volItem
                        anchors.verticalCenter: parent.verticalCenter
                        width: volRow.implicitWidth; height: 24
                        readonly property var a: Pipewire.defaultAudioSink?.audio
                        Row {
                            id: volRow
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                text: (volItem.a?.muted ?? false) ? "volume_off" : (volItem.a?.volume ?? 0) < 0.4 ? "volume_down" : "volume_up"
                                color: root.col("onSurface", "eceeff")
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 13; color: root.col("onSurface", "eceeff")
                                text: Math.round((volItem.a?.volume ?? 0) * 100) + "%"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (volItem.a) volItem.a.muted = !volItem.a.muted
                            onWheel: ev => { if (volItem.a) volItem.a.volume = Math.max(0, Math.min(1, volItem.a.volume + (ev.angleDelta.y > 0 ? 0.05 : -0.05))); }
                        }
                    }

                    Row {
                        visible: UPower.displayDevice.isLaptopBattery
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Material Symbols Rounded"; font.pixelSize: 18
                            text: UPower.displayDevice.state === UPowerDeviceState.Charging ? "battery_charging_full" : "battery_full"
                            color: UPower.displayDevice.percentage < 0.2 ? root.col("error", "ff5c7a") : "#7be0a5"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 13; color: root.col("onSurface", "eceeff")
                            text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatTime(clock.date, "hh:mm")
                            color: root.col("onSurface", "e8dfe3")
                            font.pixelSize: 14; font.bold: true
                        }
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatDate(clock.date, "ddd d MMM")
                            color: root.col("primary", "6d8bff")
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
