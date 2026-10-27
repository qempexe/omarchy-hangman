import QtQuick
import Quickshell
import Quickshell.Io
import "../js/Game.js" as Game

// the word in play + stats, in game.json next to the settings.
// read once at startup, written a moment after every change
Item {
    id: root

    visible: false

    property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state") + "/omarchy-hangman"
    property string path: stateDir + "/game.json"

    property var game: null
    property var stats: Game.emptyStats()
    property bool loaded: false
    property bool dirReady: false

    signal ready()

    function save() { writeTimer.restart() }

    Timer {
        id: writeTimer
        interval: 250
        onTriggered: root.flush()
    }

    function flush() {
        if (!dirReady || !loaded) { writeTimer.restart(); return }
        file.setText(JSON.stringify({ game: root.game, stats: root.stats }) + "\n")
    }

    function readText(fv) {
        try {
            const t = typeof fv.text === "function" ? fv.text() : fv.text
            return typeof t === "string" ? t : ""
        } catch (e) { return "" }
    }

    function absorb(text) {
        if (loaded) return
        let o = null
        try { o = JSON.parse(text || "{}") } catch (e) { o = null }
        if (o && typeof o === "object" && !Array.isArray(o)) {
            // anything set before the file came in wins
            if (root.game === null) root.game = Game.revive(o.game)
            if (root.stats.played === 0) root.stats = Game.reviveStats(o.stats)
        }
        loaded = true
        ready()
    }

    Component.onCompleted: mkdir.running = true

    Process {
        id: mkdir
        command: ["sh", "-c", 'umask 077; mkdir -p "$1" && chmod 700 "$1"', "sh", root.stateDir]
        onExited: {
            root.dirReady = true
            if (!root.loaded) file.reload()
        }
    }

    FileView {
        id: file
        path: root.path
        onLoaded: root.absorb(root.readText(file))
        onLoadFailed: root.absorb("")
    }
}
