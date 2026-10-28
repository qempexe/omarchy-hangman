.pragma library
.import "Words.js" as Words

// Every setting the plugin has. The settings tab builds its rows from `groups`,
// and resolve() at the bottom turns settings.json into a full, checked config.
//
//   kind: enum (pick one), int (number), bool (on/off), string (text), palette (3 colors)
//   when: the row is greyed out unless these other settings have these values

// custom color swatches: backgrounds, text colors, accents
const swatches = [
  "#141414", "#1d1510", "#1a1b26", "#282a36", "#2e3440", "#2d353b", "#1f1f28", "#3b2a1f",
  "#e0e0e0", "#eadbc8", "#ffffff", "#c0caf5", "#d8dee9", "#dcd7ba", "#f8f8f2", "#e0def4",
  "#d4a35a", "#c8925a", "#7aa2f7", "#cba6f7", "#a7c080", "#88c0d0", "#fabd2f", "#ff6a1f"
];

// "Words from": everything, each built-in list, then your own words
const categoryOptions = ["mixed"];
const categoryLabels = { mixed: "Everything", custom: "Your words" };
for (let c = 0; c < Words.categories.length; c++) {
    categoryOptions.push(Words.categories[c].key);
    categoryLabels[Words.categories[c].key] = Words.categories[c].label;
}
categoryOptions.push("custom");

const figures = ["gallows", "balloons", "snowman", "hearts"];

const groups = [
  {
    title: "Game",
    items: [
      { key: "language", label: "Words in", kind: "enum", fallback: "en", control: "seg",
        options: ["en", "fr", "nl", "ro", "es", "de"],
        labels: { en: "English", fr: "Français", nl: "Nederlands", ro: "Română", es: "Español", de: "Deutsch" },
        hint: "Which language the words are in. Accents are left out, so é is just E, but Spanish ñ, Romanian ă â î ș ț and German ä ö ü ß are letters with a key of their own." },
      { key: "uiLanguage", label: "Menu language", kind: "enum", fallback: "auto", control: "chips",
        options: ["auto", "en", "fr", "nl", "ro", "es", "de"],
        labels: { auto: "Same as words", en: "English", fr: "Français", nl: "Nederlands", ro: "Română", es: "Español", de: "Deutsch" },
        hint: "The language of everything in this panel. Same as the words, or one of its own." },
      { key: "category", label: "Words from", kind: "enum", fallback: "mixed", control: "chips",
        options: categoryOptions, labels: categoryLabels,
        hint: "Everything mixes all the lists of your language. Your words reads ~/.config/hangman/words.txt, one word or phrase a line, in any language." },
      { key: "length", label: "Word length", kind: "enum", fallback: "any", control: "seg",
        options: ["any", "short", "medium", "long"],
        labels: { any: "Any", short: "Short", medium: "Medium", long: "Long" },
        hint: "Short is up to 6 letters, medium 6 to 9, long 9 and more." },
      { key: "lives", label: "Lives", kind: "int", fallback: 6, min: 3, max: 10, step: 1,
        hint: "Wrong letters you can afford. 6 is the classic game." },
      { key: "hints", label: "Hints per word", kind: "int", fallback: 1, min: 0, max: 3, step: 1,
        hint: "A hint shows one hidden letter and costs a life. It never takes your last one." },
      { key: "reveal", label: "Start with a letter", kind: "bool", fallback: false,
        hint: "The first letter of every word is already filled in." },
      { key: "showCategory", label: "Category clue", kind: "bool", fallback: true,
        hint: "Show which list the word comes from above it." },
      { key: "autoNext", label: "Next word right away", kind: "bool", fallback: false,
        hint: "Start a new word a moment after you finish one. Off waits for Enter or New word." }
    ]
  },
  {
    title: "Look",
    items: [
      { key: "figure", label: "Drawing", kind: "enum", fallback: "gallows", control: "tiles",
        options: figures,
        labels: { gallows: "Gallows", balloons: "Balloons", snowman: "Snowman", hearts: "Hearts" },
        hint: "What fills up (or falls apart) with every wrong letter." },
      { key: "keyboard", label: "Letters on screen", kind: "enum", fallback: "qwerty", control: "seg",
        options: ["qwerty", "abc", "off"],
        labels: { qwerty: "QWERTY", abc: "A to Z", off: "Hidden" },
        hint: "The clickable letters under the word. Typing always works." },
      { key: "colorMode", label: "Colors", kind: "enum", fallback: "theme", control: "scheme",
        options: ["theme", "custom", "monochrome"],
        labels: { theme: "Follow theme", custom: "Custom", monochrome: "Monochrome" },
        hint: "Follow theme matches your Omarchy theme live. Custom lets you choose the background, text and accent. Monochrome removes every hue." },
      { key: "customColors", label: "Custom colors", kind: "palette",
        fallback: { customBg: "#141414", customFg: "#e0e0e0", accentColor: "#ff6a1f" },
        targets: [{ key: "customBg", label: "Background" }, { key: "customFg", label: "Text" }, { key: "accentColor", label: "Accent" }],
        presets: swatches,
        hint: "Choose Background, Text or Accent, then pick a swatch or type a hex.",
        when: [{ key: "colorMode", is: ["custom"] }] },
      { key: "density", label: "Spacing", kind: "enum", fallback: "comfortable", control: "tiles",
        options: ["compact", "comfortable", "spacious"],
        labels: { compact: "Compact", comfortable: "Comfortable", spacious: "Spacious" },
        hint: "How much air there is between things." },
      { key: "cornerRadius", label: "Roundness", kind: "int", fallback: 6, min: 0, max: 20, step: 2,
        hint: "0 is square, 20 is very round." },
      { key: "frame", label: "Window outline", kind: "bool", fallback: false,
        hint: "Draw the edge in the accent color instead of a plain neutral line." },
      { key: "fontScale", label: "Text size", kind: "int", fallback: 100, min: 80, max: 150, step: 5, divisor: 100, decimals: 2,
        hint: "1 is normal, 1.25 is a quarter bigger." },
      { key: "surfaceTint", label: "Window tint", kind: "int", fallback: 0, min: 0, max: 30, step: 1,
        hint: "How much of the accent color washes over the background. 0 keeps it plain." },
      { key: "opacity", label: "Opacity", kind: "int", fallback: 96, min: 50, max: 100, step: 2,
        hint: "Background of the panel." },
      { key: "speed", label: "Animation speed", kind: "int", fallback: 220, min: 0, max: 600, step: 20,
        hint: "Milliseconds the drawing and the letters take to move. 0 turns animations off." }
    ]
  },
  {
    title: "Panel",
    items: [
      { key: "windowWidth", label: "Panel width", kind: "int", fallback: 560, min: 440, max: 1200, step: 20,
        hint: "How wide the panel opens." },
      { key: "windowHeight", label: "Panel height", kind: "int", fallback: 660, min: 480, max: 1000, step: 20,
        hint: "How tall the panel opens." },
      { key: "openAs", label: "Open as", kind: "enum", fallback: "panel", control: "tiles",
        options: ["panel", "window"],
        labels: { panel: "Bar panel", window: "Own window" },
        hint: "Where the bar button opens the game. You can always pop it out or dock it back from the header." },
      { key: "barDisplay", label: "Bar button shows", kind: "enum", fallback: "text", control: "seg",
        options: ["text", "word", "lives"],
        labels: { text: "Text", word: "The word", lives: "Lives left" },
        hint: "The word shows your progress (B _ _ G E S) while you play, lives shows the hearts left." },
      { key: "barText", label: "Bar button text", kind: "string", fallback: "Hangman", maxLength: 12,
        presets: ["Hangman", "Words", "Guess"],
        hint: "Used for the text, and when there is no word in play." },
      { key: "middleClick", label: "Middle click", kind: "enum", fallback: "newword", control: "seg",
        options: ["newword", "none"],
        labels: { newword: "New word", none: "Nothing" },
        hint: "What clicking the bar button with the middle mouse button does." }
    ]
  }
];

// ---------- defaults and lookups, worked out once from the groups above ----------

// The color picker row saves three keys (customBg, customFg, accentColor)
// instead of its own key, so those get remembered separately.
const colorKeys = {};
const defaults = {};
const itemByKey = {};

for (let g = 0; g < groups.length; g++) {
  const items = groups[g].items;

  for (const item of items) {
    itemByKey[item.key] = item;
    if (item.kind === "palette") {
        for (let t = 0; t < item.targets.length; t++) {
            const colorKey = item.targets[t].key;
            defaults[colorKey] = item.fallback[colorKey];
            colorKeys[colorKey] = item.fallback[colorKey];
        }
    } else {
        defaults[item.key] = item.fallback;
    }
  }
}

// every key settings.json can hold (the palette row counts as its three colors)
const settingKeys = [];
for (const name in defaults) settingKeys.push(name);

function isSetting(key) {
    return settingKeys.indexOf(key) !== -1;
}

// the setting for a key, or null. Only real settings count:
// itemByKey["constructor"] is a function, not one of our items
function itemFor(key) {
    const item = itemByKey[key];
    if (item && typeof item === "object" && item.key === key) return item;
    return null;
}

// a number from a number or from text like "12", NaN for anything else
function parseNum(value) {
    if (typeof value === "number") return value;
    if (typeof value === "string" && /^-?[0-9]{1,15}(\.[0-9]+)?$/.test(value)) return parseFloat(value);
    return NaN;
}

// "#abc" or "#aabbcc"
function validHex(s) {
    return typeof s === "string" && /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(s);
}

// Checks one value against its setting. Anything weird gives the default back,
// so a hand-edited settings.json can't break the plugin.
// Unknown keys give undefined.
function clean(key, value) {
    if (typeof colorKeys[key] === "string") {
        if (validHex(value)) return value.toLowerCase();
        return colorKeys[key];
    }
    const item = itemFor(key);
    if (item === null) return undefined;
    if (value === null || value === undefined) return item.fallback;

    if (item.kind === "enum") {
        if (item.options.indexOf(Words.toText(value)) !== -1) return Words.toText(value);
        return item.fallback;
    }

    if (item.kind === "int") {
        let n = parseNum(value);
        if (!isFinite(n)) return item.fallback;
        n = Math.round(n);
        if (n < item.min) return item.min;
        if (n > item.max) return item.max;
        return n;
    }

    if (item.kind === "bool") {
        if (value === true || value === "true") return true;
        if (value === false || value === "false") return false;
        return item.fallback;
    }

    // text: no control characters and no < >, so it always shows as plain text,
    // and not longer than allowed
    let text = Words.toText(value).replace(/[\u0000-\u001f\u007f<>]/g, "");
    if (item.maxLength) text = text.slice(0, item.maxLength);
    return text;
}

// The whole saved file -> every setting, checked, with defaults filled in
function resolve(saved) {
    if (!saved) saved = {};
    const result = {};
    // only our own keys are read from the file
    for (const key in defaults) {
        let value = typeof saved === "object" ? saved[key] : undefined;
        if (typeof value === "function") value = undefined;
        result[key] = clean(key, value);
    }
    return result;
}
