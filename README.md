# Strava Activity Heatmap Widget

A home screen widget for **Android** and **iOS** that displays your Strava workout activity as a GitHub-style contribution heatmap. Shows a 13-week grid colored from gray to orange based on daily workout duration.

![widget](https://github.com/user-attachments/assets/fb992f5d-5261-4891-a9e6-50224aaacf17)

## Features

- 13x7 grid showing 13 weeks of activity (91 days)
- Color intensity based on total daily workout duration
- Automatic background sync with Strava
- Secure OAuth authentication
- Works offline with cached data

## Activity Levels

| Level | Duration | Color |
|-------|----------|-------|
| 0 | No activity | Gray (#2D2D2D) |
| 1 | 1-29 min | Light brown (#5C3D1E) |
| 2 | 30-59 min | Brown (#8B5A2B) |
| 3 | 60-89 min | Chocolate (#D2691E) |
| 4 | 90+ min | Orange (#FF8C00) |

---

## Strava API Setup (Required for Both Platforms)

1. Go to [Strava API Settings](https://www.strava.com/settings/api)
2. Create a new application
3. Set the **Authorization Callback Domain** to `localhost`
4. Note your **Client ID** and **Client Secret**

---

## Android

### Requirements
- Android Studio
- Android SDK 26+ (Android 8.0)
- Kotlin

### Setup

1. Navigate to the Android project:
   ```bash
   cd android
   ```

2. Copy the example properties file:
   ```bash
   cp local.properties.example local.properties
   ```

3. Edit `local.properties` and add your Strava credentials:
   ```properties
   STRAVA_CLIENT_ID=your_client_id
   STRAVA_CLIENT_SECRET=your_client_secret
   ```

### Build

```bash
cd android

# Build debug APK
./gradlew assembleDebug

# Install on connected device
./gradlew installDebug

# Run tests
./gradlew test
```

The APK will be at `android/app/build/outputs/apk/debug/app-debug.apk`

---

## iOS

### Requirements
- Xcode 15+
- iOS 17+
- Swift 5.9+

### Setup

1. Open the Xcode project:
   ```bash
   open ios/StravaWidget.xcodeproj
   ```

2. Edit `ios/StravaWidget/Secrets.swift` with your Strava credentials:
   ```swift
   enum Secrets {
       static let stravaClientID = "your_client_id"
       static let stravaClientSecret = "your_client_secret"
   }
   ```

3. In Xcode:
   - Select your development team for both targets (StravaWidget and StravaWidgetExtension)
   - Enable the **App Groups** capability for both targets with `group.com.stravawidget`

### Build

1. Select your target device or simulator
2. Press `Cmd+R` to build and run

---

## Project Structure

```
strava-github-dashboard/
├── android/                    # Android app
│   ├── app/
│   │   └── src/main/
│   │       ├── java/com/stravawidget/
│   │       │   ├── api/        # Strava API client
│   │       │   ├── data/       # Repository, storage
│   │       │   └── widget/     # Widget provider, sync
│   │       └── res/            # Layouts, drawables
│   ├── build.gradle.kts
│   └── local.properties        # API credentials (gitignored)
│
├── ios/                        # iOS app
│   ├── StravaWidget/           # Main app target
│   │   ├── Auth/               # OAuth authentication
│   │   ├── API/                # Strava API client
│   │   ├── Data/               # Repository, storage
│   │   └── Secrets.swift       # API credentials (gitignored)
│   ├── StravaWidgetExtension/  # Widget extension
│   └── Shared/                 # Shared code
│
├── CLAUDE.md                   # AI assistant instructions
└── README.md                   # This file
```

---

## How It Works

1. **Authentication**: User logs in via Strava OAuth
2. **Sync**: App fetches activities from the last 91 days
3. **Processing**: Daily workout minutes are summed and converted to levels (0-4)
4. **Caching**: Activity levels are cached locally
5. **Display**: Widget renders a 13x7 grid with appropriate colors
6. **Background Refresh**: Periodic sync keeps data up-to-date

---

## License

MIT
