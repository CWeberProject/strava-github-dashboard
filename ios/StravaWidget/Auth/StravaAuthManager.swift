import AuthenticationServices
import Foundation

final class StravaAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = StravaAuthManager()

    private let authURL = "https://www.strava.com/oauth/mobile/authorize"
    private let callbackScheme = "stravawidget"
    private let redirectURI = "stravawidget://callback"

    private override init() {
        super.init()
    }

    func authenticate() async throws -> TokenResponse {
        let authURLComponents = buildAuthURL()

        guard let url = authURLComponents.url else {
            throw AuthError.invalidURL
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AuthError.noCallbackURL)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            DispatchQueue.main.async {
                session.start()
            }
        }

        guard let code = extractCode(from: callbackURL) else {
            throw AuthError.missingCode
        }

        return try await StravaClient.shared.exchangeToken(code: code)
    }

    private func buildAuthURL() -> URLComponents {
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Secrets.stravaClientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read")
        ]
        return components
    }

    private func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first { $0.name == "code" }?.value
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case invalidURL
    case userCancelled
    case noCallbackURL
    case missingCode

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid authentication URL"
        case .userCancelled:
            return "Authentication was cancelled"
        case .noCallbackURL:
            return "No callback URL received"
        case .missingCode:
            return "Authorization code not found"
        }
    }
}
