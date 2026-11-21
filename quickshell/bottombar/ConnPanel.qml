import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth

PanelWindow {
    id: panel

    required property var shell         // ShellRoot (colour helper + state)
    required property var modelData     // screen
    screen: modelData

    visible: shell.panel !== ""
    anchors { bottom: true; right: true }
    margins { bottom: 68; right: 10 }
    implicitWidth: 380
    implicitHeight: 520
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "bottombar-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property color fg: shell.col("onSurface", "e8dfe3")
    readonly property color gold: shell.col("secondary", "c9a24b")
    readonly property color red: shell.col("primary", "d4344a")
    readonly property color dim: shell.col("outline", "7a6670")

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var nets: {
        const l = (wifiDev?.networks?.values ?? []).slice();
        l.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
        return l;
    }
    property string pendingNet: ""      // name of network awaiting a password
    property string failMsg: ""

    onVisibleChanged: if (visible && wifiDev) wifiDev.scannerEnabled = true
    readonly property string cur: shell.panel
    onCurChanged: {
        if (wifiDev) wifiDev.scannerEnabled = cur === "net";
        pendingNet = "";
        failMsg = "";
    }

    component Pill: Rectangle {
        id: pill
        property alias text: lbl.text
        property bool accent: false
        signal clicked
        implicitWidth: lbl.implicitWidth + 20
        implicitHeight: 28
        radius: 10
        color: pm.containsMouse ? Qt.rgba(0.83, 0.2, 0.29, 0.45)
             : accent ? Qt.rgba(0.83, 0.2, 0.29, 0.28) : Qt.rgba(1, 1, 1, 0.07)
        Text { id: lbl; anchors.centerIn: parent; color: panel.fg; font.pixelSize: 12 }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
    }

    component Toggle: Rectangle {
        id: tg
        property bool on
        signal toggled
        width: 42; height: 22; radius: 11
        color: on ? panel.red : Qt.rgba(1, 1, 1, 0.12)
        Rectangle {
            width: 16; height: 16; radius: 8; y: 3
            x: tg.on ? parent.width - width - 3 : 3
            color: tg.on ? panel.gold : panel.fg
            Behavior on x { NumberAnimation { duration: 120 } }
        }
        MouseArea { anchors.fill: parent; onClicked: tg.toggled() }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0.07, 0.05, 0.09, 0.62)
        border.width: 1
        border.color: Qt.rgba(0.79, 0.64, 0.29, 0.4)
        focus: true
        Keys.onEscapePressed: panel.shell.panel = ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header: tabs + close
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Pill { text: "📶 Wi-Fi"; accent: panel.shell.panel === "net"; onClicked: panel.shell.panel = "net" }
                Pill { text: "🔷 Bluetooth"; accent: panel.shell.panel === "bt"; onClicked: panel.shell.panel = "bt" }
                Item { Layout.fillWidth: true }
                Pill { text: "✕"; onClicked: panel.shell.panel = "" }
            }

            // ---------- Wi-Fi ----------
            ColumnLayout {
                visible: panel.shell.panel === "net"
                Layout.fillWidth: true; Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Wi-Fi"; color: panel.gold; font.pixelSize: 16; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Toggle { on: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
                }
                Text {
                    visible: panel.failMsg !== ""
                    text: panel.failMsg; color: panel.red; font.pixelSize: 12
                    Layout.fillWidth: true; wrapMode: Text.Wrap
                }

                ListView {
                    id: list
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 6
                    model: Networking.wifiEnabled ? panel.nets : []

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool secured: modelData.security !== WifiSecurityType.Open
                        readonly property bool asking: panel.pendingNet === modelData.name
                        width: list.width
                        height: asking ? 92 : 46
                        radius: 12
                        color: modelData.connected ? Qt.rgba(0.83, 0.2, 0.29, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                        Behavior on height { NumberAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: (row.secured ? "🔒 " : "") + row.modelData.name
                                    color: panel.fg; font.pixelSize: 13; font.bold: row.modelData.connected
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text { text: Math.round(row.modelData.signalStrength * 100) + "%"; color: panel.dim; font.pixelSize: 12 }
                                Pill {
                                    text: row.modelData.connected ? "Desconectar" : "Conectar"
                                    accent: !row.modelData.connected
                                    onClicked: {
                                        panel.failMsg = "";
                                        if (row.modelData.connected) row.modelData.disconnect();
                                        else if (row.secured && !row.modelData.known) panel.pendingNet = row.modelData.name;
                                        else row.modelData.connect();
                                    }
                                }
                                Pill { visible: row.modelData.known; text: "Olvidar"; onClicked: row.modelData.forget() }
                            }
                            RowLayout {
                                visible: row.asking
                                Layout.fillWidth: true
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                    TextInput {
                                        id: pw
                                        anchors.fill: parent; anchors.margins: 6
                                        echoMode: TextInput.Password
                                        color: panel.fg; font.pixelSize: 13
                                        focus: row.asking
                                        onVisibleChanged: if (visible) forceActiveFocus()
                                        onAccepted: { row.modelData.connectWithPsk(text); panel.pendingNet = ""; text = ""; }
                                    }
                                }
                                Pill {
                                    text: "OK"; accent: true
                                    onClicked: { row.modelData.connectWithPsk(pw.text); panel.pendingNet = ""; pw.text = ""; }
                                }
                            }
                        }
                        Connections {
                            target: row.modelData
                            function onConnectionFailed(reason) { panel.failMsg = "No se pudo conectar a " + row.modelData.name; }
                        }
                    }
                }

                Text {
                    visible: Networking.wifiEnabled && panel.nets.length === 0
                    text: "Buscando redes…"; color: panel.dim; font.pixelSize: 13
                }

                RowLayout {
                    Layout.fillWidth: true
                    Pill { text: "⚙ Editor de conexiones"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                    Item { Layout.fillWidth: true }
                    Pill { text: "Terminal (nmtui)"; onClicked: Quickshell.execDetached(["foot", "-e", "nmtui"]) }
                }
            }

            // ---------- Bluetooth ----------
            ColumnLayout {
                visible: panel.shell.panel === "bt"
                Layout.fillWidth: true; Layout.fillHeight: true
                spacing: 10
                readonly property var ad: Bluetooth.defaultAdapter

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Bluetooth"; color: panel.gold; font.pixelSize: 16; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { visible: parent.parent.ad?.enabled ?? false; text: parent.parent.ad?.discovering ? "buscando…" : ""; color: panel.dim; font.pixelSize: 12 }
                    Pill {
                        visible: parent.parent.ad?.enabled ?? false
                        text: parent.parent.ad?.discovering ? "Detener" : "Buscar"
                        onClicked: parent.parent.ad.discovering = !parent.parent.ad.discovering
                    }
                    Toggle {
                        on: parent.parent.ad?.enabled ?? false
                        onToggled: if (parent.parent.ad) parent.parent.ad.enabled = !parent.parent.ad.enabled
                    }
                }

                ListView {
                    id: btList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 6
                    model: ScriptModel {
                        values: {
                            const l = (Bluetooth.devices?.values ?? []).slice();
                            l.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired));
                            return l;
                        }
                    }
                    delegate: Rectangle {
                        required property var modelData
                        width: btList.width; height: 46; radius: 12
                        color: modelData.connected ? Qt.rgba(0.83, 0.2, 0.29, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8
                            Text {
                                text: modelData.name || modelData.deviceName || modelData.address
                                color: panel.fg; font.pixelSize: 13; font.bold: modelData.connected
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                visible: modelData.batteryAvailable
                                text: "🔋 " + Math.round(modelData.battery * 100) + "%"
                                color: panel.dim; font.pixelSize: 12
                            }
                            Pill {
                                text: modelData.connected ? "Desconectar" : modelData.paired ? "Conectar" : "Emparejar"
                                accent: !modelData.connected
                                onClicked: {
                                    if (modelData.connected) modelData.disconnect();
                                    else if (modelData.paired) modelData.connect();
                                    else modelData.pair();
                                }
                            }
                            Pill { visible: modelData.paired; text: "Olvidar"; onClicked: modelData.forget() }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Pill { text: "⚙ Blueman"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                }
            }
        }
    }
}
