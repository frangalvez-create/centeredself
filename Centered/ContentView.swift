//
//  ContentView.swift
//  Centered
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var journalResponse: String = ""
    @State private var textEditorHeight: CGFloat = 150
    @State private var showCenteredButton: Bool = false
    @State private var isTextLocked: Bool = false
    @State private var showTextEditDropdown: Bool = false
    @State private var showCenteredButtonClick: Bool = false
    @State private var currentAIResponse: String = ""
    @State private var showFavoriteButton: Bool = false
    @State private var isFavoriteClicked: Bool = false
    @State private var isGeneratingAI: Bool = false
    @State private var isLoadingGenerating: Bool = false // Track if we're generating AI vs saving
    
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
    @State private var openIsGeneratingAI: Bool = false
    @State private var openIsLoadingGenerating: Bool = false // Track if we're generating AI vs saving
    
    // Follow-Up Question State
    @State private var followUpJournalResponse: String = ""
    @State private var followUpIsTextLocked: Bool = false
    @State private var followUpShowCenteredButton: Bool = false
    @State private var followUpShowCenteredButtonClick: Bool = false
    @State private var followUpCurrentAIResponse: String = ""
    @State private var followUpShowFavoriteButton: Bool = false
    @State private var followUpIsFavoriteClicked: Bool = false
    @State private var followUpIsGeneratingAI: Bool = false
    @State private var followUpIsLoadingGenerating: Bool = false
    @State private var followUpTextEditorHeight: CGFloat = 150
    @State private var followUpShowTextEditDropdown: Bool = false
    @State private var isFollowUpQuestionDay: Bool = false
    
    // Navigation Tab Selection
    @State private var selectedTab: Int = 0
    
    // Centered Page Goal Text
    @State private var goalText: String = ""
    @State private var isGoalLocked: Bool = false
    @State private var showCPRefreshButton: Bool = false
    @State private var goalTextHeight: CGFloat = 40
    
    // Favorites Page State
    @State private var expandedEntries: Set<UUID> = []
    
    // Info Popup State
    @State private var showInfoPopup: Bool = false
    @State private var showGoalInfoPopup: Bool = false
    
    // Profile Settings Navigation
    @State private var showSettingsFromPopup: Bool = false
    
    // Q3 Popup for Guided Questions
    @State private var showQ3InfoPopup: Bool = false
    
    // Authentication State
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var showOTPInput: Bool = false
    @State private var otpSent: Bool = false
    
    // Welcome Message State
    @State private var showWelcomeMessage: Bool = false
    
    // Pull to Refresh Loading State
    @State private var isRefreshing: Bool = false
    
    // Analyzer
    @StateObject private var analyzerViewModel = AnalyzerViewModel()
    @State private var showCenteredSelfSheet: Bool = false
    
    private let analyzerMoodColors: [Color] = [
        Color(hex: "583F82"),
        Color(hex: "3F8259"),
        Color(hex: "823F47"),
        Color(hex: "82713F"),
        Color(hex: "3F5982")
    ]
    
    var body: some View {
        rootContent
        .onAppear {
            Task {
                await journalViewModel.checkAuthenticationStatus()
                // Ensure Journal tab is selected after authentication
                selectedTab = 0
                
                // Check if today is a follow-up question day
                isFollowUpQuestionDay = journalViewModel.supabaseService.isFollowUpQuestionDay()
                
                // Load follow-up question if it's a follow-up day
                if isFollowUpQuestionDay {
                    await journalViewModel.checkAndLoadFollowUpQuestion()
                }
            }
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // When user becomes authenticated, ensure Journal tab is selected
                selectedTab = 0
                
                // Check if this is a first-time user
                checkAndShowWelcomeMessage()
            }
        }
        .onChange(of: journalViewModel.analyzerEntries) { _ in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.journalEntries.map { $0.id }) { _ in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.openQuestionJournalEntries.map { $0.id }) { _ in
            recalculateAnalyzerState()
        }
        .onChange(of: journalViewModel.followUpQuestionEntries.map { $0.id }) { _ in
            recalculateAnalyzerState()
        }
        .alert("Oh No!", isPresented: .constant(journalViewModel.errorMessage != nil)) {
            Button("OK") {
                journalViewModel.errorMessage = nil
            }
        } message: {
            Text(journalViewModel.errorMessage ?? "")
        }
    }
    
    private var rootContent: some View {
        Group {
            if journalViewModel.isAuthenticated {
                VStack(spacing: 0) {
                    // Main Content Area
                    Group {
                        switch selectedTab {
                        case 0:
                            mainJournalView
                        case 1:
                            favoritesPageView
                        case 2:
                            analyzerPageView
                        case 3:
                            ProfileView(
                                showSettingsFromPopup: $showSettingsFromPopup,
                                openCenteredSelf: { showCenteredSelfSheet = true }
                            )
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
                .overlay(
                    // Info Popup
                    Group {
                        if showInfoPopup {
                            infoPopupView
                        }
                        if showGoalInfoPopup {
                            goalInfoPopupView
                        }
                        if showQ3InfoPopup {
                            q3InfoPopupView
                        }
                    }
                )
                .overlay(
                    // Welcome Message Modal
                    Group {
                        if showWelcomeMessage {
                            welcomeMessageView
                        }
                    }
                )
                .sheet(isPresented: $showCenteredSelfSheet) {
                    centeredPageView
                        .environmentObject(journalViewModel)
                }
            } else {
                authenticationView
            }
        }
    }
    
    private var mainJournalView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
            // Date and Log Streak - positioned at top, scrolls with content
            HStack {
                Text(formatCurrentDate())
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "545555").opacity(1.0))
                    .padding(.top, 45)
                    .padding(.leading, 38)
                
                Spacer()
                
                Text("Log Streak: \(journalViewModel.calculateEntryStreak())")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "545555").opacity(1.0))
                    .padding(.top, 45)
                    .padding(.trailing, 30)
            }
            
            // Top Logo (CS Logo.png)
            Image("CS Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(.top, -2)
            
            // Daily Journal Title (DJ.png) - Reduced to 2/3 size
            Image("DJ")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 4)
                .padding(.bottom, 25)
            
            // Q Info Icon - positioned higher and to the right of DJ.png
            
            // Guided Question Text with Refresh Button - Loaded from Database
            HStack(spacing: 8) {
                if let currentQuestion = journalViewModel.currentQuestion {
                    Text(currentQuestion.questionText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else if journalViewModel.isLoading {
                    Text("Loading today's question...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    Text("What thing, person or moment filled you with gratitude today?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Guided Question Refresh Button (HIDDEN - Logic preserved for 2AM auto-click)
                // Button(action: {
                //     guidedRefreshButtonTapped()
                // }) {
                //     Image("guide_refresh")
                //         .resizable()
                //         .frame(width: 22, height: 22)
                // }
                // .disabled(journalViewModel.isLoading)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
            
            // Text Input Field with Done Button - Dynamic height with proper sizing
            VStack {
                ZStack(alignment: .topLeading) {
                    // Background for the text editor
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.textFieldBackground)
                        .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 400 : max(150, min(300, textEditorHeight)))
                    
                    // Q3 Icon inside text field - only show when no text is entered
                    if journalResponse.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                    Button(action: {
                                        showQ3InfoPopup = true
                                    }) {
                                        Image("Q")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 27, height: 27)
                                            .opacity(0.7)
                                    }
                                .padding(.trailing, 4) // 4pt from right edge
                            }
                            Spacer()
                        }
                        .padding(.top, 4) // 4pt from top edge
                    }
                    
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
                        .frame(height: 400) // Always use max height when showing AI response
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
                            .frame(height: max(150, min(300, textEditorHeight)))
                            .disabled(isTextLocked) // Lock text when Done is pressed
                            .overlay(
                                // Bottom fade mask to prevent text overlap with Done button
                                // Only show when AI response is not yet generated (before Centered button click)
                                Group {
                                    if !isTextLocked && currentAIResponse.isEmpty {
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
                                            .frame(height: 55) // 55pt height
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
                                    }
                                }
                            )
                            .onChange(of: journalResponse) { _ in
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
                        .frame(height: max(150, min(300, textEditorHeight)))
                    }
                    
                    // Done/Centered Button - Bottom Right (hidden when AI response is present or text is empty)
                    if currentAIResponse.isEmpty && !journalResponse.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    if showCenteredButton && !isGeneratingAI {
                                        centeredButtonTapped()
                                    } else if !isGeneratingAI {
                                        doneButtonTapped()
                                    }
                                }) {
                                    if isGeneratingAI {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "3F5E82")))
                                            .frame(width: 37, height: 37)
                                    } else {
                                        Image(getButtonImageName())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: showCenteredButton ? 37 : 24, height: showCenteredButton ? 37 : 24)
                                            .opacity(showCenteredButton ? 0.9 : 0.8)
                                            .scaleEffect(showCenteredButton ? 1.4 : 1.0)
                                        }
                                }
                                .frame(width: 44, height: 44) // Keep 44x44 touch target
                                .padding(.trailing, showCenteredButton ? 15 : 5)
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
                .frame(height: (isTextLocked && !currentAIResponse.isEmpty) ? 400 : max(150, min(300, textEditorHeight)))
            }
            .padding(.horizontal, 40)
            
            // OPEN QUESTION SECTION (25pt spacing below Guided Question)
            VStack(spacing: 0) {
                // Dynamic Question Text - Follow-Up or Open Question
                HStack(spacing: 8) {
                    if isFollowUpQuestionDay && !journalViewModel.currentFollowUpQuestion.isEmpty {
                        // Follow-Up Question (color #5F4083)
                        Text(journalViewModel.currentFollowUpQuestion)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "5F4083"))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isFollowUpQuestionDay && journalViewModel.currentFollowUpQuestion.isEmpty {
                        // Generating follow-up question (during delay)
                        Text("Generating a follow up question for you...")
                            .font(.system(size: 16, weight: .medium))
                            .italic()
                            .foregroundColor(Color(hex: "5F4083"))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        // Regular Open Question
                        Text("Looking at today or yesterday, share moments or thoughts that stood out.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.textBlue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Open Question Refresh Button (HIDDEN - Logic preserved for 2AM auto-click)
                    // Button(action: {
                    //     openRefreshButtonTapped()
                    // }) {
                    //     Image("open_refresh")
                    //         .resizable()
                    //         .frame(width: 22, height: 22)
                    // }
                    // .disabled(journalViewModel.isLoading)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                .padding(.top, 25) // 25pt spacing below Guided Question
                
                // Open Question Text Input Field with Done Button - Dynamic height with proper sizing
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Background for the text editor
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.textFieldBackground)
                            .frame(height: ((isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty) ? 400 : max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
                        
                        // Q Icon inside text field - only show when no text is entered
                        if (isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse).isEmpty {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showInfoPopup = true
                                    }) {
                                        Image("Q")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 27, height: 27)
                                            .opacity(0.7)
                                    }
                                    .padding(.trailing, 4) // 4pt from right edge
                                }
                                Spacer()
                            }
                            .padding(.top, 4) // 4pt from top edge
                        }
                        
                        // Text Editor and AI Response Display
                        if (isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
                            // Show both journal text and AI response when locked and response is available
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Journal text
                                        Text(isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.textGrey)
                                            .multilineTextAlignment(.leading)
                                            .id("openJournalTextStart") // Identifier for scrolling to top
                                        
                                        // AI Response
                                        Text(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse)
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
                                        if isFollowUpQuestionDay {
                                            followUpShowFavoriteButton = true
                                        } else {
                                            openShowFavoriteButton = true
                                        }
                                    }
                                }
                            }
                            .frame(height: 400) // Always use max height when showing AI response
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
                            TextEditor(text: isFollowUpQuestionDay ? $followUpJournalResponse : $openJournalResponse)
                                .font(.system(size: 16))
                                .foregroundColor(Color.textGrey)
                                .padding(.top, 5)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.bottom, 30) // Extra bottom padding to avoid Done button
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .frame(height: max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
                                .disabled(isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) // Lock text when Done is pressed
                                .overlay(
                                    // Bottom fade mask to prevent text overlap with Done button
                                    // Only show when AI response is not yet generated (before Centered button click)
                                    Group {
                                        if !(isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
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
                                                .frame(height: 55) // 55pt height
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
                                        }
                                    }
                                )
                                .onChange(of: isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse) { _ in
                                    if isFollowUpQuestionDay {
                                        updateFollowUpTextEditorHeight()
                                    } else {
                                        updateOpenTextEditorHeight()
                                    }
                                }
                        }
                        
                        // Text Edit Button Centered (only show when text is locked but no AI response)
                        if (isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty {
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
                            .frame(height: max(150, min(300, openTextEditorHeight)))
                        }
                        
                        // Done/Centered Button - Bottom Right (hidden when AI response is present or text is empty)
                        if (isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty && !(isFollowUpQuestionDay ? followUpJournalResponse : openJournalResponse).isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if isFollowUpQuestionDay {
                                            // Follow-up question button actions
                                            if followUpShowCenteredButton && !followUpIsGeneratingAI {
                                                followUpCenteredButtonTapped()
                                            } else if !followUpIsGeneratingAI {
                                                followUpDoneButtonTapped()
                                            }
                                        } else {
                                            // Open question button actions
                                            if openShowCenteredButton && !openIsGeneratingAI {
                                                openCenteredButtonTapped()
                                            } else if !openIsGeneratingAI {
                                                openDoneButtonTapped()
                                            }
                                        }
                                    }) {
                                        if (isFollowUpQuestionDay ? followUpIsGeneratingAI : openIsGeneratingAI) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "3F5E82")))
                                                .frame(width: 37, height: 37)
                                        } else {
                                            let buttonImageName = isFollowUpQuestionDay ? getFollowUpButtonImageName() : getOpenButtonImageName()
                                            let showCenteredButton = isFollowUpQuestionDay ? followUpShowCenteredButton : openShowCenteredButton
                                            
                                            Image(buttonImageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: showCenteredButton ? 37 : 24, height: showCenteredButton ? 37 : 24)
                                                .opacity(showCenteredButton ? 0.9 : 0.8)
                                                .scaleEffect(showCenteredButton ? 1.4 : 1.0)
                                        }
                                    }
                                    .frame(width: 44, height: 44) // Keep 44x44 touch target
                                    .padding(.trailing, (isFollowUpQuestionDay ? followUpShowCenteredButton : openShowCenteredButton) ? 15 : 5)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                        
                        // Favorite Button (only when AI response is present and scrolled to bottom)
                        if !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty && (isFollowUpQuestionDay ? followUpShowFavoriteButton : openShowFavoriteButton) {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if isFollowUpQuestionDay {
                                            followUpFavoriteButtonTapped()
                                        } else {
                                            openFavoriteButtonTapped()
                                        }
                                    }) {
                                        let isFavoriteClicked = isFollowUpQuestionDay ? followUpIsFavoriteClicked : openIsFavoriteClicked
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
                    .frame(height: ((isFollowUpQuestionDay ? followUpIsTextLocked : openIsTextLocked) && !(isFollowUpQuestionDay ? followUpCurrentAIResponse : openCurrentAIResponse).isEmpty) ? 400 : max(150, min(300, isFollowUpQuestionDay ? followUpTextEditorHeight : openTextEditorHeight)))
            }
            .padding(.horizontal, 40)
            
            // Embossed gray line - 20pt below open question text box
            ZStack {
                // Shadow line (darker)
                Rectangle()
                    .fill(Color(hex: "545555"))
                    .opacity(0.225) // 75% of 0.3
                    .frame(height: 1)
                    .offset(y: 1)
                
                // Main line (lighter)
                Rectangle()
                    .fill(Color(hex: "545555"))
                    .opacity(0.075) // 75% of 0.1
                    .frame(height: 1)
            }
            .padding(.top, 25) // 25pt below open question text box
            .padding(.horizontal, 40)
            
            // Goal section - 16pt below embossed line
            VStack(spacing: 4) {
                Text("My Goal is to be…")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "545555"))
                
                // Goal text field with button overlay
                ZStack(alignment: .trailing) {
                    ZStack {
                        // Custom TextEditor with dynamic height and centered text
                        TextEditor(text: $goalText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "545555"))
                        .multilineTextAlignment(.center) // Center the text
                        .padding(.leading, 15)
                        .padding(.trailing, (isGoalLocked || goalText.isEmpty) ? 15 : 50) // Center when locked or empty, make room for button when unlocked and has text
                        .padding(.top, 0)
                        .padding(.bottom, 6)
                        .background(Color(hex: "F5F4EB"))
                        .cornerRadius(8)
                        .disabled(isGoalLocked) // Disable editing when locked
                        .frame(height: max(40, goalTextHeight)) // Dynamic height starting at 40pt
                        .scrollContentBackground(.hidden)
                        .onChange(of: goalText) { _ in
                            updateGoalTextHeight()
                            // Character limit for multiline
                            if goalText.count > 50 {
                                goalText = String(goalText.prefix(50))
                            }
                        }
                        
                        // Custom placeholder text with smaller font
                        if goalText.isEmpty {
                            Text("ex. Less critical, more ambitious, more empathetic")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "545555").opacity(0.6))
                                .multilineTextAlignment(.center)
                                .allowsHitTesting(false) // Allow taps to go through to TextEditor
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                                .padding(.top, 6)
                                .padding(.bottom, 6)
                        }
                    }
                    
                    // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                    if !goalText.isEmpty {
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
                            .frame(width: 24, height: 24)
                            .opacity(showCPRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                    }
                    .padding(.trailing, 5) // 5pt from right edge
                    }
                }
                .padding(.horizontal, 40) // Centered with more padding
            }
            .padding(.top, 16) // 16pt below embossed line
            .overlay(
                // Q2 Icon as overlay - positioned to the right of "My Goal is to be..." text
                Button(action: {
                    showGoalInfoPopup = true
                }) {
                    Image("Q2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                }
                .offset(x: 330, y: 10), // 330pt to the right, 10pt down
                alignment: .topLeading
            )
        }
        
        // Emergency Support Reminder - 175pt below Goal text field
        VStack(spacing: 8) {
            Text("Emergency Support Reminder")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "545555"))
                .opacity(0.8)
                .multilineTextAlignment(.center)
            
            Text("If you are experiencing a crisis or thinking about harming yourself, do not rely on this App. Call 988 in the U.S. or your local emergency number.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "545555"))
                .opacity(0.8)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 175)
        
        // Add bottom padding for future navigation tabs
        Spacer(minLength: 5) // Extra space at bottom for navigation tabs
            }
            .padding(.bottom, 50) // Additional padding for navigation tabs
            }
            .background(Color.backgroundBeige)
            .ignoresSafeArea(.all, edges: .top)
        }
        .overlay(
            // Loading indicator
            Group {
                if journalViewModel.isLoading {
                    ZStack {
                        Color(hex: "4E4C4C").opacity(0.5)
                            .ignoresSafeArea()
                        
        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(getLoadingText())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "F5F4EB"))
                                .padding(.top, 10)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
            }
        )
        .refreshable {
            // Pull to refresh gesture - manual journal text refresh
            isRefreshing = true
            
            // Track start time for minimum display duration
            let startTime = Date()

            await reloadJournalDataSequence(suppressErrors: true)
            
            // Calculate elapsed time and ensure minimum 2-second display
            let elapsedTime = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 2.0
            let remainingTime = max(0, minimumDisplayTime - elapsedTime)
            
            // Wait for remaining time to ensure minimum 2-second display
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // Verify the question was loaded correctly
            if journalViewModel.currentQuestion != nil {
                // Set to false after all operations complete and minimum display time
                await MainActor.run {
                    isRefreshing = false
                }
            } else {
                // Retry if question not loaded
                await journalViewModel.loadTodaysQuestion()
                await MainActor.run {
                    isRefreshing = false
                }
            }
        }
        .overlay {
            // Loading overlay during refresh
            if isRefreshing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Updating daily questions...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                }
                .allowsHitTesting(true) // Block all interactions
            }
        }
        .onAppear {
            Task {
                await reloadJournalDataSequence(suppressErrors: false)
            }
            
            // Set up the callbacks for UI state management
            journalViewModel.clearUIStateCallback = {
                print("🧹 Direct callback triggered - clearing UI state")
                clearAllUIState()
            }
            
            journalViewModel.populateUIStateCallback = {
                print("🔄 Direct callback triggered - populating UI state")
                populateUIStateFromJournalEntries()
            }
        }
        .onChange(of: journalViewModel.shouldClearUIState) { shouldClear in
            print("🔄 onChange triggered - shouldClear: \(shouldClear)")
            if shouldClear {
                print("🧹 Clearing UI state due to user sign out")
                clearAllUIState()
                // Reset the trigger
                journalViewModel.shouldClearUIState = false
                print("🧹 UI state cleared and trigger reset")
            }
        }
        .onDisappear {
            // Global timer handles 2AM reset - no cleanup needed here
            print("🕐 View disappeared - global timer continues running")
        }
    }
    
    // Format current date as "Sept 24th" format
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        
        let monthDay = formatter.string(from: Date())
        let ordinalDay = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        
        return monthDay.replacingOccurrences(of: "\(day)", with: ordinalDay)
    }
    
    private var authenticationView: some View {
        VStack(spacing: 20) {
            // Centered Logo - moved to 100pt from top
            Image("CS Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding(.top, 100)
            
            // Welcome to text - 22pt regular, Blue #3F5E82
            Text("Welcome to")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "3F5E82"))
            
            // CenteredApp Logo - 5pt below Welcome to
            Image("CenteredApp Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .padding(.top, 5)
            
            VStack(spacing: 15) {
                if !showOTPInput {
                    // Email Input Screen
                    VStack(spacing: 15) {
                        // Instruction text - only show on email screen
                        Text("Enter your email to get started")
                            .font(.body)
                            .foregroundColor(Color(hex: "3F5E82"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Email TextField with fixed background color
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(hex: "F5F4EB"))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            Task {
                                await journalViewModel.sendOTP(email: email)
                                if journalViewModel.errorMessage == nil {
                                    showOTPInput = true
                                    otpSent = true
                                }
                            }
                        }) {
                            Text("Send One Time Passcode")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "3F5E82"))
                                .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || journalViewModel.isLoading)
                        .padding(.horizontal, 40)
                    }
                } else {
                    // OTP Code Input Screen
                    VStack(spacing: 15) {
                        // Check your email text - 5pt below logo (adjusted spacing)
                        Text("Check your email for the OTP code")
                            .font(.body)
                            .foregroundColor(Color(hex: "3F5E82"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 5) // 5pt padding as requested
                        
                        // OTP TextField with fixed background color
                        TextField("Enter OTP code", text: $otpCode)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 12) // Reduced height (3/4 of current size)
                            .background(Color(hex: "F5F4EB"))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .medium))
                            .padding(.horizontal, 40)
                            .padding(.top, 5) // 5pt padding as requested
                        
                        HStack(spacing: 15) {
                        Button(action: {
                            showOTPInput = false
                            otpSent = false
                        }) {
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "3F5E82"), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            Task {
                                await journalViewModel.verifyOTP(email: email, token: otpCode)
                            }
                        }) {
                            Text("Verify")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "3F5E82"))
                                .cornerRadius(8)
                        }
                            .disabled(otpCode.isEmpty || journalViewModel.isLoading)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            // Resend OTP Code
                            Task {
                                await journalViewModel.sendOTP(email: email)
                            }
                        }) {
                        Text("Resend Code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "3F5E82").opacity(0.7))
                        }
                        .disabled(journalViewModel.isLoading)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🚨🚨🚨 DONE BUTTON TAPPED - METHOD CALLED!")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        print("🔘🔘🔘 DONE BUTTON TAPPED - Content: \(journalResponse)")
        
        // Change to Centered Button and lock text (no animation on Done button)
        showCenteredButton = true
        isTextLocked = true
        isLoadingGenerating = false // This is saving, not generating
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase
        Task {
            print("📝📝📝 Calling journalViewModel.createJournalEntry with content: \(journalResponse)")
            await journalViewModel.createJournalEntry(content: journalResponse)
        }
        
        print("Done button tapped - Journal entry saved to Supabase: \(journalResponse)")
        print("Text locked and button changed to Centered Button")
    }
    
    private func centeredButtonTapped() {
        // Prevent multiple clicks during AI generation
        guard !isGeneratingAI else { 
            print("⚠️ AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        showCenteredButtonClick = true
        isGeneratingAI = true
        isLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.isGeneratingAI = false
                    self.isLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.showCenteredButtonClick = false
                    self.isGeneratingAI = false
                    self.isLoadingGenerating = false
                }
                print("❌ AI generation failed: \(error)")
            }
        }
        
        print("Centered button tapped - Generating AI prompt for: \(journalResponse)")
    }
    
    private func generateAndSaveAIPrompt() async throws {
        // Ensure user profile is loaded before generating AI prompt
        do {
            let loadedProfile = try await journalViewModel.supabaseService.loadUserProfile()
            if let profile = loadedProfile {
                journalViewModel.currentUser = profile
                print("✅ User profile loaded and updated in currentUser")
            }
        } catch {
            print("⚠️ Warning: Could not load user profile: \(error)")
            // Continue execution even if profile loading fails
        }
        
        // Get the most recent goal from the loaded goals
        let mostRecentGoal = journalViewModel.goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: journalResponse, goal: mostRecentGoal, questionText: journalViewModel.currentQuestion?.questionText ?? "")
        
        // Update the current journal entry with the AI prompt
        await journalViewModel.updateCurrentJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ AI Prompt generated and saved:")
        print("📝 Content: \(journalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        try await withTimeout(seconds: 30) {
            await journalViewModel.generateAndSaveAIResponse()
        }
        
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
    
    private func createAIPromptText(content: String, goal: String, questionText: String) -> String {
        let aiPromptTemplate = """
Task: Given search terms related to behavioral science and therapy topics, perform a task inquiry in Chat GPT to retrieve information from current behavioral, CBT, EFT, IPT or other therapy sources, and produce a concise summary of the key points. The client ({gender}, occupation: {occupation}, born {birthdate}) was asked {question_text}. Client response is the search terms/input below.
Input: {content}
Output: Provide only a succinct, information-dense summary capturing the essence of recent therapy modalities found in task inquiry, relevant to the search terms. The summary must be concise, in 2 short paragraphs. The first paragraph must empathetically acknowledge and summarize the search term concerns and provide fact-based analysis. The second paragraph must provide achievable actions the users can implement to address the concern and the goal to be {goal}. Limit the bulleted actions to no more than 3. End with related, "quote" from well known figures.
Constraints: Focus on capturing the main points succinctly: complete sentences and in a conversational empathetic tone. Ignore fluff, background information. Do not include your own analysis or opinion. Do not reiterate the input. Ignore dangerous and abusive talk in input.
Capabilities and Reminders: You have access to the web search tools, published research papers/studies and gained knowledge to find and retrieve therapy related data. Do not mention the following in the output: label paragraph 1 and 2; CBT, EFT, IPT; and word limits. Limit the entire response to 230 words.
"""
        
        // Get user profile data for placeholders
        let gender = journalViewModel.currentUser?.gender ?? "null"
        let occupation = journalViewModel.currentUser?.occupation ?? "null"
        let birthdate = journalViewModel.currentUser?.birthdate ?? "null"
        let goalText = goal.isEmpty ? "centered" : goal
        
        // Replace all placeholders
        return aiPromptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{goal}", with: goalText)
            .replacingOccurrences(of: "{question_text}", with: questionText)
            .replacingOccurrences(of: "{gender}", with: gender)
            .replacingOccurrences(of: "{occupation}", with: occupation)
            .replacingOccurrences(of: "{birthdate}", with: birthdate)
    }
    
    private func createFollowUpAIPromptText(content: String, fuqAiResponse: String) -> String {
        let followUpAIPromptTemplate = """
        Therapist: {fuq_ai_response}
        Client: {content}
        Output: Provide only a succinct response to the above therapist/client conversation. First be encouraging, supportive, with a pleasant tone to their progress. Then provide additional insight on the action item mentioned by the therapist. Based on relevant behavioral, CBT, EFT, IPT or other therapy modalities. In a new paragraph, end with related, "quote" from well known figures
        Constraints: Focus on capturing the main points succinctly: complete sentences and in an encouraging, supportive, pleasant tone. Ignore fluff, background information. Do not include your own analysis or opinion. Do not reiterate the input.
        Capabilities and Reminders: You have access to the web search tools, published research papers/studies and your gained knowledge to find and retrieve behavioral science and therapy related data. Limit the entire response to 150 words.
        """
        
        // Replace placeholders
        return followUpAIPromptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{fuq_ai_response}", with: fuqAiResponse)
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
    
    // MARK: - Question Refresh Button Actions
    
    private func guidedRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset UI state for guided question
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Refresh guided question in database
        Task {
            await journalViewModel.refreshGuidedQuestion()
        }
        
        print("Guided Question refresh button clicked")
    }
    
    private func openRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset UI state for open question
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Refresh open question in database
        Task {
            await journalViewModel.refreshOpenQuestion()
        }
        
        print("Open Question refresh button clicked")
    }
    
    // MARK: - UI State Management
    
    // Clear only journal-related UI state (preserves goals and other state)
    private func clearJournalUIState() {
        print("🧹 Clearing journal UI state (yesterday's data)")
        
        // Clear guided question UI state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Clear open question UI state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Clear follow-up question UI state
        followUpJournalResponse = ""
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        followUpIsGeneratingAI = false
        followUpIsLoadingGenerating = false
        followUpTextEditorHeight = 150
        followUpShowTextEditDropdown = false
        
        print("✅ Journal UI state cleared - ready for today's data")
    }
    
    private func populateUIStateFromJournalEntries() {
        print("🔄 Populating UI state from journal entries")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Find today's guided question entry
        let todaysGuidedEntry = journalViewModel.journalEntries.first { entry in
            entry.entryType == "guided" && calendar.isDateInToday(entry.createdAt)
        }
        
        if let guidedEntry = todaysGuidedEntry {
            print("📝 Found today's guided entry: \(guidedEntry.content)")
            journalResponse = guidedEntry.content
            currentAIResponse = guidedEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !currentAIResponse.isEmpty {
                isTextLocked = true
                showCenteredButtonClick = true
                showFavoriteButton = true
                isFavoriteClicked = guidedEntry.isFavorite
                textEditorHeight = 300
            }
        }
        
        // Find today's open question entry
        let todaysOpenEntry = journalViewModel.openQuestionJournalEntries.first { entry in
            entry.entryType == "open" && calendar.isDateInToday(entry.createdAt)
        }
        
        if let openEntry = todaysOpenEntry {
            print("📝 Found today's open entry: \(openEntry.content)")
            openJournalResponse = openEntry.content
            openCurrentAIResponse = openEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !openCurrentAIResponse.isEmpty {
                openIsTextLocked = true
                openShowCenteredButtonClick = true
                openShowFavoriteButton = true
                openIsFavoriteClicked = openEntry.isFavorite
                openTextEditorHeight = 300
            }
        }
        
        // Find today's follow-up question entry (user's response entry, not the question entry)
        // The question entry has empty content and fuqAiResponse
        // The user's response entry has non-empty content and potentially aiResponse
        let todaysFollowUpEntry = journalViewModel.followUpQuestionEntries.first { entry in
            entry.entryType == "follow_up" &&
            calendar.isDate(entry.createdAt, inSameDayAs: today) &&
            !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if let followUpEntry = todaysFollowUpEntry {
            print("📝 Found today's follow-up entry: \(followUpEntry.content.prefix(50))...")
            followUpJournalResponse = followUpEntry.content
            followUpCurrentAIResponse = followUpEntry.aiResponse ?? ""
            
            // Set UI state based on whether AI response exists
            if !followUpCurrentAIResponse.isEmpty {
                followUpIsTextLocked = true
                followUpShowCenteredButtonClick = true
                followUpShowFavoriteButton = true
                followUpIsFavoriteClicked = followUpEntry.isFavorite
                followUpTextEditorHeight = 300
            }
        } else {
            print("📝 No follow-up entry found for today (user hasn't responded yet)")
        }
        
        // Load goal text from the most recent goal
        if let mostRecentGoal = journalViewModel.goals.first {
            print("📝 Found goal: \(mostRecentGoal.goals)")
            goalText = mostRecentGoal.goals
            isGoalLocked = true
            showCPRefreshButton = true
        } else {
            print("📝 No goals found - clearing goal text")
            goalText = ""
            isGoalLocked = false
            showCPRefreshButton = false
        }
        
        print("✅ UI state populated from journal entries")
    }
    
    // Unified data refresh sequence used by both onAppear and pull-to-refresh
    private func reloadJournalDataSequence(suppressErrors: Bool) async {
        // Clear existing UI state on the main actor
        await MainActor.run {
            clearJournalUIState()
        }
        
        // Load the latest guided question and perform daily reset if needed
        await journalViewModel.loadTodaysQuestion()
        await journalViewModel.checkAndResetIfNeeded()
        
        // Determine follow-up state after potential reset
        let isFollowUpDay = journalViewModel.supabaseService.isFollowUpQuestionDay()
        await MainActor.run {
            isFollowUpQuestionDay = isFollowUpDay
        }
        
        // Load journal data sets
        await journalViewModel.loadJournalEntries()
        await journalViewModel.loadOpenQuestionJournalEntries()
        
        // Load or clear follow-up question data depending on the day
        if isFollowUpDay {
            await journalViewModel.checkAndLoadFollowUpQuestion(suppressErrors: suppressErrors)
        } else {
            await MainActor.run {
                journalViewModel.currentFollowUpQuestion = ""
            }
        }
        
        // Load goals after journal data
        await journalViewModel.loadGoals()
        
        // Repopulate UI state with the freshly loaded data
        await MainActor.run {
            populateUIStateFromJournalEntries()
            
            if let mostRecentGoal = journalViewModel.goals.first {
                goalText = mostRecentGoal.goals
                isGoalLocked = true
                showCPRefreshButton = true
            } else {
                goalText = ""
                isGoalLocked = false
                showCPRefreshButton = false
            }
        }
    }
    
    private func clearAllUIState() {
        print("🧹 Clearing all UI state for user isolation")
        print("🧹 Before clear - journalResponse: '\(journalResponse)'")
        print("🧹 Before clear - currentAIResponse: '\(currentAIResponse)'")
        print("🧹 Before clear - openJournalResponse: '\(openJournalResponse)'")
        print("🧹 Before clear - openCurrentAIResponse: '\(openCurrentAIResponse)'")
        
        // Clear guided question UI state
        journalResponse = ""
        isTextLocked = false
        showCenteredButton = false
        showCenteredButtonClick = false
        currentAIResponse = ""
        showFavoriteButton = false
        isFavoriteClicked = false
        textEditorHeight = 150
        
        // Clear open question UI state
        openJournalResponse = ""
        openIsTextLocked = false
        openShowCenteredButton = false
        openShowCenteredButtonClick = false
        openCurrentAIResponse = ""
        openShowFavoriteButton = false
        openIsFavoriteClicked = false
        openTextEditorHeight = 150
        
        // Clear centered page state
        goalText = ""
        isGoalLocked = false
        showCPRefreshButton = false
        
        // Clear favorites page state
        expandedEntries = []
        
        // Clear authentication state
        email = ""
        otpCode = ""
        showOTPInput = false
        otpSent = false
        
        print("🧹 After clear - journalResponse: '\(journalResponse)'")
        print("🧹 After clear - currentAIResponse: '\(currentAIResponse)'")
        print("🧹 After clear - openJournalResponse: '\(openJournalResponse)'")
        print("🧹 After clear - openCurrentAIResponse: '\(openCurrentAIResponse)'")
        print("✅ All UI state cleared for user isolation")
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
    
    private func updateFollowUpTextEditorHeight() {
        // If we have AI response, always use max height for scrolling
        if followUpIsTextLocked && !followUpCurrentAIResponse.isEmpty {
            followUpTextEditorHeight = 250
            return
        }
        
        // Return early if text is empty to avoid NaN calculations
        guard !followUpJournalResponse.isEmpty else {
            followUpTextEditorHeight = 150
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth = UIScreen.main.bounds.width - 100 // Account for padding
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            followUpTextEditorHeight = 150
            return
        }
        
        let boundingRect = followUpJournalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 150 : calculatedHeight
        
        followUpTextEditorHeight = max(150, min(250, validatedHeight))
    }
    
    private func updateGoalTextHeight() {
        // Return early if text is empty to avoid NaN calculations
        guard !goalText.isEmpty else {
            goalTextHeight = 40
            return
        }
        
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth = UIScreen.main.bounds.width - 120 // Account for padding and button space
        
        // Ensure maxWidth is valid
        guard maxWidth > 0 else {
            goalTextHeight = 40
            return
        }
        
        let boundingRect = goalText.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Validate the calculated height to prevent NaN
        let calculatedHeight = boundingRect.height + 20 // Extra padding for comfort
        let validatedHeight = calculatedHeight.isNaN || calculatedHeight.isInfinite ? 40 : calculatedHeight
        
        goalTextHeight = max(40, min(120, validatedHeight)) // Max 120pt height for multiline
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
        // Change to Centered Button and lock text (no animation on Done button)
        openShowCenteredButton = true
        openIsTextLocked = true
        openIsLoadingGenerating = false // This is saving, not generating
        
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
        // Prevent multiple clicks during AI generation
        guard !openIsGeneratingAI else { 
            print("⚠️ Open AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        openShowCenteredButtonClick = true
        openIsGeneratingAI = true
        openIsLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveOpenAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.openIsGeneratingAI = false
                    self.openIsLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.openShowCenteredButtonClick = false
                    self.openIsGeneratingAI = false
                    self.openIsLoadingGenerating = false
                }
                print("❌ Open AI generation failed: \(error)")
            }
        }
        
        print("Open Centered button tapped - Generating AI prompt for: \(openJournalResponse)")
    }
    
    private func generateAndSaveOpenAIPrompt() async throws {
        // Get the most recent goal from the loaded goals
        let mostRecentGoal = journalViewModel.goals.first?.goals ?? ""
        
        // Create the AI prompt text with replacements
        let aiPromptText = createAIPromptText(content: openJournalResponse, goal: mostRecentGoal, questionText: "Looking at today or yesterday, share moments or thoughts that stood out")
        
        // Update the current open question journal entry with the AI prompt
        await journalViewModel.updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ Open AI Prompt generated and saved:")
        print("📝 Content: \(openJournalResponse)")
        print("🎯 Goal: \(mostRecentGoal)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        try await withTimeout(seconds: 30) {
            await journalViewModel.generateAndSaveOpenQuestionAIResponse()
        }
        
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
    
    // MARK: - Follow-Up Question Button Actions
    
    private func getFollowUpButtonImageName() -> String {
        if followUpShowCenteredButtonClick {
            return "Centered Button Click"
        } else if followUpShowCenteredButton {
            return "Centered Button"
        } else {
            return "Done Button"
        }
    }
    
    private func followUpDoneButtonTapped() {
        // Change to Centered Button and lock text (no animation on Done button)
        followUpShowCenteredButton = true
        followUpIsTextLocked = true
        followUpIsLoadingGenerating = false // This is saving, not generating
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save journal entry to Supabase with follow-up question
        Task {
            await journalViewModel.createFollowUpQuestionJournalEntry(content: followUpJournalResponse)
        }
        
        print("Follow-Up Done button tapped - Journal entry saved to Supabase: \(followUpJournalResponse)")
        print("Follow-Up Text locked and button changed to Centered Button")
    }
    
    private func followUpCenteredButtonTapped() {
        // Prevent multiple clicks during AI generation
        guard !followUpIsGeneratingAI else { 
            print("⚠️ Follow-Up AI generation already in progress, ignoring click")
            return 
        }
        
        // Change to Centered Button Click state
        followUpShowCenteredButtonClick = true
        followUpIsGeneratingAI = true
        followUpIsLoadingGenerating = true // This is generating AI, not saving
        
        // Reset retry attempt to 1 for new generation
        journalViewModel.currentRetryAttempt = 1
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate AI prompt and update journal entry
        Task {
            do {
                try await generateAndSaveFollowUpAIPrompt()
                // Reset loading state on success
                await MainActor.run {
                    self.followUpIsGeneratingAI = false
                    self.followUpIsLoadingGenerating = false
                }
            } catch {
                // Reset button state on error
                await MainActor.run {
                    self.followUpShowCenteredButtonClick = false
                    self.followUpIsGeneratingAI = false
                    self.followUpIsLoadingGenerating = false
                }
                print("❌ Follow-Up AI generation failed: \(error)")
            }
        }
        
        print("Follow-Up Centered button tapped - Generating AI prompt for: \(followUpJournalResponse)")
    }
    
    private func generateAndSaveFollowUpAIPrompt() async throws {
        // Get the current follow-up question
        let currentFollowUpQuestion = journalViewModel.currentFollowUpQuestion
        
        // Create the AI prompt text with follow-up template
        let aiPromptText = createFollowUpAIPromptText(content: followUpJournalResponse, fuqAiResponse: currentFollowUpQuestion)
        
        // Update the current follow-up question journal entry with the AI prompt
        await journalViewModel.updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt: aiPromptText)
        
        print("✅ Follow-Up AI Prompt generated and saved:")
        print("📝 Content: \(followUpJournalResponse)")
        print("🤖 AI Prompt: \(aiPromptText)")
        
        // Generate AI response using OpenAI API with timeout
        try await withTimeout(seconds: 30) {
            await journalViewModel.generateAndSaveFollowUpQuestionAIResponse()
        }
        
        // Update the AI response in the UI
        await updateFollowUpAIResponseDisplay()
    }
    
    private func updateFollowUpAIResponseDisplay() async {
        // Load the latest journal entries to get the AI response
        await journalViewModel.loadFollowUpQuestionEntries()
        
        // Get the most recent follow-up question entry with AI response
        if let mostRecentEntry = journalViewModel.followUpQuestionEntries.first,
           let aiResponse = mostRecentEntry.aiResponse, !aiResponse.isEmpty {
            await MainActor.run {
                self.followUpCurrentAIResponse = aiResponse
                // Update height to accommodate AI response
                self.updateFollowUpTextEditorHeight()
            }
            print("✅ Follow-Up AI Response updated in UI: \(aiResponse.prefix(100))...")
        }
    }
    
    private func followUpEditLogSelected() {
        // Close dropdown
        followUpShowTextEditDropdown = false
        
        // Revert to editable state
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        
        // Clear AI response when editing
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Follow-Up Edit Log selected - Text unlocked for editing")
    }
    
    private func followUpDeleteLogSelected() {
        // Close dropdown
        followUpShowTextEditDropdown = false
        
        // Clear text and revert to initial state
        followUpJournalResponse = ""
        followUpIsTextLocked = false
        followUpShowCenteredButton = false
        followUpShowCenteredButtonClick = false
        
        // Clear AI response when deleting
        followUpCurrentAIResponse = ""
        followUpShowFavoriteButton = false
        followUpIsFavoriteClicked = false
        
        // Reset text editor height
        followUpTextEditorHeight = 150
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Follow-Up Delete Log selected - Text cleared and state reset")
    }
    
    private func followUpFavoriteButtonTapped() {
        // Only allow one click - if already clicked, do nothing
        guard !followUpIsFavoriteClicked else { return }
        
        // Perform haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update button state to show clicked version
        followUpIsFavoriteClicked = true
        
        // Update the database
        Task {
            await journalViewModel.updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: true)
        }
        
        print("Follow-Up Favorite button clicked - Journal entry marked as favorite")
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
    
    // MARK: - Analyzer View
    
    private var analyzerPageView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image("Anal Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 60)
                    .padding(.bottom, 0)
                
                Image("Anal Title")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.6)
                    .padding(.bottom, 0)
                
                // Date range display with divider lines
                HStack(alignment: .center, spacing: 12) {
                    Rectangle()
                        .fill(Color(hex: "F5F4EB").opacity(0.6))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                    
                    Text(analyzerViewModel.dateRangeDisplay)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "F5F4EB"))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Rectangle()
                        .fill(Color(hex: "F5F4EB").opacity(0.6))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                }
                .padding(.top, 0)
                
                moodTrackerSection
                    .padding(.top, 20)
                
                statisticsSection
                    .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(hex: "3F5E82"))
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            recalculateAnalyzerState()
        }
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
                    .frame(height: 204) // Reduced by 15% (240 * 0.85 = 204)
                    .padding(.top, 17) // Changed from 2pt to 17pt
                    .padding(.bottom, 8) // Add bottom padding to create exact 2pt gap
                
                // First text chunk
                Text("In today's fast-paced and uncertain world, it's easy to feel scattered as our minds swirl with complex emotions and thoughts. Staying stuck in any one state, however, can harm both mental and physical health. Our goal is to help people return to balance—living peacefully as their most centered selves.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 15) // Added 15pt top padding
                
                // Second text chunk
                (Text("Daily Journal").font(.system(size: 15, weight: .bold)) + Text(" - Keeping a daily journal is a simple yet powerful way to become more centered. Journaling has proven to help clear your mind, build self-awareness, ease stress, manage emotions, celebrate progress, and set meaningful goals.").font(.system(size: 15)))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 17) // Changed from 12pt to 17pt
                
                
                // Fourth text chunk with overlay icon
                ZStack {
                    (Text("AI Insights").font(.system(size: 15, weight: .bold)) + Text(" - Our app elevates your journaling experience with personalized, AI-powered guidance that is supportive, inspiring, and goal-oriented. After each journal entry, tap the \"Insights\" button to unlock tailored insights. You can further customize the insights by setting a behavioral goal and providing your personal information (occupation, age, gender etc) in the user settings page.").font(.system(size: 15)))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                }
                .padding(.top, 17) // Changed from 12pt to 17pt
                            
                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private var moodTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Tracker")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "8BECF8"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            if analyzerViewModel.moodCounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "3F5E82").opacity(0.4))
                    Text("No mood data available yet.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .multilineTextAlignment(.center)
                    Text("Run Analyze to see your top moods for the week.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "3F5E82").opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "F5F4EB"))
                )
            } else {
                moodBarChart()
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "F5F4EB"))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func moodBarChart() -> some View {
        let counts = analyzerViewModel.moodCounts
        let maxCount = max(counts.map { $0.count }.max() ?? 1, 1)
        let tickCount = min(maxCount, 5)
        let tickStep = max(1, maxCount / tickCount)
        let tickValues: [Int]
        if maxCount <= 5 {
            tickValues = Array((1...maxCount).reversed())
        } else {
            tickValues = stride(from: maxCount, through: tickStep, by: -tickStep).map { Int($0) }
        }
        let chartHeight: CGFloat = 180
        let barSpacing: CGFloat = counts.count > 0 ? 16 : 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "3F5E82"))
                    ForEach(tickValues, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "3F5E82"))
                    }
                    Spacer()
                }
                .frame(height: chartHeight)
                
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(Array(counts.enumerated()), id: \.element.id) { index, mood in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(analyzerMoodColors[index % analyzerMoodColors.count])
                                .frame(width: 28,
                                       height: max(CGFloat(mood.count) / CGFloat(maxCount) * (chartHeight - 40), 10))
                            
                            Text(mood.mood)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: chartHeight)
            }
            
            HStack(spacing: barSpacing) {
                Spacer().frame(width: 40)
                ForEach(counts, id: \.id) { mood in
                    Text("\(mood.count) entries")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "3F5E82").opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.leading, 40)
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "8BECF8"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            GeometryReader { geo in
                let spacing: CGFloat = 16
                let columnWidth = (geo.size.width - spacing * 2) / 3
                let topRowHeight: CGFloat = 120
                let centeredScoreHeight: CGFloat = 300
                let favLogTimeHeight: CGFloat = 90
                
                ZStack(alignment: .topLeading) {
                    statisticsCard(
                        title: "# Logs",
                        value: "\(analyzerViewModel.logsCount)",
                        titleColor: Color(hex: "545555"),
                        valueColor: Color(hex: "3F8259")
                    )
                    .frame(width: columnWidth, height: topRowHeight)
                    .offset(x: 0, y: 0)
                    
                    statisticsCard(
                        title: "Log Streak",
                        value: analyzerViewModel.streakDuringRange == 0 ? "—" : "\(analyzerViewModel.streakDuringRange) days",
                        titleColor: Color(hex: "545555"),
                        valueColor: Color(hex: "3F8259")
                    )
                    .frame(width: columnWidth, height: topRowHeight)
                    .offset(x: columnWidth + spacing, y: 0)
                    
                    statisticsCard(
                        title: "Centered Score",
                        value: analyzerViewModel.centeredScore.map { "\($0)" } ?? "—",
                        titleColor: Color(hex: "545555"),
                        valueColor: Color(hex: "823F47"),
                        valueFontSize: 32
                    )
                    .frame(width: columnWidth, height: centeredScoreHeight)
                    .offset(x: (columnWidth + spacing) * 2, y: 0)
                    
                    statisticsCard(
                        title: "Fav Log Time",
                        value: analyzerViewModel.favoriteLogTime,
                        titleColor: Color(hex: "545555"),
                        valueColor: Color(hex: "583F82"),
                        valueFontSize: 24
                    )
                    .frame(width: columnWidth * 2 + spacing, height: favLogTimeHeight)
                    .offset(x: 0, y: topRowHeight + spacing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 300) // Centered Score height (tallest card)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func statisticsCard(
        title: String,
        value: String,
        titleColor: Color,
        valueColor: Color,
        valueFontSize: CGFloat = 16,
        minHeight: CGFloat? = nil
    ) -> some View {
        let card = VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "F5F4EB"))
        )
        
        if let minHeight = minHeight {
            card.frame(minHeight: minHeight)
        } else {
            card
        }
    }
    
    private func recalculateAnalyzerState() {
        analyzerViewModel.update(with: journalViewModel.analyzerEntries)
        let referenceDate = analyzerViewModel.latestEntry?.createdAt ?? Date()
        let displayData = analyzerViewModel.computeDisplayData(for: referenceDate)
        analyzerViewModel.refreshDateRangeDisplay(referenceDate: referenceDate)
        let stats = journalViewModel.calculateAnalyzerStats(startDate: displayData.startDate, endDate: displayData.endDate)
        analyzerViewModel.refreshStats(using: stats)
    }
    
    @State private var isEditingFavorites = false
    
    private var favoritesPageView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Fav Logo - lowered by 5pt total from original position (3pt + 2pt)
                Image("Fav Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 60) // 55 + 5 = 60pt (additional 2pt lower)
                    .padding(.bottom, -10) // Negative padding to reduce gap
                
                // Favorite title - much closer to logo
                Image("Favorite title")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.353) // Reduced to 2/3 of previous size (0.53 * 0.667)
                    .padding(.bottom, 10)
                
                // List of favorite entries with swipe-to-delete - 10pt below title
                if journalViewModel.favoriteJournalEntries.isEmpty {
                    // Show empty state message when no favorites exist
                    VStack {
                        Spacer()
                            .frame(height: 10) // Fixed height to raise text up 10pt
                        
                        Text("No favorite entries have been made yet..")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "545555"))
                            .opacity(0.7) // 70% opacity
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(journalViewModel.favoriteJournalEntries) { entry in
                            favoriteEntryView(entry: entry)
                                .listRowBackground(Color(hex: "E3E0C9"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7.5, leading: 8, bottom: 7.5, trailing: 8))
                        }
                        .onDelete { offsets in
                            Task {
                                await journalViewModel.deleteFavoriteEntries(at: offsets)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .environment(\.editMode, isEditingFavorites ? .constant(.active) : .constant(.inactive))
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(hex: "E3E0C9"))
            
            // Edit Button positioned at top-right with functionality
            Button(action: {
                withAnimation {
                    isEditingFavorites.toggle()
                }
            }) {
                Text(isEditingFavorites ? "Done" : "Edit")
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "3F5E82"))
            }
            .padding(.top, 60) // Same as logo top padding
            .padding(.trailing, 20)
        }
        .onAppear {
            Task {
                await journalViewModel.loadFavoriteEntries()
            }
        }
    }
    
    // MARK: - Favorite Entry View
    private func favoriteEntryView(entry: JournalEntry) -> some View {
        let isExpanded = expandedEntries.contains(entry.id)
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Date column - fixed width
                Text(formatDate(entry.createdAt))
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .frame(width: 80, alignment: .leading)
                
                // 3pt spacing
                Spacer()
                    .frame(width: 3)
                
                // Content column - takes remaining space
                VStack(alignment: .leading, spacing: 8) {
                    // Journal entry text
                    if isExpanded {
                        // Show full text
                        Text(entry.content)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "545555"))
                            .multilineTextAlignment(.leading)
                    } else {
                        // Show truncated text (max 3 lines)
                        Text(truncateText(entry.content, maxLines: 3))
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "545555"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    
                    // AI response text (only shown when expanded)
                    if isExpanded && !(entry.aiResponse?.isEmpty ?? true) {
                        Text(entry.aiResponse ?? "")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 5) // 5pt indent
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 8pt spacing before icon
                Spacer()
                    .frame(width: 8)
                
                // Icon - fixed position on right
                Button(action: {
                    if isExpanded {
                        expandedEntries.remove(entry.id)
                    } else {
                        expandedEntries.insert(entry.id)
                    }
                }) {
                    Image(isExpanded ? "Minus icon" : "Plus icon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                }
                .frame(width: 17, alignment: .trailing)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
        }
        .background(Color(hex: "F5F4EB"))
        .cornerRadius(8)
    }
    
    // Helper function to format date as "Sept 2nd"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let baseString = formatter.string(from: date)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let day = Int(dayFormatter.string(from: date)) ?? 1
        
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return baseString + suffix
    }
    
    // Helper function to truncate text to max lines with "..."
    private func truncateText(_ text: String, maxLines: Int) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let approximateWordsPerLine = 8 // Rough estimate
        let maxWords = maxLines * approximateWordsPerLine
        
        if words.count > maxWords {
            let truncatedWords = Array(words.prefix(maxWords))
            return truncatedWords.joined(separator: " ") + "..."
        }
        return text
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
            
            // Centered Tab (now using Favorite Tab icons)
            Button(action: { selectedTab = 1 }) {
                Image(selectedTab == 1 ? "Fav Tab click" : "Fav Tab")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .frame(maxWidth: .infinity)
            
            // Favorites Tab (now using Centered Tab icons)
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "Centered Tab click" : "Centered Tab")
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
    
    // MARK: - Welcome Message
    
    private var welcomeMessageView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
            
            // Welcome modal
            VStack(spacing: 20) {
                // Welcome title
                Text("Welcome to Centered Self!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "3F5E82"))
                    .multilineTextAlignment(.center)
                
                // Description
                Text("This is your personal journaling space where you can:")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.center)
                
                // Bullet points
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                        Text("Answer guided questions for daily reflection")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                        Text("Write freely about anything on your mind")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                        Text("Get AI-powered insights to deepen your self-awareness")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                        Text("Customize AI guidance to help achieve your goals")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "545555"))
                    }
                }
                .padding(.horizontal, 20)
                
                // Get Started button
                Button(action: {
                    dismissWelcomeMessage()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "3F5E82"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 30)
        }
    }
    
    private func checkAndShowWelcomeMessage() {
        // Get user-specific key to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let hasSeenWelcomeKey = "hasSeenWelcome_\(userId)"
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
        if !hasSeenWelcome {
            showWelcomeMessage = true
        }
    }
    
    private func dismissWelcomeMessage() {
        showWelcomeMessage = false
        // Get user-specific key to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let hasSeenWelcomeKey = "hasSeenWelcome_\(userId)"
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
    }
    
    private var infoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showInfoPopup = false
                }
            
            // Simple popup content
            VStack(alignment: .leading, spacing: 8) {
                Text("Free write and Check In Questions")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• Share anything on your mind.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• Periodically, check in questions will ask about previous journal entries.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• After completing your entry, you can tap the \"Insight\" button to receive customized insights.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Journal Reminder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Whether you like to journal early in the morning or right before bed, you can set your own reminder times in the Notifications section of the User Settings page.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Tips")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("The more detail you share, the more helpful and accurate the AI insights will be.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("If you add your information (gender, occupation and birthdate) in the User Settings page (Here), the AI Insight will include this in its analysis and insights")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .onTapGesture {
                        showInfoPopup = false
                        selectedTab = 3 // Navigate to Profile tab
                        showSettingsFromPopup = true // Trigger settings sheet
                    }
                
                Text("New entries are available each morning. Swipe down to refresh")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private var q3InfoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showQ3InfoPopup = false
                }
            
            // Simple popup content
            VStack(alignment: .leading, spacing: 8) {
                Text("Guided Questions")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• The guided question changes daily. The topics include gratitude, mindset, mental and physical health and other similar topics.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• These questions are designed to help you reflect on specific aspects of your life and well-being.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• After completing your entry, you have an option to tap the \"Insight\" button to receive customized AI insights.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("• New questions are automatically refreshed at 2 AM every morning.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Tips")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("The more detail you share, the more helpful and accurate the AI insights will be.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("If yesterday's question/entry still appear, you can refresh by swiping down.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Journal Reminder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                
                Text("Whether you like to journal early in the morning or right before bed, you can set your own reminder times in the Notifications section of the User Settings page.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private var goalInfoPopupView: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showGoalInfoPopup = false
                }
            
            // Popup content
            VStack(spacing: 8) {
                Text("Goals")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("You can enter a personal goal in this field (e.g. 'less worried' or 'more patient'), and the AI will tailor its insights around it.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Since goals can change, you can update your goal anytime by clicking the refresh button and entering a new one.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(hex: "E3E0C9"))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Loading Text Helper Function
    private func getLoadingText() -> String {
        if isLoadingGenerating || openIsLoadingGenerating {
            // Check retry attempt status
            switch journalViewModel.currentRetryAttempt {
            case 1:
                return "Generating..."
            case 2:
                return "Retrying..."
            case 3:
                return "Retrying again..."
            default:
                return "Generating..."
            }
        } else {
            return "Saving..."
        }
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

// MARK: - Timeout Helper Function
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out after 30 seconds"
    }
}

#Preview {
    ContentView()
}
