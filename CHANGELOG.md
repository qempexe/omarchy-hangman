# Changelog

All notable changes to Hangman. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-28

### Added

- **Spanish**: the fifteen word lists and the menus, with Ñ as a letter of its own.
  Thanks to [pwn27sbx](https://github.com/pwn27sbx).
- **German**: the fifteen word lists and the menus, Galgenmännchen.
- Letters a language has of its own are played as letters, with a key of their own:
  ñ in Spanish, ă â î ș ț in Romanian and ä ö ü ß in German. A word from another
  language keeps its letters playable when you switch mid-word.
- An **About** tab with the logo, the version and a link to more plugins, and the logo
  in the panel's header.
- A contributing guide and a code of conduct.

### Changed

- Romanian words keep their diacritics: `șarpe` is `ȘARPE`, no longer `SARPE`.
- **Menu language** is a row of chips, so all seven choices fit.
- The JavaScript is written in ES6: `const` and `let`, and arrow functions.
- The README follows a new layout, with new screenshots and preview.

### Fixed

- Switching language on your own words cleans them for the new language, also when
  you switch twice quickly.
- Switching language with an empty words file swaps the word straight away.

## [1.0.0] - 2026-10-15

### Added

- First release: hangman in the bar, with about 3,000 words in fifteen lists in
  English, French, Dutch and Romanian, menus in the same four languages, your own
  words, four drawings (gallows, balloons, snowman, hearts), hints, stats and streaks.

[1.1.0]: https://github.com/qempexe/omarchy-hangman/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/qempexe/omarchy-hangman/releases/tag/v1.0.0
