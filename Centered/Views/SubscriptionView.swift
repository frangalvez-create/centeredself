import SwiftUI
import RevenueCat
import RevenueCatUI

struct SubscriptionView: View {
    @StateObject private var revenueCatService = RevenueCatService()
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 20) {
            if revenueCatService.isLoading {
                ProgressView("Loading...")
            } else if revenueCatService.isPremium {
                VStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    Text("Premium Active!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You have access to all premium features")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Upgrade to Premium")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock advanced AI insights, unlimited journal entries, and more!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    if let package = revenueCatService.getPremiumPackage() {
                        VStack(spacing: 12) {
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                            
                            Text(package.storeProduct.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(package.storeProduct.localizedPriceString)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button("Subscribe Now") {
                        showingPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Restore Purchases") {
                        Task {
                            await revenueCatService.restorePurchases()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatService = RevenueCatService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let package = revenueCatService.getPremiumPackage() {
                    VStack(spacing: 16) {
                        Text("Unlock Premium Features")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "brain.head.profile", text: "Enhanced AI Insights with Quotes & Affirmations")
                            FeatureRow(icon: "list.bullet", text: "3 Action Items vs 2 (Free)")
                            FeatureRow(icon: "doc.text", text: "230 Words vs 120 (Free)")
                            FeatureRow(icon: "infinity", text: "Unlimited Journal Entries")
                            FeatureRow(icon: "clock", text: "No 30-Day Entry Limit")
                            FeatureRow(icon: "person.crop.circle.badge.checkmark", text: "Priority Support")
                        }
                        
                        VStack(spacing: 12) {
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                            
                            Text(package.storeProduct.localizedPriceString)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Start Free Trial") {
                            Task {
                                let success = await revenueCatService.purchase(package: package)
                                if success {
                                    dismiss()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        
                        Button("Restore Purchases") {
                            Task {
                                let success = await revenueCatService.restorePurchases()
                                if success {
                                    dismiss()
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionView()
}
