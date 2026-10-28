import QtQuick
import QtQuick.Layouts
import "../controls"

// the whole panel: header, three tabs, content, footer.
// used by both the docked popup and the popped out window
Item {
    id: view

    property var svc: null
    property bool shown: false
    readonly property var ui: svc ? svc.ui : null
    clip: true

    // popped out there's no shortcut for esc, so handle it here
    Keys.onEscapePressed: function(e) {
        if (ui.popped) { ui.closeRequested(); e.accepted = true }
        else e.accepted = false
    }

    // background
    Rectangle {
        anchors.fill: parent
        radius: ui.r(3)
        color: ui.panelColor
    }
    Rectangle {   // optional accent wash (Window tint, 0 by default)
        anchors.fill: parent
        radius: ui.r(3)
        visible: ui.tintPct > 0
        color: ui.accentTint(ui.tintPct / 100)
    }
    Rectangle {   // edge: a plain neutral line; accent only if "Window outline" is on
        anchors.fill: parent
        radius: ui.r(3)
        color: "transparent"
        border.width: 1
        border.color: ui.frameOn ? ui.accent : ui.tint(0.14)
        opacity: ui.frameOn ? 0.8 : 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ui.px(14)
        spacing: ui.px(12)

        // header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + ui.px(24)
            radius: ui.r(2.5)
            color: ui.tint(0.05)
            border.width: 1
            border.color: ui.tint(0.08)

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: ui.px(12)
                spacing: ui.px(10)

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: ui.px(30); implicitHeight: ui.px(30)
                    radius: ui.r(1.5)
                    color: ui.accentTint(0.18)
                    border.width: 1
                    border.color: ui.tint(0.08)
                    Image {   // the logo, light or dark to suit the panel
                        anchors.centerIn: parent
                        width: ui.px(24); height: width
                        source: Qt.resolvedUrl(ui.lightSurface ? "../../assets/logo-dark.png" : "../../assets/logo.png")
                        sourceSize.width: 96
                        sourceSize.height: 96
                        smooth: true
                        mipmap: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Txt {
                        ui: view.ui
                        Layout.fillWidth: true
                        text: ui.t("game")
                        font.pixelSize: ui.fs(13)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Txt {
                        ui: view.ui
                        Layout.fillWidth: true
                        font.pixelSize: ui.fs(11)
                        opacity: 0.6
                        elide: Text.ElideRight
                        text: {
                            if (!view.svc) return ui.t("head.starting")
                            const st = view.svc.stats
                            let s = ui.t("head.won", st.won, st.played)
                            if (st.streak > 0) s += "  ·  " + ui.t("head.streak", st.streak)
                            if (st.best > 1) s += "  ·  " + ui.t("head.best", st.best)
                            return s
                        }
                    }
                }

                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    visible: ui.tabName === "play"
                    kind: view.svc && view.svc.finished ? "primary" : "normal"
                    text: ui.t("btn.newWord")
                    onClicked: { view.svc.newWord(); ui.tabName = "play" }
                }
                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    visible: ui.tabName === "stats"
                    enabled: view.svc && view.svc.stats.played > 0
                    kind: statsView.confirmReset ? "primary" : "normal"
                    text: statsView.confirmReset ? ui.t("btn.reallyReset") : ui.t("btn.resetStats")
                    onClicked: statsView.resetStats()
                }
                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    visible: ui.tabName === "settings"
                    kind: settingsView.confirmReset ? "primary" : "normal"
                    text: settingsView.confirmReset ? ui.t("btn.reallyReset") : ui.t("btn.resetAll")
                    onClicked: settingsView.resetAll()
                }
                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    text: ui.popped ? ui.t("btn.dock") : ui.t("btn.popOut")
                    onClicked: ui.popped ? ui.dockRequested() : ui.popOutRequested()
                }
                Btn { ui: view.ui; Layout.alignment: Qt.AlignVCenter; text: "×"; implicitWidth: ui.px(24); onClicked: ui.closeRequested() }
            }
        }

        // tabs
        Item {
            Layout.fillWidth: true
            implicitHeight: ui.px(32)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: ui.tint(0.10)
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: ["play", "stats", "settings"]
                    delegate: Item {
                        id: tab
                        readonly property bool on: ui.tabName === modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Txt {
                            ui: view.ui
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: ui.t("tab." + modelData)
                            font.pixelSize: ui.fs(12)
                            font.weight: tab.on ? Font.DemiBold : Font.Normal
                            opacity: tab.on ? 1 : (tabArea.containsMouse ? 0.8 : 0.5)
                        }
                        Rectangle {
                            visible: tab.on
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            radius: 1
                            color: ui.accent
                        }
                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ui.tabName = modelData
                        }
                    }
                }
            }
        }

        // content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            radius: ui.r(2.5)
            color: ui.tint(0.035)
            border.width: 1
            border.color: ui.tint(0.07)
            clip: true

            PlayView {
                id: playView
                anchors.fill: parent
                anchors.margins: ui.px(12)
                visible: ui.tabName !== "settings" && ui.tabName !== "stats"
                svc: view.svc
                shown: view.shown && visible
            }
            StatsView {
                id: statsView
                anchors.fill: parent
                anchors.margins: ui.px(12)
                visible: ui.tabName === "stats"
                svc: view.svc
            }
            SettingsView {
                id: settingsView
                anchors.fill: parent
                anchors.margins: ui.px(10)
                visible: ui.tabName === "settings"
                svc: view.svc
            }
        }

        // footer
        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(8)

            Rectangle {
                implicitWidth: escLabel.implicitWidth + ui.px(12)
                implicitHeight: ui.px(18)
                radius: ui.r(1)
                color: ui.tint(0.08)
                Txt { id: escLabel; ui: view.ui; anchors.centerIn: parent; text: "Esc"; font.pixelSize: ui.fs(10); opacity: 0.75 }
            }
            Txt { ui: view.ui; text: ui.t("foot.close"); font.pixelSize: ui.fs(10); opacity: 0.45 }

            Txt {
                ui: view.ui
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: ui.fs(10)
                opacity: 0.45
                text: ui.tabName === "settings"
                    ? (settingsView.changed === 0 ? ui.t("foot.defaults")
                       : settingsView.changed === 1 ? ui.t("foot.differOne") : ui.t("foot.differMany", settingsView.changed))
                    : ui.tabName === "stats" ? ui.t("foot.stats")
                    : (view.svc && view.svc.finished ? ui.t("foot.enter") : ui.t("foot.help"))
            }
            Txt { ui: view.ui; visible: ui.tabName === "settings"; text: ui.t("foot.instant"); font.pixelSize: ui.fs(10); opacity: 0.45 }
        }
    }
}
