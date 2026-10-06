# Keystona design kit — how to turn the storyboard into Flutter

Put this folder in the app repo as `design/`. Everything Claude Code needs to build a screen is here:

| Folder / file | What it is |
|---|---|
| `screens/sNN-…/NN-Name.png` | Every storyboard screen at 2× (390 pt wide = iPhone logical width), sorted by sprint and build order |
| `source/Name.dc.html` | The storyboard source: exact copy, colors, sizes, every state, and where each button goes (`href`) |
| `BUILD_ORDER.md` | 11 sprints, 107 commits, each tied to its screens |
| `Keystona_Implementation_Notes.md` | Behaviour a still screen can't show: long-press, Undo, offline, reminder rules, the report |
| `CLAUDE.md.snippet` | Paste into the repo's `CLAUDE.md` |

## The approach: translate, don't transpile

The HTML is a **spec, not code to convert**. A line-by-line HTML→Flutter conversion gives you nested `Container`s that nobody can maintain. Instead:

1. **Build the theme and widgets first (Sprint 0.4–0.5).** Have Claude Code read every file in `source/` and list the repeated patterns: top bar, pills, switch rows, sheets, chips, cards, the tab bar, snackbars. It should map them to `Keystona_Aurora_Component_Library.md`, then build them once in `lib/core/` with a widget-gallery screen and golden tests. After this, every screen is just these pieces put together.
2. **Then one commit at a time from `BUILD_ORDER.md`.** Each commit goes through the same loop:
   1. **UI on fake data.** Build the screen from `lib/core` widgets only, using a fake repository that returns the storyboard's mock home (1428 Elm Hollow Ln).
   2. **Golden test, then compare.** Look at the golden image next to the PNG and fix the differences. Claude Code can view both images.
   3. **Wire to real data.** Connect a Riverpod provider to Supabase through the repository, following the API Contract.
   4. **Check and commit.** Run `flutter analyze` and `flutter test`, check it in the iOS simulator, then commit with the message from `BUILD_ORDER.md`.
3. **What to take from the `.dc.html`:**
   - text, exactly as written
   - px values, which are Flutter logical pixels 1:1
   - colors, which must be token names, never hex in a screen
   - the states in `renderVals()`
   - every `href`, which becomes a route
4. **What to ignore:** the div and flex structure, `{{holes}}` syntax, and anything only there because it's a mockup (`hint-*` attributes, the `<dc-import>` used to draw a background behind a sheet).

## A prompt that works for one commit

```
Build commit 1.2b from design/BUILD_ORDER.md: camera scan.
Look at design/screens/s01-docs/04-DocCamera.png and read design/source/DocCamera.dc.html.
Rules: lib/core widgets and AppColors/AppText only; no hex values or new shared widgets
without asking me first. Fake repository with fixture data first, then a golden test.
Show me the golden next to the PNG before you wire Supabase.
Also check design/Keystona_Implementation_Notes.md for anything about this screen.
```

## iOS now, Android later: same code

Flutter builds both from one codebase, so there is no separate Android port. To keep Android cheap:

- **Font:** don't bundle SF Pro. Its license only covers Apple platforms. Use the platform system font, so iOS gets SF Pro and Android gets Roboto. The Home Health number's SF Pro Rounded needs an Android fallback.
- **Test both every sprint:** run the Android emulator once at the end of each sprint, not once at the end of the project.
- **Android-only items to plan for:**
  - the system back button and predictive back
  - Sign in with Apple through the web flow
  - Play Integrity instead of App Attest
  - notification channels
  - edge-to-edge insets
  - camera and file permissions
  - no Material ripple, since Aurora is a custom look

## Who does what

- **Claude in the Keystona project** (design chat): storyboard changes, specs, docs, reviewing simulator screenshots against the PNGs.
- **Claude Code in the repo:** the code, tests, simulator runs and commits. Your five domain agents line up with sprints 1–5. Work one commit at a time until Sprint 0 is merged and the widget library has settled, then run them in parallel on separate branches.
