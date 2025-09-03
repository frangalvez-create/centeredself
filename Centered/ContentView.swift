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
    @State private var showFavoriteButton: Bool = false
    @State private var isFavoriteClicked: Bool = false
    
    // OPEN QUESTION SECTION STATE (Duplicate all state variables)
    @State private var openJournalResponse: String = ""
    @State private var openTextEditorHeight: CGFloat = 150
    @State private var openShowCenteredButton: Bool = false
    @State private var openIsTextLocked: Bool = false
    @State private var openShowTextEditDropdown: Bool = false
    @State private var openShowCenteredButtonClick: Bool = false
    @State private var openCurrentAIResponse: String = ""
    @State private var openShowFavoriteButton: Bool = false
    @State private var openIsFavoriteClicked: Bool = false
    
    // Navigation Tab Selection
    @State private var selectedTab: Int = 0
    
    // Centered Page Goal Text
    @State private var goalText: String = ""
    @State private var isGoalLocked: Bool = false
    @State private var showCPRefreshButton: Bool = false
    
    var body: some View {
        Group {
            if journalViewModel.isAuthenticated {
                VStack(spacing: 0) {
                    // Main Content Area
                    Group {
                        switch selectedTab {
                        case 0:
                            mainJournalView
                        case 1:
                            centeredPageView
                        case 2:
                            favoritesPageView
                        case 3:
                            profilePageView
                        default:
                            mainJournalView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar
                    customTabBar
                }
                .background(Color(hex: "E3E0C9"))
                .ignoresSafeArea(.all)
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
        ScrollView {
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
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Journal text
                                    Text(journalResponse)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.textGrey)
                                        .multilineTextAlignment(.leading)
                                        .id("journalTextStart") // Identifier for scrolling to top
                                    
                                    // AI Response
                                    Text(currentAIResponse)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(red: 63/255, green: 94/255, blue: 130/255)) // Blue #3F5E82
                                        .multilineTextAlignment(.leading)
                                        .padding(.leading, 12) // Indent 3 characters to the right
                                        .id("aiResponseEnd") // Identifier for scroll detection
                                }
                                .padding(.top, 5)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.bottom, 40) // Reduced bottom padding
                            }
                            .background(Color.clear)
                            .onAppear {
                                // Scroll to TOP when AI response appears (not bottom)
                                withAnimation {
                                    proxy.scrollTo("journalTextStart", anchor: .top)
                                }
                                // Show favorite button after a delay to ensure scroll is complete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showFavoriteButton = true
                                }
                            }
                        }
                        .frame(height: 250) // Always use max height when showing AI response
                        .clipped() // Ensure content doesn't extend beyond container
                        .overlay(
                            // Bottom fade mask to prevent text overlap with favorite button
                            VStack {
                                Spacer()
                                // Gradient mask with proper rounded bottom corners
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0.0),
                                        .init(color: Color.textFieldBackground, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 55) // Increased to 55pt
                                .clipShape(
                                    // Custom shape that matches the bottom rounded corners of the text field
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 20,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: 0
                                    )
                                )
                            }
                        )
                    } else {
                        // Normal TextEditor when not locked or no AI response
                        TextEditor(text: $journalResponse)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textGrey)
                            .padding(.top, 5)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                            .padding(.bottom, 30) // Extra bottom padding to avoid Done button
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
                    
                    // Done/Centered Button - Bottom Right (hidden when AI response is present)
                    if currentAIResponse.isEmpty {
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
                    }
                    
                    // Favorite Button (only when AI response is present and scrolled to bottom)
                    if !currentAIResponse.isEmpty && showFavoriteButton {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    favoriteButtonTapped()
                                }) {
                                    Image(isFavoriteClicked ? "Fav Button Click" : "Fav Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                }
                                .frame(width: 44, height: 44) // Keep 44x44 touch target
                                .padding(.trailing, 5)
                                .padding(.bottom, 0) // Reduced from 5pt to 0pt to position closer to bottom edge
                            }
                        }
                    }
                }
                .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 250 : max(150, min(250, textEditorHeight)))
            }
            .padding(.horizontal, 30)
            
            // OPEN QUESTION SECTION (25pt spacing below Guided Question)
            VStack(spacing: 0) {
                // Static Open Question Text
                Text("Share anything... fears, goals, confusions, delights, etc")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
                    .padding(.top, 25) // 25pt spacing below Guided Question
                
                // Open Question Text Input Field with Done Button - Dynamic height with proper sizing
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Background for the text editor
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.textFieldBackground)
                            .frame(height: (openIsTextLocked && !openCurrentAIResponse.isEmpty) ? 250 : max(150, min(250, openTextEditorHeight)))
                        
                        // Text Editor and AI Response Display
                        if openIsTextLocked && !openCurrentAIResponse.isEmpty {
                            // Show both journal text and AI response when locked and response is available
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Journal text
                                        Text(openJournalResponse)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.textGrey)
                                            .multilineTextAlignment(.leading)
                                            .id("openJournalTextStart") // Identifier for scrolling to top
                                        
                                        // AI Response
                                        Text(openCurrentAIResponse)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(red: 63/255, green: 94/255, blue: 130/255)) // Blue #3F5E82
                                            .multilineTextAlignment(.leading)
                                            .padding(.leading, 12) // Indent 3 characters to the right
                                            .id("openAIResponseEnd") // Identifier for scroll detection
                                    }
                                    .padding(.top, 5)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                                    .padding(.bottom, 40) // Reduced bottom padding
                                }
                                .background(Color.clear)
                                .onAppear {
                                    // Scroll to TOP when AI response appears (not bottom)
                                    withAnimation {
                                        proxy.scrollTo("openJournalTextStart", anchor: .top)
                                    }
                                    // Show favorite button after a delay to ensure scroll is complete
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        openShowFavoriteButton = true
                                    }
                                }
                            }
                            .frame(height: 250) // Always use max height when showing AI response
                            .clipped() // Ensure content doesn't extend beyond container
                            .overlay(
                                // Bottom fade mask to prevent text overlap with favorite button
                                VStack {
                                    Spacer()
                                    // Gradient mask with proper rounded bottom corners
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.clear, location: 0.0),
                                            .init(color: Color.textFieldBackground, location: 1.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 55) // Same 55pt height as Guided Question
                                    .clipShape(
                                        // Custom shape that matches the bottom rounded corners of the text field
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 0,
                                            bottomLeadingRadius: 20,
                                            bottomTrailingRadius: 20,
                                            topTrailingRadius: 0
                                        )
                                    )
                                }
                            )
                        } else {
                            // Normal TextEditor when not locked or no AI response
                            TextEditor(text: $openJournalResponse)
                                .font(.system(size: 16))
                                .foregroundColor(Color.textGrey)
                                .padding(.top, 5)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.bottom, 30) // Extra bottom padding to avoid Done button
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .frame(height: max(150, min(250, openTextEditorHeight)))
                                .disabled(openIsTextLocked) // Lock text when Done is pressed
                                .onChange(of: openJournalResponse) {
                                    updateOpenTextEditorHeight()
                                }
                        }
                        
                        // Text Edit Button Centered (only show when text is locked but no AI response)
                        if openIsTextLocked && openCurrentAIResponse.isEmpty {
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    
                                    VStack {
                                        Button(action: {
                                            openShowTextEditDropdown.toggle()
                                        }) {
                                            Image("Text Edit Button")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 28)
                                        }
                                        .frame(width: 44, height: 44)
                                        
                                        // Dropdown Menu
                                        if openShowTextEditDropdown {
                                            VStack(spacing: 0) {
                                                Button("Edit Log") {
                                                    openEditLogSelected()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(Color.textFieldBackground)
                                                .foregroundColor(Color.textBlue)
                                                .font(.system(size: 14, weight: .medium))
                                                
                                                Divider()
                                                    .background(Color.textBlue.opacity(0.3))
                                                
                                                Button("Delete Log") {
                                                    openDeleteLogSelected()
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
                            .frame(height: max(150, min(250, openTextEditorHeight)))
                        }
                        
                        // Done/Centered Button - Bottom Right (hidden when AI response is present)
                        if openCurrentAIResponse.isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if openShowCenteredButton {
                                            openCenteredButtonTapped()
                                        } else {
                                            openDoneButtonTapped()
                                        }
                                    }) {
                                        Image(getOpenButtonImageName())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                                    .frame(width: 44, height: 44) // Keep 44x44 touch target
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                        
                        // Favorite Button (only when AI response is present and scrolled to bottom)
                        if !openCurrentAIResponse.isEmpty && openShowFavoriteButton {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        openFavoriteButtonTapped()
                                    }) {
                                        Image(openIsFavoriteClicked ? "Fav Button Click" : "Fav Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                                    .frame(width: 44, height: 44) // Keep 44x44 touch target
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 0) // Reduced from 5pt to 0pt to position closer to bottom edge
                                }
                            }
                        }
                    }
                    .frame(height: (openIsTextLocked && !openCurrentAIResponse.isEmpty) ? 250 : max(150, min(250, openTextEditorHeight)))
                }
                .padding(.horizontal, 30)
            }
            
            // Add bottom padding for future navigation tabs
            Spacer(minLength: 100) // Extra space at bottom for navigation tabs
            }
            .padding(.bottom, 50) // Additional padding for navigation tabs
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
        showFavoriteButton = false
        isFavoriteClicked = false
        
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
        showFavoriteButton = false
        isFavoriteClicked = false
        
        // Reset text editor height
        textEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Delete Log selected - Text cleared and state reset")
    }
    
    private func favoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !isFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        isFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Favorite button clicked - Journal entry marked as favorite")
    }
    
    // MARK: - OPEN QUESTION HELPER FUNCTIONS (Duplicated from Guided Question)
    
    private func updateOpenTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if openIsTextLocked && !openCurrentAIResponse.isEmpty {
            openTextEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !openJournalResponse.isEmpty else {
            openTextEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth = UIScreen.main.bounds.width - 100 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            openTextEditorHeight = 150
            return
        }
        
        let boundingRect = openJournalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        openTextEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func getOpenButtonImageName() -> String {
        if openShowCenteredButtonClick {
            return "Centered Button Click"
        } else if openShowCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func openDoneButtonTapped() {
        // Change to Centered Button and lock text
        openShowCenteredButton = true
        openIsTextLocked = true
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase with static question
        Task {
            await journalViewModel.createOpenQuestionJournalEntry(content: openJournalResponse)
        }
        
        print("Open Done button tapped - Journal entry saved to Supabase: \(openJournalResponse)")
        print("Open Text locked and button changed to Centered Button")
    }
    
    private func openCenteredButtonTapped() {
        // Change to Centered Button Click state
        openShowCenteredButtonClick = true
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            await generateAndSaveOpenAIPrompt()
        }
        
        print("Open Centered button tapped - Generating AI prompt for: \(openJournalResponse)")
    }
    
    private func generateAndSaveOpenAIPrompt() async {
        // Get the most recent goal from the database
        let goals = await journalViewModel.fetchGoals()
        let mostRecentGoal = goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: openJournalResponse, goal: mostRecentGoal)
        
        // Update the current open question journal entry with the AI prompt
        await journalViewModel.updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ Open AI Prompt generated and saved:")
        print("📝 Content: \(openJournalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API
        await journalViewModel.generateAndSaveOpenQuestionAIResponse()
        
        // Update the AI response in the UI
        await updateOpenAIResponseDisplay()
    }
    
    private func updateOpenAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadOpenQuestionJournalEntries()
        
        // Get the most recent open question entry with AI response
        if let mostRecentEntry = journalViewModel.openQuestionJournalEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.openCurrentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateOpenTextEditorHeight()
            }
            print("✅ Open AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func openEditLogSelected() {
        // Close dropdown
        openShowTextEditDropdown = false
        
        // Revert to editable state
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        
        // Clear AI response when editing
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Open Edit Log selected - Text unlocked for editing")
    }
    
    private func openDeleteLogSelected() {
        // Close dropdown
        openShowTextEditDropdown = false
        
        // Clear text and revert to initial state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        
        // Clear AI response when deleting
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        
        // Reset text editor height
        openTextEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Open Delete Log selected - Text cleared and state reset")
    }
    
    private func openFavoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !openIsFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        openIsFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Open Favorite button clicked - Journal entry marked as favorite")
    }
    
    // MARK: - Goal Button Actions
    
    private func cpDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isGoalLocked = true
        showCPRefreshButton = true
        
        // Save goal to database
        Task {
            await journalViewModel.saveGoal(goalText)
        }
        
        print("CP Done button clicked - Goal saved: \(goalText)")
    }
    
    private func cpRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the goal entry process
        goalText = ""
        isGoalLocked = false
        showCPRefreshButton = false
        
        print("CP Refresh button clicked - Goal entry reset")
    }
    
    // MARK: - Placeholder Views for Other Tabs
    
    private var centeredPageView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Centered Self Title
                Image("Centered Words")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40) // Reduced to 2/3rd (60 * 2/3 = 40)
                    .padding(.top, 58) // Lowered by additional 3pt (55 + 3 = 58)
                    .padding(.bottom, 2) // Add bottom padding to create exact 2pt gap
                
                // CS Graphic
                Image("CS graphic")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 240) // Doubled size (120 * 2 = 240)
                    .padding(.top, -8) // Move up by 8pt to reduce gap with title
                    .padding(.bottom, 2) // Add bottom padding to create exact 2pt gap
                
                // First text chunk
                Text("In today's fast-paced, uncertain world, it's easy to feel scattered. Emotions like love, loneliness, happiness, and anxiety are natural, but staying stuck in one state harms mental and physical health. We aim to help people return to balance-living peacefully as their most centered self.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Second text chunk
                Text("Keeping a daily journal is a simple yet powerful way to become more centered. Journaling has proven to help clear your mind, build self-awareness, ease stress, manage emotions, celebrate progress, and set meaningful goals.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Third text chunk with journal link
                HStack(spacing: 8) {
                    Text("Start journaling here")
                        .font(.system(size: 15, weight: .bold)) // Made bold
                        .foregroundColor(Color(hex: "3F5E82"))
                    
                    Button(action: {
                        selectedTab = 0 // Navigate to Journal tab
                    }) {
                        Image("Journal chunk")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }
                }
                .padding(.top, 20) // Changed from 25pt to 20pt
                
                // Fourth text chunk with centered icon line
                VStack(spacing: 2) {
                    Text("Our app enhances the journaling experience by providing Al-driven guidance that is supportive, inspiring, actionable and goal oriented.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Centered line with icon
                    HStack(spacing: 4) {
                        Text("Click this icon")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "3F5E82"))
                        
                        Image("Centered chunk")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                        
                        Text("after each journal log")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "3F5E82"))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    
                    Text("to unlock these insights. It can even cater its guidance towards a behavioral goal you are currently working on. You can enter that goal below.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20) // Changed from 25pt to 20pt
                
                // Fifth text chunk with text field and button
                VStack(spacing: 10) {
                    Text("I want to be")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "545555"))
                    
                    // Goal text field with button overlay
                    ZStack(alignment: .trailing) {
                        TextField("ex. Less critical, more ambitious, more empathetic", text: $goalText)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: "545555"))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .padding(.trailing, 35) // Make room for button
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(isGoalLocked) // Disable editing when locked
                            .onReceive(goalText.publisher.collect()) { _ in
                                if goalText.count > 100 {
                                    goalText = String(goalText.prefix(100))
                                }
                            }
                        
                        // CP Done/Refresh Button positioned at the right edge
                        Button(action: {
                            if showCPRefreshButton {
                                // CP Refresh button clicked - reset
                                cpRefreshButtonTapped()
                            } else {
                                // CP Done button clicked - lock in
                                cpDoneButtonTapped()
                            }
                        }) {
                            Image(showCPRefreshButton ? "CP Refresh" : "CP Done")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                        }
                        .padding(.trailing, 5) // 5pt from right edge
                    }
                    .padding(.horizontal, 40) // Centered with more padding
                }
                .padding(.top, 20)
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private var favoritesPageView: some View {
        VStack {
            Spacer()
            Text("Favorites Page")
                .font(.largeTitle)
                .foregroundColor(Color.textBlue)
            Text("Coming Soon")
                .font(.body)
                .foregroundColor(Color.textBlue.opacity(0.7))
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private var profilePageView: some View {
        VStack {
            Spacer()
            Text("Profile Page")
                .font(.largeTitle)
                .foregroundColor(Color.textBlue)
            Text("Coming Soon")
                .font(.body)
                .foregroundColor(Color.textBlue.opacity(0.7))
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // Custom Tab Bar
    var customTabBar: some View {
        HStack {
            // Journal Tab
            Button(action: { selectedTab = 0 }) {
                Image(selectedTab == 0 ? "Journal Tab click" : "Journal Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Centered Tab
            Button(action: { selectedTab = 1 }) {
                Image(selectedTab == 1 ? "Centered Tab click" : "Centered Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Favorites Tab
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "Fav Tab click" : "Fav Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Profile Tab
            Button(action: { selectedTab = 3 }) {
                Image(selectedTab == 3 ? "Profile Tab click" : "Profile Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, -5)
        .padding(.bottom, 22)
        .background(Color(hex: "E3E0C9"))
        .frame(height: 75) // Updated to 75pt height
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
