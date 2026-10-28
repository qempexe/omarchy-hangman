# Adding words, a language or a drawing

Hangman is mostly lists: the words are plain text files, every text in the panel
is one line in `qml/js/Lang.js`, and each language is a key in a handful of lists.
Most changes never touch the panel itself.

## Words

Every list is a file in `words/`, a folder per language and a file per category:

```
words/
├── en/   animals-en.txt, body-en.txt, cities-en.txt, ...
├── fr/   animals-fr.txt, ...
├── nl/   ...
├── ro/
├── es/
└── de/
```

One word or phrase a line, `#` starts a comment. The lists line up across
languages: line 12 of `animals-en.txt` is the same animal as line 12 of
`animals-de.txt`, so switching language gives you the same game in other words.
When you add a word, add it to the same place in every language. When you fix a
translation, change only that one line.

- Letters, spaces, hyphens and apostrophes only, 2 to 30 long.
- No two lines in a file that end up as the same word (`año` and `ano` are two
  words in Spanish, one everywhere else).
- Write words the way the language writes them, accents and all. Hangman drops
  the accents itself, and keeps the letters a language has of its own (below).

## A language

A language is added in these places:

1. `words/<key>/`: the 15 lists, named `<category>-<key>.txt`, lined up with the
   English ones.
2. `languages` in `qml/js/Words.js`: the key and the name in its own language
   (`{ key: "de", label: "Deutsch" }`).
3. `options` and `labels` of both **Words in** and **Menu language** in
   `qml/js/Schema.js`.
4. `languages` in `qml/js/Lang.js`, and a `texts.<key>` block with every text in
   `texts.en`. Keep the `{0}` and `{1}` where the English one has them.
5. If the language has letters of its own, its alphabet in `alphabets` in
   `qml/js/Words.js`, in the language's own order, and the new letters in
   `ALL_LETTERS`. Those letters keep their accent and get a key of their own;
   everything else folds to A to Z.

A letter whose capital `toUpperCase()` gets wrong (ß gives `SS`) needs a line in
`upperLetter()` too.

## A drawing

The drawings are in `qml/panel/Figure.qml`, one `draw...(ctx)` function each.
`lost` goes from 0 (no misses) to 1 (out of lives) and moves smoothly, so draw
every part from it and the parts grow in by themselves. Use `ink`, `accent` and
`bad` for the colors, so it follows the theme. Then add the key to `figures` in
`qml/js/Schema.js`, its name to `opt.figure.<key>` in every language, and a call
in `onPaint`. The settings tile draws itself with the same function.

## Rules

- ES6 JavaScript: `const` and `let`, and arrow functions for callbacks.
- No network, and no new commands: the plugin only runs `sh` and `head` (reading
  the word files, making its state folder) and `xdg-open` for the link in About.
- Anything read from a file is checked before it's used: words through `clean()`,
  settings through `Schema.clean()`, the saved game through `Game.revive()`.

## Tests

```bash
node tests/test_game.js
```

They need nothing but node. They read every word file and check every line in it
is a usable word, and that every language has every text.
