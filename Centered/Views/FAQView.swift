import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                        
                        // FAQ Title
                        Text("FAQ")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "3F5E82"))
                            .padding(.top, 25) // 25pt below logo
                        
                        // FAQ Content Sections
                        VStack(spacing: 20) {
                            // Question 1
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What is CenteredSelf?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 50) // 50pt below FAQ title
                                
                                Text("Centered is a journaling and self-reflection app designed to help you explore your thoughts and experiences, build self-awareness, ease stress, manage emotions, celebrate progress and set meaningful goals through guided prompts and AI-powered insights.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 2 - How often can I enter journals?
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How often can I enter journals?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("You can enter journal logs once a day into our guide question section and/or write freely into the lower section. Both give you the option for AI insights after you've entered your log. All daily journal entries will refresh overnight and new journaling opportunities will come available the next day.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 3 - How do I refresh the journal entries everyday?
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How do I refresh the journal entries everyday?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("All daily journal entries will refresh overnight and new journaling opportunities will come available the next day. If you still see yesterday's journal entry in the morning, simply give your phone a shake and it will clear.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 4
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How does the AI integration work?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("CenteredSelf uses OpenAI's language model to provide personalized journaling prompts, insights, and suggestions based on your entries. Your data is encrypted, processed and stored securely.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 3
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Is my data secure?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("Yes, we take your privacy seriously. Your journal entries are stored securely and are only accessible to you. We use industry-standard security measures to protect your data.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 4
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How do I get started?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("Simply create an account, verify your email, authenticate your One Time Passcode (OTP) and start journaling! You can choose from guided questions or write freely about anything on your mind. The AI will provide helpful insight and actions as you go.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 5
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Can I export my journal entries?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("Currently, you can view and edit your entries within the app. Export functionality is planned for future updates. Your data remains accessible to you at all times.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                            
                            // Question 6
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How do I contact support?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "3F5E82"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10) // 10pt left padding
                                    .padding(.top, 20) // 20pt below previous answer
                                
                                Text("You can reach us at centeredselfapp@gmail.com for any questions, feedback, or support needs. We typically respond within 24-48 hours.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "545555"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15) // 15pt left padding
                                    .padding(.trailing, 10) // 10pt right padding
                                    .padding(.top, 10) // 10pt below question
                            }
                        }
                        .frame(maxWidth: .infinity) // Expand to full width
                        .padding(.horizontal, 0) // Remove horizontal padding
                        .background(Color(hex: "E3E0C9")) // Background for main content
                    }
                    .frame(maxWidth: .infinity) // Expand main VStack to full width
                    .padding(.horizontal, 0) // Remove horizontal padding from main VStack
                }
                .frame(maxWidth: .infinity) // Expand ScrollView to full width
                .background(Color(hex: "E3E0C9")) // Background for ScrollView
                .navigationBarHidden(true)
            }
            .frame(maxWidth: .infinity) // Expand NavigationView to full width
        }
    }
}

#Preview {
    FAQView()
}
