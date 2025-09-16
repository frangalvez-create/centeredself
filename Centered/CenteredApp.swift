//
//  CenteredApp.swift
//  Centered
//
//  Created by Family Galvez on 8/31/25.
//

import SwiftUI

@main
struct CenteredApp: App {
    @StateObject private var journalViewModel = JournalViewModel()
    @State private var globalResetTimer: Timer?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalViewModel)
                .onAppear {
                    // Global timer disabled - using pull-to-refresh instead
                    // startGlobal2AMTimer()
                    // Check for existing authentication session on app startup
                    Task {
                        await journalViewModel.checkAuthenticationStatus()
                    }
                }
                .onDisappear {
                    // Global timer disabled - using pull-to-refresh instead
                    // stopGlobal2AMTimer()
                }
        }
    }
    
    // MARK: - Global 2AM Auto-Reset Timer (DISABLED - Using pull-to-refresh instead)
    
    private func startGlobal2AMTimer() {
        // Stop any existing timer
        globalResetTimer?.invalidate()
        
        // Create timer that fires every minute globally
        globalResetTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task {
                await journalViewModel.checkAndResetIfNeeded()
            }
        }
        
        print("🕐 Started GLOBAL 2AM reset timer - checking every minute")
    }
    
    private func stopGlobal2AMTimer() {
        globalResetTimer?.invalidate()
        globalResetTimer = nil
        print("🕐 Stopped GLOBAL 2AM reset timer")
    }
}
