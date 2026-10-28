import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "js/Schema.js" as Schema
import "js/Game.js" as Game
import "js/Words.js" as Words
import "core"

// the always-loaded part: settings, the word in play, stats, your own words and ipc.
// the bar button, the panel and the popped out window all read from here,
// so closing the panel never loses a game
Item {
    id: root

    visible: false

    property var shell: null
    property var manifest: null

    readonly property string pluginId: "io.github.qempexe.hangman"

    // settings
    SettingsStore { id: settingsStore }
    property alias store: settingsStore
    readonly property var cfg: Schema.resolve(settingsStore.values)

    function setValue(key, value) {
        const v = Schema.clean(key, value)
        if (v !== undefined) settingsStore.set(key, v)
    }

    UiState {
        id: ux
        store: settingsStore
        cfg: root.cfg
        barFg: Color.bar.text
        barBg: Color.bar.background
        themeAccent: Color.accent
        themeUrgent: Color.urgent
        fontName: Style.font.family
    }
    property alias ui: ux

    // game
    GameStore {
        id: gameStore
        onReady: if (root.game === null) root.newWord()
    }
    readonly property var game: gameStore.game
    readonly property var stats: gameStore.stats
    readonly property bool playing: game !== null && game.status === "playing"
    readonly property bool finished: game !== null && game.status !== "playing"

    // bumped on every guess, the panel uses it to shake / pop things
    property int lastHit: 0
    property int lastMiss: 0

    function wordsFor(choice) {
        const all = Words.pool(choice, root.lists, root.customWords)
        const fit = all.filter(p => Words.fitsLength(p.word, root.cfg.length))
        return fit.length > 0 ? fit : all
    }

    // a word that's still open when you ask for a new one counts as lost
    function newWord() {
        if (!gameStore.loaded) return
        // the word files are still being read: do it once they're in
        if (!root.listsReady) { root.wantWord = true; return }
        root.wantWord = false
        if (root.cfg.category === "custom") readCustom()
        const choice = root.cfg.category === "custom" && root.customWords.length === 0 ? "mixed" : root.cfg.category
        if (root.playing && Game.touched(root.game)) giveUp()
        const recent = root.stats.recent.map(r => r.word)
        const entry = Game.pick(wordsFor(choice), recent, Math.random)
        if (!entry) return
        autoNext.stop()
        gameStore.game = Game.start(entry, { lives: root.cfg.lives, hints: root.cfg.hints, reveal: root.cfg.reveal }, Date.now())
        gameStore.save()
    }

    function apply(next) {
        const before = root.game
        if (next === before) return
        gameStore.game = next
        if (next.wrong > before.wrong) root.lastMiss++
        else root.lastHit++
        if (next.status !== "playing") {
            gameStore.stats = Game.record(root.stats, next)
            if (root.cfg.autoNext) autoNext.restart()
        }
        gameStore.save()
    }

    function guess(letter) { if (root.game) apply(Game.guess(root.game, letter)) }
    function useHint() { if (root.game) apply(Game.hint(root.game, Math.random)) }
    readonly property bool hintReady: Game.canHint(root.game)

    function giveUp() {
        if (!root.playing) return
        const g = Game.revive(root.game)
        g.wrong = g.lives
        g.status = "lost"
        gameStore.game = g
        gameStore.stats = Game.record(root.stats, g)
        gameStore.save()
    }

    function resetStats() {
        gameStore.stats = Game.emptyStats()
        gameStore.save()
    }

    Timer { id: autoNext; interval: 1600; onTriggered: root.newWord() }

    // the built-in words for the chosen language: words/<language>/<category>-<language>.txt
    readonly property string wordsDir: decodeURIComponent(Qt.resolvedUrl("../words").toString().replace(/^file:\/\//, ""))
    property var lists: ({})
    property bool listsReady: false
    property bool wantWord: false
    property string listsLanguage: ""

    function readLists() {
        if (listsReader.running) { listsAgain = true; return }
        listsReader.lang = root.cfg.language
        listsReader.running = true
    }
    property bool listsAgain: false

    // one sh call prints every file of the language, each after a "@@ <category>" line
    Process {
        id: listsReader
        property string lang: "en"
        command: ["sh", "-c",
            'for f in "$1/$2"/*-"$2".txt; do [ -f "$f" ] || continue; '
            + 'printf "@@ %s\\n" "$(basename "$f" "-$2.txt")"; head -c 262144 "$f"; printf "\\n"; done',
            "sh", root.wordsDir, lang]
        stdout: StdioCollector {
            onStreamFinished: {
                const switched = root.listsLanguage !== "" && root.listsLanguage !== listsReader.lang
                root.lists = Words.parseBundle(text, listsReader.lang)
                root.listsLanguage = listsReader.lang
                root.listsReady = true
                // new language and nothing guessed yet: swap the word straight away.
                // your own words live in another file, that read does the swap instead,
                // unless the list is empty: then the game falls back to every list, which
                // is exactly what this read just replaced
                const customWords = root.cfg.category === "custom" && root.customWords.length > 0
                if (switched && !customWords && root.playing && !Game.touched(root.game))
                    Qt.callLater(root.newWord)
            }
        }
        onExited: if (root.listsAgain) { root.listsAgain = false; Qt.callLater(root.readLists) }
    }

    onListsReadyChanged: if (root.listsReady && (root.wantWord || (gameStore.loaded && root.game === null))) Qt.callLater(root.newWord)

    readonly property string wantedLanguage: cfg.language
    onWantedLanguageChanged: { readLists(); readCustom() }

    // new settings for lives/hints/reveal only change the next word
    readonly property string gameKey: cfg.category + "/" + cfg.length
    onGameKeyChanged: if (gameStore.loaded && root.playing && !Game.touched(root.game)) root.newWord()

    // your own words: ~/.config/hangman/words.txt, first 64 KB only
    readonly property string wordsPath: (Quickshell.env("XDG_CONFIG_HOME")
        || Quickshell.env("HOME") + "/.config") + "/hangman/words.txt"
    property var customWords: []

    // asked again while a read is still going (a quick language switch): read once more after it
    function readCustom() {
        if (wordsReader.running) { customAgain = true; return }
        wordsReader.running = true
    }
    property bool customAgain: false

    Process {
        id: wordsReader
        property string lang: ""
        command: ["head", "-c", "65536", root.wordsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                // a language keeps its own letters (ñ, ș, ä, ...), so the file is cleaned for the language in play now
                const switched = wordsReader.lang !== "" && wordsReader.lang !== root.cfg.language
                root.customWords = Words.parseCustom(text, root.cfg.language)
                wordsReader.lang = root.cfg.language
                // switched to your words, or switched language on your own words: swap the word, if untouched
                if (root.cfg.category === "custom" && root.customWords.length > 0 && root.playing
                        && !Game.touched(root.game) && (switched || root.game.category !== "custom"))
                    root.newWord()
            }
        }
        onExited: if (root.customAgain) { root.customAgain = false; Qt.callLater(root.readCustom) }
    }
    Component.onCompleted: { readCustom(); readLists() }

    // bar text
    readonly property string barLabel: {
        const c = root.cfg
        const g = root.game
        if (c.barDisplay === "word" && g && root.playing) return Game.masked(g)
        if (c.barDisplay === "lives" && g && root.playing)
            return "♥ " + (g.lives - g.wrong) + "/" + g.lives
        return c.barText.trim() !== "" ? c.barText : ux.t("game")
    }

    // ipc: omarchy-shell io.github.qempexe.hangman <function>
    IpcHandler {
        target: root.pluginId

        function play(): string { root.ui.tabRequested("play", false); return "ok" }
        function settings(): string { root.ui.tabRequested("settings", true); return "ok" }
        function next(): string { root.newWord(); return root.game ? Game.masked(root.game) : "no words" }
        function status(): string {
            const g = root.game
            return JSON.stringify({
                word: g ? Game.masked(g) : "",
                status: g ? g.status : "",
                lives: g ? g.lives - g.wrong : 0,
                played: root.stats.played,
                won: root.stats.won,
                streak: root.stats.streak
            })
        }
    }
}
