import Foundation

final class StravaClient {
    static let shared = StravaClient()

    private let baseURL = "https://www.strava.com"
    private let session = URLSession.shared

    private init() {}

    // MARK: - Token Exchange

    func exchangeToken(code: String) async throws -> TokenResponse {
        let url = URL(string: "\(baseURL)/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Secrets.stravaClientID,
            "client_secret": Secrets.stravaClientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        request.httpBody = body.percentEncoded()

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw StravaAPIError.invalidResponse
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: - Token Refresh

    func refreshToken(_ refreshToken: String) async throws -> TokenResponse {
        let url = URL(string: "\(baseURL)/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Secrets.stravaClientID,
            "client_secret": Secrets.stravaClientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        request.httpBody = body.percentEncoded()

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw StravaAPIError.invalidResponse
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: - Get Activities

    func getActivities(accessToken: String, after: TimeInterval) async throws -> [StravaActivity] {
        var components = URLComponents(string: "\(baseURL)/api/v3/athlete/activities")!
        components.queryItems = [
            URLQueryItem(name: "after", value: String(Int(after))),
            URLQueryItem(name: "per_page", value: "200")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw StravaAPIError.invalidResponse
        }

        return try JSONDecoder().decode([StravaActivity].self, from: data)
    }
}

// MARK: - Errors

enum StravaAPIError: Error {
    case invalidResponse
    case decodingError
}

// MARK: - Dictionary Extension

extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}
