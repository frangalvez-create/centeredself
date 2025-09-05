import Foundation
import Supabase

class SupabaseService: ObservableObject {
    private let useMockData = false // Now using real Supabase!
    private let supabase: SupabaseClient
    
    init() {
        if useMockData {
            // Mock initialization
            print("Using mock Supabase service")
            // Create a dummy client to satisfy compiler
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://example.com")!,
                supabaseKey: "dummy"
            )
        } else {
            // Real Supabase initialization
            print("🚀 Connecting to real Supabase database...")
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://vozayapiwlbndqwztvwa.supabase.co")!,
                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvemF5YXBpd2xibmRxd3p0dndhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NjA4NjEsImV4cCI6MjA3MjIzNjg2MX0.owG2uIaB6KQFVlgH9tSZJGZVe9YnLv_hHQDcfqsNtdI"
            )
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String) async throws -> UserProfile {
        if useMockData {
            // Mock implementation
            return UserProfile(
                id: UUID(),
                email: email,
                fullName: nil,
                avatarUrl: nil,
                goals: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Real Supabase implementation
            let authResponse = try await supabase.auth.signUp(email: email, password: password)
            let user = authResponse.user
            
            // Create user profile
            let userProfile = UserProfile(
                id: user.id,
                email: email,
                fullName: nil,
                avatarUrl: nil,
                goals: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Insert into user_profiles table
            try await supabase
                .from("user_profiles")
                .insert(userProfile)
                .execute()
            
            return userProfile
        }
    }
    
    func signIn(email: String, password: String) async throws -> UserProfile {
        if useMockData {
            // Mock implementation - always succeeds for testing
            return UserProfile(
                id: UUID(),
                email: email,
                fullName: "Test User",
                avatarUrl: nil,
                goals: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Real implementation
            let authResponse = try await supabase.auth.signIn(email: email, password: password)
            let user = authResponse.user
            
            // Fetch user profile
            return try await getUserProfile(userId: user.id)
        }
    }
    
    func signOut() async throws {
        if useMockData {
            // Mock implementation
        } else {
            try await supabase.auth.signOut()
        }
    }
    
    func getCurrentUserId() -> UUID? {
        if useMockData {
            return nil // No user logged in by default for testing
        } else {
            // Get current authenticated user ID
            return supabase.auth.currentUser?.id
        }
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile {
        if useMockData {
            // Mock implementation - return a test user profile
            return UserProfile(
                id: userId,
                email: "test@example.com",
                fullName: "Test User",
                avatarUrl: nil,
                goals: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Real implementation
            let response: [UserProfile] = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let userProfile = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
            }
            
            return userProfile
        }
    }
    
    // MARK: - Guided Questions
    func fetchGuidedQuestions() async throws -> [GuidedQuestion] {
        if useMockData {
            // Return mock guided questions that match your database
            return [
                GuidedQuestion(
                    id: UUID(),
                    questionText: "What thing, person or moment filled you with gratitude today?",
                    isActive: true,
                    orderIndex: 1,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "What went well today and why?",
                    isActive: true,
                    orderIndex: 2,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "How are you feeling today? Mind and body",
                    isActive: true,
                    orderIndex: 3,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "If you dream, what would you like to dream about tonight?",
                    isActive: true,
                    orderIndex: 4,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "How was your time management today? Anything to improve?",
                    isActive: true,
                    orderIndex: 5,
                    createdAt: Date()
                )
            ]
        } else {
            // Real implementation - fetch guided questions from database
            let response: [GuidedQuestion] = try await supabase
                .from("guided_questions")
                .select()
                .eq("is_active", value: true)
                .order("order_index")
                .execute()
                .value
            
            return response
        }
    }
    
    func getRandomGuidedQuestion() async throws -> GuidedQuestion? {
        let questions = try await fetchGuidedQuestions()
        return questions.randomElement()
    }
    
    // MARK: - Journal Entries
    func createJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation - simulate saving
            print("Mock: Saved journal entry - \(entry.content)")
            // Create a new entry with database-generated fields
            let savedEntry = JournalEntry(
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite
            )
            return savedEntry
        } else {
            // Real implementation - save journal entry to database
            let response: [JournalEntry] = try await supabase
                .from("journal_entries")
                .insert(entry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save journal entry"])
            }
            
            return savedEntry
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation
            print("Mock: Updated journal entry - \(entry.content)")
            // Create a new entry with updated timestamp
            let updatedEntry = JournalEntry(
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite
            )
            return updatedEntry
        } else {
            // Real implementation
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .update(entry)
                .eq("id", value: entry.id)
                .select()
                .execute()
                .value
            
            guard let updatedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update journal entry"])
            }
            
            return updatedEntry
        }
    }
    
    func fetchJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return empty array
            return []
        } else {
            // Real implementation
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        if useMockData {
            // Mock implementation
            print("Mock: Deleted journal entry with ID: \(id)")
        } else {
            // Real implementation (to be uncommented)
            /*
            try await supabase.database
                .from("journal_entries")
                .delete()
                .eq("id", value: id)
                .execute()
            */
            throw NSError(domain: "NotImplemented", code: 0, userInfo: [NSLocalizedDescriptionKey: "Real Supabase not yet configured"])
        }
    }
    
    // MARK: - Open Question Journal Entries (Special handling)
    func createOpenQuestionJournalEntry(_ entry: JournalEntry, staticQuestion: String) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation - simulate saving
            print("Mock: Saved open question journal entry - \(entry.content)")
            // Create a new entry with database-generated fields
            let savedEntry = JournalEntry(
                userId: entry.userId,
                guidedQuestionId: nil, // Open question entries have null guided_question_id
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite
            )
            return savedEntry
        } else {
            // Real implementation - save open question journal entry to database
            // For open questions, we use tags to identify them as open question entries
            let response: [JournalEntry] = try await supabase
                .from("journal_entries")
                .insert(entry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save open question journal entry"])
            }
            
            return savedEntry
        }
    }
    
    func fetchOpenQuestionJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return empty array
            return []
        } else {
            // Real implementation - fetch entries tagged as open questions
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .contains("tags", value: ["open_question"]) // Filter by open_question tag
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    // MARK: - Goals
    func createGoal(_ goal: Goal) async throws -> Goal {
        if useMockData {
            // Mock implementation
            let savedGoal = Goal(
                userId: goal.userId,
                content: goal.content,
                goals: goal.goals
            )
            return savedGoal
        } else {
            // Real implementation
            let newGoal: [Goal] = try await supabase.from("goals")
                .insert(goal)
                .select()
                .execute()
                .value
            
            guard let savedGoal = newGoal.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create goal"])
            }
            return savedGoal
        }
    }
    
    func fetchGoals(userId: UUID) async throws -> [Goal] {
        if useMockData {
            return []
        } else {
            // Real implementation
            let goals: [Goal] = try await supabase.from("goals")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            return goals
        }
    }
    
    func updateGoal(_ goal: Goal) async throws -> Goal {
        if useMockData {
            let updatedGoal = Goal(
                userId: goal.userId,
                content: goal.content,
                goals: goal.goals
            )
            return updatedGoal
        } else {
            // Real implementation
            let updatedGoal: [Goal] = try await supabase.from("goals")
                .update(goal)
                .eq("id", value: goal.id)
                .select()
                .execute()
                .value
            
            guard let newGoal = updatedGoal.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update goal"])
            }
            return newGoal
        }
    }
    
    func deleteGoal(id: UUID) async throws {
        if useMockData {
            print("Mock: Deleted goal with ID: \(id)")
        } else {
            // Real implementation
            try await supabase.from("goals").delete().eq("id", value: id).execute()
        }
    }
    
    // MARK: - Favorite Journal Entries
    func fetchFavoriteJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return sample favorite entries
            return [
                JournalEntry(
                    id: UUID(),
                    userId: userId,
                    guidedQuestionId: UUID(),
                    content: "I learned that vibe coding is doable and I'm excited for the future of this app!",
                    aiPrompt: "Sample AI prompt",
                    aiResponse: "It's wonderful to hear that your family relationships are going well. Positive connections with family can significantly enhance emotional well-being and contribute to a supportive environment.",
                    tags: [],
                    isFavorite: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                JournalEntry(
                    id: UUID(),
                    userId: userId,
                    guidedQuestionId: UUID(),
                    content: "So far all my family relationships are going well.",
                    aiPrompt: "Sample AI prompt",
                    aiResponse: "To further strengthen these relationships, consider setting aside regular time for family activities, practicing active listening during conversations, and expressing appreciation for each family member's contributions.",
                    tags: [],
                    isFavorite: true,
                    createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                )
            ]
        } else {
            // Real implementation
            let favoriteEntries: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .eq("is_favorite", value: true)
                .order("created_at", ascending: false) // Newest first
                .execute()
                .value
            return favoriteEntries
        }
    }
    
    // MARK: - Delete Favorite Entry
    func removeFavoriteEntry(entryId: UUID) async throws {
        if useMockData {
            print("Mock: Removed favorite status for entry ID: \(entryId)")
        } else {
            // Real implementation - set is_favorite to FALSE
            try await supabase
                .from("journal_entries")
                .update(["is_favorite": false])
                .eq("id", value: entryId)
                .execute()
        }
    }
}