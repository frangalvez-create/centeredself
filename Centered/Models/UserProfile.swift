import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let displayName: String?
    let currentStreak: Int
    let longestStreak: Int
    let totalJournalEntries: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalJournalEntries = "total_journal_entries"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, email: String, displayName: String? = nil, currentStreak: Int = 0, longestStreak: Int = 0, totalJournalEntries: Int = 0, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalJournalEntries = totalJournalEntries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
