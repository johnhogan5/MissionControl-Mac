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
