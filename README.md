# crossplatform-chess-game

A Flutter-based chess game that targets Android, iOS, desktop, and the web.

## Features

- Rich main menu with guided setup for player name, piece color, opponent type, and AI difficulty.
- Single-player mode with three computer difficulties powered by a lightweight chess engine.
- Local multiplayer mode for pass-and-play sessions on one device.
- Interactive chess board with coordinate overlays, move highlighting, and undo/reset controls.
- Toggleable top-down and 3D-inspired board rendering to suit your preferred perspective.
- Visual indicators while the AI is thinking so you always know when it's your turn.

## Getting started

1. Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.10 or higher) and Android Studio installed.
2. Connect an Android device such as a Pixel 9a with USB debugging enabled.
3. From the project root run:
   ```sh
   flutter pub get
   ```
4. Open the project in Android Studio (`File` → `Open` and choose this folder).
5. When the IDE finishes syncing, it will create a **MainActivity** run configuration automatically. Select your device and press **Run**.
   Android Studio will download any missing Gradle wrapper files on first use.

## Running from the command line

You can also run the game directly with Flutter tools:

```sh
flutter run
```

## Publishing to GitHub

To host this application in a new GitHub repository:

1. Create an empty repository from the [GitHub UI](https://github.com/new) (do **not** initialize it with a README or license).
2. In this project folder run:
   ```sh
   git remote add origin git@github.com:<your-account>/<your-repo>.git
   git branch -M main
   git push -u origin main
   ```
3. The repository will now contain the full Flutter project, ready for pull requests and CI workflows.

## Project structure

- `lib/` – Dart source code for the chess game.
- `android/` – Android project files including a Kotlin `MainActivity` used as the entry point when running on Android.

## Notes

The chess logic is implemented in `lib/models/chess_game.dart`. A bug was fixed to ensure listeners are notified whenever a move is made so the UI updates correctly.
