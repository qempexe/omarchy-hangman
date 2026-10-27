import QtQuick
import QtQuick.Layouts
import "../js/Words.js" as Words
import "../controls"

// numbers, per category bars, and the last words you played
Item {
    id: root

    property var svc: null
    readonly property var ui: svc ? svc.ui : null
    readonly property var stats: svc ? svc.stats : null
    property bool confirmReset: false

    function resetStats() {
        if (!root.confirmReset) { root.confirmReset = true; confirmTimer.restart(); return }
        root.confirmReset = false
        if (root.svc) root.svc.resetStats()
    }
    Timer { id: confirmTimer; interval: 2500; onTriggered: root.confirmReset = false }

    readonly property var tiles: {
        const s = root.stats
        if (!s) return []
        const rate = s.played > 0 ? Math.round(s.won / s.played * 100) + "%" : "–"
        return [
            { value: "" + s.played, label: ui.t("stats.played") },
            { value: rate, label: ui.t("stats.won") },
            { value: "" + s.streak, label: ui.t("stats.streak") },
            { value: "" + s.best, label: ui.t("stats.best") },
            { value: "" + s.perfect, label: ui.t("stats.perfect") }
        ]
    }

    readonly property var cats: {
        const s = root.stats
        if (!s) return []
        const out = []
        for (const k in s.byCategory) {
            const c = s.byCategory[k]
            if (c.played > 0) out.push({ key: k, label: ui.t("cat." + k), played: c.played, won: c.won })
        }
        out.sort((a, b) => b.played - a.played || a.label.localeCompare(b.label))
        return out
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + ui.px(8)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: flick.width
            spacing: ui.px(16)

            // the numbers
            GridLayout {
                Layout.fillWidth: true
                columns: 5
                columnSpacing: ui.px(8)
                rowSpacing: ui.px(8)
                Repeater {
                    model: root.tiles
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: ui.px(66)
                        radius: ui.r(1.4)
                        color: index === 1 ? ui.accentTint(0.14) : ui.tint(0.05)
                        border.width: 1
                        border.color: index === 1 ? ui.accentTint(0.5) : ui.tint(0.08)
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Txt {
                                ui: root.ui
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                font.pixelSize: ui.fs(22)
                                font.weight: Font.DemiBold
                                color: index === 1 ? ui.accent : ui.fg
                            }
                            Txt {
                                ui: root.ui
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: ui.fs(10)
                                opacity: 0.55
                            }
                        }
                    }
                }
            }

            // per category
            Txt {
                ui: root.ui
                visible: root.cats.length > 0
                text: ui.t("stats.byCategory")
                font.pixelSize: ui.fs(10)
                font.letterSpacing: 2
                opacity: 0.5
            }
            Repeater {
                model: root.cats
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: ui.px(10)
                    Txt {
                        ui: root.ui
                        Layout.preferredWidth: ui.px(96)
                        text: modelData.label
                        font.pixelSize: ui.fs(11)
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: ui.px(8)
                        radius: height / 2
                        color: ui.tint(0.08)
                        Rectangle {
                            width: parent.width * (modelData.played > 0 ? modelData.won / modelData.played : 0)
                            height: parent.height
                            radius: height / 2
                            color: ui.accent
                            Behavior on width { enabled: ui.animations; NumberAnimation { duration: ui.speed * 2 } }
                        }
                    }
                    Txt {
                        ui: root.ui
                        Layout.preferredWidth: ui.px(54)
                        horizontalAlignment: Text.AlignRight
                        text: modelData.won + " / " + modelData.played
                        font.pixelSize: ui.fs(11)
                        opacity: 0.7
                    }
                }
            }

            // recent words
            Txt {
                ui: root.ui
                visible: !!root.stats && root.stats.recent.length > 0
                text: ui.t("stats.lastWords")
                font.pixelSize: ui.fs(10)
                font.letterSpacing: 2
                opacity: 0.5
            }
            Flow {
                Layout.fillWidth: true
                spacing: ui.px(6)
                Repeater {
                    model: root.stats ? root.stats.recent.slice(0, 18) : []
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: wl.implicitWidth + ui.px(16)
                        implicitHeight: ui.px(24)
                        radius: ui.r(1.5)
                        color: modelData.won ? ui.accentTint(0.16) : ui.tint(0.04)
                        border.width: 1
                        border.color: modelData.won ? ui.accentTint(0.6) : Qt.rgba(ui.bad.r, ui.bad.g, ui.bad.b, 0.45)
                        Txt {
                            id: wl
                            ui: root.ui
                            anchors.centerIn: parent
                            text: modelData.word + (modelData.won ? (modelData.wrong === 0 ? "  ★" : "") : "  ✕")
                            font.pixelSize: ui.fs(10)
                            color: modelData.won ? ui.fg : ui.bad
                        }
                    }
                }
            }

            Txt {
                ui: root.ui
                visible: !root.stats || root.stats.played === 0
                Layout.fillWidth: true
                Layout.topMargin: ui.px(30)
                horizontalAlignment: Text.AlignHCenter
                text: ui.t("stats.empty")
                font.pixelSize: ui.fs(12)
                opacity: 0.5
            }
        }
    }
}
