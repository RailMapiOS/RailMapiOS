//
//  APIConfiguration.swift
//  RailMapiOS
//
//  Single source of truth for the RailMapAPI base URL + auth token.
//  Every URLRequest going to the backend should be built via
//  `URLRequest.authorized(_:)` so the Bearer token is always attached.
//

import Foundation

enum APIConfiguration {
    /// Base URL of RailMapAPI. The simulator default points at `localhost:8080`;
    /// device builds and TestFlight should override via `Info.plist` key
    /// `RAILMAP_API_URL` or via the `RAILMAP_API_URL` env var (debug only).
    static let baseURL: String = {
        if let env = ProcessInfo.processInfo.environment["RAILMAP_API_URL"], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "RAILMAP_API_URL") as? String,
           !plist.isEmpty {
            return plist
        }
        return "http://127.0.0.1:8080"
    }()

    /// Bearer token sent on every authenticated request.
    /// Stored in `APIKeys.swift` (git-ignored) — see `APIKeys.example.swift`.
    static var authToken: String { APIKeys.railmapToken }
}

// MARK: - URLRequest helper

extension URLRequest {
    /// Builds a GET URLRequest with `Authorization: Bearer <token>` attached.
    /// Use this everywhere instead of `URLRequest(url:)` for backend calls.
    static func authorized(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(APIConfiguration.authToken)", forHTTPHeaderField: "Authorization")
        return req
    }
}
