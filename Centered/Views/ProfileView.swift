import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var journalViewModel: JournalViewModel
    @State private var showingSettings = false
    @State private var showingContact = false
    @State private var showingInfo = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Logo
            Image("Profile Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(.top, 58) // 58pt from top of screen
            
            // User Name
            Text("User")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "3F5E82"))
                .padding(.top, 10) // 10pt below profile logo
            
            // User Email
            Text(journalViewModel.currentUser?.email ?? "user@example.com")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "3F5E82"))
                .padding(.top, 10) // 10pt below user name
            
            // Statistics Section
            HStack {
                // Total Entries
                Text("Total Entries: \(journalViewModel.journalEntries.count)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .padding(.leading, 30) // 30pt from left edge
                
                Spacer()
                
                // Entry Streak
                Text("Entry Streak: 0") // TODO: Calculate actual streak
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "545555"))
                    .padding(.trailing, 30) // 30pt from right edge
            }
            .padding(.top, 20) // 20pt below email
            
            // Interactive Menu Sections
            VStack(spacing: 0) {
                // Settings Section
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image("setting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("Settings")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("setting forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Contact Section
                Button(action: {
                    showingContact = true
                }) {
                    HStack {
                        Image("mail")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("Contact")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("contact forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 25) // 25pt below Settings section
                
                // Info Section
                Button(action: {
                    showingInfo = true
                }) {
                    HStack {
                        Image("info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.leading, 10) // 10pt from left edge
                        
                        Text("Info")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.leading, 10) // 10pt to the right of icon
                        
                        Spacer()
                        
                        Image("info forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(.trailing, 20) // 20pt from right edge
                    }
                    .padding(.vertical, 15)
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 25) // 25pt below Contact section
            }
            .padding(.top, 80) // 80pt below statistics section
            .padding(.leading, 10) // 10pt more left padding
            
            Spacer()
            
            // Log Out Button (separate from menu container)
            Button(action: {
                Task {
                    await journalViewModel.signOut()
                }
            }) {
                Text("Log Out")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "3F5E82"))
            }
            .padding(.bottom, 40) // 40pt from bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "E3E0C9"))
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showingSettings) {
            // SettingsView will be created later
            Text("Settings Page - Coming Soon")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showingContact) {
            // ContactView will be created later
            Text("Contact Page - Coming Soon")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showingInfo) {
            // InfoView will be created later
            Text("Info Page - Coming Soon")
                .font(.title)
                .padding()
        }
    }
}


#Preview {
    ProfileView()
        .environmentObject(JournalViewModel())
}
