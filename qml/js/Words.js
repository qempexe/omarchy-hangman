.pragma library

// Everything about words: the categories, the languages, reading the word files,
// cleaning words up, and building the list a word is picked from.
//
// The words themselves live in the words/ folder, a folder per language and a file per category:
//   words/en/animals-en.txt, words/fr/animals-fr.txt, words/nl/animals-nl.txt, words/ro/animals-ro.txt, words/es/animals-es.txt, ...
// One word or phrase per line, # starts a comment.

var categories = [
    { key: "animals",   label: "Animals" },
    { key: "countries", label: "Countries" },
    { key: "cities",    label: "Cities" },
    { key: "food",      label: "Food" },
    { key: "nature",    label: "Nature" },
    { key: "home",      label: "Home" },
    { key: "jobs",      label: "Jobs" },
    { key: "sports",    label: "Sports" },
    { key: "music",     label: "Music" },
    { key: "science",   label: "Science" },
    { key: "space",     label: "Space" },
    { key: "tech",      label: "Computers" },
    { key: "transport", label: "Transport" },
    { key: "clothes",   label: "Clothes" },
    { key: "body",      label: "Body" }
];

var languages = [
    { key: "en", label: "English" },
    { key: "fr", label: "Français" },
    { key: "nl", label: "Nederlands" },
    { key: "ro", label: "Română" },
    { key: "es", label: "Español" }
];

var MAX_WORDS_PER_FILE = 5000;
var MAX_CUSTOM_WORDS = 2000;

// ---------- small helpers ----------

// anything -> text, without trusting what it is
function toText(value) {
    if (typeof value === "string") return value;
    if (typeof value === "number" || typeof value === "boolean") return "" + value;
    return "";
}

// the category keys: ["animals", "countries", ...]
var keys = [];
for (var k = 0; k < categories.length; k++) keys.push(categories[k].key);

function isCategory(key) {
    return keys.indexOf(key) !== -1;
}

// "animals" -> "Animals"
function labelOf(key) {
    if (key === "custom") return "Your words";
    for (var i = 0; i < categories.length; i++) {
        if (categories[i].key === key) return categories[i].label;
    }
    return "";
}

// ---------- cleaning words ----------

// Turns one line into a word we can play, or "" if it can't be one.
//   "  Brașov " -> "BRASOV"   (upper case, accents dropped)
//   "bœuf"      -> "BOEUF"    (œ, æ and ß written out)
//   "new york"  -> "NEW YORK"
//   "chute d’eau" -> "CHUTE D'EAU"   (apostrophes are kept, like spaces they're shown for free)
//   "abc1", "a/b", "x" -> ""   (only letters, spaces, hyphens and apostrophes, 2 to 30 long)
//   "año", "es"  -> "AÑO"      (Spanish keeps ñ as a letter of its own)
//   "año"        -> "ANO"      (any other language folds ñ to N, like an accent)
function clean(raw, lang) {
    var s = toText(raw);
    var spanish = lang === "es";

    // Spanish keeps ñ, so hold it aside as a placeholder while the accents come off.
    // a literal placeholder in the file is not a letter, so drop it first
    if (spanish) {
        if (s.normalize) s = s.normalize("NFC");   // an already decomposed ñ counts too
        s = s.replace(/[\uE000\uE001]/g, "");
        s = s.replace(/ñ/g, "\uE000").replace(/Ñ/g, "\uE000");
    }

    s = s.replace(/œ/g, "oe").replace(/Œ/g, "OE");
    s = s.replace(/æ/g, "ae").replace(/Æ/g, "AE");
    s = s.replace(/ß/g, "ss");
    s = s.replace(/ł/g, "l").replace(/Ł/g, "L").replace(/ø/g, "o").replace(/Ø/g, "O");
    s = s.replace(/[’‘`]/g, "'");   // every kind of apostrophe becomes the plain one

    // split letters from their accents, then drop the accents
    if (s.normalize) s = s.normalize("NFD").replace(/[̀-ͯ]/g, "");

    s = s.toUpperCase();
    s = s.replace(/\s+/g, " ").trim();   // one space between words

    // uppercase on the way in and out, so both ñ and Ñ come back as Ñ
    if (spanish) s = s.replace(/\uE000/g, "Ñ");

    if (s.length < 2 || s.length > 30) return "";
    var allowed = spanish ? /^[A-ZÑ][A-ZÑ '-]*[A-ZÑ]$/ : /^[A-Z][A-Z '-]*[A-Z]$/;
    if (!allowed.test(s)) return "";
    // no two marks in a row, like "--", "- " or "' "
    if (/[ '-]{2}/.test(s)) return "";
    return s;
}

// Reads a list: one word or phrase per line, everything after # is a comment.
// Bad lines and duplicates are skipped, and it stops at `max` words.
// `lang` is only used for ñ, see clean().
function parseList(text, max, lang) {
    var result = [];
    var seen = {};
    var lines = toText(text).split(/\r?\n/);

    for (var i = 0; i < lines.length; i++) {
        if (result.length >= max) break;

        var line = lines[i];
        var hash = line.indexOf("#");
        if (hash !== -1) line = line.substring(0, hash);

        var word = clean(line, lang);
        if (word !== "" && seen[word] !== true) {
            seen[word] = true;
            result.push(word);
        }
    }
    return result;
}

// your own words.txt
function parseCustom(text, lang) {
    return parseList(text, MAX_CUSTOM_WORDS, lang);
}

// The word files for one language come in as one block of text, each file
// starting with a line "@@ animals". This splits it back into lists:
//   { animals: ["AARDVARK", ...], countries: [...], ... }
// Unknown category names are ignored.
function parseBundle(text, lang) {
    var lists = {};
    var parts = toText(text).split(/^@@ /m);

    for (var i = 0; i < parts.length; i++) {
        var part = parts[i];
        var newline = part.indexOf("\n");
        if (newline === -1) continue;

        var name = part.substring(0, newline).trim();
        if (!isCategory(name)) continue;

        lists[name] = parseList(part.substring(newline + 1), MAX_WORDS_PER_FILE, lang);
    }
    return lists;
}

// ---------- building the list to pick from ----------

// Every word for a choice, as [{ word, category }].
//   "mixed"  -> every category
//   "custom" -> your own words
//   "food"   -> just that one (an unknown name gives everything)
// lists is what parseBundle() returned for the current language.
function pool(choice, lists, customWords) {
    var result = [];

    function addAll(categoryKey, words) {
        if (!words) return;
        for (var i = 0; i < words.length; i++) {
            result.push({ word: words[i], category: categoryKey });
        }
    }

    if (choice === "custom") {
        addAll("custom", customWords);
        return result;
    }

    if (choice !== "mixed" && isCategory(choice)) {
        addAll(choice, lists[choice]);
        return result;
    }

    for (var c = 0; c < keys.length; c++) addAll(keys[c], lists[keys[c]]);
    return result;
}

// letters only, spaces, hyphens and apostrophes don't count ("NEW YORK" -> 7).
// Ñ is a letter here too, so "AÑO" is 3.
function letterCount(word) {
    var count = 0;
    var w = toText(word);
    for (var i = 0; i < w.length; i++) {
        var c = w.charAt(i);
        if ((c >= "A" && c <= "Z") || c === "Ñ") count++;
    }
    return count;
}

// the "Word length" setting
function fitsLength(word, length) {
    var n = letterCount(word);
    if (length === "short") return n <= 6;
    if (length === "medium") return n >= 6 && n <= 9;
    if (length === "long") return n >= 9;
    return true;   // "any"
}
