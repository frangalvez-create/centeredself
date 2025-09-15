import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State variables for user information
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = Date()
    @State private var age: String = ""
    
    // State variables for notification settings
    @State private var notificationFrequency: String = "Weekly"
    @State private var streakEndingNotification: Bool = true
    
    var body: some View {
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
                    
                    // Profile Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Profile")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt left padding
                            .padding(.top, 30) // 30pt below Settings text
                        
                        // First Name Field
                        HStack {
                            Text("First Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .frame(maxWidth: 70) // Max 70pt wide
                                .padding(.leading, 40) // 40pt from left edge
                        }
                        .padding(.top, 10) // 10pt below Profile text
                        
                        // Last Name Field
                        HStack {
                            Text("Last Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
                            TextField("Enter last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .frame(maxWidth: 70) // Max 70pt wide
                                .padding(.leading, 40) // 40pt from left edge
                        }
                        
                        // Birthday Field
                        HStack {
                            Text("Birthday")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
                            DatePicker("", selection: $birthday, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .frame(maxWidth: 70) // Max 70pt wide
                                .padding(.leading, 40) // 40pt from left edge
                        }
                        
                        // Age Field
                        HStack {
                            Text("Age")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
                            TextField("Enter age", text: $age)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .frame(maxWidth: 30) // Max 30pt wide
                                .padding(.leading, 40) // 40pt from left edge
                        }
                    }
                    
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notifications")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt left padding
                            .padding(.top, 40) // 40pt below age field
                        
                        // Frequency Dropdown
                        HStack {
                            Text("Frequency")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
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
                                .frame(maxWidth: 70) // Max 70pt wide
                                .padding(.leading, 40) // 40pt from left edge
                            }
                        }
                        .padding(.top, 10) // 10pt below Notifications text
                        
                        // Streak Ending Toggle
                        HStack {
                            Text("Streak Ending")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 20) // 20pt from left edge
                            
                            Toggle("", isOn: $streakEndingNotification)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(maxWidth: 30) // Max 30pt wide
                                .padding(.leading, 40) // 40pt from left edge
                        }
                        .padding(.top, 10) // 10pt below Frequency
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadPersistedData()
            }
            .onChange(of: firstName) { _ in
                savePersistedData()
                updateUserProfile()
            }
            .onChange(of: lastName) { _ in
                savePersistedData()
            }
            .onChange(of: birthday) { _ in
                savePersistedData()
            }
            .onChange(of: age) { _ in
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
        if let savedFirstName = UserDefaults.standard.string(forKey: "firstName") {
            firstName = savedFirstName
        }
        if let savedLastName = UserDefaults.standard.string(forKey: "lastName") {
            lastName = savedLastName
        }
        if let savedAge = UserDefaults.standard.string(forKey: "age") {
            age = savedAge
        }
        if let savedFrequency = UserDefaults.standard.string(forKey: "notificationFrequency") {
            notificationFrequency = savedFrequency
        }
        streakEndingNotification = UserDefaults.standard.bool(forKey: "streakEndingNotification")
        
        // Load birthday
        if let savedBirthday = UserDefaults.standard.object(forKey: "birthday") as? Date {
            birthday = savedBirthday
        }
    }
    
    // Save data to UserDefaults
    private func savePersistedData() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(age, forKey: "age")
        UserDefaults.standard.set(notificationFrequency, forKey: "notificationFrequency")
        UserDefaults.standard.set(streakEndingNotification, forKey: "streakEndingNotification")
        UserDefaults.standard.set(birthday, forKey: "birthday")
    }
    
    // Update user profile in the app
    private func updateUserProfile() {
        if !firstName.isEmpty {
            Task {
                await journalViewModel.updateUserProfile(
                    firstName: firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    birthday: birthday,
                    age: age.isEmpty ? nil : age,
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
