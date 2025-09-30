import Foundation
import RevenueCat
import RevenueCatUI

class RevenueCatService: NSObject, ObservableObject {
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    
    private var apiKey: String
    private let supabaseService: SupabaseService
    
    // Entitlement identifier for premium features
    static let premiumEntitlementId = "premium"
    
    // Shared instance
    static let shared = RevenueCatService()
    
    override init() {
        // Initialize with API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["RevenueCatAPIKey"] as? String else {
            fatalError("RevenueCat API key not found in Config.plist")
        }
        
        self.apiKey = key
        self.supabaseService = SupabaseService()
        
        super.init()
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = self
        
        // Load initial data
        Task {
            await loadCustomerInfo()
            await loadOfferings()
            await syncSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Sync
    
    @MainActor
    func syncSubscriptionStatus() async {
        do {
            let subscriptionStatus = isPremium ? "active" : "free"
            let expiresAt = customerInfo?.entitlements[RevenueCatService.premiumEntitlementId]?.expirationDate
            
            try await supabaseService.updateSubscriptionStatus(
                isPremium: isPremium,
                subscriptionStatus: subscriptionStatus,
                subscriptionExpiresAt: expiresAt,
                revenuecatUserId: customerInfo?.originalAppUserId
            )
            
            print("✅ Subscription status synced with Supabase")
        } catch {
            print("❌ Failed to sync subscription status: \(error)")
        }
    }
    
    // MARK: - Customer Info
    
    @MainActor
    func loadCustomerInfo() async {
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[RevenueCatService.premiumEntitlementId]?.isActive == true
            print("✅ Customer info loaded. Premium status: \(isPremium)")
            
            // Sync with Supabase
            await syncSubscriptionStatus()
        } catch {
            print("❌ Failed to load customer info: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Offerings
    
    @MainActor
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            print("✅ Offerings loaded: \(offerings.all.count) packages available")
        } catch {
            print("❌ Failed to load offerings: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(package: Package) async -> Bool {
        isLoading = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                self.customerInfo = result.customerInfo
                self.isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
                print("✅ Purchase successful!")
                
                // Sync with Supabase
                await syncSubscriptionStatus()
                return true
            } else {
                print("ℹ️ Purchase cancelled by user")
            }
        } catch {
            print("❌ Purchase failed: \(error)")
        }
        isLoading = false
        return false
    }
    
    // MARK: - Restore
    
    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[RevenueCatService.premiumEntitlementId]?.isActive == true
            print("✅ Purchases restored successfully")
            
            // Sync with Supabase
            await syncSubscriptionStatus()
            return true
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
        isLoading = false
        return false
    }
    
    // MARK: - Check Premium Status
    
    func checkPremiumStatus() -> Bool {
        return customerInfo?.entitlements[RevenueCatService.premiumEntitlementId]?.isActive == true
    }
    
    // MARK: - Get Premium Package
    
    func getPremiumPackage() -> Package? {
        return offerings?.current?.availablePackages.first { package in
            package.storeProduct.productIdentifier.contains("premium")
        }
    }
    
    // MARK: - Subscription Status Helpers
    
    /// Check if user has any active entitlements
    func hasAnyActiveEntitlements() -> Bool {
        return !(customerInfo?.entitlements.active.isEmpty ?? true)
    }
    
    /// Get the premium entitlement info
    func getPremiumEntitlementInfo() -> EntitlementInfo? {
        return customerInfo?.entitlements[RevenueCatService.premiumEntitlementId]
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[RevenueCatService.premiumEntitlementId]?.isActive == true
            print("🔄 Customer info updated. Premium status: \(isPremium)")
        }
    }
}
