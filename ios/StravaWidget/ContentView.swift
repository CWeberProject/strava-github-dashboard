import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var isLoggedIn = StravaRepository.shared.isLoggedIn
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastSyncTime: String = ""

    var body: some View {
        ZStack {
            Color(hex: Constants.widgetBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Strava Heatmap Widget")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if isLoggedIn {
                    connectedView
                } else {
                    disconnectedView
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.orange)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            updateLastSyncTime()
        }
    }

    private var connectedView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Connected to Strava")
                    .foregroundColor(.green)
            }

            Text("Add the widget to your home screen to see your activity heatmap.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            if !lastSyncTime.isEmpty {
                Text("Last sync: \(lastSyncTime)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }

            Button(action: {
                Task {
                    await syncActivities()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Now")
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("Disconnect") {
                disconnect()
            }
            .foregroundColor(.red)
            .padding(.top, 8)
        }
    }

    private var disconnectedView: some View {
        VStack(spacing: 16) {
            Text("Connect your Strava account to display your workout activity on your home screen.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await authenticate()
                }
            }) {
                HStack {
                    Image(systemName: "figure.run")
                    Text("Connect with Strava")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await StravaAuthManager.shared.authenticate()
            StravaRepository.shared.saveTokens(from: response)
            isLoggedIn = true
            await syncActivities()
        } catch {
            if case AuthError.userCancelled = error {
                // User cancelled, no error message needed
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func syncActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            try await StravaRepository.shared.syncActivities()
            updateLastSyncTime()
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func disconnect() {
        StravaRepository.shared.logout()
        isLoggedIn = false
        lastSyncTime = ""
    }

    private func updateLastSyncTime() {
        let timestamp = ActivityCache.shared.getLastSyncTime()
        if timestamp > 0 {
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            lastSyncTime = formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}

#Preview {
    ContentView()
}
