.pragma library

// Everything about words: the categories, the languages, reading the word files,
// cleaning words up, and building the list a word is picked from.
//
// The words themselves live in the words/ folder, a folder per language and a file per category:
//   words/en/animals-en.txt, words/fr/animals-fr.txt, words/nl/animals-nl.txt, words/ro/animals-ro.txt, words/es/animals-es.txt, words/de/animals-de.txt, ...
// One word or phrase per line, # starts a comment.

const categories = [
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

const languages = [
    { key: "en", label: "English" },
    { key: "fr", label: "Français" },
    { key: "nl", label: "Nederlands" },
    { key: "ro", label: "Română" },
    { key: "es", label: "Español" },
    { key: "de", label: "Deutsch" }
];

const MAX_WORDS_PER_FILE = 5000;
const MAX_CUSTOM_WORDS = 2000;

// ---------- small helpers ----------

// anything -> text, without trusting what it is
function toText(value) {
    if (typeof value === "string") return value;
    if (typeof value === "number" || typeof value === "boolean") return "" + value;
    return "";
}

// the category keys: ["animals", "countries", ...]
const keys = [];
for (let k = 0; k < categories.length; k++) keys.push(categories[k].key);

function isCategory(key) {
    return keys.indexOf(key) !== -1;
}

// "animals" -> "Animals"
function labelOf(key) {
    if (key === "custom") return "Your words";
    for (let i = 0; i < categories.length; i++) {
        if (categories[i].key === key) return categories[i].label;
    }
    return "";
}

// ---------- letters ----------

// A to Z is every language's alphabet. Some languages have letters of their own on top,
// played as letters (with a key of their own) instead of losing their accent:
//   Spanish ñ, Romanian ă â î ș ț, German ä ö ü ß
const AZ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const alphabets = {
    es: "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ",
    ro: "AĂÂBCDEFGHIÎJKLMNOPQRSȘTȚUVWXYZ",
    de: AZ + "ÄÖÜẞ"
};
// every letter a word can have, whatever its language
const ALL_LETTERS = AZ + "ÑĂÂÎȘȚÄÖÜẞ";

// "ro" -> "AĂÂBCDEFGHIÎJ...", in the order of that language's alphabet
function alphabetOf(lang) {
    return alphabets[lang] || AZ;
}

// the letters a language adds to A to Z: "es" -> "Ñ", "en" -> ""
function ownLetters(lang) {
    return alphabetOf(lang).split("").filter(c => AZ.indexOf(c) === -1).join("");
}

function isLetter(c) {
    return typeof c === "string" && c.length === 1 && ALL_LETTERS.indexOf(c) !== -1;
}

// one typed letter in capitals. ß has no capital in toUpperCase() (it gives "SS"),
// so it becomes ẞ, the capital sharp s
function upperLetter(c) {
    const t = toText(c);
    if (t === "ß" || t === "ẞ") return "ẞ";
    return t.toUpperCase();
}

// ---------- cleaning words ----------

// Turns one line into a word we can play, or "" if it can't be one.
//   "  Brașov " -> "BRASOV"   (upper case, accents dropped)
//   "bœuf"      -> "BOEUF"    (œ, æ and ß written out)
//   "new york"  -> "NEW YORK"
//   "chute d’eau" -> "CHUTE D'EAU"   (apostrophes are kept, like spaces they're shown for free)
//   "abc1", "a/b", "x" -> ""   (only letters, spaces, hyphens and apostrophes, 2 to 30 long)
// A language keeps its own letters (see alphabets above):
//   "año", "es"     -> "AÑO"       but "año" in any other language -> "ANO"
//   "Brașov", "ro"  -> "BRAȘOV"    (an old ş with a cedilla counts as ș)
//   "Straße", "de"  -> "STRAẞE"    and "Käse", "de" -> "KÄSE"
function clean(raw, lang) {
    let s = toText(raw);
    if (s.normalize) s = s.normalize("NFC");   // an already decomposed ñ or ă counts too
    const own = ownLetters(lang);

    // Romanian was long written with ş and ţ (a cedilla), they're the same letters as ș and ț
    if (lang === "ro") s = s.replace(/ş/g, "ș").replace(/Ş/g, "Ș").replace(/ţ/g, "ț").replace(/Ţ/g, "Ț");

    // the language's own letters are held aside as placeholders while the accents come off.
    // a literal placeholder in the file is not a letter, so those go first
    s = s.replace(/[\uE000-\uE00F]/g, "");
    for (let i = 0; i < own.length; i++) {
        const upper = own.charAt(i);
        const lower = upper === "ẞ" ? "ß" : upper.toLowerCase();
        s = s.split(lower).join(String.fromCharCode(0xE000 + i)).split(upper).join(String.fromCharCode(0xE000 + i));
    }

    s = s.replace(/œ/g, "oe").replace(/Œ/g, "OE");
    s = s.replace(/æ/g, "ae").replace(/Æ/g, "AE");
    s = s.replace(/ß/g, "ss").replace(/ẞ/g, "SS");
    s = s.replace(/ł/g, "l").replace(/Ł/g, "L").replace(/ø/g, "o").replace(/Ø/g, "O");
    s = s.replace(/[’‘`]/g, "'");   // every kind of apostrophe becomes the plain one

    // split letters from their accents, then drop the accents
    if (s.normalize) s = s.normalize("NFD").replace(/[\u0300-\u036f]/g, "");

    s = s.toUpperCase();
    s = s.replace(/\s+/g, " ").trim();   // one space between words

    // and the language's own letters come back, in capitals
    for (let i = 0; i < own.length; i++) s = s.split(String.fromCharCode(0xE000 + i)).join(own.charAt(i));

    if (s.length < 2 || s.length > 30) return "";
    // only the language's letters, with spaces, hyphens or apostrophes inside
    const letters = alphabetOf(lang);
    for (let i = 0; i < s.length; i++) {
        const c = s.charAt(i);
        const inside = i > 0 && i < s.length - 1;
        if (letters.indexOf(c) === -1 && !(inside && " '-".indexOf(c) !== -1)) return "";
    }
    // no two marks in a row, like "--", "- " or "' "
    if (/[ '-]{2}/.test(s)) return "";
    return s;
}

// Reads a list: one word or phrase per line, everything after # is a comment.
// Bad lines and duplicates are skipped, and it stops at `max` words.
// `lang` decides which letters are kept, see clean().
function parseList(text, max, lang) {
    const result = [];
    const seen = {};
    const lines = toText(text).split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
        if (result.length >= max) break;

        let line = lines[i];
        const hash = line.indexOf("#");
        if (hash !== -1) line = line.substring(0, hash);

        const word = clean(line, lang);
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
    const lists = {};
    const parts = toText(text).split(/^@@ /m);

    for (const part of parts) {
        const newline = part.indexOf("\n");
        if (newline === -1) continue;

        const name = part.substring(0, newline).trim();
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
    const result = [];

    function addAll(categoryKey, words) {
        if (!words) return;
        for (let i = 0; i < words.length; i++) {
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

    for (let c = 0; c < keys.length; c++) addAll(keys[c], lists[keys[c]]);
    return result;
}

// letters only, spaces, hyphens and apostrophes don't count ("NEW YORK" -> 7, "AÑO" -> 3)
function letterCount(word) {
    return toText(word).split("").filter(isLetter).length;
}

// the "Word length" setting
function fitsLength(word, length) {
    const n = letterCount(word);
    if (length === "short") return n <= 6;
    if (length === "medium") return n >= 6 && n <= 9;
    if (length === "long") return n >= 9;
    return true;   // "any"
}

// ---------- the letters on screen ----------

// The keys to show, as rows. The language's letters, plus any letter of the word in play
// that it doesn't have (switching language mid-word must never make a word unwinnable).
//   "abc"    -> the alphabet in order, in rows of up to 10
//   "qwerty" -> the usual three rows, Ñ at the end of the middle one like on a Spanish
//               keyboard, other letters of a language's own in a row underneath
function keyRows(layout, lang, word) {
    let letters = alphabetOf(lang);
    const w = toText(word);
    for (let i = 0; i < w.length; i++) {
        const c = w.charAt(i);
        if (isLetter(c) && letters.indexOf(c) === -1) letters += c;
    }

    if (layout === "abc") {
        const count = Math.ceil(letters.length / 10);
        const per = Math.ceil(letters.length / count);
        const rows = [];
        for (let i = 0; i < letters.length; i += per) rows.push(letters.substring(i, i + per));
        return rows;
    }

    const extra = letters.split("").filter(c => AZ.indexOf(c) === -1).join("");
    if (extra === "") return ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    if (extra === "Ñ") return ["QWERTYUIOP", "ASDFGHJKLÑ", "ZXCVBNM"];
    return ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM", extra];
}
