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
            
            // After successful OTP verification, load the full user profile from user_profiles table
            do {
                let fullProfile = try await loadUserProfile()
                if let profile = fullProfile {
                    print("✅ OTP verified and full profile loaded for \(email)")
                    return profile
                } else {
                    // If no profile exists, create a basic one
                    let userProfile = UserProfile(
                        id: user.id,
                        email: user.email ?? email,
                        displayName: user.userMetadata["full_name"]?.stringValue ?? "User"
                    )
                    print("✅ OTP verified for \(email) - no profile found, created basic profile")
                    return userProfile
                }
            } catch {
                // Fallback to basic profile if loading fails
                let userProfile = UserProfile(
                    id: user.id,
                    email: user.email ?? email,
                    displayName: user.userMetadata["full_name"]?.stringValue ?? "User"
                )
                print("⚠️ OTP verified for \(email) - profile loading failed, using basic profile")
                return userProfile
            }
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
    
    func getTodaysGuidedQuestion() async throws -> GuidedQuestion? {
        let questions = try await fetchGuidedQuestions()
        
        // Sort questions by order_index to ensure consistent ordering
        let sortedQuestions = questions.sorted { $0.orderIndex ?? 0 < $1.orderIndex ?? 0 }
        
        // Calculate days since a reference date (January 1, 2024)
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceReference = Calendar.current.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        
        // Use modulo to cycle through questions
        let questionIndex = daysSinceReference % sortedQuestions.count
        let todaysQuestion = sortedQuestions[questionIndex]
        
        print("📅 Date-based question selection: Day \(daysSinceReference), Question index \(questionIndex), Question: \(todaysQuestion.questionText)")
        
        return todaysQuestion
    }
    
    // MARK: - Follow-Up Question Logic
    
    /// Determines if today is a follow-up question day (every 3rd day)
    func isFollowUpQuestionDay() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate days since January 1, 2024 (same reference as guided questions)
        let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        
        // Every 3rd day (days 0, 3, 6, 9, etc.)
        return daysSinceReference % 3 == 0
    }
    
    /// Selects a past journal entry for follow-up question generation
    func selectPastJournalEntryForFollowUp(userId: UUID) async throws -> JournalEntry? {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate date range: 5 to 15 days ago
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
        
        if useMockData {
            // Mock implementation - return a mock entry if available
            let mockEntries = mockJournalEntries.filter { entry in
                entry.userId == userId && 
                entry.createdAt >= fifteenDaysAgo && 
                entry.createdAt <= fiveDaysAgo
            }
            return mockEntries.first
        } else {
            // Real implementation - query database
            
            // Priority 1: is_favorite = TRUE entries (not yet used for follow-up)
            let favoriteEntries: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .eq("is_favorite", value: true)
                .neq("used_for_follow_up", value: true) // Exclude already used entries
                .gte("created_at", value: fifteenDaysAgo.ISO8601Format())
                .lte("created_at", value: fiveDaysAgo.ISO8601Format())
                .order("created_at", ascending: true) // Oldest first
                .limit(1)
                .execute()
                .value
            
            if let favoriteEntry = favoriteEntries.first {
                print("✅ Selected favorite entry for follow-up: \(favoriteEntry.content.prefix(50))...")
                return favoriteEntry
            }
            
            // Priority 2: tags = "open_question" entries (not yet used for follow-up)
            let openQuestionEntries: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .contains("tags", value: ["open_question"])
                .neq("used_for_follow_up", value: true) // Exclude already used entries
                .gte("created_at", value: fifteenDaysAgo.ISO8601Format())
                .lte("created_at", value: fiveDaysAgo.ISO8601Format())
                .order("created_at", ascending: true) // Oldest first
                .limit(1)
                .execute()
                .value
            
            if let openQuestionEntry = openQuestionEntries.first {
                print("✅ Selected open question entry for follow-up: \(openQuestionEntry.content.prefix(50))...")
                return openQuestionEntry
            }
            
            // Priority 3: Most recent entry older than current day (not yet used for follow-up)
            let recentEntries: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .neq("used_for_follow_up", value: true) // Exclude already used entries
                .lt("created_at", value: today.ISO8601Format())
                .order("created_at", ascending: false) // Most recent first
                .limit(1)
                .execute()
                .value
            
            if let recentEntry = recentEntries.first {
                print("✅ Selected most recent entry for follow-up: \(recentEntry.content.prefix(50))...")
                return recentEntry
            }
            
            print("⚠️ No eligible entries found for follow-up question")
            return nil
        }
    }
    
    /// Generates a follow-up question AI prompt template
    func generateFollowUpQuestionPrompt(pastEntry: JournalEntry) -> String {
        let content = pastEntry.content
        let aiResponse = pastEntry.aiResponse ?? ""
        
        // Extract first paragraph from ai_response
        let firstParagraph = aiResponse.components(separatedBy: "\n\n").first ?? aiResponse.components(separatedBy: "\n").first ?? aiResponse
        
        print("📝 FUQ Prompt - Using first paragraph of AI response:")
        print("   Original length: \(aiResponse.count) characters")
        print("   First paragraph length: \(firstParagraph.count) characters")
        print("   First paragraph: \(firstParagraph.prefix(100))...")
        
        let promptTemplate = """
        Past Client statements: {content} 
        Therapist response: {ai_response} 
        Create a "follow up" style question (25 word limit) from the above conversation previously had. Question structure: "You previously mentioned… Summarize past client statements, then ask a probing question regarding either client's current progress or mindset or realizations or feelings"
        """
        
        return promptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{ai_response}", with: firstParagraph)
    }
    
    /// Creates a follow-up question journal entry
    func createFollowUpQuestionEntry(userId: UUID, fuqAiPrompt: String, fuqAiResponse: String) async throws -> JournalEntry {
        let followUpEntry = JournalEntry(
            id: UUID(),
            userId: userId,
            guidedQuestionId: nil,
            content: "", // Empty initially, user will fill this
            aiPrompt: nil, // Will be filled when user generates AI response
            aiResponse: nil, // Will be filled when user generates AI response
            tags: ["follow_up"],
            isFavorite: false,
            entryType: "follow_up",
            createdAt: Date(),
            updatedAt: Date(),
            fuqAiPrompt: fuqAiPrompt,
            fuqAiResponse: fuqAiResponse,
            isFollowUpDay: true,
            usedForFollowUp: false // New entries start as not used
        )
        
        return try await createJournalEntry(followUpEntry)
    }
    
    /// Marks a journal entry as used for follow-up question generation
    func markEntryAsUsedForFollowUp(entryId: UUID) async throws {
        do {
            try await supabase
                .from("journal_entries")
                .update(["used_for_follow_up": true])
                .eq("id", value: entryId)
                .execute()
            
            print("✅ Marked entry \(entryId) as used for follow-up")
        } catch {
            print("❌ Failed to mark entry as used for follow-up: \(error.localizedDescription)")
            throw error
        }
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
    
    // MARK: - User Profile Updates
    func updateUserProfile(firstName: String? = nil, lastName: String? = nil, gender: String? = nil, occupation: String? = nil, birthdate: String? = nil, notificationFrequency: String? = nil, streakEndingNotification: Bool? = nil) async throws {
        if useMockData {
            print("Mock: Updated user profile with first name: \(firstName)")
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - save to user_profiles table
            struct ProfileData: Codable {
                let user_id: String
                let first_name: String?
                let last_name: String?
                let gender: String?
                let occupation: String?
                let birthdate: String?
                let updated_at: String
            }
            
            let profileData = ProfileData(
                user_id: userId.uuidString,
                first_name: firstName,
                last_name: lastName,
                gender: gender,
                occupation: occupation,
                birthdate: birthdate,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            // Try to update first, if no rows affected, then insert
            do {
                let updateResponse = try await supabase
                    .from("user_profiles")
                    .update([
                        "first_name": firstName,
                        "last_name": lastName,
                        "gender": gender,
                        "occupation": occupation,
                        "birthdate": birthdate,
                        "updated_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                
                // Check if any rows were actually updated by parsing the response
                if let responseData = try JSONSerialization.jsonObject(with: updateResponse.data) as? [[String: Any]],
                   responseData.isEmpty {
                    // No rows were updated, insert a new record
                    let _ = try await supabase
                        .from("user_profiles")
                        .insert(profileData)
                        .execute()
                }
            } catch {
                // If update fails, try to insert a new record
                let _ = try await supabase
                    .from("user_profiles")
                    .insert(profileData)
                    .execute()
            }
            
            print("✅ User profile updated successfully for user: \(userId)")
            print("   First Name: \(firstName)")
            print("   Last Name: \(lastName ?? "nil")")
            print("   Birthdate: \(birthdate ?? "nil")")
        }
    }
    
    func loadUserProfile() async throws -> UserProfile? {
        if useMockData {
            print("Mock: Loading user profile")
            return UserProfile(
                id: UUID(),
                email: "test@example.com",
                displayName: "Test User",
                firstName: "Test",
                lastName: "User",
                gender: "Non-binary",
                occupation: "Software Developer",
                birthdate: "01/15/1990",
                currentStreak: 5,
                longestStreak: 10,
                totalJournalEntries: 15,
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - fetch from user_profiles table
            let response = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            if let profileData = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let profile = profileData.first {
                print("✅ User profile loaded successfully for user: \(userId)")
                
                return UserProfile(
                    id: userId,
                    email: supabase.auth.currentUser?.email ?? "unknown@example.com",
                    displayName: profile["first_name"] as? String ?? "User",
                    firstName: profile["first_name"] as? String,
                    lastName: profile["last_name"] as? String,
                    gender: profile["gender"] as? String,
                    occupation: profile["occupation"] as? String,
                    birthdate: profile["birthdate"] as? String,
                    currentStreak: 0, // Default values for now
                    longestStreak: 0,
                    totalJournalEntries: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            } else {
                print("ℹ️ No user profile found for user: \(userId) - returning nil")
                return nil
            }
        }
    }
    
    func fetchUserProfile() async throws -> [String: Any]? {
        if useMockData {
            print("Mock: Fetching user profile")
            return [
                "first_name": "Test",
                "last_name": "User",
                "notification_frequency": "Weekly",
                "streak_ending_notification": true
            ]
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - fetch from user_profiles table
            let response = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            if let profileData = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                print("✅ User profile fetched successfully for user: \(userId)")
                return profileData
            } else {
                print("ℹ️ No user profile found for user: \(userId) - returning default values")
                // Return default values so existing users don't break
                return [
                    "first_name": "" as Any,
                    "last_name": "" as Any,
                    "notification_frequency": "Weekly",
                    "streak_ending_notification": true
                ]
            }
        }
    }
    
    // MARK: - Delete Account Functions
    
    /// Deletes all user data associated with the currently logged-in user
    /// Returns true if successful, false otherwise
    func deleteUserAccount() async throws -> Bool {
        do {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Delete journal entries for this user
            try await supabase
                .from("journal_entries")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Delete goals for this user
            try await supabase
                .from("goals")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Delete user profile for this user
            try await supabase
                .from("user_profiles")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Sign out the user instead of deleting auth record (admin API not available)
            try await supabase.auth.signOut()
            
            return true
            
        } catch {
            if error.localizedDescription.contains("No current user") {
                return false
            }
            throw error
        }
    }
}