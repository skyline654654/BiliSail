# analysis-env

A minimal dependency set used only for type-checking the adaptation files.

The app pubspec pins media-kit to git forks; resolving it needs git-over-https to
github.com. The adaptation layer (create flow, ads, immersive theme, harmony
bridge, bottom bar, theme, shell wiring) does not import media-kit, so this package
declares just `flutter`, `flutter_riverpod`, `file_selector`, `path` and the local
`bili_api` package. `verify/analyze-app.mjs` resolves it and hands the resulting
package config to the repo analyzer.

Nothing here ships with the app.
