import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let guidedQuestionId: UUID?
    let content: String
    let aiPrompt: String?
    let aiResponse: String?
    let tags: [String]
    let isFavorite: Bool
    let entryType: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case guidedQuestionId = "guided_question_id"
        case content
        case aiPrompt = "ai_prompt"
        case aiResponse = "ai_response"
        case tags
        case isFavorite = "is_favorite"
        case entryType = "entry_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(userId: UUID, guidedQuestionId: UUID?, content: String, aiPrompt: String? = nil, aiResponse: String? = nil, tags: [String] = [], isFavorite: Bool = false, entryType: String = "guided") {
        self.id = UUID()
        self.userId = userId
        self.guidedQuestionId = guidedQuestionId
        self.content = content
        self.aiPrompt = aiPrompt
        self.aiResponse = aiResponse
        self.tags = tags
        self.isFavorite = isFavorite
        self.entryType = entryType
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Full initializer for updates
    init(id: UUID, userId: UUID, guidedQuestionId: UUID?, content: String, aiPrompt: String? = nil, aiResponse: String? = nil, tags: [String] = [], isFavorite: Bool = false, entryType: String = "guided", createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.guidedQuestionId = guidedQuestionId
        self.content = content
        self.aiPrompt = aiPrompt
        self.aiResponse = aiResponse
        self.tags = tags
        self.isFavorite = isFavorite
        self.entryType = entryType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
