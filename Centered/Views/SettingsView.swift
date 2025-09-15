import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State variables for user information
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    // State variables for notification settings
    @State private var notificationFrequency: String = "Weekly"
    @State private var streakEndingNotification: Bool = true
    
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
                    
                    // Profile and Notifications Section (Combined Container)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Profile")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt left padding
                            .padding(.top, 60) // 60pt below Settings text
                        
                        // First Name Field
                        HStack(spacing: 0) {
                            Text("First Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 10) // 10pt from left edge
                            
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .frame(maxWidth: 210) // Tripled: 70pt -> 210pt
                                .padding(.leading, 10) // 10pt spacing from label
                        }
                        .padding(.top, 10) // 10pt below Profile text
                        
                        // Last Name Field
                        HStack(spacing: 0) {
                            Text("Last Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 10) // 10pt from left edge
                            
                            TextField("Enter last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .frame(maxWidth: 210) // Tripled: 70pt -> 210pt
                                .padding(.leading, 10) // 10pt spacing from label
                        }
                        
                        
                        // Notifications Header
                        Text("Notifications")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt left padding
                            .padding(.top, 50) // 50pt below Last Name field
                        
                        // Frequency Dropdown
                        HStack(spacing: 0) {
                            Text("Frequency")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 10) // 10pt from left edge
                            
                            Menu {
                                Button("Weekly") {
                                    notificationFrequency = "Weekly"
                                }
                                Button("Monthly") {
                                    notificationFrequency = "Monthly"
                                }
                            } label: {
                                HStack {
                                    Text(notificationFrequency)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "3F5E82"))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "3F5E82"))
                                }
                                .frame(maxWidth: 140) // Doubled: 70pt -> 140pt
                                .padding(.leading, 10) // 10pt spacing from label
                            }
                        }
                        .padding(.top, 10) // 10pt below Notifications text
                        
                        // Streak Ending Toggle
                        HStack(spacing: 0) {
                            Text("Streak Ending")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 10) // 10pt from left edge
                            
                            Toggle("", isOn: $streakEndingNotification)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(maxWidth: 30) // Keep toggle size
                                .padding(.leading, 25) // 25pt spacing from label
                        }
                        .padding(.top, 10) // 10pt below Frequency
                    }
                }
                .frame(maxWidth: .infinity) // Expand to full width
                .padding(.horizontal, 0) // Remove horizontal padding
                .background(Color(hex: "E3E0C9")) // Background for main content
            }
            .frame(maxWidth: .infinity) // Expand ScrollView to full width
            .background(Color(hex: "E3E0C9")) // Background for ScrollView
            .navigationBarHidden(true)
        }
        .frame(maxWidth: .infinity) // Expand NavigationView to full width
        .onAppear {
            loadPersistedData()
        }
        
        // Swipe Down Text - positioned at bottom of screen
        VStack {
            Spacer()
            Text("Swipe Down")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "545555"))
                .opacity(0.7) // 70% opacity
                .padding(.bottom, 30) // 30pt from bottom
        }
        .onChange(of: firstName) { _ in
            savePersistedData()
            updateUserProfile()
        }
        .onChange(of: lastName) { _ in
            savePersistedData()
        }
        .onChange(of: notificationFrequency) { _ in
            savePersistedData()
        }
        .onChange(of: streakEndingNotification) { _ in
            savePersistedData()
        }
    }
}
    
    // Load persisted data from UserDefaults
    private func loadPersistedData() {
        // Get user-specific keys to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let firstNameKey = "firstName_\(userId)"
        let lastNameKey = "lastName_\(userId)"
        let frequencyKey = "notificationFrequency_\(userId)"
        let streakKey = "streakEndingNotification_\(userId)"
        
        if let savedFirstName = UserDefaults.standard.string(forKey: firstNameKey) {
            firstName = savedFirstName
        }
        if let savedLastName = UserDefaults.standard.string(forKey: lastNameKey) {
            lastName = savedLastName
        }
        if let savedFrequency = UserDefaults.standard.string(forKey: frequencyKey) {
            notificationFrequency = savedFrequency
        }
        streakEndingNotification = UserDefaults.standard.bool(forKey: streakKey)
    }
    
    // Save data to UserDefaults
    private func savePersistedData() {
        // Get user-specific keys to prevent data leakage between users
        let userId = journalViewModel.currentUser?.id.uuidString ?? "anonymous"
        let firstNameKey = "firstName_\(userId)"
        let lastNameKey = "lastName_\(userId)"
        let frequencyKey = "notificationFrequency_\(userId)"
        let streakKey = "streakEndingNotification_\(userId)"
        
        UserDefaults.standard.set(firstName, forKey: firstNameKey)
        UserDefaults.standard.set(lastName, forKey: lastNameKey)
        UserDefaults.standard.set(notificationFrequency, forKey: frequencyKey)
        UserDefaults.standard.set(streakEndingNotification, forKey: streakKey)
    }
    
    // Update user profile in the app
    private func updateUserProfile() {
        if !firstName.isEmpty {
            Task {
                await journalViewModel.updateUserProfile(
                    firstName: firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    notificationFrequency: notificationFrequency,
                    streakEndingNotification: streakEndingNotification
                )
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(JournalViewModel())
}
