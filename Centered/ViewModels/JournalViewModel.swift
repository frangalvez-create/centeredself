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
    
    private let supabaseService = SupabaseService()
    // OpenAI service will be added later
    
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
    
    private func loadJournalEntries() async {
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
            try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) async {
        do {
            try await supabaseService.deleteJournalEntry(id: entry.id)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
}

// OpenAI integration will be added later when requested
