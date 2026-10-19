import QtQuick
import "../js/Game.js" as Game
import "../controls"

// one slot of the word. pops in when guessed, waves when the word is won,
// shows the missing letters in red when it's lost
Item {
    id: root

    property var ui: null
    property string ch: ""
    property real size: 30
    property int order: 0
    property string guessed: ""
    property string status: "playing"

    readonly property bool letter: Game.isLetter(ch)
    readonly property bool shown: !letter || guessed.indexOf(ch) >= 0
    readonly property bool revealed: !shown && status === "lost"

    width: size
    height: size * 1.25

    property real pop: 1
    property real wave: 0
    onShownChanged: if (shown && ui && ui.animations) popAnim.restart()
    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: root; property: "pop"; from: 0.4; to: 1.15; duration: root.ui ? root.ui.speed * 0.7 : 150; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "pop"; to: 1; duration: root.ui ? root.ui.speed * 0.5 : 100; easing.type: Easing.InOutQuad }
    }
    // a wave across the word on a win
    SequentialAnimation {
        running: root.status === "won" && root.ui && root.ui.animations
        PauseAnimation { duration: root.order * 45 }
        NumberAnimation { target: root; property: "wave"; to: 1; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "wave"; to: 0; duration: 220; easing.type: Easing.InQuad }
    }

    Txt {
        ui: root.ui
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: line.top
        anchors.bottomMargin: root.size * 0.06 + root.wave * root.size * 0.3
        visible: root.shown || root.revealed
        text: root.ch
        scale: root.pop
        font.pixelSize: Math.max(8, root.size * 0.78)
        font.weight: Font.DemiBold
        color: root.revealed ? ui.bad : (root.status === "won" ? ui.accent : ui.fg)
        opacity: root.revealed ? 0.85 : 1
    }
    Rectangle {
        id: line
        visible: root.letter
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.max(2, root.size * 0.07)
        radius: height / 2
        color: root.status === "won" ? ui.accent : (root.revealed ? ui.bad : ui.tint(root.shown ? 0.5 : 0.75))
    }
}
