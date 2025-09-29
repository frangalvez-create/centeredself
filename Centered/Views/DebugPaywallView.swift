import SwiftUI
import RevenueCat
import RevenueCatUI

struct DebugPaywallView: View {
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading paywall...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Paywall Error")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    // Try to show the actual paywall
                    if revenueCatService.offerings?.current != nil {
                        PaywallView()
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("No Offering Available")
                                .font(.headline)
                            Text("Please configure an offering in your RevenueCat dashboard")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
                
                // Debug information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Info:")
                        .font(.headline)
                    
                    Text("Offerings: \(revenueCatService.offerings?.all.count ?? 0)")
                    Text("Customer Info: \(revenueCatService.customerInfo != nil ? "Loaded" : "Not loaded")")
                    Text("Is Premium: \(revenueCatService.isPremium)")
                    
                    if let offerings = revenueCatService.offerings {
                        Text("Current Offering: \(offerings.current?.identifier ?? "None")")
                        Text("Available Packages: \(offerings.current?.availablePackages.count ?? 0)")
                        
                        // Show all available offerings
                        if !offerings.all.isEmpty {
                            Text("All Offerings:")
                            ForEach(Array(offerings.all.keys), id: \.self) { key in
                                Text("  - \(key)")
                            }
                        }
                    }
                }
                .font(.caption)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // This will be handled by the parent view
                    }
                }
            }
        }
        .onAppear {
            loadPaywallData()
        }
    }
    
    private func loadPaywallData() {
        Task {
            // Load offerings and customer info
            await revenueCatService.loadOfferings()
            await revenueCatService.loadCustomerInfo()
            
            // Check if we have the necessary data
            if revenueCatService.offerings?.current == nil {
                errorMessage = "No current offering found. Please check your RevenueCat configuration."
            } else if revenueCatService.offerings?.current?.availablePackages.isEmpty == true {
                errorMessage = "No packages available in current offering."
            }
            
            isLoading = false
        }
    }
}

#Preview {
    DebugPaywallView()
}
