import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let goals: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case goals
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
