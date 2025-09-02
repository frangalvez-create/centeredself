//
//  ContentView.swift
//  Centered
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var journalViewModel = JournalViewModel()
    @State private var journalResponse: String = ""
    @State private var textEditorHeight: CGFloat = 150
    @State private var showCenteredButton: Bool = false
    @State private var isTextLocked: Bool = false
    @State private var showTextEditDropdown: Bool = false
    @State private var showCenteredButtonClick: Bool = false
    @State private var currentAIResponse: String = ""
    
    var body: some View {
        Group {
            if journalViewModel.isAuthenticated {
                mainJournalView
            } else {
                authenticationView
            }
        }
        .alert("Error", isPresented: .constant(journalViewModel.errorMessage != nil)) {
            Button("OK") {
                journalViewModel.errorMessage = nil
            }
        } message: {
            Text(journalViewModel.errorMessage ?? "")
        }
    }
    
    private var mainJournalView: some View {
        VStack(spacing: 0) {
            // Top Logo (CS Logo.png)
            Image("CS Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(.top, 60)
            
            // Daily Journal Title (DJ.png) - Reduced to 2/3 size
            Image("DJ")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 4)
                .padding(.bottom, 30)
            
            // Guided Question Text - Loaded from Database
            if let currentQuestion = journalViewModel.currentQuestion {
                Text(currentQuestion.questionText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
            } else if journalViewModel.isLoading {
                Text("Loading today's question...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textBlue.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
            } else {
                Text("What thing, person or moment filled you with gratitude today?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
            }
            
            // Text Input Field with Done Button - Dynamic height with proper sizing
            VStack {
                ZStack(alignment: .topLeading) {
                    // Background for the text editor
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.textFieldBackground)
                        .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 250 : max(150, min(250, textEditorHeight)))
                    
                    // Text Editor and AI Response Display
                    if isTextLocked && !currentAIResponse.isEmpty {
                        // Show both journal text and AI response when locked and response is available
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                // Journal text
                                Text(journalResponse)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.textGrey)
                                    .multilineTextAlignment(.leading)
                                
                                // AI Response
                                Text(currentAIResponse)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(red: 63/255, green: 94/255, blue: 130/255)) // Blue #3F5E82
                                    .multilineTextAlignment(.leading)
                                    .padding(.leading, 12) // Indent 3 characters to the right
                            }
                            .padding(.top, 15)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                            .padding(.bottom, 80) // Extra bottom padding to avoid button overlap
                        }
                        .background(Color.clear)
                        .frame(height: 250) // Always use max height when showing AI response
                    } else {
                        // Normal TextEditor when not locked or no AI response
                        TextEditor(text: $journalResponse)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textGrey)
                            .padding(.top, 15)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                            .padding(.bottom, 40) // Extra bottom padding to avoid Done button
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .frame(height: max(150, min(250, textEditorHeight)))
                            .disabled(isTextLocked) // Lock text when Done is pressed
                            .onChange(of: journalResponse) {
                                updateTextEditorHeight()
                            }
                    }
                    
                    // Text Edit Button Centered (only show when text is locked but no AI response)
                    if isTextLocked && currentAIResponse.isEmpty {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                VStack {
                                    Button(action: {
                                        showTextEditDropdown.toggle()
                                    }) {
                                        Image("Text Edit Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                                    .frame(width: 44, height: 44)
                                    
                                    // Dropdown Menu
                                    if showTextEditDropdown {
                                        VStack(spacing: 0) {
                                            Button("Edit Log") {
                                                editLogSelected()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.textFieldBackground)
                                            .foregroundColor(Color.textBlue)
                                            .font(.system(size: 14, weight: .medium))
                                            
                                            Divider()
                                                .background(Color.textBlue.opacity(0.3))
                                            
                                            Button("Delete Log") {
                                                deleteLogSelected()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.textFieldBackground)
                                            .foregroundColor(Color.textBlue)
                                            .font(.system(size: 14, weight: .medium))
                                        }
                                        .background(Color.textFieldBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.textBlue.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(radius: 3)
                                        .offset(y: -10)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.bottom, 5) // 5pt from bottom edge
                        }
                        .frame(height: max(150, min(250, textEditorHeight)))
                    }
                    
                    // Done/Centered Button - Bottom Right
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                if showCenteredButton {
                                    centeredButtonTapped()
                                } else {
                                    doneButtonTapped()
                                }
                            }) {
                                Image(getButtonImageName())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                            }
                            .frame(width: 44, height: 44) // Keep 44x44 touch target
                            .padding(.trailing, 5)
                            .padding(.bottom, 5)
                        }
                    }
                    .frame(height: max(150, min(250, textEditorHeight)))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all, edges: .top)
        .overlay(
            // Loading indicator
            Group {
                if journalViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Saving...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
            }
        )
        .onAppear {
            Task {
                await journalViewModel.loadTodaysQuestion()
            }
        }
    }
    
    private var authenticationView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("CS Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding(.bottom, 20)
            
            Text("Welcome to Centered")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.textBlue)
            
            Text("Sign in to start your journaling journey")
                .font(.body)
                .foregroundColor(Color.textBlue.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 15) {
                Button(action: {
                    // Demo authentication - try to sign up, if user exists, sign in
                    Task {
                        await journalViewModel.authenticateTestUser()
                    }
                }) {
                    Text("Continue as Test User")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.textBlue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Text("This is a demo - no real authentication required")
                    .font(.caption)
                    .foregroundColor(Color.textBlue.opacity(0.6))
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all)
    }
    
    private func updateTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if isTextLocked && !currentAIResponse.isEmpty {
            textEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !journalResponse.isEmpty else {
            textEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth = UIScreen.main.bounds.width - 100 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            textEditorHeight = 150
            return
        }
        
        let boundingRect = journalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        textEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func getButtonImageName() -> String {
        if showCenteredButtonClick {
            return "Centered Button Click"
        } else if showCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func doneButtonTapped() {
        // Change to Centered Button and lock text
        showCenteredButton = true
        isTextLocked = true
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase
        Task {
            await journalViewModel.createJournalEntry(content: journalResponse)
        }
        
        print("Done button tapped - Journal entry saved to Supabase: \(journalResponse)")
        print("Text locked and button changed to Centered Button")
    }
    
    private func centeredButtonTapped() {
        // Change to Centered Button Click state
        showCenteredButtonClick = true
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            await generateAndSaveAIPrompt()
        }
        
        print("Centered button tapped - Generating AI prompt for: \(journalResponse)")
    }
    
    private func generateAndSaveAIPrompt() async {
        // Get the most recent goal from the database
        let goals = await journalViewModel.fetchGoals()
        let mostRecentGoal = goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: journalResponse, goal: mostRecentGoal)
        
        // Update the current journal entry with the AI prompt
        await journalViewModel.updateCurrentJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ AI Prompt generated and saved:")
        print("📝 Content: \(journalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API
        await journalViewModel.generateAndSaveAIResponse()
        
        // Update the AI response in the UI
        await updateAIResponseDisplay()
    }
    
    private func updateAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadJournalEntries()
        
        // Get the most recent entry with AI response
        if let mostRecentEntry = journalViewModel.journalEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.currentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateTextEditorHeight()
            }
            print("✅ AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func createAIPromptText(content: String, goal: String) -> String {
        let aiPromptTemplate = """
Role: You are an AI Behavioral Therapist tasked with acknowledging daily journal logs and providing constructive suggestions or helpful tips. Task: Given search terms related to behavioral science and therapy topics, perform an inquiry in Chat GPT to retrieve information from current behavioral science and therapy sources, and produce a concise summary of the key points.
Input: {content}
Output: Provide only a succinct, information-dense summary capturing the essence of recent behavioral science and therapy sources relevant to the search terms The summary must be concise, in 2 short paragraphs. The first paragraph must empathetically acknowledge and summarize the search term concerns. The second paragraph must provide achievable actions the users can implement to address the concern and the goal to be {goal}. Limit the bulleted actions to no more than 3.
Constraints: Focus on capturing the main points succinctly: complete sentences and in a conversational empathetic tone. Ignore fluff, background information. Do not include your own analysis or opinion. Do not reiterate the input.
Capabilities and Reminders: You have access to the web search tools to find and retrieve behavioral science and therapy related data. Do not label paragraph 1 and 2 in the reply and do not mention the work limits in the reply. Limit the entire response to 100 words.
"""
        
        // Replace {content} and {goal} placeholders
        return aiPromptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{goal}", with: goal)
    }
    
    private func editLogSelected() {
        // Close dropdown
        showTextEditDropdown = false
        
        // Revert to editable state
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        
        // Clear AI response when editing
        currentAIResponse = ""
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Edit Log selected - Text unlocked for editing")
    }
    
    private func deleteLogSelected() {
        // Close dropdown
        showTextEditDropdown = false
        
        // Clear text and revert to initial state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        
        // Clear AI response when deleting
        currentAIResponse = ""
        
        // Reset text editor height
        textEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Delete Log selected - Text cleared and state reset")
    }
}



// Color Extensions
extension Color {
    static let textBlue = Color(hex: "#3F5E82")
    static let backgroundBeige = Color(hex: "#E3E0C9")
    static let textFieldBackground = Color(hex: "#F5F4EB")
    static let textGrey = Color(hex: "#545555")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
