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
    @Published var followUpQuestionEntries: [JournalEntry] = []
    @Published var analyzerEntries: [AnalyzerEntry] = []
    @Published var currentFollowUpQuestion: String = ""
    @Published var currentRetryAttempt: Int = 1 // Track current retry attempt for UI status
    
    // Callback to clear UI state directly
    var clearUIStateCallback: (() -> Void)?
    
    // Callback to populate UI state from loaded data
    var populateUIStateCallback: (() -> Void)?
    
    // Track the last user ID to detect user changes
    private var lastUserId: UUID?
    
    // Track when we last performed a reset to prevent multiple resets per day
    private var lastResetDate: Date?
    
    let supabaseService = SupabaseService()
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
            analyzerEntries = []
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
        await loadAnalyzerEntries()
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
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadGoals: Request was cancelled, keeping existing goals")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load goals: \(error.localizedDescription)"
                print("❌ Failed to load goals: \(error.localizedDescription)")
            }
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
            
            // Use date-based question selection - all users get the same question each day
            currentQuestion = try await supabaseService.getTodaysGuidedQuestion()
            print("✅ loadTodaysQuestion: Loaded date-based question: \(currentQuestion?.questionText ?? "nil")")
            
        } catch {
            // Handle specific error types more gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadTodaysQuestion: Request was cancelled, keeping existing question")
                // Don't change currentQuestion if request was cancelled - keep existing question
                // This prevents resetting to orderIndex=1 during pull-to-refresh cancellations
            } else {
                errorMessage = "Failed to load today's question: \(error.localizedDescription)"
                print("❌ loadTodaysQuestion error: \(error.localizedDescription)")
                // Only use fallback if we don't have a question yet
                if currentQuestion == nil {
                    currentQuestion = GuidedQuestion(
                        id: UUID(),
                        questionText: "What thing, person or moment filled you with gratitude today?",
                        isActive: true,
                        orderIndex: 1,
                        createdAt: Date()
                    )
                }
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
            
            // Generate AI response using OpenAI with retry logic
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt)
            
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
            errorMessage = "The AI's taking a short break 😅 please try again shortly."
            print("❌ Failed to generate AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Generates AI response with retry logic (up to 3 attempts with exponential backoff)
    private func generateAIResponseWithRetry(for prompt: String, maxRetries: Int = 3) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 AI generation attempt \(attempt)/\(maxRetries)")
                
                // Update UI to show current attempt status
                await MainActor.run {
                    if attempt == 1 {
                        // First attempt - explicitly set to 1 for "Generating..." status
                        self.currentRetryAttempt = 1
                    } else if attempt == 2 {
                        // Second attempt - show "Retrying..."
                        self.currentRetryAttempt = 2
                    } else if attempt == 3 {
                        // Third attempt - show "Retrying again..."
                        self.currentRetryAttempt = 3
                    }
                }
                
                let response = try await openAIService.generateAIResponse(for: prompt)
                
                // Check if response is empty or whitespace-only - treat as failure to retry
                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedResponse.isEmpty {
                    print("⚠️ AI response is empty or whitespace-only, treating as failure for retry")
                    throw OpenAIError.invalidResponse("Empty or whitespace-only response received")
                }
                
                print("✅ AI response successful on attempt \(attempt)")
                
                // Reset retry attempt on success
                await MainActor.run {
                    self.currentRetryAttempt = 1
                }
                
                return response
            } catch {
                lastError = error
                print("❌ AI generation attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry on certain errors
                if let openAIError = error as? OpenAIError {
                    switch openAIError {
                    case .invalidAPIKey, .quotaExceeded:
                        // Reset retry attempt on non-retryable errors
                        await MainActor.run {
                            self.currentRetryAttempt = 1
                        }
                        throw error // Don't retry these errors
                    default:
                        break // Retry other errors
                    }
                }
                
                // Wait before retrying (exponential backoff: 2s, 4s)
                if attempt < maxRetries {
                    let delay: Double = attempt == 1 ? 2.0 : 4.0 // 2s for first retry, 4s for second retry
                    print("⏳ Waiting \(delay) seconds before retry...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // Reset retry attempt on final failure
        await MainActor.run {
            self.currentRetryAttempt = 1
        }
        
        throw lastError ?? AIError.generationFailed
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
            let savedEntry = try await supabaseService.createOpenQuestionJournalEntry(entry, staticQuestion: "Looking at today or yesterday, share moments or thoughts that stood out.")
            
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
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadOpenQuestionJournalEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load open question journal entries: \(error.localizedDescription)"
                print("❌ Failed to load open question journal entries: \(error.localizedDescription)")
            }
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
            
            // Generate AI response using OpenAI with retry logic
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt)
            
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
            errorMessage = "The AI's taking a short break 😅 please try again shortly."
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
    
    // MARK: - Analyzer Stats
    func calculateAnalyzerStats(startDate: Date, endDate: Date) -> AnalyzerStats {
        let calendar = Calendar.current
        let allEntries = journalEntries + openQuestionJournalEntries + followUpQuestionEntries
        
        // Filter entries within date range
        let entriesInRange = allEntries.filter { entry in
            entry.createdAt >= startDate && entry.createdAt <= endDate
        }
        
        // Calculate logs count (unique days with entries)
        let uniqueDays = Set(entriesInRange.map { calendar.startOfDay(for: $0.createdAt) })
        let logsCount = uniqueDays.count
        
        // Calculate streak (consecutive days with entries from endDate backwards)
        let sortedDays = uniqueDays.sorted(by: >)
        var streakCount = 0
        var currentDate = calendar.startOfDay(for: endDate)
        
        for day in sortedDays {
            if calendar.isDate(day, inSameDayAs: currentDate) {
                streakCount += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDay
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        // Calculate favorite log time (time of day with most entries)
        let timeCategories: [(String, Range<Int>)] = [
            ("Early Morning", 2..<7),
            ("Morning", 7..<10),
            ("Mid Day", 10..<14),
            ("Afternoon", 14..<17),
            ("Evening", 17..<21),
            ("Late Evening", 21..<26) // 21-23, 0-2 (wraps around)
        ]
        
        var timeCounts: [String: Int] = [:]
        for entry in entriesInRange {
            let hour = calendar.component(.hour, from: entry.createdAt)
            for (category, range) in timeCategories {
                if range.contains(hour) || (range.lowerBound == 21 && hour < 2) {
                    timeCounts[category, default: 0] += 1
                    break
                }
            }
        }
        
        let favoriteLogTime = timeCounts.max(by: { $0.value < $1.value })?.key ?? "—"
        
        return AnalyzerStats(
            logsCount: logsCount,
            streakCount: streakCount,
            favoriteLogTime: favoriteLogTime
        )
    }
    // MARK: - Analyzer Entries
    func loadAnalyzerEntries() async {
        guard let user = currentUser else { return }
        
        do {
            analyzerEntries = try await supabaseService.fetchAnalyzerEntries()
            print("✅ Analyzer entries loaded: \(analyzerEntries.count) entries found")
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadAnalyzerEntries: Request was cancelled, keeping existing entries")
            } else {
                errorMessage = "Failed to load analyzer entries: \(error.localizedDescription)"
                print("❌ Failed to load analyzer entries: \(error.localizedDescription)")
            }
        }
    }
    
    func updateAnalyzerEntryResponse(entryId: UUID, analyzerAiResponse: String) async {
        do {
            let updated = try await supabaseService.updateAnalyzerEntryResponse(
                entryId: entryId,
                analyzerAiResponse: analyzerAiResponse
            )
            
            if let index = analyzerEntries.firstIndex(where: { $0.id == entryId }) {
                analyzerEntries[index] = updated
            } else {
                analyzerEntries.insert(updated, at: 0)
            }
            print("🧠 Updated analyzer entry response for \(entryId)")
        } catch {
            errorMessage = "Failed to update analyzer entry: \(error.localizedDescription)"
            print("❌ Failed to update analyzer entry: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Streak Calculation
    func calculateEntryStreak() -> Int {
        guard let user = currentUser else { return 0 }
        
        // Get all journal entries for the user, sorted by creation date (newest first)
        let allEntries = journalEntries + openQuestionJournalEntries
        let sortedEntries = allEntries.sorted { $0.createdAt > $1.createdAt }
        
        guard !sortedEntries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        // Start from yesterday to count streak up to yesterday (not including today)
        var currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Start from today and work backwards
        for entry in sortedEntries {
            let entryDate = entry.createdAt
            
            // Check if this entry was created on the current date we're checking
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                streak += 1
                // Move to the previous day
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if entryDate < currentDate {
                // If the entry is older than the current date we're checking, break
                break
            }
        }
        
        print("📊 Calculated entry streak: \(streak) days")
        return streak
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
        
        // Refresh the goals array to reflect the updated goal
        await loadGoals()
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
            
            _ = try await supabaseService.createOpenQuestionJournalEntry(newEntry, staticQuestion: "Looking at today or yesterday, share moments or thoughts that stood out.")
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
                
                // Pre-generate follow-up question if today is a follow-up day
                await preGenerateFollowUpQuestionIfNeeded()
            } else {
                print("🕐 Not yet time for reset - skipping")
            }
            
        } catch {
            print("❌ Failed to check reset status: \(error.localizedDescription)")
        }
    }
    
    /// Pre-generates follow-up question during 2 AM reset if today is a follow-up day
    private func preGenerateFollowUpQuestionIfNeeded() async {
        guard let user = currentUser else { return }
        
        // Check if today is a follow-up question day
        guard supabaseService.isFollowUpQuestionDay() else {
            print("📅 Today is not a follow-up question day - skipping pre-generation")
            return
        }
        
        // Load existing follow-up question entries
        await loadFollowUpQuestionEntries()
        
        // Check if we already have a follow-up question for today
        let calendar = Calendar.current
        let todaysFollowUpEntry = followUpQuestionEntries.first { entry in
            calendar.isDateInToday(entry.createdAt)
        }
        
        if todaysFollowUpEntry != nil {
            print("✅ Follow-up question already exists for today - skipping pre-generation")
            return
        }
        
        // Generate follow-up question in the background
        print("🔮 Pre-generating follow-up question for today...")
        await generateFollowUpQuestion()
        print("✅ Pre-generation complete - follow-up question ready for users")
    }
    
    // MARK: - User Profile Updates
    
    func updateUserProfile(firstName: String? = nil, lastName: String? = nil, gender: String? = nil, occupation: String? = nil, birthdate: String? = nil, notificationFrequency: String? = nil, streakEndingNotification: Bool? = nil) async {
        print("🔄 JournalViewModel: updateUserProfile() called")
        print("   firstName: '\(firstName)'")
        print("   lastName: '\(lastName ?? "nil")'")
        print("   currentUser: \(currentUser?.email ?? "nil")")
        
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            print("❌ JournalViewModel: User not authenticated")
            return 
        }
        
        do {
            print("✅ JournalViewModel: Calling supabaseService.updateUserProfile")
            // Update the user's profile in Supabase
            try await supabaseService.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                occupation: occupation,
                birthdate: birthdate,
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
    
    // MARK: - Follow-Up Question Management
    
    /// Loads follow-up question entries for the current user
    func loadFollowUpQuestionEntries() async {
        guard let user = currentUser else { return }
        
        do {
            let allEntries = try await supabaseService.fetchJournalEntries(userId: user.id)
            print("🔍 Fetched \(allEntries.count) total entries")
            
            // Filter for follow-up entries
            followUpQuestionEntries = allEntries.filter { $0.entryType == "follow_up" }
            
            print("✅ Follow-up question entries loaded: \(followUpQuestionEntries.count) entries")
            
            // Debug: Print all follow-up entries with their details
            for (index, entry) in followUpQuestionEntries.enumerated() {
                let calendar = Calendar.current
                let isToday = calendar.isDate(entry.createdAt, inSameDayAs: Date())
                print("   Entry \(index): entryType=\(entry.entryType ?? "nil"), contentLength=\(entry.content.count), fuqAiResponseLength=\(entry.fuqAiResponse?.count ?? 0), isToday=\(isToday)")
                if let fuqAiResponse = entry.fuqAiResponse {
                    print("      Question: \(fuqAiResponse.prefix(50))...")
                }
            }
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadFollowUpQuestionEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load follow-up question entries: \(error.localizedDescription)"
                print("❌ Failed to load follow-up question entries: \(error.localizedDescription)")
            }
        }
    }
    
    /// Checks if today is a follow-up question day and loads/generates the question
    /// - Parameter suppressErrors: If true, errors will be logged but not shown to the user (useful for background operations like pull-to-refresh)
    func checkAndLoadFollowUpQuestion(suppressErrors: Bool = false) async {
        guard let user = currentUser else { 
            print("⚠️ checkAndLoadFollowUpQuestion: User not authenticated")
            return 
        }
        
        // Check if today is a follow-up question day
        guard supabaseService.isFollowUpQuestionDay() else {
            print("📅 Today is not a follow-up question day")
            // Clear follow-up question if it's not a follow-up day
            currentFollowUpQuestion = ""
            return
        }
        
        // Load existing follow-up question entries for today
        // Retry up to 3 times with delays to account for database write delays/race conditions
        var retryCount = 0
        let maxRetries = 3
        var todaysEntries: [JournalEntry] = []
        let calendar = Calendar.current
        let today = Date()
        
        while retryCount < maxRetries {
            await loadFollowUpQuestionEntries()
            
            print("🔍 Searching for today's follow-up question (attempt \(retryCount + 1)/\(maxRetries))... Found \(followUpQuestionEntries.count) total follow-up entries")
            
            // Check if we already have a follow-up question for today
            // First, try to find an entry created today with a non-empty fuqAiResponse
            // Prioritize entries with empty content (the question entry, not the user response entry)
            todaysEntries = followUpQuestionEntries.filter { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: today)
            }
            
            print("📅 Found \(todaysEntries.count) follow-up entries created today")
            
            // If we found entries for today, break out of retry loop
            if !todaysEntries.isEmpty {
                break
            }
            
            // If no entries found and not last attempt, wait and retry
            if retryCount < maxRetries - 1 {
                print("⏳ No entries found, waiting 0.5s before retry...")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            }
            
            retryCount += 1
        }
        
        // Debug: Print details of today's entries before filtering
        for (index, entry) in todaysEntries.enumerated() {
            print("   Today's entry \(index): entryType=\(entry.entryType ?? "nil"), contentLength=\(entry.content.count), fuqAiResponseLength=\(entry.fuqAiResponse?.count ?? 0)")
            if let fuqAiResponse = entry.fuqAiResponse {
                print("      Question: \(fuqAiResponse.prefix(50))...")
            }
        }
        
        // Sort by creation time (oldest first) to get the question entry first
        let sortedTodaysEntries = todaysEntries.sorted { $0.createdAt < $1.createdAt }
        
        // Look for an entry with non-empty fuqAiResponse
        // Prioritize entries with empty content (the question entry) over entries with content (user response)
        var todaysFollowUpEntry: JournalEntry?
        
        // First, try to find an entry with empty content (the question entry)
        if let questionEntry = sortedTodaysEntries.first(where: { entry in
            let hasEmptyContent = entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if let fuqAiResponse = entry.fuqAiResponse, !fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if hasEmptyContent {
                    print("✅ Found follow-up question entry (empty content): \(fuqAiResponse.prefix(50))...")
                    return true
                }
            }
            return false
        }) {
            todaysFollowUpEntry = questionEntry
        } else {
            // Fallback: Find any entry with non-empty fuqAiResponse
            todaysFollowUpEntry = sortedTodaysEntries.first { entry in
                if let fuqAiResponse = entry.fuqAiResponse, !fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("✅ Found follow-up question entry (with content): \(fuqAiResponse.prefix(50))...")
                    return true
                }
                return false
            }
        }
        
        if let existingEntry = todaysFollowUpEntry, let fuqAiResponse = existingEntry.fuqAiResponse, !fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Use existing follow-up question (pre-generated during 2 AM reset or generated earlier)
            currentFollowUpQuestion = fuqAiResponse
            print("✅ Using existing follow-up question: \(currentFollowUpQuestion.prefix(50))...")
        } else {
            print("⚠️ No pre-generated follow-up question found for today")
            print("🔍 DEBUG: Why no entry found?")
            print("   - Total follow-up entries: \(followUpQuestionEntries.count)")
            print("   - Today's entries: \(todaysEntries.count)")
            print("   - Sorted entries: \(sortedTodaysEntries.count)")
            
            // Debug: Print why no entry was found
            if todaysEntries.isEmpty {
                print("   ❌ NO ENTRIES FOUND FOR TODAY - This is the problem!")
            } else {
                print("   ❌ ENTRIES EXIST BUT NOT SELECTED:")
                for (index, entry) in sortedTodaysEntries.enumerated() {
                    print("      Entry \(index): contentLength=\(entry.content.count), hasFuqAiResponse=\(entry.fuqAiResponse != nil)")
                    if let fuqAiResponse = entry.fuqAiResponse {
                        print("         fuqAiResponse: \(fuqAiResponse.prefix(50))...")
                    } else {
                        print("         fuqAiResponse is NIL")
                    }
                }
            }
            
            // Only generate if we don't already have a question loaded
            if currentFollowUpQuestion.isEmpty {
                print("🔄 Generating new follow-up question...")
                await generateFollowUpQuestion(suppressErrors: suppressErrors)
            } else {
                print("✅ Keeping existing follow-up question in memory: \(currentFollowUpQuestion.prefix(50))...")
            }
        }
    }
    
    /// Generates a new follow-up question based on past journal entries
    /// - Parameter suppressErrors: If true, errors will be logged but not shown to the user (useful for background operations like pull-to-refresh)
    private func generateFollowUpQuestion(suppressErrors: Bool = false) async {
        guard let user = currentUser else { return }
        
        // SAFEGUARD: Double-check that we don't already have a follow-up question for today
        // This prevents duplicate generation if the initial check somehow missed it
        await loadFollowUpQuestionEntries()
        let calendar = Calendar.current
        let today = Date()
        let existingTodayEntry = followUpQuestionEntries.first { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: today) &&
            entry.fuqAiResponse != nil &&
            !entry.fuqAiResponse!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if let existingEntry = existingTodayEntry, let fuqAiResponse = existingEntry.fuqAiResponse, !fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🛡️ SAFEGUARD: Found existing follow-up question for today, skipping generation to prevent duplicate")
            print("   Existing question: \(fuqAiResponse.prefix(50))...")
            currentFollowUpQuestion = fuqAiResponse
            return
        }
        
        print("✅ No existing follow-up question found for today, proceeding with generation")
        
        do {
            // Select a past journal entry for follow-up
            guard let pastEntry = try await supabaseService.selectPastJournalEntryForFollowUp(userId: user.id) else {
                print("⚠️ No eligible past entry found for follow-up question")
                return
            }
            
            // Generate the follow-up question prompt
            let fuqAiPrompt = supabaseService.generateFollowUpQuestionPrompt(pastEntry: pastEntry)
            
            // Generate the follow-up question using OpenAI with retry logic (2s, 4s delays)
            let fuqAiResponse = try await generateAIResponseWithRetry(for: fuqAiPrompt)
            
            // Create the follow-up question entry
            let followUpEntry = try await supabaseService.createFollowUpQuestionEntry(
                userId: user.id,
                fuqAiPrompt: fuqAiPrompt,
                fuqAiResponse: fuqAiResponse
            )
            
            // Mark the selected past entry as used for follow-up
            try await supabaseService.markEntryAsUsedForFollowUp(entryId: pastEntry.id)
            
            // CRITICAL: Wait for database write to complete and verify it was saved
            // Add a small delay to ensure the database transaction has committed
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            // Reload follow-up question entries to ensure we have the latest data
            await loadFollowUpQuestionEntries()
            
            // Verify the entry was actually saved by checking for it
            let calendar = Calendar.current
            let today = Date()
            let savedEntry = followUpQuestionEntries.first { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: today) &&
                entry.fuqAiResponse == fuqAiResponse
            }
            
            if savedEntry == nil {
                print("⚠️ WARNING: Generated follow-up question was not found after save, retrying reload...")
                // Retry reload once more after a brief delay
                try await Task.sleep(nanoseconds: 500_000_000) // Another 0.5 second
                await loadFollowUpQuestionEntries()
            }
            
            // Update the current follow-up question
            currentFollowUpQuestion = fuqAiResponse
            
            print("✅ Generated new follow-up question: \(fuqAiResponse)")
            print("✅ Marked past entry as used for follow-up: \(pastEntry.id)")
            print("✅ Follow-up question entries reloaded: \(followUpQuestionEntries.count) entries")
            
        } catch {
            // Only show error message if not suppressed (e.g., during pull-to-refresh)
            if !suppressErrors {
                errorMessage = "The AI's taking a short break 😅 please try again shortly."
            }
            print("❌ Failed to generate follow-up question: \(error.localizedDescription)")
            if suppressErrors {
                print("⚠️ Error suppressed - not showing alert to user (background operation)")
            }
        }
    }
    
    /// Creates a follow-up question journal entry
    func createFollowUpQuestionJournalEntry(content: String) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create journal entry with follow-up question type
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil,
                content: content,
                tags: ["follow_up"],
                entryType: "follow_up",
                fuqAiPrompt: nil,
                fuqAiResponse: currentFollowUpQuestion,
                isFollowUpDay: true
            )
            
            _ = try await supabaseService.createJournalEntry(entry)
            await loadFollowUpQuestionEntries()
            print("✅ Follow-up question journal entry created")
            
        } catch {
            errorMessage = "Failed to create follow-up question journal entry: \(error.localizedDescription)"
            print("❌ Failed to create follow-up question journal entry: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates a follow-up question journal entry with AI prompt
    func updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt: String) async {
        guard let user = currentUser else { return }
        
        // Load current entries to find the most recent one
        await loadFollowUpQuestionEntries()
        
        guard let mostRecentEntry = followUpQuestionEntries.first else {
            errorMessage = "No follow-up question journal entry found to update."
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
            entryType: mostRecentEntry.entryType,
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Refresh entries
            print("✅ Follow-up question journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update follow-up question journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update follow-up question journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the follow-up question journal entry
    func generateAndSaveFollowUpQuestionAIResponse() async {
        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadFollowUpQuestionEntries()
            
            guard let mostRecentEntry = followUpQuestionEntries.first,
                  let aiPrompt = mostRecentEntry.aiPrompt else {
                errorMessage = "No follow-up question journal entry or AI prompt found."
                isLoading = false
                return
            }
            
            // Generate AI response using OpenAI with retry logic
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt)
            
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
                entryType: mostRecentEntry.entryType,
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date(), // Update timestamp
                fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
                fuqAiResponse: mostRecentEntry.fuqAiResponse,
                isFollowUpDay: mostRecentEntry.isFollowUpDay
            )
            
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Refresh entries
            
            print("✅ Follow-up question AI response generated and saved")
            
        } catch {
            errorMessage = "The AI's taking a short break 😅 please try again shortly."
            print("❌ Failed to generate follow-up question AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates the favorite status of the current follow-up question journal entry
    func updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard let user = currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadFollowUpQuestionEntries()
        
        guard let mostRecentEntry = followUpQuestionEntries.first else {
            errorMessage = "No follow-up question journal entry found to update favorite status."
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
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Reload to reflect changes
            print("✅ Follow-up question journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update follow-up question journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update follow-up question journal entry favorite status: \(error.localizedDescription)")
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
    
    // MARK: - Analyzer Entry Functions
    
    /// Determines if analysis should be weekly or monthly based on date
    func determineAnalysisType(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        // Check if today is the last Sunday of the month
        let lastSundayOfMonth = findLastSundayOfMonth(for: today)
        if let lastSunday = lastSundayOfMonth, calendar.isDate(today, inSameDayAs: lastSunday) {
            return "monthly"
        }
        
        // Otherwise, use weekly analysis
        return "weekly"
    }
    
    /// Finds the last Sunday of the month for a given date
    private func findLastSundayOfMonth(for date: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return nil
        }
        
        // Find the last Sunday of the month
        for day in range.reversed() {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                if calendar.component(.weekday, from: date) == 1 { // Sunday
                    return date
                }
            }
        }
        
        return nil
    }
    
    /// Checks if user has enough entries for analysis
    func checkAnalyzerEligibility(analysisType: String, startDate: Date, endDate: Date) async throws -> (isEligible: Bool, entryCount: Int, minimumRequired: Int) {
        let entries = try await supabaseService.fetchJournalEntriesForAnalyzer(startDate: startDate, endDate: endDate)
        
        // Count unique days with entries
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let entryCount = uniqueDays.count
        
        // Determine minimum required based on analysis type
        let minimumRequired = analysisType == "monthly" ? 9 : 2
        
        let isEligible = entryCount >= minimumRequired
        
        return (isEligible, entryCount, minimumRequired)
    }
    
    /// Creates a new analyzer entry and generates AI response
    func createAnalyzerEntry(analysisType: String) async throws {
        guard let user = currentUser else {
            throw AIError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        currentRetryAttempt = 1
        
        do {
            // Determine date range based on analysis type
            let dateRange: (start: Date, end: Date)
            if analysisType == "monthly" {
                dateRange = supabaseService.calculateDateRangeForMonthlyAnalysis()
            } else {
                dateRange = supabaseService.calculateDateRangeForWeeklyAnalysis()
            }
            
            // Check eligibility
            let eligibility = try await checkAnalyzerEligibility(
                analysisType: analysisType,
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            if !eligibility.isEligible {
                let message = analysisType == "monthly"
                    ? "Sorry, a minimum of \"nine days\" of journal entries is needed to run the monthly analysis."
                    : "Sorry, a minimum of \"two days\" of journal entries is needed to run the weekly analysis. Try again next week"
                throw NSError(domain: "AnalyzerError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
            }
            
            // Fetch journal entries for the date range
            let entries = try await supabaseService.fetchJournalEntriesForAnalyzer(
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            // Combine all entry content
            let content = entries.map { $0.content }.joined(separator: "\n\n")
            
            // Generate analyzer prompt
            let analyzerPrompt: String
            if analysisType == "monthly" {
                analyzerPrompt = supabaseService.generateMonthlyAnalyzerPrompt(content: content)
            } else {
                analyzerPrompt = supabaseService.generateWeeklyAnalyzerPrompt(content: content)
            }
            
            // Create analyzer entry with prompt (no response yet)
            let analyzerEntry = AnalyzerEntry(
                userId: user.id,
                analyzerAiPrompt: analyzerPrompt,
                analyzerAiResponse: nil,
                entryType: analysisType,
                tags: [],
                createdAt: Date(),
                updatedAt: nil
            )
            
            // Save analyzer entry to database
            let createdEntry = try await supabaseService.createAnalyzerEntry(analyzerEntry)
            
            // Generate AI response with retry logic
            let aiResponse = try await generateAIResponseWithRetry(for: analyzerPrompt)
            
            // Update analyzer entry with AI response
            let updatedEntry = AnalyzerEntry(
                id: createdEntry.id,
                userId: createdEntry.userId,
                analyzerAiPrompt: createdEntry.analyzerAiPrompt,
                analyzerAiResponse: aiResponse,
                entryType: createdEntry.entryType,
                tags: createdEntry.tags,
                createdAt: createdEntry.createdAt,
                updatedAt: Date()
            )
            
            _ = try await supabaseService.updateAnalyzerEntry(updatedEntry)
            
            // Reload analyzer entries to update UI
            await loadAnalyzerEntries()
            
            print("✅ Analyzer entry created and AI response generated successfully")
            
        } catch {
            errorMessage = "The AI's taking a short break 😅 please try again shortly."
            print("❌ Failed to create analyzer entry: \(error.localizedDescription)")
            throw error
        }
        
        isLoading = false
    }
}

struct AnalyzerStats {
    let logsCount: Int
    let streakCount: Int
    let favoriteLogTime: String
}

// MARK: - AI Error Types
enum AIError: Error, LocalizedError {
    case userNotAuthenticated
    case noJournalEntry
    case noAIPrompt
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .noJournalEntry:
            return "No journal entry found to generate AI response"
        case .noAIPrompt:
            return "No AI prompt found in journal entry"
        case .generationFailed:
            return "AI generation failed after multiple attempts"
        }
    }
}
