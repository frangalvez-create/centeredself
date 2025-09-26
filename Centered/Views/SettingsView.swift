import SwiftUI

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
                    
                    // First Name section - 70pt below Settings text
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
                            .padding(.trailing, 20) // 20pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 70) // 70pt below Settings text
                    
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
                            .padding(.trailing, 20) // 20pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below First Name section
                    
                    // Gender section - directly below Last Name
                    VStack(spacing: 4) {
                        HStack {
                            Text("Gender")
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
                            .padding(.trailing, 20) // 20pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Last Name section
                    
                    // Occupation section - directly below Gender
                    VStack(spacing: 4) {
                                HStack {
                            Text("Occupation")
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
                            .padding(.trailing, 20) // 20pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Gender section
                    
                    // Birthdate section - directly below Occupation
                    VStack(spacing: 4) {
                        HStack {
                            Text("Birthdate")
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
                            .padding(.trailing, 20) // 20pt from right edge of screen
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40) // Overall horizontal padding
                    }
                    .padding(.top, 10) // 10pt below Occupation section
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
                        print("🔄 SettingsView onAppear called")
                        loadFirstNameFromDatabase()
                        loadLastNameFromDatabase()
                        loadGenderFromDatabase()
                        loadOccupationFromDatabase()
                        loadBirthdateFromDatabase()
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
        
        print("✅ Last Name saved: \(lastNameText)")
    }
    
    private func cpLastNameRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the last name entry process
        lastNameText = ""
        isLastNameLocked = false
        showLastNameRefreshButton = false
        
        print("CP Refresh button clicked - Last Name entry reset")
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
            print("✅ Last Name saved successfully: \(lastName)")
        } catch {
            print("❌ Failed to save last name: \(error)")
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
                    print("✅ Last Name loaded from database: \(lastName)")
                } else {
                    print("ℹ️ No last name found in database")
                }
            } catch {
                print("❌ Failed to load last name: \(error)")
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
        
        print("✅ Gender saved: \(genderText)")
    }
    
    private func cpGenderRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the gender entry process
        genderText = ""
        isGenderLocked = false
        showGenderRefreshButton = false
        
        print("CP Refresh button clicked - Gender entry reset")
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
            print("✅ Gender saved successfully: \(gender)")
        } catch {
            print("❌ Failed to save gender: \(error)")
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
                    print("✅ Gender loaded from database: \(gender)")
                } else {
                    print("ℹ️ No gender found in database")
                }
            } catch {
                print("❌ Failed to load gender: \(error)")
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
        
        print("✅ Occupation saved: \(occupationText)")
    }
    
    private func cpOccupationRefreshButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset the occupation entry process
        occupationText = ""
        isOccupationLocked = false
        showOccupationRefreshButton = false
        
        print("CP Refresh button clicked - Occupation entry reset")
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
            print("✅ Occupation saved successfully: \(occupation)")
        } catch {
            print("❌ Failed to save occupation: \(error)")
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
                                print("✅ Occupation loaded from database: \(occupation)")
                            } else {
                                print("ℹ️ No occupation found in database")
                            }
                        } catch {
                            print("❌ Failed to load occupation: \(error)")
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
                    
                    print("✅ Birthdate saved: \(birthdateText)")
                }
                
                private func cpBirthdateRefreshButtonTapped() {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Reset the birthdate entry process
                    birthdateText = ""
                    isBirthdateLocked = false
                    showBirthdateRefreshButton = false
                    
                    print("CP Refresh button clicked - Birthdate entry reset")
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
                        print("✅ Birthdate saved successfully: \(birthdate)")
                    } catch {
                        print("❌ Failed to save birthdate: \(error)")
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
                                print("✅ Birthdate loaded from database: \(birthdate)")
                            } else {
                                print("ℹ️ No birthdate found in database")
                            }
                        } catch {
                            print("❌ Failed to load birthdate: \(error)")
                        }
                    }
                }
}

#Preview {
    SettingsView()
        .environmentObject(JournalViewModel())
}