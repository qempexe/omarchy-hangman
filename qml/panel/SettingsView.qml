import QtQuick
import QtQuick.Layouts
import "../js/Schema.js" as Schema
import "../js/Lang.js" as Lang
import "../js/Words.js" as Words
import "../controls"

// settings tab: one tab per group in Schema.js, rows underneath, and About at the end
Item {
    id: root

    property var svc: null
    readonly property var ui: svc ? svc.ui : null
    property bool confirmReset: false

    readonly property int group: ui ? Math.max(0, Math.min(Schema.groups.length, ui.settingsGroup)) : 0
    // the last tab, after the groups: About
    readonly property bool onAbout: group === Schema.groups.length

    function val(key) {
        const it = Schema.itemByKey[key]
        if (it && it.kind === "palette") {
            const o = {}
            for (let i = 0; i < it.targets.length; i++) o[it.targets[i].key] = val(it.targets[i].key)
            return o
        }
        return svc && svc.cfg && svc.cfg[key] !== undefined ? svc.cfg[key] : Schema.defaults[key]
    }

    function same(item) {
        const v = val(item.key)
        return item.kind === "palette" ? JSON.stringify(v) === JSON.stringify(item.fallback) : Words.toText(v) === Words.toText(item.fallback)
    }

    // popped out, the window manager decides the size, so lock these two
    function offHere(item) {
        return ui.popped === true && (item.key === "windowWidth" || item.key === "windowHeight")
    }

    function dimmed(item) {
        if (!item.when) return false
        for (let i = 0; i < item.when.length; i++) {
            const c = item.when[i]
            if (c.is.indexOf(Words.toText(val(c.key))) < 0) return true
        }
        return false
    }

    readonly property var rows: onAbout ? [] : Schema.groups[group].items

    // a row's texts in the menu language (English from the schema if a text is missing)
    function labelOf(item) { return Lang.tOr(ui.lang, "set." + item.key, item.label) }
    function hintOf(item) { return Lang.tOr(ui.lang, "hint." + item.key, item.hint || "") }
    function targetsOf(item) {
        const list = []
        const targets = item.targets || []
        for (let i = 0; i < targets.length; i++)
            list.push({ key: targets[i].key, label: Lang.tOr(ui.lang, "color." + targets[i].key, targets[i].label) })
        return list
    }

    // count of changed settings (footer)
    readonly property int changed: {
        let n = 0
        for (let g = 0; g < Schema.groups.length; g++) {
            const items = Schema.groups[g].items
            for (let i = 0; i < items.length; i++)
                if (!same(items[i])) n++
        }
        return n
    }

    function resetAll() {
        if (!root.confirmReset) { root.confirmReset = true; confirmTimer.restart(); return }
        root.confirmReset = false
        if (svc && svc.store) svc.store.resetAll(Schema.defaults)
    }
    Timer { id: confirmTimer; interval: 2500; onTriggered: root.confirmReset = false }

    ColumnLayout {
        anchors.fill: parent
        spacing: ui.px(12)

        // group tabs
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
                    model: Schema.groups.concat([{ title: "About" }])
                    delegate: Item {
                        readonly property bool on: index === root.group
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Txt {
                            ui: root.ui
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: ui.t("group." + modelData.title.toLowerCase())
                            opacity: parent.on ? 1.0 : (tabArea.containsMouse ? 0.8 : 0.5)
                            font.pixelSize: ui.fs(12)
                            font.weight: parent.on ? Font.DemiBold : Font.Normal
                        }
                        Rectangle {
                            visible: parent.on
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
                            onClicked: { root.ui.settingsGroup = index; flick.contentY = 0 }
                        }
                    }
                }
            }
        }

        AboutPage {
            ui: root.ui
            visible: root.onAbout
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // rows
        Flickable {
            id: flick
            visible: !root.onAbout
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: card.implicitHeight + ui.px(4)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Item {
                id: card
                width: flick.width
                implicitHeight: rowsCol.implicitHeight + ui.px(12)

                ColumnLayout {
                    id: rowsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: ui.px(16)
                    anchors.rightMargin: ui.px(16)
                    anchors.topMargin: ui.px(6)
                    spacing: 0

                    Repeater {
                        model: root.rows
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Rectangle {
                                visible: index > 0
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: ui.tint(0.07)
                            }
                            SettingRow {
                                Layout.fillWidth: true
                                Layout.topMargin: ui.px(14)
                                Layout.bottomMargin: ui.px(14)
                                ui: root.ui
                                settingKey: modelData.key
                                label: root.labelOf(modelData)
                                hint: root.offHere(modelData)
                                    ? ui.t("settings.locked")
                                    : (modelData.key === "category" && root.svc && root.svc.cfg.category === "custom"
                                       && root.svc.customWords.length === 0
                                       ? root.hintOf(modelData) + "\n" + ui.t("settings.noCustom")
                                       : root.hintOf(modelData))
                                kind: modelData.kind
                                control: modelData.control || ""
                                options: modelData.options || []
                                labels: Lang.optionLabels(ui.lang, modelData.key, modelData.options || [], modelData.labels || ({}))
                                presets: modelData.presets || []
                                maxLength: modelData.maxLength !== undefined ? modelData.maxLength : 2048
                                min: modelData.min !== undefined ? modelData.min : 0
                                max: modelData.max !== undefined ? modelData.max : 100
                                step: modelData.step !== undefined ? modelData.step : 1
                                divisor: modelData.divisor !== undefined ? modelData.divisor : 1
                                decimals: modelData.decimals !== undefined ? modelData.decimals : 0
                                defaultValue: modelData.fallback
                                dimmed: root.dimmed(modelData)
                                locked: root.offHere(modelData)
                                value: root.val(modelData.key)
                                targets: root.targetsOf(modelData)
                                onEdited: function(v) {
                                    if (root.offHere(modelData) || !root.svc) return
                                    if (modelData.kind === "palette") {
                                        if (v && v.reset) {
                                            for (let i = 0; i < modelData.targets.length; i++) {
                                                const k = modelData.targets[i].key
                                                root.svc.setValue(k, modelData.fallback[k])
                                            }
                                        } else if (v && v.key) root.svc.setValue(v.key, v.value)
                                        return
                                    }
                                    root.svc.setValue(modelData.key, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
