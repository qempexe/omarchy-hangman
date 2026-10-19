.pragma library
.import "Words.js" as Words

// Game logic for hangman. No QML in here, just plain functions.
//
// A game is an object like this:
//   {
//     word: "BRUGES",       the word to guess (upper case)
//     category: "cities",   which list it came from
//     guessed: "BUX",       every letter tried so far, in order
//     given: "",            the letter we got for free at the start (or "")
//     wrong: 1,             lives used up
//     lives: 6,             lives at the start
//     hints: 0,             hints used
//     maxHints: 1,          hints allowed
//     status: "playing",    "playing", "won" or "lost"
//     started: 0            when it started (ms)
//   }
//
// The functions never change the game you give them. They make a copy and
// return that, so the QML side always sees a new object and updates.

var ALPHABET = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ";
var MAX_RECENT = 30;

// ---------- small helpers ----------

function isLetter(c) {
    if (typeof c !== "string" || c.length !== 1) return false;
    return ALPHABET.indexOf(c) !== -1;
}

// anything -> text, without trusting what it is
function toText(value) {
    if (typeof value === "string") return value;
    if (typeof value === "number" || typeof value === "boolean") return "" + value;
    return "";
}

// turns a number, or text like "12", into a whole number between min and max.
// anything else (objects, "abc", "1e999") gives the fallback
function toInt(value, min, max, fallback) {
    var n = fallback;
    if (typeof value === "number") n = value;
    else if (typeof value === "string" && /^-?[0-9]{1,15}(\.[0-9]+)?$/.test(value)) n = parseFloat(value);
    if (!isFinite(n)) return fallback;
    n = Math.round(n);
    if (n < min) return min;
    if (n > max) return max;
    return n;
}

// a word we can play: capital letters, maybe spaces, hyphens or apostrophes inside, max 30 long.
// Ñ counts as a letter here, but only Spanish words are cleaned with it kept
function isValidWord(word) {
    return /^[A-ZÑ][A-ZÑ '-]{0,28}[A-ZÑ]$/.test(word);
}

// only the categories we know, so a hand-edited file can't sneak in odd keys
function isValidCategory(name) {
    return name === "custom" || Words.keys.indexOf(name) !== -1;
}

// every category stats can be kept for
function statsCategories() {
    return Words.keys.concat(["custom"]);
}

function copyGame(game) {
    return {
        word: game.word,
        category: game.category,
        guessed: game.guessed,
        given: game.given,
        wrong: game.wrong,
        lives: game.lives,
        hints: game.hints,
        maxHints: game.maxHints,
        status: game.status,
        started: game.started
    };
}

// every different letter in the word, once ("BRUGES" -> "BRUGES", "APPLE" -> "APLE")
function letters(word) {
    var result = "";
    for (var i = 0; i < word.length; i++) {
        var c = word.charAt(i);
        if (isLetter(c) && result.indexOf(c) === -1) result += c;
    }
    return result;
}

// ---------- starting a game ----------

// Picks a random entry from the list. Words played recently are skipped,
// unless every word was played recently (then anything goes).
// random is a function that returns 0..1 (Math.random, or a fake one in tests)
function pick(list, recent, random) {
    if (!list || list.length === 0) return null;
    if (!random) random = Math.random;
    if (!recent) recent = [];

    var fresh = [];
    for (var i = 0; i < list.length; i++) {
        if (recent.indexOf(list[i].word) === -1) fresh.push(list[i]);
    }
    var choices = fresh.length > 0 ? fresh : list;

    var index = Math.floor(random() * choices.length);
    if (index >= choices.length) index = choices.length - 1;
    return choices[index];
}

// entry: { word, category }
// options: { lives, hints, reveal }   reveal = get the first letter for free
function start(entry, options, now) {
    if (!options) options = {};

    var game = {
        word: entry.word,
        category: entry.category,
        guessed: "",
        given: "",
        wrong: 0,
        lives: toInt(options.lives || 6, 1, 12, 6),
        hints: 0,
        maxHints: toInt(options.hints || 0, 0, 5, 0),
        status: "playing",
        started: now || 0
    };

    if (options.reveal) {
        var first = entry.word.charAt(0);
        if (isLetter(first)) {
            game.guessed = first;
            game.given = first;
        }
    }
    return updateStatus(game);
}

// ---------- playing ----------

// true when every letter of the word has been guessed
function solved(game) {
    var needed = letters(game.word);
    for (var i = 0; i < needed.length; i++) {
        if (game.guessed.indexOf(needed.charAt(i)) === -1) return false;
    }
    return true;
}

// won, lost or still going?
function updateStatus(game) {
    if (game.status !== "playing") return game;
    if (solved(game)) game.status = "won";
    else if (game.wrong >= game.lives) game.status = "lost";
    return game;
}

// did the player try anything yet? (the free letter doesn't count)
function touched(game) {
    if (!game) return false;
    return game.guessed.length > game.given.length;
}

// Try one letter. If it does nothing (game over, not a letter, already tried)
// the same game comes back.
function guess(game, letter) {
    var c = toText(letter).toUpperCase();
    if (!game || game.status !== "playing") return game;
    if (!isLetter(c)) return game;
    if (game.guessed.indexOf(c) !== -1) return game;

    var next = copyGame(game);
    next.guessed = game.guessed + c;
    if (game.word.indexOf(c) === -1) next.wrong = game.wrong + 1;
    return updateStatus(next);
}

// A hint costs a life, so it's only allowed if it won't use the last one
function canHint(game) {
    if (!game || game.status !== "playing") return false;
    if (game.hints >= game.maxHints) return false;
    return game.wrong + 1 < game.lives;
}

// Shows one random letter that's still hidden
function hint(game, random) {
    if (!canHint(game)) return game;
    if (!random) random = Math.random;

    var all = letters(game.word);
    var hidden = [];
    for (var i = 0; i < all.length; i++) {
        if (game.guessed.indexOf(all.charAt(i)) === -1) hidden.push(all.charAt(i));
    }
    if (hidden.length === 0) return game;

    var index = Math.floor(random() * hidden.length);
    if (index >= hidden.length) index = hidden.length - 1;

    var next = copyGame(game);
    next.guessed = game.guessed + hidden[index];
    next.hints = game.hints + 1;
    next.wrong = game.wrong + 1;
    return updateStatus(next);
}

// ---------- showing the word ----------

// one object per character: { ch: "B", letter: true, shown: false }
function cells(game) {
    var result = [];
    if (!game) return result;
    for (var i = 0; i < game.word.length; i++) {
        var c = game.word.charAt(i);
        var letter = isLetter(c);
        result.push({
            ch: c,
            letter: letter,
            // spaces, hyphens and apostrophes are always shown
            shown: !letter || game.guessed.indexOf(c) !== -1
        });
    }
    return result;
}

// the word for the bar: "B _ U _ _ S", two spaces between words
function masked(game) {
    var parts = [];
    var list = cells(game);
    for (var i = 0; i < list.length; i++) {
        if (list[i].ch === " ") parts.push(" ");
        else if (list[i].shown) parts.push(list[i].ch);
        else parts.push("_");
    }
    return parts.join(" ").replace(/   /g, "  ");
}

// how a key on the keyboard looks: "hit", "miss", or "" if not tried yet
function state(game, letter) {
    if (!game || game.guessed.indexOf(letter) === -1) return "";
    if (game.word.indexOf(letter) !== -1) return "hit";
    return "miss";
}

// ---------- loading a saved game ----------

// game.json could be edited by hand, so nothing is trusted.
// Returns a clean game, or null if it doesn't look like one.
function revive(saved) {
    if (!saved || typeof saved !== "object") return null;

    var word = toText(saved.word);
    if (!isValidWord(word)) return null;

    // keep only real letters, each once
    var guessed = "";
    var raw = toText(saved.guessed);
    for (var i = 0; i < raw.length && i < ALPHABET.length; i++) {
        var c = raw.charAt(i);
        if (isLetter(c) && guessed.indexOf(c) === -1) guessed += c;
    }

    var given = toText(saved.given);
    if (!isLetter(given) || guessed.indexOf(given) === -1) given = "";

    var game = {
        word: word,
        category: isValidCategory(toText(saved.category)) ? toText(saved.category) : "",
        guessed: guessed,
        given: given,
        wrong: 0,
        lives: toInt(saved.lives, 1, 12, 6),
        hints: toInt(saved.hints, 0, 5, 0),
        maxHints: toInt(saved.maxHints, 0, 5, 0),
        status: "playing",
        started: toInt(saved.started, 0, 1e15, 0)
    };

    // count the misses ourselves instead of trusting the file,
    // and every hint used costs a life too
    var misses = 0;
    for (var j = 0; j < guessed.length; j++) {
        if (word.indexOf(guessed.charAt(j)) === -1) misses++;
    }
    game.wrong = Math.min(game.lives, misses + game.hints);

    return updateStatus(game);
}

// ---------- stats ----------

function emptyStats() {
    return {
        played: 0,
        won: 0,
        streak: 0,       // wins in a row right now
        best: 0,         // longest streak ever
        perfect: 0,      // won without a single miss
        byCategory: {},  // "animals": { played, won }
        recent: []       // last words, newest first: { word, won, wrong, category }
    };
}

// same idea as revive(): clean up whatever came from the file
function reviveStats(saved) {
    var stats = emptyStats();
    if (!saved || typeof saved !== "object") return stats;

    stats.played = toInt(saved.played, 0, 1e9, 0);
    stats.won = Math.min(toInt(saved.won, 0, 1e9, 0), stats.played);
    stats.streak = toInt(saved.streak, 0, 1e9, 0);
    stats.best = Math.max(toInt(saved.best, 0, 1e9, 0), stats.streak);
    stats.perfect = Math.min(toInt(saved.perfect, 0, 1e9, 0), stats.won);

    // walk our own category list, not the keys in the file
    var cats = saved.byCategory;
    if (cats && typeof cats === "object") {
        var names = statsCategories();
        for (var i = 0; i < names.length; i++) {
            var c = cats[names[i]];
            if (!c || typeof c !== "object") continue;
            var played = toInt(c.played, 0, 1e9, 0);
            stats.byCategory[names[i]] = { played: played, won: Math.min(toInt(c.won, 0, 1e9, 0), played) };
        }
    }

    var recent = Array.isArray(saved.recent) ? saved.recent.slice(0, MAX_RECENT) : [];
    for (var j = 0; j < recent.length; j++) {
        var r = recent[j] || {};
        var word = toText(r.word);
        if (!isValidWord(word)) continue;
        stats.recent.push({
            word: word,
            won: r.won === true,
            wrong: toInt(r.wrong, 0, 12, 0),
            category: isValidCategory(toText(r.category)) ? toText(r.category) : ""
        });
    }
    return stats;
}

// Adds a finished game to the stats and returns the new stats.
// Unfinished games don't change anything.
function record(stats, game) {
    var next = reviveStats(JSON.parse(JSON.stringify(stats)));
    if (!game) return next;
    if (game.status !== "won" && game.status !== "lost") return next;

    var won = game.status === "won";
    next.played++;
    if (won) {
        next.won++;
        next.streak++;
        if (game.wrong === 0) next.perfect++;
    } else {
        next.streak = 0;
    }
    if (next.streak > next.best) next.best = next.streak;

    var category = isValidCategory(game.category) ? game.category : "";
    if (category !== "") {
        var old = next.byCategory[category] || { played: 0, won: 0 };
        next.byCategory[category] = {
            played: old.played + 1,
            won: old.won + (won ? 1 : 0)
        };
    }

    next.recent.unshift({ word: game.word, won: won, wrong: game.wrong, category: category });
    if (next.recent.length > MAX_RECENT) next.recent = next.recent.slice(0, MAX_RECENT);
    return next;
}
