import Foundation

struct HealthResponse: Codable {
    let ok: Bool?
}

struct ResponseRequest: Codable {
    let model: String
    let input: String
    let stream: Bool?

    init(model: String, input: String, stream: Bool? = nil) {
        self.model = model
        self.input = input
        self.stream = stream
    }
}

struct ResponseEnvelope: Codable {
    let output: [ResponseOutput]?
}

struct ResponseOutput: Codable {
    let content: [ResponseContent]?
}

struct ResponseContent: Codable {
    let type: String?
    let text: String?
}

struct GatewaySessionSummary: Identifiable, Codable {
    let id: String
    let title: String
    let updatedAt: Date?
    let messageCount: Int?

    init(id: String, title: String, updatedAt: Date? = nil, messageCount: Int? = nil) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.messageCount = messageCount
    }
}

struct GatewayStatusSnapshot: Codable {
    let uptimeSec: Int?
    let activeSessions: Int?
    let model: String?
}
