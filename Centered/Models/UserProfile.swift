import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let displayName: String?
    var firstName: String?
    var lastName: String?
    var gender: String?
    var occupation: String?
    var birthdate: String?
    let currentStreak: Int
    let longestStreak: Int
    let totalJournalEntries: Int
    let createdAt: Date
    let updatedAt: Date
    
    // Subscription fields
    var isPremium: Bool
    var subscriptionStatus: String
    var subscriptionExpiresAt: Date?
    var revenuecatUserId: String?
    var subscriptionUpdatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case gender = "gender"
        case occupation = "occupation"
        case birthdate = "birthdate"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalJournalEntries = "total_journal_entries"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPremium = "is_premium"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
        case revenuecatUserId = "revenuecat_user_id"
        case subscriptionUpdatedAt = "subscription_updated_at"
    }
    
    init(id: UUID, email: String, displayName: String? = nil, firstName: String? = nil, lastName: String? = nil, gender: String? = nil, occupation: String? = nil, birthdate: String? = nil, currentStreak: Int = 0, longestStreak: Int = 0, totalJournalEntries: Int = 0, createdAt: Date = Date(), updatedAt: Date = Date(), isPremium: Bool = false, subscriptionStatus: String = "free", subscriptionExpiresAt: Date? = nil, revenuecatUserId: String? = nil, subscriptionUpdatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.occupation = occupation
        self.birthdate = birthdate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalJournalEntries = totalJournalEntries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPremium = isPremium
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.revenuecatUserId = revenuecatUserId
        self.subscriptionUpdatedAt = subscriptionUpdatedAt
    }
}
