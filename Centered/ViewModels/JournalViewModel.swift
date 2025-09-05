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
    
    private let supabaseService = SupabaseService()
    private let openAIService = OpenAIService()
    
    init() {
        // Start with not authenticated for testing
        isAuthenticated = false
    }
    
    // MARK: - Authentication
    func checkAuthenticationStatus() async {
        if let userId = supabaseService.getCurrentUserId() {
            do {
                currentUser = try await supabaseService.getUserProfile(userId: userId)
                isAuthenticated = true
                await loadInitialData()
            } catch {
                print("Error loading user profile: \(error)")
                isAuthenticated = false
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await supabaseService.signIn(email: email, password: password)
            isAuthenticated = true
            await loadInitialData()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await supabaseService.signUp(email: email, password: password)
            isAuthenticated = true
            await loadInitialData()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
            currentUser = nil
            isAuthenticated = false
            journalEntries = []
            currentQuestion = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func authenticateTestUser() async {
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        isLoading = true
        errorMessage = nil
        
        print("🔐 Starting authentication for test user: \(testEmail)")
        
        do {
            // Try to sign up first (creates user if doesn't exist)
            print("📝 Attempting to sign up test user...")
            currentUser = try await supabaseService.signUp(email: testEmail, password: testPassword)
            isAuthenticated = true
            await loadInitialData()
            print("✅ Test user created and signed in successfully")
        } catch let signUpError {
            // If sign up fails (user might already exist), try to sign in
            print("❌ Sign up failed: \(signUpError.localizedDescription)")
            print("🔄 Trying to sign in existing user...")
            
            do {
                currentUser = try await supabaseService.signIn(email: testEmail, password: testPassword)
                isAuthenticated = true
                await loadInitialData()
                print("✅ Test user signed in successfully")
            } catch let signInError {
                print("❌ Sign in also failed: \(signInError.localizedDescription)")
                print("🔍 Sign up error details: \(signUpError)")
                print("🔍 Sign in error details: \(signInError)")
                
                // Provide more specific error messages
                if signUpError.localizedDescription.contains("Email rate limit") {
                    errorMessage = "Too many signup attempts. Please wait a moment and try again."
                } else if signUpError.localizedDescription.contains("email") && signInError.localizedDescription.contains("credentials") {
                    errorMessage = "Authentication setup issue. Please check Supabase configuration."
                } else {
                    errorMessage = "Authentication failed. Sign up: \(signUpError.localizedDescription). Sign in: \(signInError.localizedDescription)"
                }
                
                isAuthenticated = false
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Data Loading
    private func loadInitialData() async {
        await loadTodaysQuestion()
        await loadJournalEntries()
    }
    
    func loadTodaysQuestion() async {
        isLoading = true
        
        do {
            currentQuestion = try await supabaseService.getRandomGuidedQuestion()
        } catch {
            errorMessage = "Failed to load today's question: \(error.localizedDescription)"
            // Fallback to default question
            currentQuestion = GuidedQuestion(
                id: UUID(),
                questionText: "What thing, person or moment filled you with gratitude today?",
                isActive: true,
                orderIndex: 1,
                createdAt: Date()
            )
        }
        
        isLoading = false
    }
    
    func loadJournalEntries() async {
        guard let user = currentUser else { return }
        
        do {
            journalEntries = try await supabaseService.fetchJournalEntries(userId: user.id)
        } catch {
            errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Journal Entry Management
    func createJournalEntry(content: String) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create journal entry with current question
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: currentQuestion?.id,
                content: content
            )
            
            // Save to database
            let savedEntry = try await supabaseService.createJournalEntry(entry)
            
            // Refresh entries
            await loadJournalEntries()
            
            print("Journal entry saved successfully: \(savedEntry.content)")
            
        } catch {
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
                isFavorite: false
            )
            
            // Save to database with special handling for open question
            let savedEntry = try await supabaseService.createOpenQuestionJournalEntry(entry, staticQuestion: "Share anything... fears, goals, confusions, delights, etc")
            
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
}

// OpenAI integration will be added later when requested
