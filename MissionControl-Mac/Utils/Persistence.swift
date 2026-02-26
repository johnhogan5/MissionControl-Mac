import Foundation

enum Persistence {
    static let profileKey = "missioncontrol.mac.profile"
    static let sessionsKey = "missioncontrol.mac.sessions"
    static let eventsKey = "missioncontrol.mac.events"
    static let journalKey = "missioncontrol.mac.journal"
    static let cronJobsKey = "missioncontrol.mac.cronjobs"
    static let latencySamplesKey = "missioncontrol.mac.latencySamples"

    static func saveProfile(_ profile: ConnectionProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    static func loadProfile() -> ConnectionProfile {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(ConnectionProfile.self, from: data)
        else {
            return ConnectionProfile()
        }
        return profile
    }

    static func saveSessions(_ sessions: [LocalSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    static func loadSessions() -> [LocalSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([LocalSession].self, from: data)
        else {
            return [
                LocalSession(title: "Main", sessionKey: "agent:main:main")
            ]
        }
        return sessions
    }

    static func saveEvents(_ events: [AppEvent]) {
        if let data = try? JSONEncoder().encode(events.suffix(500)) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
    }

    static func loadEvents() -> [AppEvent] {
        guard let data = UserDefaults.standard.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([AppEvent].self, from: data)
        else {
            return []
        }
        return events
    }

    static func saveJournal(_ entries: [JournalEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: journalKey)
        }
    }

    static func loadJournal() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: journalKey),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    static func saveCronJobs(_ jobs: [CronJobSummary]) {
        if let data = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(data, forKey: cronJobsKey)
        }
    }

    static func loadCronJobs() -> [CronJobSummary] {
        guard let data = UserDefaults.standard.data(forKey: cronJobsKey),
              let jobs = try? JSONDecoder().decode([CronJobSummary].self, from: data)
        else {
            return [
                CronJobSummary(name: "healthcheck:security-audit", schedule: "Mon 15:00 UTC", enabled: true, lastRun: "Pending"),
                CronJobSummary(name: "healthcheck:update-status", schedule: "Mon 15:10 UTC", enabled: true, lastRun: "Pending")
            ]
        }
        return jobs
    }

    static func saveLatencySamples(_ samples: [Int]) {
        UserDefaults.standard.set(samples.suffix(500), forKey: latencySamplesKey)
    }

    static func loadLatencySamples() -> [Int] {
        UserDefaults.standard.array(forKey: latencySamplesKey) as? [Int] ?? []
    }
}
