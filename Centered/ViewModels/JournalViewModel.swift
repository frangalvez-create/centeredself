import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var currentQuestion: GuidedQuestion?
    @Published var journalEntries: [JournalEntry] = []
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var openQuestionJournalEntries: [JournalEntry] = []
    @Published var favoriteJournalEntries: [JournalEntry] = []
    @Published var goals: [Goal] = []
    @Published var shouldClearUIState = false
    
    // Callback to clear UI state directly
    var clearUIStateCallback: (() -> Void)?
    
    // Callback to populate UI state from loaded data
    var populateUIStateCallback: (() -> Void)?
    
    // Track the last user ID to detect user changes
    private var lastUserId: UUID?
    
    // Track when we last performed a reset to prevent multiple resets per day
    private var lastResetDate: Date?
    
    private let supabaseService = SupabaseService()
    private let openAIService = OpenAIService()
    
    init() {
        // Start with not authenticated for testing
        isAuthenticated = false
    }
    
    // MARK: - Authentication
    func checkAuthenticationStatus() async {
        // For mock data, automatically authenticate with a test user
        if supabaseService.isUsingMockData() {
            print("🔄 Using mock data - auto-authenticating for testing")
            let mockUser = UserProfile(
                id: UUID(),
                email: "test@example.com",
                displayName: "Test User"
            )
            currentUser = mockUser
            lastUserId = mockUser.id
            isAuthenticated = true
            await loadInitialData()
            return
        }
        
        if let userId = supabaseService.getCurrentUserId() {
            do {
                let userProfile = try await supabaseService.getUserProfile(userId: userId)
                
                // Check if this is a different user than before
                let isDifferentUser = lastUserId != nil && lastUserId != userProfile.id
                print("🔄 checkAuthenticationStatus - User change detected: \(isDifferentUser), Previous: \(lastUserId?.uuidString ?? "nil"), Current: \(userProfile.id.uuidString)")
                
                // Only clear UI state if switching to a different user
                if isDifferentUser {
                    print("🧹 Different user detected in checkAuthenticationStatus - clearing UI state")
                    await clearUIState()
                } else {
                    print("✅ Same user in checkAuthenticationStatus - preserving UI state")
                }
                
                currentUser = userProfile
                lastUserId = userProfile.id // Update the tracked user ID
                isAuthenticated = true
                await loadInitialData()
            } catch {
                print("Error loading user profile: \(error)")
                isAuthenticated = false
            }
        }
    }
    
    // Removed signIn method - using OTP authentication instead
    
    func sendOTP(email: String) async {
        print("📧 sendOTP called with email: \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signUpWithOTP(email: email)
            print("✅ OTP code sent successfully to \(email)")
            // Don't set isAuthenticated yet - wait for OTP verification
        } catch {
            print("❌ OTP send failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func verifyOTP(email: String, token: String) async {
        print("🔐 verifyOTP called with email: \(email), token: \(token)")
        isLoading = true
        errorMessage = nil
        
        do {
            let userProfile = try await supabaseService.verifyOTP(email: email, token: token)
            
            // Check if this is a different user than before
            let isDifferentUser = lastUserId != nil && lastUserId != userProfile.id
            print("🔄 User change detected: \(isDifferentUser), Previous: \(lastUserId?.uuidString ?? "nil"), Current: \(userProfile.id.uuidString)")
            
            // Only clear UI state if switching to a different user
            if isDifferentUser {
                print("🧹 Different user detected - clearing UI state")
                await clearUIState()
            } else {
                print("✅ Same user - preserving UI state")
            }
            
            currentUser = userProfile
            lastUserId = userProfile.id // Update the tracked user ID
            isAuthenticated = true
            print("✅ OTP verification successful")
            await loadInitialData()
        } catch {
            print("❌ OTP verification failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // OTP authentication requires explicit verification - no automatic session checking needed
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
            currentUser = nil
            isAuthenticated = false
            journalEntries = []
            currentQuestion = nil
            openQuestionJournalEntries = []
            favoriteJournalEntries = []
            // Don't clear UI state here - let verifyOTP handle it when a different user signs in
            print("🚪 User signed out - UI state preserved for same user re-login")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - UI State Management
    func clearUIState() async {
        print("🧹 Triggering UI state clear for user isolation - shouldClearUIState set to true")
        
        // Try both approaches
        shouldClearUIState = true
        
        // Also call the callback directly if available
        if let callback = clearUIStateCallback {
            print("🧹 Calling UI state clear callback directly")
            callback()
        }
        
        // Give the UI time to process the change before resetting
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        shouldClearUIState = false
        print("🧹 Reset shouldClearUIState to false")
    }
    
    func authenticateTestUser() async {
        let testEmail = "test@example.com"
        
        isLoading = true
        errorMessage = nil
        
        print("🔐 Starting authentication for test user: \(testEmail)")
        
        do {
            // For mock data, just create a test user directly
            print("📝 Creating test user with mock data...")
            try await supabaseService.signUpWithOTP(email: testEmail)
            
            // For mock data, we can directly verify with a dummy OTP
            currentUser = try await supabaseService.verifyOTP(email: testEmail, token: "123456")
            isAuthenticated = true
            await loadInitialData()
            print("✅ Test user authenticated successfully")
        } catch {
            print("❌ Test user authentication failed: \(error.localizedDescription)")
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Data Loading
    private func loadInitialData() async {
        await loadTodaysQuestion()
        await loadJournalEntries()
        await loadOpenQuestionJournalEntries()
        await loadGoals() // Load goals for persistence
        
        // Notify UI to populate state from loaded data
        DispatchQueue.main.async {
            if let callback = self.populateUIStateCallback {
                callback()
            }
        }
    }
    
    func loadGoals() async {
        guard let user = currentUser else { return }
        
        do {
            goals = try await supabaseService.fetchGoals(userId: user.id)
            print("✅ Goals loaded: \(goals.count) goals found")
            if let firstGoal = goals.first {
                print("📝 Most recent goal: \(firstGoal.goals)")
            }
        } catch {
            errorMessage = "Failed to load goals: \(error.localizedDescription)"
            print("❌ Failed to load goals: \(error.localizedDescription)")
        }
    }
    
    func loadTodaysQuestion() async {
        isLoading = true
        
        do {
            guard let user = currentUser else {
                print("❌ loadTodaysQuestion: No current user")
                isLoading = false
                return
            }
            
            // First, load journal entries to check if there's a recent one for today
            let entries = try await supabaseService.fetchJournalEntries(userId: user.id)
            
            // Check if there's a journal entry from today
            let today = Calendar.current.startOfDay(for: Date())
            let todayEntries = entries.filter { entry in
                Calendar.current.isDate(entry.createdAt, inSameDayAs: today)
            }
            
            if let mostRecentTodayEntry = todayEntries.first,
               let guidedQuestionId = mostRecentTodayEntry.guidedQuestionId {
                // Load the guided question that was used for today's entry
                let guidedQuestions = try await supabaseService.fetchGuidedQuestions()
                if let question = guidedQuestions.first(where: { $0.id == guidedQuestionId }) {
                    currentQuestion = question
                    print("✅ loadTodaysQuestion: Loaded question from today's journal entry: \(question.questionText)")
                } else {
                    // Fallback to random question if the specific question isn't found
                    currentQuestion = try await supabaseService.getRandomGuidedQuestion()
                    print("⚠️ loadTodaysQuestion: Couldn't find guided question ID \(guidedQuestionId), using random question")
                }
            } else {
                // No journal entry for today, load a random question
                currentQuestion = try await supabaseService.getRandomGuidedQuestion()
                print("✅ loadTodaysQuestion: No journal entry for today, loaded random question: \(currentQuestion?.questionText ?? "nil")")
            }
            
        } catch {
            // Handle specific error types more gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadTodaysQuestion: Request was cancelled, using fallback question")
                // Don't show error for cancelled requests - just use fallback
                currentQuestion = GuidedQuestion(
                    id: UUID(),
                    questionText: "What thing, person or moment filled you with gratitude today?",
                    isActive: true,
                    orderIndex: 1,
                    createdAt: Date()
                )
            } else {
                errorMessage = "Failed to load today's question: \(error.localizedDescription)"
                print("❌ loadTodaysQuestion error: \(error.localizedDescription)")
                // Fallback to default question
                currentQuestion = GuidedQuestion(
                    id: UUID(),
                    questionText: "What thing, person or moment filled you with gratitude today?",
                    isActive: true,
                    orderIndex: 1,
                    createdAt: Date()
                )
            }
        }
        
        isLoading = false
    }
    
    func loadJournalEntries() async {
        guard let user = currentUser else { return }
        
        do {
            journalEntries = try await supabaseService.fetchJournalEntries(userId: user.id)
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadJournalEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
                print("❌ loadJournalEntries error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Journal Entry Management
    func createJournalEntry(content: String) async {
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        
        guard let user = currentUser else { 
            print("❌❌❌ createJournalEntry: No current user found")
            errorMessage = "No user authenticated"
            return 
        }
        
        print("✅✅✅ createJournalEntry: User found - \(user.id)")
        print("📝📝📝 createJournalEntry: Content - \(content)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // If currentQuestion is nil, try to load a question first
            if currentQuestion == nil {
                print("⚠️ createJournalEntry: currentQuestion is nil, loading a question first")
                await loadTodaysQuestion()
            }
            
            // Create journal entry with current question (or nil if still no question)
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: currentQuestion?.id,
                content: content
            )
            
            print("📝📝📝 createJournalEntry: Created entry with userId: \(entry.userId), guidedQuestionId: \(entry.guidedQuestionId?.uuidString ?? "nil")")
            
            // Save to database
            let savedEntry = try await supabaseService.createJournalEntry(entry)
            
            // Refresh entries
            await loadJournalEntries()
            
            print("✅✅✅ Journal entry saved successfully: \(savedEntry.content)")
            
        } catch {
            print("❌❌❌ Failed to save journal entry: \(error.localizedDescription)")
            errorMessage = "Failed to save journal entry: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // AI functionality removed for now - will be added later
    
    func toggleFavorite(_ entry: JournalEntry) async {
        let updatedEntry = JournalEntry(
            userId: entry.userId,
            guidedQuestionId: entry.guidedQuestionId,
            content: entry.content,
            aiPrompt: entry.aiPrompt,
            aiResponse: entry.aiResponse,
            tags: entry.tags,
            isFavorite: !entry.isFavorite
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    func updateCurrentJournalEntryWithAIPrompt(aiPrompt: String) async {
        // Find the most recent journal entry for the current user
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadJournalEntries()
        
        guard let mostRecentEntry = journalEntries.first else {
            errorMessage = "No journal entry found to update."
            return
        }
        
        // Create updated entry with AI prompt
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id,
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: aiPrompt, // Add the AI prompt
            aiResponse: mostRecentEntry.aiResponse,
            tags: mostRecentEntry.tags,
            isFavorite: mostRecentEntry.isFavorite,
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date() // Update timestamp
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Refresh entries
            print("✅ Journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the journal entry
    func generateAndSaveAIResponse() async {
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadJournalEntries()
            
            guard let mostRecentEntry = journalEntries.first else {
                errorMessage = "No journal entry found to generate AI response."
                return
            }
            
            guard let aiPrompt = mostRecentEntry.aiPrompt, !aiPrompt.isEmpty else {
                errorMessage = "No AI prompt found in journal entry."
                return
            }
            
            print("🤖 Generating AI response for prompt: \(aiPrompt.prefix(100))...")
            
            // Generate AI response using OpenAI
            let aiResponse = try await openAIService.generateAIResponse(for: aiPrompt)
            
            // Create updated entry with AI response
            let updatedEntry = JournalEntry(
                id: mostRecentEntry.id,
                userId: mostRecentEntry.userId,
                guidedQuestionId: mostRecentEntry.guidedQuestionId,
                content: mostRecentEntry.content,
                aiPrompt: mostRecentEntry.aiPrompt,
                aiResponse: aiResponse, // Add the AI response
                tags: mostRecentEntry.tags,
                isFavorite: mostRecentEntry.isFavorite,
                entryType: mostRecentEntry.entryType, // Preserve entry type
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date() // Update timestamp
            )
            
            // Save updated entry to database
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Refresh entries
            
            print("✅ AI response generated and saved: \(aiResponse.prefix(100))...")
            
        } catch {
            errorMessage = "Failed to generate AI response: \(error.localizedDescription)"
            print("❌ Failed to generate AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) async {
        do {
            try await supabaseService.deleteJournalEntry(id: entry.id)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
    
    /// Updates the favorite status of the most recent journal entry
    func updateCurrentJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadJournalEntries()
        
        guard let mostRecentEntry = journalEntries.first else {
            errorMessage = "No journal entry found to update favorite status."
            return
        }
        
        // Create updated entry with the new favorite status
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id, // Use existing ID
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: mostRecentEntry.aiPrompt,
            aiResponse: mostRecentEntry.aiResponse,
            tags: mostRecentEntry.tags,
            isFavorite: isFavorite, // Update favorite status
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date() // Update timestamp
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Reload to reflect changes
            print("✅ Journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update journal entry favorite status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Open Question Journal Entry Management (Duplicate functionality)
    func createOpenQuestionJournalEntry(content: String) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create journal entry with static open question - store in tags for identification
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil, // No actual question ID for open question
                content: content,
                aiPrompt: nil,
                aiResponse: nil,
                tags: ["open_question"], // Tag to identify as open question entry
                isFavorite: false,
                entryType: "open"
            )
            
            // Save to database with special handling for open question
            let savedEntry = try await supabaseService.createOpenQuestionJournalEntry(entry, staticQuestion: "How was your day? Share anything…\nhighs, lows, worries, insights, etc.")
            
            // Refresh entries
            await loadOpenQuestionJournalEntries()
            
            print("Open Question journal entry saved successfully: \(savedEntry.content)")
            
        } catch {
            errorMessage = "Failed to save open question journal entry: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadOpenQuestionJournalEntries() async {
        guard let user = currentUser else { return }
        
        do {
            openQuestionJournalEntries = try await supabaseService.fetchOpenQuestionJournalEntries(userId: user.id)
        } catch {
            errorMessage = "Failed to load open question journal entries: \(error.localizedDescription)"
        }
    }
    
    func updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt: String) async {
        // Find the most recent open question journal entry for the current user
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadOpenQuestionJournalEntries()
        
        guard let mostRecentEntry = openQuestionJournalEntries.first else {
            errorMessage = "No open question journal entry found to update."
            return
        }
        
        // Create updated entry with AI prompt
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id,
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: aiPrompt, // Add the AI prompt
            aiResponse: mostRecentEntry.aiResponse,
            tags: mostRecentEntry.tags,
            isFavorite: mostRecentEntry.isFavorite,
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date() // Update timestamp
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Refresh entries
            print("✅ Open Question journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update open question journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update open question journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the open question journal entry
    func generateAndSaveOpenQuestionAIResponse() async {
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadOpenQuestionJournalEntries()
            
            guard let mostRecentEntry = openQuestionJournalEntries.first else {
                errorMessage = "No open question journal entry found to generate AI response."
                return
            }
            
            guard let aiPrompt = mostRecentEntry.aiPrompt, !aiPrompt.isEmpty else {
                errorMessage = "No AI prompt found in open question journal entry."
                return
            }
            
            print("🤖 Generating Open Question AI response for prompt: \(aiPrompt.prefix(100))...")
            
            // Generate AI response using OpenAI
            let aiResponse = try await openAIService.generateAIResponse(for: aiPrompt)
            
            // Create updated entry with AI response
            let updatedEntry = JournalEntry(
                id: mostRecentEntry.id,
                userId: mostRecentEntry.userId,
                guidedQuestionId: mostRecentEntry.guidedQuestionId,
                content: mostRecentEntry.content,
                aiPrompt: mostRecentEntry.aiPrompt,
                aiResponse: aiResponse, // Add the AI response
                tags: mostRecentEntry.tags,
                isFavorite: mostRecentEntry.isFavorite,
                entryType: mostRecentEntry.entryType, // Preserve entry type
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date() // Update timestamp
            )
            
            // Save updated entry to database
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Refresh entries
            
            print("✅ Open Question AI response generated and saved: \(aiResponse.prefix(100))...")
            
        } catch {
            errorMessage = "Failed to generate open question AI response: \(error.localizedDescription)"
            print("❌ Failed to generate open question AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates the favorite status of the most recent open question journal entry
    func updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadOpenQuestionJournalEntries()
        
        guard let mostRecentEntry = openQuestionJournalEntries.first else {
            errorMessage = "No open question journal entry found to update favorite status."
            return
        }
        
        // Create updated entry with the new favorite status
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id, // Use existing ID
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: mostRecentEntry.aiPrompt,
            aiResponse: mostRecentEntry.aiResponse,
            tags: mostRecentEntry.tags,
            isFavorite: isFavorite, // Update favorite status
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date() // Update timestamp
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Reload to reflect changes
            print("✅ Open Question journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update open question journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update open question journal entry favorite status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Goal Management
    func createGoal(content: String, goals: String) async {
        guard let user = currentUser else { return }
        
        do {
            let goal = Goal(userId: user.id, content: content, goals: goals)
            _ = try await supabaseService.createGoal(goal)
        } catch {
            errorMessage = "Failed to create goal: \(error.localizedDescription)"
        }
    }
    
    func fetchGoals() async -> [Goal] {
        guard let user = currentUser else { return [] }
        do {
            return try await supabaseService.fetchGoals(userId: user.id)
        } catch {
            errorMessage = "Failed to fetch goals: \(error.localizedDescription)"
            return []
        }
    }
    
    func updateGoal(_ goal: Goal) async {
        do {
            _ = try await supabaseService.updateGoal(goal)
        } catch {
            errorMessage = "Failed to update goal: \(error.localizedDescription)"
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        do {
            try await supabaseService.deleteGoal(id: goal.id)
        } catch {
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
        }
    }
    
    func saveGoal(_ goalText: String) async {
        guard let user = currentUser else { return }
        guard !goalText.isEmpty else { return }
        
        do {
            // First, try to get existing goals for this user
            let existingGoals = try await supabaseService.fetchGoals(userId: user.id)
            
            if let existingGoal = existingGoals.first {
                // Update the existing goal - we'll need to modify the existing goal's properties
                // Since we can't directly modify the struct, we'll delete the old one and create a new one
                _ = try await supabaseService.deleteGoal(id: existingGoal.id)
                let newGoal = Goal(userId: user.id, content: existingGoal.content, goals: goalText)
                _ = try await supabaseService.createGoal(newGoal)
                print("✅ Goal updated successfully: \(goalText)")
            } else {
                // Create a new goal if none exists
                let newGoal = Goal(userId: user.id, content: "", goals: goalText)
                _ = try await supabaseService.createGoal(newGoal)
                print("✅ Goal created successfully: \(goalText)")
            }
        } catch {
            errorMessage = "Failed to save goal: \(error.localizedDescription)"
            print("❌ Failed to save goal: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Favorite Journal Entries
    func loadFavoriteEntries() async {
        guard let user = currentUser else { return }
        
        do {
            favoriteJournalEntries = try await supabaseService.fetchFavoriteJournalEntries(userId: user.id)
            print("✅ Loaded \(favoriteJournalEntries.count) favorite entries")
        } catch {
            errorMessage = "Failed to load favorite entries: \(error.localizedDescription)"
            print("❌ Failed to load favorite entries: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Favorite Entry
    func deleteFavoriteEntries(at offsets: IndexSet) async {
        for index in offsets {
            let entry = favoriteJournalEntries[index]
            
            do {
                // Remove from database
                try await supabaseService.removeFavoriteEntry(entryId: entry.id)
                
                // Remove from local array
                await MainActor.run {
                    favoriteJournalEntries.remove(atOffsets: IndexSet([index]))
                }
                
                print("✅ Successfully removed favorite entry: \(entry.id)")
            } catch {
                errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                print("❌ Failed to remove favorite entry: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Question Refresh Functions
    
    func refreshGuidedQuestion() async {
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            return 
        }
        
        do {
            // Create new guided question entry with empty content (preserve history)
            let newEntry = JournalEntry(
                userId: user.id,
                guidedQuestionId: currentQuestion?.id,
                content: "",
                entryType: "guided"
            )
            
            _ = try await supabaseService.createJournalEntry(newEntry)
            print("✅ Created new guided question entry (preserving history)")
            
            // Reload data to reflect changes
            await loadJournalEntries()
            
        } catch {
            errorMessage = "Failed to refresh guided question: \(error.localizedDescription)"
            print("❌ Failed to refresh guided question: \(error.localizedDescription)")
        }
    }
    
    func refreshOpenQuestion() async {
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            return 
        }
        
        do {
            // Create new open question entry with empty content (preserve history)
            let newEntry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil,
                content: "",
                tags: ["open_question"],
                entryType: "open"
            )
            
            _ = try await supabaseService.createOpenQuestionJournalEntry(newEntry, staticQuestion: "How was your day? Share anything…\nhighs, lows, worries, insights, etc.")
            print("✅ Created new open question entry (preserving history)")
            
            // Reload data to reflect changes
            await loadOpenQuestionJournalEntries()
            
        } catch {
            errorMessage = "Failed to refresh open question: \(error.localizedDescription)"
            print("❌ Failed to refresh open question: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Smart Reset Functions (Better than 2AM timer)
    
    func checkAndResetIfNeeded() async {
        guard let user = currentUser else { 
            print("🕐 checkAndResetIfNeeded: No current user, skipping")
            return 
        }
        
        do {
            // Get user's last journal entry date
            let entries = try await supabaseService.fetchJournalEntries(userId: user.id)
            
            guard let lastEntry = entries.max(by: { $0.createdAt < $1.createdAt }) else {
                // No entries yet, nothing to reset
                print("🕐 checkAndResetIfNeeded: No journal entries found, skipping reset")
                return
            }
            
            // Check if it's been past 2AM since last entry
            let calendar = Calendar.current
            let now = Date()
            let lastEntryDate = lastEntry.createdAt
            
            print("🕐 checkAndResetIfNeeded: Last entry at \(lastEntryDate), Current time: \(now)")
            
            // Get 2AM of the day after the last entry
            var components = calendar.dateComponents([.year, .month, .day], from: lastEntryDate)
            components.hour = 2
            components.minute = 0
            components.second = 0
            
            let next2AM = calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
            
            print("🕐 checkAndResetIfNeeded: Next 2AM reset time: \(next2AM)")
            print("🕐 checkAndResetIfNeeded: Is now >= next2AM? \(now >= next2AM)")
            
            // If current time is past the next 2AM, reset the UI
            if now >= next2AM {
                // Check if we've already reset today to prevent multiple resets
                let calendar = Calendar.current
                if let lastReset = lastResetDate,
                   calendar.isDate(lastReset, inSameDayAs: now) {
                    print("🕐 Already reset today at \(lastReset), skipping additional reset")
                    return
                }
                
                print("🕐 It's past 2AM since last entry - resetting UI")
                lastResetDate = now
                await resetUIForNewDay()
            } else {
                print("🕐 Not yet time for reset - skipping")
            }
            
        } catch {
            print("❌ Failed to check reset status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Profile Updates
    
    func updateUserProfile(firstName: String, lastName: String? = nil, notificationFrequency: String? = nil, streakEndingNotification: Bool? = nil) async {
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            return 
        }
        
        do {
            // Update the user's profile in Supabase
            try await supabaseService.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                notificationFrequency: notificationFrequency,
                streakEndingNotification: streakEndingNotification
            )
            
            // Update the local user profile
            currentUser?.firstName = firstName
            
            print("✅ Updated user profile with first name: \(firstName)")
            
        } catch {
            errorMessage = "Failed to update user profile: \(error.localizedDescription)"
            print("❌ Failed to update user profile: \(error.localizedDescription)")
        }
    }
    
    private func resetUIForNewDay() async {
        // Reset UI state without deleting database entries
        // This will be called from ContentView to reset the UI
        print("🔄 Resetting UI for new day (preserving all history)")
        
        // Trigger UI state clear using the callback mechanism
        DispatchQueue.main.async {
            if let callback = self.clearUIStateCallback {
                print("🧹 Calling UI state clear callback for new day reset")
                callback()
            }
        }
    }
}

// OpenAI integration will be added later when requested
