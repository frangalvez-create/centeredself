//
//  ContentView.swift
//  Centered
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    @State private var journalResponse: String = ""
    @State private var textEditorHeight: CGFloat = 150
    
    var body: some View {
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
            
            // Guided Question Text - Multiple lines allowed
            Text("What thing, person or moment filled you with gratitude today?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.textBlue)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            
            // Text Input Field - Dynamic height with proper sizing
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
                        .padding(20)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                        .frame(height: max(150, min(250, textEditorHeight)))
                        .onChange(of: journalResponse) { _ in
                            updateTextEditorHeight()
                        }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.backgroundBeige)
        .ignoresSafeArea(.all, edges: .top)
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
