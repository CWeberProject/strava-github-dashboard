import Foundation
import SwiftUI
import WebKit

final class StravaAuthManager: ObservableObject {
    static let shared = StravaAuthManager()

    private let authURL = "https://www.strava.com/oauth/mobile/authorize"
    private let redirectURI = "http://localhost/callback"

    @Published var isShowingAuth = false

    private var authContinuation: CheckedContinuation<String, Error>?

    private init() {}

    func authenticate() async throws -> TokenResponse {
        let code = try await getAuthorizationCode()
        return try await StravaClient.shared.exchangeToken(code: code)
    }

    private func getAuthorizationCode() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            DispatchQueue.main.async {
                self.isShowingAuth = true
            }
        }
    }

    func buildAuthURL() -> URL? {
        var components = URLComponents(string: authURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Secrets.stravaClientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read")
        ]
        return components?.url
    }

    func handleCallback(url: URL) -> Bool {
        guard url.absoluteString.starts(with: "http://localhost/callback") else {
            return false
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            authContinuation?.resume(returning: code)
            authContinuation = nil
            isShowingAuth = false
            return true
        } else if let error = components?.queryItems?.first(where: { $0.name == "error" })?.value {
            authContinuation?.resume(throwing: AuthError.authorizationDenied(error))
            authContinuation = nil
            isShowingAuth = false
            return true
        }

        authContinuation?.resume(throwing: AuthError.missingCode)
        authContinuation = nil
        isShowingAuth = false
        return true
    }

    func cancelAuth() {
        authContinuation?.resume(throwing: AuthError.userCancelled)
        authContinuation = nil
        isShowingAuth = false
    }
}

// MARK: - Auth WebView

struct StravaAuthWebView: UIViewRepresentable {
    let url: URL
    let onCallback: (URL) -> Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCallback: onCallback)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onCallback: (URL) -> Bool

        init(onCallback: @escaping (URL) -> Bool) {
            self.onCallback = onCallback
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.starts(with: "http://localhost/callback") {
                _ = onCallback(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case invalidURL
    case userCancelled
    case noCallbackURL
    case missingCode
    case authorizationDenied(String)

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
        case .authorizationDenied(let reason):
            return "Authorization denied: \(reason)"
        }
    }
}
