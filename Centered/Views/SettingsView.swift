import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State variables for First Name field (duplicated from goals field)
    @State private var firstNameText: String = ""
    @State private var isFirstNameLocked: Bool = false
    @State private var showFirstNameRefreshButton: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "E3E0C9")
                .ignoresSafeArea(.all)
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 0) {
                    // Profile Logo
                    Image("Profile Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .padding(.top, 20) // 20pt from top
                    
                    // Settings Title
                    Text("Settings")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .padding(.top, 25) // 25pt below logo
                    
                    // First Name section - 30pt below Settings text
                    VStack(spacing: 4) {
                        HStack(spacing: 15) {
                            Text("First Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                            
                            // First Name text field with button overlay
                            ZStack(alignment: .trailing) {
                                // Single-line TextField instead of TextEditor
                                TextField("", text: $firstNameText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 15)
                                .padding(.trailing, (isFirstNameLocked || firstNameText.isEmpty) ? 15 : 50) // Make room for button when unlocked and has text
                                .padding(.vertical, 6) // Vertical padding for single line
                                .background(Color(hex: "F5F4EB"))
                                .cornerRadius(8)
                                .disabled(isFirstNameLocked) // Disable editing when locked
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.4) // Reduced width to fit in HStack
                                .onChange(of: firstNameText) { _ in
                                    // Character limit for single line
                                    if firstNameText.count > 50 {
                                        firstNameText = String(firstNameText.prefix(50))
                                    }
                                }
                                
                                // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                                if !firstNameText.isEmpty {
                                    Button(action: {
                                    if showFirstNameRefreshButton {
                                        // CP Refresh button clicked - reset
                                        cpFirstNameRefreshButtonTapped()
                                    } else {
                                        // CP Done button clicked - lock in
                                        cpFirstNameDoneButtonTapped()
                                    }
                                }) {
                                    Image(showFirstNameRefreshButton ? "CP Refresh" : "CP Done")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(showFirstNameRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                                }
                                .padding(.trailing, 5) // 5pt from right edge
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 30) // 30pt below Settings text
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 0)
                    .background(Color(hex: "E3E0C9"))
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "E3E0C9"))
                .navigationBarHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            loadFirstNameFromDatabase()
        }
    }
    
    // MARK: - Functions (duplicated from goals field)
    
    private func cpFirstNameDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isFirstNameLocked = true
        showFirstNameRefreshButton = true
        
        // Save first name to database
        Task {
            await saveFirstNameToDatabase(firstNameText)
        }
        
        print("✅ First Name saved: \(firstNameText)")
    }
    
    private func cpFirstNameRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the first name entry process
        firstNameText = ""
        isFirstNameLocked = false
        showFirstNameRefreshButton = false
        
        print("CP Refresh button clicked - First Name entry reset")
    }
    
    private func saveFirstNameToDatabase(_ firstName: String) async {
        guard !firstName.isEmpty else { return }
        
        do {
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: firstName,
                lastName: nil,
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
            print("✅ First Name saved successfully: \(firstName)")
        } catch {
            print("❌ Failed to save first name: \(error)")
        }
    }
    
    private func loadFirstNameFromDatabase() {
        Task {
            do {
                let profile = try await journalViewModel.supabaseService.loadUserProfile()
                if let profile = profile, let firstName = profile.firstName, !firstName.isEmpty {
                    firstNameText = firstName
                    isFirstNameLocked = true
                    showFirstNameRefreshButton = true
                    print("✅ First Name loaded from database: \(firstName)")
                } else {
                    print("ℹ️ No first name found in database")
                }
            } catch {
                print("❌ Failed to load first name: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(JournalViewModel())
}