import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State variables for First Name field (duplicated from goals field)
    @State private var firstNameText: String = ""
    @State private var isFirstNameLocked: Bool = false
    @State private var showFirstNameRefreshButton: Bool = false
    
    // State variables for Last Name field (duplicated from First Name field)
    @State private var lastNameText: String = ""
    @State private var isLastNameLocked: Bool = false
    @State private var showLastNameRefreshButton: Bool = false
    
    // State variables for Gender field (duplicated from Last Name field)
    @State private var genderText: String = ""
    @State private var isGenderLocked: Bool = false
    @State private var showGenderRefreshButton: Bool = false
    
    // State variables for Occupation field (duplicated from Gender field)
    @State private var occupationText: String = ""
    @State private var isOccupationLocked: Bool = false
    @State private var showOccupationRefreshButton: Bool = false
    
    // State variables for Birthdate field (duplicated from Occupation field)
    @State private var birthdateText: String = ""
    @State private var isBirthdateLocked: Bool = false
    @State private var showBirthdateRefreshButton: Bool = false
    
    // State variables for Daily Notification Reminders
    @AppStorage("morning_reminder_enabled") private var morningReminder: Bool = false
    @AppStorage("work_am_break_reminder_enabled") private var workAMBreakReminder: Bool = false
    @AppStorage("lunch_reminder_enabled") private var lunchReminder: Bool = false
    @AppStorage("work_pm_break_reminder_enabled") private var workPMBreakReminder: Bool = false
    @AppStorage("evening_reminder_enabled") private var eveningReminder: Bool = false
    @AppStorage("before_bed_reminder_enabled") private var beforeBedReminder: Bool = false
    
    // State variable for Weekly Notification Reminder
    @AppStorage("weekly_reminder_enabled") private var weeklyReminder: Bool = true // Pre-enabled as requested
    
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
                    
                    // User Settings Title
                    Text("User Settings")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "3F5E82"))
                        .padding(.top, 25) // 25pt below logo
                    
                    // User Profile section - 30pt below Settings text
                    VStack(spacing: 4) {
                        HStack {
                            Text("User Profile")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                        .padding(.leading, 0) // 0pt horizontal position
                    }
                    .padding(.top, 30) // 30pt below Settings text
                    
                    // First Name section - 10pt below User Profile
                    VStack(spacing: 4) {
                        HStack {
                            Text("First Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                            
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
                                .frame(width: UIScreen.main.bounds.width * 0.5) // Fixed width
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
                            .padding(.trailing, 15) // 15pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below User Profile section
                    
                    // Last Name section - directly below First Name
                    VStack(spacing: 4) {
                        HStack {
                            Text("Last Name")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                            
                            // Last Name text field with button overlay
                            ZStack(alignment: .trailing) {
                                // Single-line TextField instead of TextEditor
                                TextField("", text: $lastNameText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 15)
                                .padding(.trailing, (isLastNameLocked || lastNameText.isEmpty) ? 15 : 50) // Make room for button when unlocked and has text
                                .padding(.vertical, 6) // Vertical padding for single line
                                .background(Color(hex: "F5F4EB"))
                                .cornerRadius(8)
                                .disabled(isLastNameLocked) // Disable editing when locked
                                .frame(width: UIScreen.main.bounds.width * 0.5) // Fixed width
                                .onChange(of: lastNameText) { _ in
                                    // Character limit for single line
                                    if lastNameText.count > 50 {
                                        lastNameText = String(lastNameText.prefix(50))
                                    }
                                }
                                
                                // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                                if !lastNameText.isEmpty {
                                    Button(action: {
                                    if showLastNameRefreshButton {
                                        // CP Refresh button clicked - reset
                                        cpLastNameRefreshButtonTapped()
                                    } else {
                                        // CP Done button clicked - lock in
                                        cpLastNameDoneButtonTapped()
                                    }
                                }) {
                                    Image(showLastNameRefreshButton ? "CP Refresh" : "CP Done")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(showLastNameRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                                }
                                .padding(.trailing, 5) // 5pt from right edge
                                }
                            }
                            .padding(.trailing, 15) // 15pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below First Name section
                    
                    // Gender section - directly below Last Name
                    VStack(spacing: 4) {
                        HStack {
                            Text("Gender*")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                            
                            // Gender text field with button overlay
                            ZStack(alignment: .trailing) {
                                // Single-line TextField instead of TextEditor
                                TextField("", text: $genderText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 15)
                                .padding(.trailing, (isGenderLocked || genderText.isEmpty) ? 15 : 50) // Make room for button when unlocked and has text
                                .padding(.vertical, 6) // Vertical padding for single line
                                .background(Color(hex: "F5F4EB"))
                                .cornerRadius(8)
                                .disabled(isGenderLocked) // Disable editing when locked
                                .frame(width: UIScreen.main.bounds.width * 0.5) // Fixed width
                                .onChange(of: genderText) { _ in
                                    // Character limit for single line
                                    if genderText.count > 50 {
                                        genderText = String(genderText.prefix(50))
                                    }
                                }
                                
                                // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                                if !genderText.isEmpty {
                                    Button(action: {
                                    if showGenderRefreshButton {
                                        // CP Refresh button clicked - reset
                                        cpGenderRefreshButtonTapped()
                                    } else {
                                        // CP Done button clicked - lock in
                                        cpGenderDoneButtonTapped()
                                    }
                                }) {
                                    Image(showGenderRefreshButton ? "CP Refresh" : "CP Done")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(showGenderRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                                }
                                .padding(.trailing, 5) // 5pt from right edge
                                }
                            }
                            .padding(.trailing, 15) // 15pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Last Name section
                    
                    // Occupation section - directly below Gender
                    VStack(spacing: 4) {
                                HStack {
                            Text("Occupation*")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                            
                            // Occupation text field with button overlay
                            ZStack(alignment: .trailing) {
                                // Single-line TextField instead of TextEditor
                                TextField("", text: $occupationText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 15)
                                .padding(.trailing, (isOccupationLocked || occupationText.isEmpty) ? 15 : 50) // Make room for button when unlocked and has text
                                .padding(.vertical, 6) // Vertical padding for single line
                                .background(Color(hex: "F5F4EB"))
                                .cornerRadius(8)
                                .disabled(isOccupationLocked) // Disable editing when locked
                                .frame(width: UIScreen.main.bounds.width * 0.5) // Fixed width
                                .onChange(of: occupationText) { _ in
                                    // Character limit for single line
                                    if occupationText.count > 50 {
                                        occupationText = String(occupationText.prefix(50))
                                    }
                                }
                                
                                // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                                if !occupationText.isEmpty {
                                    Button(action: {
                                    if showOccupationRefreshButton {
                                        // CP Refresh button clicked - reset
                                        cpOccupationRefreshButtonTapped()
                                    } else {
                                        // CP Done button clicked - lock in
                                        cpOccupationDoneButtonTapped()
                                    }
                                }) {
                                    Image(showOccupationRefreshButton ? "CP Refresh" : "CP Done")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(showOccupationRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                                }
                                .padding(.trailing, 5) // 5pt from right edge
                                }
                            }
                            .padding(.trailing, 15) // 15pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Gender section
                    
                    // Birthdate section - directly below Occupation
                    VStack(spacing: 4) {
                        HStack {
                            Text("Birthdate*")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                            
                            // Birthdate text field with button overlay
                            ZStack(alignment: .trailing) {
                                // Single-line TextField with placeholder
                                TextField("mm/dd/yyyy", text: $birthdateText)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 15)
                                .padding(.trailing, (isBirthdateLocked || birthdateText.isEmpty) ? 15 : 50) // Make room for button when unlocked and has text
                                .padding(.vertical, 6) // Vertical padding for single line
                                .background(Color(hex: "F5F4EB"))
                                .cornerRadius(8)
                                .disabled(isBirthdateLocked) // Disable editing when locked
                                .frame(width: UIScreen.main.bounds.width * 0.5) // Same width as other fields
                                .onChange(of: birthdateText) { _ in
                                    // Character limit for single line
                                    if birthdateText.count > 50 {
                                        birthdateText = String(birthdateText.prefix(50))
                                    }
                                }
                                
                                // CP Done/Refresh Button positioned at the right edge (only show when text is entered)
                                if !birthdateText.isEmpty {
                                    Button(action: {
                                    if showBirthdateRefreshButton {
                                        // CP Refresh button clicked - reset
                                        cpBirthdateRefreshButtonTapped()
                                    } else {
                                        // CP Done button clicked - lock in
                                        cpBirthdateDoneButtonTapped()
                                    }
                                }) {
                                    Image(showBirthdateRefreshButton ? "CP Refresh" : "CP Done")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(showBirthdateRefreshButton ? 0.6 : 0.8) // 60% opacity for CP Refresh, 80% for CP Done
                                }
                                .padding(.trailing, 5) // 5pt from right edge
                                }
                            }
                            .padding(.trailing, 15) // 15pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Occupation section
                    
                    // Notification section - 20pt below Birthdate section
                    VStack(spacing: 4) {
                        HStack {
                            Text("Notification")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                        .padding(.leading, 0) // 0pt horizontal position
                    }
                    .padding(.top, 40) // 40pt below Birthdate section
                    
                    // Daily Notification Reminder section - directly below Notification
                    VStack(spacing: 4) {
                        HStack {
                            Text("Daily Journal Reminder")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Notification section
                    
                    // Daily Notification Reminder Options
                    VStack(spacing: 10) {
                        // 7:00 AM - Morning
                        HStack {
                            Text("7:00 am - Morning")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $morningReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: morningReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 7, minute: 0, identifier: "morning_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                        
                        // 9:30 AM - Work AM Break
                        HStack {
                            Text("9:30 am - Work AM Break")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $workAMBreakReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: workAMBreakReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 9, minute: 30, identifier: "work_am_break_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                        
                        // 12:00 PM - Lunch
                        HStack {
                            Text("12:00 pm - Lunch")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $lunchReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: lunchReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 12, minute: 0, identifier: "lunch_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                        
                        // 3:00 PM - Work PM Break
                        HStack {
                            Text("3:00 pm - Work PM Break")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $workPMBreakReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: workPMBreakReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 15, minute: 0, identifier: "work_pm_break_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                        
                        // 6:00 PM - Evening
                        HStack {
                            Text("6:00 pm - Evening")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $eveningReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: eveningReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 18, minute: 0, identifier: "evening_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                        
                        // 9:30 PM - Before Bed
                        HStack {
                            Text("9:30 pm - Before Bed")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $beforeBedReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: beforeBedReminder) { isOn in
                                    handleNotificationToggle(isOn: isOn, hour: 21, minute: 30, identifier: "before_bed_reminder")
                                }
                                .padding(.trailing, 30)
                        }
                    }
                    .padding(.top, 15) // 15pt below Daily Notification Reminder text
                    
                    // Weekly Journal Reminder section - 20pt below Daily Journal Reminder Options
                    VStack(spacing: 4) {
                        HStack {
                            Text("Weekly Journal Reminder")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3F5E82"))
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 20) // 20pt below Daily Journal Reminder Options
                    
                    // Weekly Journal Reminder Option
                    VStack(spacing: 10) {
                        // Sunday 8:00 PM - End of Week
                        HStack {
                            Text("End of Week")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "545555"))
                                .padding(.leading, 70)
                            
                            Spacer()
                            
                            Toggle("", isOn: $weeklyReminder)
                                .toggleStyle(SwitchToggleStyle())
                                .frame(width: 45, height: 20)
                                .scaleEffect(0.8)
                                .onChange(of: weeklyReminder) { isOn in
                                    handleWeeklyNotificationToggle(isOn: isOn)
                                }
                                .padding(.trailing, 30)
                        }
                    }
                    .padding(.top, 15) // 15pt below Weekly Journal Reminder text
                    
                    // AI Enhancement Note - 25pt below Weekly Journal Reminder section
                    Text("* these elements will be used to further enhance the AI insights response")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "545555"))
                        .opacity(0.8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 40)
                        .padding(.top, 25) // 25pt below Daily Notification Reminder section
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
                .background(Color(hex: "E3E0C9"))
                .navigationBarHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
            .onAppear {
                loadFirstNameFromDatabase()
                loadLastNameFromDatabase()
                loadGenderFromDatabase()
                loadOccupationFromDatabase()
                loadBirthdateFromDatabase()
                loadNotificationStates()
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
        
    }
    
    private func cpFirstNameRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()        
        // Reset the first name entry process
        firstNameText = ""
        isFirstNameLocked = false
        showFirstNameRefreshButton = false
        
    }
    
    private func saveFirstNameToDatabase(_ firstName: String) async {
        guard !firstName.isEmpty else { return }
        
        do {
            // Load current profile to preserve existing lastName
            let currentProfile = try await journalViewModel.supabaseService.loadUserProfile()
            
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: firstName,
                lastName: currentProfile?.lastName, // Preserve existing lastName
                gender: currentProfile?.gender, // Preserve existing gender
                occupation: currentProfile?.occupation, // Preserve existing occupation
                birthdate: currentProfile?.birthdate, // Preserve existing birthdate
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
        } catch {
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
                } else {
                }
            } catch {
            }
        }
    }
    
    // MARK: - Last Name Functions (duplicated from First Name functions)
    
    private func cpLastNameDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isLastNameLocked = true
        showLastNameRefreshButton = true        
        // Save last name to database
        Task {
            await saveLastNameToDatabase(lastNameText)
        }
        
    }
    
    private func cpLastNameRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()        
        // Reset the last name entry process
        lastNameText = ""
        isLastNameLocked = false
        showLastNameRefreshButton = false
        
    }
    
    private func saveLastNameToDatabase(_ lastName: String) async {
        guard !lastName.isEmpty else { return }
        
        do {
            // Load current profile to preserve existing firstName
            let currentProfile = try await journalViewModel.supabaseService.loadUserProfile()
            
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: currentProfile?.firstName, // Preserve existing firstName
                lastName: lastName,
                gender: currentProfile?.gender, // Preserve existing gender
                occupation: currentProfile?.occupation, // Preserve existing occupation
                birthdate: currentProfile?.birthdate, // Preserve existing birthdate
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
        } catch {
        }
    }
    
    private func loadLastNameFromDatabase() {
        Task {
            do {
                let profile = try await journalViewModel.supabaseService.loadUserProfile()
                if let profile = profile, let lastName = profile.lastName, !lastName.isEmpty {
                    lastNameText = lastName
                    isLastNameLocked = true
                    showLastNameRefreshButton = true
                } else {
                }
            } catch {
            }
        }
    }
    
    // MARK: - Gender Functions (duplicated from Last Name functions)
    
    private func cpGenderDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isGenderLocked = true
        showGenderRefreshButton = true        
        // Save gender to database
        Task {
            await saveGenderToDatabase(genderText)
        }
        
    }
    
    private func cpGenderRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()        
        // Reset the gender entry process
        genderText = ""
        isGenderLocked = false
        showGenderRefreshButton = false
        
    }
    
    private func saveGenderToDatabase(_ gender: String) async {
        guard !gender.isEmpty else { return }
        
        do {
            // Load current profile to preserve existing firstName and lastName
            let currentProfile = try await journalViewModel.supabaseService.loadUserProfile()
            
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: currentProfile?.firstName, // Preserve existing firstName
                lastName: currentProfile?.lastName, // Preserve existing lastName
                gender: gender,
                occupation: currentProfile?.occupation, // Preserve existing occupation
                birthdate: currentProfile?.birthdate, // Preserve existing birthdate
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
        } catch {
        }
    }
    
    private func loadGenderFromDatabase() {
        Task {
            do {
                let profile = try await journalViewModel.supabaseService.loadUserProfile()
                if let profile = profile, let gender = profile.gender, !gender.isEmpty {
                    genderText = gender
                    isGenderLocked = true
                    showGenderRefreshButton = true
                } else {
                }
            } catch {
            }
        }
    }
    
    // MARK: - Occupation Functions (duplicated from Gender functions)
    
    private func cpOccupationDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isOccupationLocked = true
        showOccupationRefreshButton = true        
        // Save occupation to database
        Task {
            await saveOccupationToDatabase(occupationText)
        }
        
    }
    
    private func cpOccupationRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()        
        // Reset the occupation entry process
        occupationText = ""
        isOccupationLocked = false
        showOccupationRefreshButton = false
        
    }
    
    private func saveOccupationToDatabase(_ occupation: String) async {
        guard !occupation.isEmpty else { return }
        
        do {
            // Load current profile to preserve existing firstName, lastName, and gender
            let currentProfile = try await journalViewModel.supabaseService.loadUserProfile()
            
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: currentProfile?.firstName, // Preserve existing firstName
                lastName: currentProfile?.lastName, // Preserve existing lastName
                gender: currentProfile?.gender, // Preserve existing gender
                occupation: occupation,
                birthdate: currentProfile?.birthdate, // Preserve existing birthdate
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
        } catch {
        }
    }
    
    private func loadOccupationFromDatabase() {
        Task {
            do {
                let profile = try await journalViewModel.supabaseService.loadUserProfile()
                if let profile = profile, let occupation = profile.occupation, !occupation.isEmpty {
                    occupationText = occupation
                    isOccupationLocked = true
                    showOccupationRefreshButton = true
                } else {
                }
            } catch {
            }
        }
    }
    
    // MARK: - Birthdate Functions (duplicated from Occupation functions)
    
    private func cpBirthdateDoneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Lock the text field and show refresh button
        isBirthdateLocked = true
        showBirthdateRefreshButton = true        
        // Save birthdate to database
            Task {
            await saveBirthdateToDatabase(birthdateText)
        }
        
    }
    
    private func cpBirthdateRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()        
        // Reset the birthdate entry process
        birthdateText = ""
        isBirthdateLocked = false
        showBirthdateRefreshButton = false
        
    }
    
    private func saveBirthdateToDatabase(_ birthdate: String) async {
        guard !birthdate.isEmpty else { return }
        
        do {
            // Load current profile to preserve existing firstName, lastName, gender, and occupation
            let currentProfile = try await journalViewModel.supabaseService.loadUserProfile()
            
            try await journalViewModel.supabaseService.updateUserProfile(
                firstName: currentProfile?.firstName, // Preserve existing firstName
                lastName: currentProfile?.lastName, // Preserve existing lastName
                gender: currentProfile?.gender, // Preserve existing gender
                occupation: currentProfile?.occupation, // Preserve existing occupation
                birthdate: birthdate, // New birthdate value
                notificationFrequency: nil,
                streakEndingNotification: nil
            )
        } catch {
        }
    }
    
    private func loadBirthdateFromDatabase() {
        Task {
            do {
                let profile = try await journalViewModel.supabaseService.loadUserProfile()
                if let profile = profile, let birthdate = profile.birthdate, !birthdate.isEmpty {
                    birthdateText = birthdate
                    isBirthdateLocked = true
                    showBirthdateRefreshButton = true
                } else {
                    // Ensure text field is empty to show placeholder
                    birthdateText = ""
                    isBirthdateLocked = false
                    showBirthdateRefreshButton = false
                }
            } catch {
                // Ensure text field is empty to show placeholder on error
                birthdateText = ""
                isBirthdateLocked = false
                showBirthdateRefreshButton = false
            }
        }
    }
    
    // MARK: - Notification Management Functions
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Handle authorization result
        }
    }
    
    private func handleNotificationToggle(isOn: Bool, hour: Int, minute: Int, identifier: String) {
        if isOn {
            scheduleNotification(hour: hour, minute: minute, identifier: identifier)
        } else {
            cancelNotification(identifier: identifier)
        }
    }
    
    private func scheduleNotification(hour: Int, minute: Int, identifier: String) {
        // Request permission first
        requestNotificationAuthorization()
        
        let content = UNMutableNotificationContent()
        
        // Set different titles and bodies based on time
        switch (hour, minute) {
        case (7, 0), (9, 30):
            content.title = "Morning Journal Reminder"
            content.body = "Quick journal session to start your day?"
        case (12, 0), (15, 0):
            content.title = "Daily Journal Reminder"
            content.body = "Ready to journal?"
        case (18, 0), (21, 30):
            content.title = "Evening Journal Reminder"
            content.body = "How did your day go?"
        default:
            content.title = "Daily Journal Reminder"
            content.body = "Have you journaled today?"
        }
        
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            // Handle scheduling result
        }
    }
    
    private func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    private func loadNotificationStates() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                let identifiers = requests.map { $0.identifier }
                
                // Reschedule missing notifications if @AppStorage says they should be on
                // @AppStorage is the source of truth, so we don't overwrite it
                if morningReminder && !identifiers.contains("morning_reminder") {
                    scheduleNotification(hour: 7, minute: 0, identifier: "morning_reminder")
                }
                if workAMBreakReminder && !identifiers.contains("work_am_break_reminder") {
                    scheduleNotification(hour: 9, minute: 30, identifier: "work_am_break_reminder")
                }
                if lunchReminder && !identifiers.contains("lunch_reminder") {
                    scheduleNotification(hour: 12, minute: 0, identifier: "lunch_reminder")
                }
                if workPMBreakReminder && !identifiers.contains("work_pm_break_reminder") {
                    scheduleNotification(hour: 15, minute: 0, identifier: "work_pm_break_reminder")
                }
                if eveningReminder && !identifiers.contains("evening_reminder") {
                    scheduleNotification(hour: 18, minute: 0, identifier: "evening_reminder")
                }
                if beforeBedReminder && !identifiers.contains("before_bed_reminder") {
                    scheduleNotification(hour: 21, minute: 30, identifier: "before_bed_reminder")
                }
                
                // Weekly reminder: reschedule if it should be on but is missing
                if weeklyReminder && !identifiers.contains("weekly_reminder") {
                    scheduleWeeklyNotification()
                }
            }
        }
    }
    
    // MARK: - Weekly Notification Management Functions
    
    private func handleWeeklyNotificationToggle(isOn: Bool) {
        if isOn {
            scheduleWeeklyNotification()
        } else {
            cancelNotification(identifier: "weekly_reminder")
        }
    }
    
    private func scheduleWeeklyNotification() {
        // Request permission first
        requestNotificationAuthorization()
        
        let content = UNMutableNotificationContent()
        content.title = "End of Week Journal Reminder"
        content.body = "How did your week go? Want to journal about it?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday (1 = Sunday, 2 = Monday, etc.)
        dateComponents.hour = 20 // 8:00 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            // Handle scheduling result
        }
    }
    
}

#Preview {
    SettingsView()
        .environmentObject(JournalViewModel())
}