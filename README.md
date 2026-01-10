# Strava Activity Heatmap Widget

An Android home screen widget that displays your Strava activities as a GitHub-style contribution heatmap.

## Features

- 13×7 grid showing the last 91 days of activity
- Color intensity based on workout duration (gray → orange)
- Background sync every 15 minutes
- Tap widget to open Strava app

## Color Scale

| Duration | Color |
|----------|-------|
| No activity | Gray |
| 1-29 min | Light orange |
| 30-59 min | Medium orange |
| 60-89 min | Dark orange |
| 90+ min | Bright orange |

## Setup

1. **Get Strava API credentials**
   - Go to https://www.strava.com/settings/api
   - Create an app (or use existing)
   - Set Authorization Callback Domain to `localhost`
   - Note your Client ID and Client Secret

2. **Configure the project**
   - Copy `local.properties.example` to `local.properties`
   - Fill in your Strava credentials

3. **Build and install**
   ```bash
   ./gradlew installDebug
   ```

4. **Add widget to home screen**
   - Long press home screen → Widgets → Strava Heatmap
   - Tap widget to authenticate with Strava

## Requirements

- Android 8.0+ (API 26)
- Strava account

## License

MIT
