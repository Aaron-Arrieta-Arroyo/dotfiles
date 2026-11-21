pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    // Newest first, only notifications that were not dismissed.
    readonly property var items: Notifs.list.filter(n => !n.closed).slice(0, 30)

    implicitHeight: 240
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: "Notificaciones (" + Notifs.list.filter(n => !n.closed).length + ")"
                font: Tokens.font.body.medium
            }

            StyledText {
                visible: root.items.length > 0
                text: "Limpiar todo"
                color: Colours.palette.m3primary
                font: Tokens.font.label.large

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.items.forEach(n => n.close())
                }
            }
        }

        StyledText {
            visible: root.items.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.large
            text: "Todo al día"
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length > 0
            clip: true
            spacing: Tokens.spacing.small
            model: root.items

            delegate: Item {
                id: row

                required property var modelData

                width: ListView.view.width
                height: textCol.implicitHeight + 16

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                }

                Column {
                    id: textCol
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6

                    StyledText {
                        width: parent.width
                        text: row.modelData.summary
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }
                    StyledText {
                        width: parent.width
                        visible: row.modelData.body.length > 0
                        text: row.modelData.body
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.large
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        width: parent.width
                        text: row.modelData.appName + " · " + row.modelData.timeStr
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    color: Colours.palette.m3outline

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.modelData.close()
                    }
                }
            }
        }
    }
}
