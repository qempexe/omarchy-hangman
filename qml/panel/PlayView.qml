import QtQuick
import QtQuick.Layouts
import "../js/Game.js" as Game
import "../js/Words.js" as Words
import "../controls"

// the game: clue + lives, the drawing, the word, the letters.
// typing works anywhere in here, the letters below are just for the mouse
Item {
    id: root

    property var svc: null
    property bool shown: false
    readonly property var ui: svc ? svc.ui : null
    readonly property var game: svc ? svc.game : null
    readonly property var cfg: svc ? svc.cfg : null
    readonly property bool done: !!game && game.status !== "playing"

    focus: true
    onShownChanged: if (shown) forceActiveFocus()
    onVisibleChanged: if (visible && shown) forceActiveFocus()

    Keys.onPressed: function(e) {
        if (!root.svc || !root.game) return
        if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_N) { root.svc.newWord(); e.accepted = true; return }
        if (e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        if (root.done && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)) {
            root.svc.newWord(); e.accepted = true; return
        }
        if (e.text === "?") { root.svc.useHint(); e.accepted = true; return }
        // only letters that have a key: Ñ in English, say, is not a letter you can play
        const t = Words.upperLetter(e.text)
        if (t.length === 1 && root.keyRows.join("").indexOf(t) !== -1) { root.svc.guess(t); e.accepted = true }
    }

    // shake the word on a wrong letter
    property real shake: 0
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shake"; to: -1; duration: 50 }
        NumberAnimation { target: root; property: "shake"; to: 1; duration: 70 }
        NumberAnimation { target: root; property: "shake"; to: -0.5; duration: 60 }
        NumberAnimation { target: root; property: "shake"; to: 0; duration: 60 }
    }
    Connections {
        target: root.svc
        ignoreUnknownSignals: true
        function onLastMissChanged() { if (root.ui && root.ui.animations) shakeAnim.restart() }
    }

    // the language's letters, plus any odd one in the word in play (see Words.keyRows)
    readonly property var keyRows: !cfg ? [] : Words.keyRows(cfg.keyboard, cfg.language, game ? game.word : "")

    ColumnLayout {
        anchors.fill: parent
        spacing: ui.px(10)

        // clue + lives + hint
        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(8)

            Txt {
                ui: root.ui
                visible: root.cfg && root.cfg.showCategory && !!root.game
                text: root.game ? ui.t("cat." + root.game.category).toUpperCase() : ""
                font.pixelSize: ui.fs(10)
                font.letterSpacing: 2
                font.weight: Font.DemiBold
                color: ui.accent
            }
            Txt {
                ui: root.ui
                visible: !!root.game
                text: !root.game ? "" : ui.t("play.letters", Words.letterCount(root.game.word))
                      + (root.game.word.indexOf(" ") >= 0 ? ", " + ui.t("play.words", root.game.word.split(" ").length) : "")
                font.pixelSize: ui.fs(10)
                opacity: 0.5
            }
            Item { Layout.fillWidth: true }
            Txt {
                ui: root.ui
                visible: !!root.game
                text: !root.game ? "" : (root.game.lives - root.game.wrong === 1 ? ui.t("play.lifeOne") : ui.t("play.lives", root.game.lives - root.game.wrong))
                font.pixelSize: ui.fs(11)
                color: root.game && root.game.lives - root.game.wrong <= 1 && !root.done ? ui.bad : ui.fg
                opacity: 0.8
            }
            Btn {
                ui: root.ui
                visible: root.game && root.game.maxHints > 0
                enabled: root.svc && root.svc.hintReady
                text: ui.t("btn.hint", root.game ? root.game.maxHints - root.game.hints : "")
                onClicked: { root.svc.useHint(); root.forceActiveFocus() }
            }
        }

        // the drawing
        Figure {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: ui.px(80)
            ui: root.ui
            style: root.cfg ? root.cfg.figure : "gallows"
            lives: root.game ? root.game.lives : 6
            wrong: root.game ? root.game.wrong : 0
            status: root.game ? root.game.status : "playing"
        }

        // the word, split on spaces so phrases wrap between words
        Item {
            id: wordBox
            Layout.fillWidth: true
            implicitHeight: wordFlow.implicitHeight
            readonly property int longest: {
                if (!root.game) return 1
                const parts = root.game.word.split(" ")
                let m = 1
                for (let i = 0; i < parts.length; i++) m = Math.max(m, parts[i].length)
                return Math.max(m, Math.min(root.game.word.length, 12))
            }
            readonly property real cell: Math.max(ui.px(14), Math.min(ui.px(36), (width - ui.px(8)) / longest - ui.px(6)))

            Flow {
                id: wordFlow
                x: (parent.width - implicitW) / 2 + root.shake * ui.px(8)
                width: parent.width
                spacing: wordBox.cell * 0.9
                readonly property real implicitW: Math.min(parent.width, childrenRect.width)

                Repeater {
                    model: root.game ? root.game.word.split(" ") : []
                    delegate: Row {
                        id: wordRow
                        required property string modelData
                        required property int index
                        // where this word starts in the whole phrase
                        readonly property int offset: {
                            const parts = root.game.word.split(" ")
                            let n = 0
                            for (let i = 0; i < index; i++) n += parts[i].length + 1
                            return n
                        }
                        spacing: ui.px(6)
                        Repeater {
                            model: wordRow.modelData.length
                            delegate: LetterCell {
                                required property int index
                                ui: root.ui
                                ch: wordRow.modelData.charAt(index)
                                size: wordBox.cell
                                order: wordRow.offset + index
                                guessed: root.game ? root.game.guessed : ""
                                status: root.game ? root.game.status : "playing"
                            }
                        }
                    }
                }
            }
        }

        // after the word: what happened + next
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: ui.px(26)
            spacing: ui.px(10)
            Item { Layout.fillWidth: true }
            Txt {
                ui: root.ui
                text: !root.game ? (root.svc ? ui.t("play.noWords") : "")
                    : root.game.status === "won" ? (root.game.wrong === 0 ? ui.t("play.perfect") : ui.t("play.won"))
                    : root.game.status === "lost" ? ui.t("play.lost") : ""
                font.pixelSize: ui.fs(13)
                font.weight: Font.DemiBold
                color: root.game && root.game.status === "lost" ? ui.bad : ui.accent
            }
            Btn {
                ui: root.ui
                visible: root.done
                kind: "primary"
                text: root.cfg && root.cfg.autoNext ? ui.t("btn.nextWordSoon") : ui.t("btn.nextWord")
                onClicked: { root.svc.newWord(); root.forceActiveFocus() }
            }
            Item { Layout.fillWidth: true }
        }

        // the letters
        Column {
            Layout.fillWidth: true
            visible: root.cfg && root.cfg.keyboard !== "off"
            spacing: ui.px(6)
            readonly property real key: Math.min(ui.px(34), (width - 9 * ui.px(6)) / 10)

            Repeater {
                model: root.keyRows
                delegate: Row {
                    id: keyRow
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ui.px(6)
                    Repeater {
                        model: keyRow.modelData.length
                        delegate: Rectangle {
                            id: key
                            required property int index
                            readonly property string letter: keyRow.modelData.charAt(index)
                            readonly property string st: Game.state(root.game, letter)
                            readonly property bool usable: st === "" && !root.done
                            width: parent.parent.key
                            height: width * 1.08
                            radius: ui.r(1.2)
                            color: st === "hit" ? ui.accentTint(0.85)
                                 : st === "miss" ? ui.tint(0.03)
                                 : ui.tint(kArea.containsMouse && usable ? 0.16 : 0.08)
                            border.width: 1
                            border.color: st === "hit" ? ui.accent : ui.tint(st === "miss" ? 0.06 : 0.12)
                            Behavior on color { enabled: ui.animations; ColorAnimation { duration: ui.speed } }

                            Txt {
                                ui: root.ui
                                anchors.centerIn: parent
                                text: key.letter
                                font.pixelSize: Math.max(8, key.width * 0.42)
                                font.weight: Font.DemiBold
                                color: key.st === "hit" ? ui.accentText : ui.fg
                                opacity: key.st === "miss" ? 0.25 : (root.done ? 0.5 : 0.9)
                            }
                            Rectangle {   // crossed out
                                visible: key.st === "miss"
                                anchors.centerIn: parent
                                width: parent.width * 0.6; height: 1.5
                                rotation: -35
                                color: ui.bad
                                opacity: 0.6
                            }
                            MouseArea {
                                id: kArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: key.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: { if (key.usable) root.svc.guess(key.letter); root.forceActiveFocus() }
                            }
                        }
                    }
                }
            }
        }
    }
}
