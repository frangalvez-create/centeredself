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
                        .frame(height: max(150, min(250, textEditorHeight)))
                    
                    // Text Editor
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
                        .onChange(of: journalResponse) { _ in
                            updateTextEditorHeight()
                        }
                    
                    // Text Edit Button Centered (only show when text is locked)
                    if isTextLocked {
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
                                doneButtonTapped()
                            }) {
                                Image(showCenteredButton ? "Centered Button" : "Done Button")
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
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth = UIScreen.main.bounds.width - 100 // Account for padding
        
        let boundingRect = journalResponse.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Calculate height with padding and minimum constraints
        let calculatedHeight = boundingRect.height + 60 // Extra padding for comfort
        textEditorHeight = max(150, min(250, calculatedHeight))
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
    
    private func editLogSelected() {
        // Close dropdown
        showTextEditDropdown = false
        
        // Revert to editable state
        isTextLocked = false
        showCenteredButton = false
        
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
