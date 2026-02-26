import Foundation

enum OpenClawClientError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Gateway URL is invalid."
        case .invalidResponse:
            return "Received an invalid server response."
        case let .server(statusCode, message):
            if message.isEmpty {
                return "Server error (\(statusCode))."
            }
            return "Server error (\(statusCode)): \(message)"
        }
    }
}

final class OpenClawClient {
    static let shared = OpenClawClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    func health(baseURL: String, token: String) async throws -> Bool {
        let req = try buildRequest(
            baseURL: baseURL,
            path: "/health",
            token: token,
            method: "GET",
            body: Optional<ResponseRequest>.none,
            stream: false,
            sessionKey: nil
        )

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw OpenClawClientError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw OpenClawClientError.server(statusCode: http.statusCode, message: text)
        }

        if let decoded = try? JSONDecoder().decode(HealthResponse.self, from: data), let ok = decoded.ok {
            return ok
        }

        return true
    }

    func fetchGatewaySessions(baseURL: String, token: String, limit: Int = 100) async throws -> [GatewaySessionSummary] {
        let req = try buildRequest(
            baseURL: baseURL,
            path: "/v1/sessions?limit=\(max(1, min(limit, 500)))",
            token: token,
            method: "GET",
            body: Optional<ResponseRequest>.none,
            stream: false,
            sessionKey: nil
        )

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw OpenClawClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw OpenClawClientError.server(statusCode: http.statusCode, message: text)
        }

        return Self.parseGatewaySessions(from: data)
    }

    func fetchGatewayStatus(baseURL: String, token: String) async throws -> GatewayStatusSnapshot {
        let req = try buildRequest(
            baseURL: baseURL,
            path: "/status",
            token: token,
            method: "GET",
            body: Optional<ResponseRequest>.none,
            stream: false,
            sessionKey: nil
        )

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw OpenClawClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw OpenClawClientError.server(statusCode: http.statusCode, message: text)
        }

        return Self.parseGatewayStatus(from: data)
    }

    func streamResponse(
        baseURL: String,
        token: String,
        sessionKey: String,
        model: String,
        input: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let req = try buildRequest(
                        baseURL: baseURL,
                        path: "/v1/responses",
                        token: token,
                        method: "POST",
                        body: ResponseRequest(model: model, input: input, stream: true),
                        stream: true,
                        sessionKey: sessionKey.isEmpty ? nil : sessionKey
                    )

                    let (bytes, response) = try await session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else { throw OpenClawClientError.invalidResponse }
                    guard (200..<300).contains(http.statusCode) else {
                        throw OpenClawClientError.server(statusCode: http.statusCode, message: "Streaming request failed")
                    }

                    for try await line in bytes.lines {
                        guard let delta = Self.extractDelta(from: line) else { continue }
                        continuation.yield(delta)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func buildRequest<T: Encodable>(
        baseURL: String,
        path: String,
        token: String,
        method: String,
        body: T?,
        stream: Bool,
        sessionKey: String?
    ) throws -> URLRequest {
        guard let url = Self.makeURL(baseURL: baseURL, path: path) else {
            throw OpenClawClientError.invalidBaseURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(stream ? "text/event-stream" : "application/json", forHTTPHeaderField: "Accept")
        req.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        req.setValue("MissionControl-Mac/1.0", forHTTPHeaderField: "User-Agent")

        if let sessionKey, !sessionKey.isEmpty {
            req.setValue(sessionKey, forHTTPHeaderField: "x-openclaw-session-key")
        }

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }

        return req
    }

    private static func makeURL(baseURL: String, path: String) -> URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard var components = URLComponents(string: trimmed) else { return nil }
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"

        let existingPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let incomingPath = cleanPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if existingPath.isEmpty {
            components.path = "/\(incomingPath)"
        } else {
            components.path = "/\(existingPath)/\(incomingPath)"
        }

        return components.url
    }

    private static func parseGatewaySessions(from data: Data) -> [GatewaySessionSummary] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return [] }

        let rows: [[String: Any]]
        if let list = json as? [[String: Any]] {
            rows = list
        } else if let object = json as? [String: Any] {
            if let sessions = object["sessions"] as? [[String: Any]] {
                rows = sessions
            } else if let items = object["items"] as? [[String: Any]] {
                rows = items
            } else if let dataRows = object["data"] as? [[String: Any]] {
                rows = dataRows
            } else {
                rows = []
            }
        } else {
            rows = []
        }

        return rows.compactMap { row in
            let id = (row["sessionKey"] as? String)
                ?? (row["session_key"] as? String)
                ?? (row["id"] as? String)
            guard let id else { return nil }

            let title = (row["title"] as? String)
                ?? (row["name"] as? String)
                ?? id

            let messageCount = (row["messageCount"] as? Int)
                ?? (row["message_count"] as? Int)
                ?? (row["messages"] as? [[String: Any]])?.count

            let updatedAtString = (row["updatedAt"] as? String)
                ?? (row["updated_at"] as? String)
                ?? (row["lastSeen"] as? String)

            return GatewaySessionSummary(
                id: id,
                title: title,
                updatedAt: dateFromPossiblyISO(updatedAtString),
                messageCount: messageCount
            )
        }
    }

    private static func parseGatewayStatus(from data: Data) -> GatewayStatusSnapshot {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return GatewayStatusSnapshot(uptimeSec: nil, activeSessions: nil, model: nil)
        }

        let uptimeSec = (object["uptimeSec"] as? Int)
            ?? (object["uptime_sec"] as? Int)
            ?? (object["uptime"] as? Int)

        let activeSessions = (object["activeSessions"] as? Int)
            ?? (object["active_sessions"] as? Int)
            ?? (object["sessions"] as? Int)

        let model = (object["model"] as? String)
            ?? (object["defaultModel"] as? String)
            ?? (object["default_model"] as? String)

        return GatewayStatusSnapshot(uptimeSec: uptimeSec, activeSessions: activeSessions, model: model)
    }

    private static func dateFromPossiblyISO(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: value) { return date }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    private static func extractDelta(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("event:") else { return nil }

        let payload: String
        if trimmed.hasPrefix("data:") {
            payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        } else {
            payload = trimmed
        }

        guard payload != "[DONE]", let data = payload.data(using: .utf8) else { return nil }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let delta = object["delta"] as? String, !delta.isEmpty { return delta }
            if let text = object["text"] as? String, !text.isEmpty { return text }
            if let outputText = object["output_text"] as? String, !outputText.isEmpty { return outputText }

            if let item = object["item"] as? [String: Any],
               let content = item["content"] as? [[String: Any]] {
                let chunks = content.compactMap { $0["text"] as? String }.filter { !$0.isEmpty }
                if !chunks.isEmpty { return chunks.joined() }
            }

            if let deltaObj = object["delta"] as? [String: Any],
               let text = deltaObj["text"] as? String,
               !text.isEmpty {
                return text
            }
        }

        return nil
    }
}
