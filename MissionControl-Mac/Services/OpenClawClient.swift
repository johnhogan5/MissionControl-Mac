import Foundation

final class OpenClawClient {
    static let shared = OpenClawClient()
    private init() {}

    func health(baseURL: String, token: String) async throws -> Bool {
        guard let url = URL(string: baseURL + "/health") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { return false }
        return (200..<300).contains(http.statusCode)
    }

    func sendResponse(
        baseURL: String,
        token: String,
        sessionKey: String,
        model: String,
        input: String
    ) async throws -> String {
        let req = try buildRequest(
            baseURL: baseURL,
            token: token,
            sessionKey: sessionKey,
            model: model,
            input: input,
            stream: false
        )

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "OpenClawClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let decoded = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        let text = decoded.output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (text?.isEmpty == false) ? text! : "(No response text)"
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
                        token: token,
                        sessionKey: sessionKey,
                        model: model,
                        input: input,
                        stream: true
                    )

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                    guard (200..<300).contains(http.statusCode) else {
                        throw NSError(domain: "OpenClawClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Streaming request failed (\(http.statusCode))"])
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

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func buildRequest(
        baseURL: String,
        token: String,
        sessionKey: String,
        model: String,
        input: String,
        stream: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + "/v1/responses") else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if !sessionKey.isEmpty {
            req.setValue(sessionKey, forHTTPHeaderField: "x-openclaw-session-key")
        }

        let body = ResponseRequest(model: model, input: input, stream: stream ? true : nil)
        req.httpBody = try JSONEncoder().encode(body)
        return req
    }

    private static func extractDelta(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

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
