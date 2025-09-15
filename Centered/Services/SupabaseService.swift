import Foundation
import Supabase

class SupabaseService: ObservableObject {
    private let useMockData = false // Using live Supabase data with OTP authentication
    private let supabase: SupabaseClient
    
    // Mock data storage
    private var mockJournalEntries: [JournalEntry] = []
    private var mockGoals: [Goal] = []
    private var mockUserProfile: UserProfile?
    
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
    
    func isUsingMockData() -> Bool {
        return useMockData
    }
    
    // MARK: - Authentication
    func signUpWithOTP(email: String) async throws {
        if useMockData {
            // Mock implementation - always succeeds for testing
            print("Mock: OTP code sent to \(email)")
        } else {
            // Real implementation - send OTP code (not Magic Link)
            _ = try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )
            print("OTP code sent to \(email)")
        }
    }
    
    func verifyOTP(email: String, token: String) async throws -> UserProfile {
        if useMockData {
            // Mock implementation - always succeeds for testing
            let userProfile = UserProfile(
                id: UUID(),
                email: email,
                displayName: "Test User"
            )
            mockUserProfile = userProfile
            print("Mock: OTP verified for \(email)")
            return userProfile
        } else {
            // Real implementation - verify OTP
            let authResponse = try await supabase.auth.verifyOTP(email: email, token: token, type: .email)
            let user = authResponse.user
            
            // For OTP auth, we create a simple UserProfile from auth.users data
            // No separate user_profiles table needed
            let userProfile = UserProfile(
                id: user.id,
                email: user.email ?? email,
                displayName: user.userMetadata["full_name"]?.stringValue ?? "User"
            )
            
            print("✅ OTP verified successfully for \(email)")
            return userProfile
        }
    }
    
    func signOut() async throws {
        if useMockData {
            // Mock implementation
        } else {
            try await supabase.auth.signOut()
        }
    }
    
    func getCurrentSession() async throws -> Session? {
        if useMockData {
            // Mock implementation - return mock session if user exists
            if let mockUser = mockUserProfile {
                return Session(
                    providerToken: nil,
                    providerRefreshToken: nil,
                    accessToken: "mock_token",
                    tokenType: "bearer",
                    expiresIn: 3600,
                    expiresAt: Date().timeIntervalSince1970 + 3600,
                    refreshToken: "mock_refresh_token",
                    weakPassword: nil,
                    user: User(
                        id: mockUser.id,
                        appMetadata: [:],
                        userMetadata: [:],
                        aud: "authenticated",
                        createdAt: mockUser.createdAt,
                        updatedAt: mockUser.updatedAt
                    )
                )
            }
            return nil
        } else {
            // Real implementation - get current session
            return try await supabase.auth.session
        }
    }
    
    func getCurrentUserId() -> UUID? {
        if useMockData {
            return mockUserProfile?.id
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
                displayName: "Test User"
            )
        } else {
            // Real implementation - get user info from auth.users table
            // Since we're using simplified OTP auth, we don't have a separate user_profiles table
            // We'll create a basic UserProfile from the auth session
            let session = try await supabase.auth.session
            return UserProfile(
                id: session.user.id,
                email: session.user.email ?? "unknown@example.com",
                displayName: session.user.userMetadata["full_name"]?.stringValue ?? "User"
            )
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
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        
        if useMockData {
            // Mock implementation - store the entry
            let savedEntry = JournalEntry(
                id: UUID(),
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: Date(),
                updatedAt: Date()
            )
            mockJournalEntries.append(savedEntry)
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
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
            print("Mock: Updating journal entry - ID: \(entry.id), Content: \(entry.content), AI Prompt: \(entry.aiPrompt ?? "nil"), AI Response: \(entry.aiResponse ?? "nil")")
            
            // Find and update the entry in mock storage
            if let index = mockJournalEntries.firstIndex(where: { $0.id == entry.id }) {
                mockJournalEntries[index] = entry
                print("Mock: Updated journal entry at index \(index), Total entries: \(mockJournalEntries.count)")
            } else {
                print("Mock: Entry not found for update, adding new entry")
                mockJournalEntries.append(entry)
            }
            
            // Create a new entry with updated timestamp
            let updatedEntry = JournalEntry(
                id: entry.id,
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: entry.createdAt,
                updatedAt: Date()
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
            // Mock implementation - return only guided question entries for this user (exclude open question entries)
            let userEntries = mockJournalEntries.filter { 
                $0.userId == userId && $0.guidedQuestionId != nil 
            }
            print("Mock: Returning \(userEntries.count) guided question journal entries for user \(userId)")
            for entry in userEntries {
                print("Mock: Entry - Content: \(entry.content), AI Prompt: \(entry.aiPrompt ?? "nil"), AI Response: \(entry.aiResponse ?? "nil")")
            }
            return userEntries
        } else {
            // Real implementation - only fetch guided question entries (exclude open question entries)
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .not("entry_type", operator: .eq, value: "open") // Exclude open question entries
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        if useMockData {
            // Mock implementation - remove from mock storage
            mockJournalEntries.removeAll { $0.id == id }
            print("Mock: Deleted journal entry with ID: \(id), Remaining entries: \(mockJournalEntries.count)")
        } else {
            // Real implementation
            try await supabase
                .from("journal_entries")
                .delete()
                .eq("id", value: id)
                .execute()
            print("Real: Deleted journal entry with ID: \(id)")
        }
    }
    
    // MARK: - Open Question Journal Entries (Special handling)
    func createOpenQuestionJournalEntry(_ entry: JournalEntry, staticQuestion: String) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation - store the entry
            let savedEntry = JournalEntry(
                id: UUID(),
                userId: entry.userId,
                guidedQuestionId: nil, // Open question entries have null guided_question_id
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: Date(),
                updatedAt: Date()
            )
            mockJournalEntries.append(savedEntry)
            print("Mock: Saved open question journal entry - \(entry.content)")
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
            // Mock implementation - return stored open question entries for this user
            let userEntries = mockJournalEntries.filter { 
                $0.userId == userId && $0.guidedQuestionId == nil 
            }
            print("Mock: Returning \(userEntries.count) open question entries for user")
            return userEntries
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
            // Mock implementation - store the goal
            let savedGoal = Goal(
                userId: goal.userId,
                content: goal.content,
                goals: goal.goals
            )
            mockGoals.append(savedGoal)
            print("Mock: Saved goal - \(goal.content)")
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
            // Mock implementation - return stored goals for this user
            let userGoals = mockGoals.filter { $0.userId == userId }
            print("Mock: Returning \(userGoals.count) goals for user")
            return userGoals
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
                    entryType: "guided",
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
                    entryType: "guided",
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