import Foundation
import Combine
import UserNotifications
import AppKit

// MARK: - Notification Manager Protocol
protocol NotificationManagerProtocol {
    func requestPermissions() async throws
    func sendNotification(_ notification: AppNotification) async throws
    func scheduleNotification(_ notification: AppNotification, at date: Date) async throws
    func cancelNotification(_ notificationId: String) async
    func cancelAllNotifications() async
    func getNotificationHistory() -> [AppNotification]
    func getNotificationSettings() -> NotificationSettings
    func updateNotificationSettings(_ settings: NotificationSettings) async
    func markNotificationAsRead(_ notificationId: String) async
    func deleteNotification(_ notificationId: String) async
}

// MARK: - App Notification
struct AppNotification: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let severity: NotificationSeverity
    let category: NotificationCategory
    let timestamp: Date
    var isRead: Bool
    let isPersistent: Bool
    let actionButtons: [NotificationAction]
    let metadata: [String: String]
    let deviceId: String?
    let componentId: String?
    let relatedMetrics: [String: Double]
    let priority: NotificationPriority
    let expirationDate: Date?
    let groupId: String?
    let sound: NotificationSound?
    let badge: Int?
    let userInfo: [String: String] // Changed from [String: Any] to [String: String] for Codable conformance
    
    init(id: String, title: String, message: String, type: NotificationType, severity: NotificationSeverity, category: NotificationCategory, timestamp: Date, isRead: Bool, isPersistent: Bool, actionButtons: [NotificationAction], metadata: [String: String], deviceId: String?, componentId: String?, relatedMetrics: [String: Double], priority: NotificationPriority, expirationDate: Date?, groupId: String?, sound: NotificationSound?, badge: Int?, userInfo: [String: String]) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.severity = severity
        self.category = category
        self.timestamp = timestamp
        self.isRead = isRead
        self.isPersistent = isPersistent
        self.actionButtons = actionButtons
        self.metadata = metadata
        self.deviceId = deviceId
        self.componentId = componentId
        self.relatedMetrics = relatedMetrics
        self.priority = priority
        self.expirationDate = expirationDate
        self.groupId = groupId
        self.sound = sound
        self.badge = badge
        self.userInfo = userInfo
    }
}

// MARK: - Notification Type
enum NotificationType: String, CaseIterable, Codable {
    case alert = "alert"
    case warning = "warning"
    case info = "info"
    case success = "success"
    case error = "error"
    case critical = "critical"
    case system = "system"
    case user = "user"
    case ai = "ai"
    case security = "security"
}

// MARK: - Notification Severity
enum NotificationSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    case emergency = "emergency"
    
    var color: String {
        switch self {
        case .low: return "#00CC00"
        case .medium: return "#FFCC00"
        case .high: return "#FF6600"
        case .critical: return "#FF0000"
        case .emergency: return "#990000"
        }
    }
}

// MARK: - Notification Category
enum NotificationCategory: String, CaseIterable, Codable {
    case system = "system"
    case performance = "performance"
    case security = "security"
    case device = "device"
    case network = "network"
    case battery = "battery"
    case thermal = "thermal"
    case storage = "storage"
    case ai = "ai"
    case maintenance = "maintenance"
    case backup = "backup"
    case sync = "sync"
    case user = "user"
    case custom = "custom"
}

// MARK: - Notification Action
struct NotificationAction: Identifiable, Codable {
    let id: String
    let title: String
    let action: String
    let isDestructive: Bool
    let requiresConfirmation: Bool
    let icon: String?
    let url: URL?
}

// MARK: - Notification Priority
enum NotificationPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    case critical = "critical"
}

// MARK: - Notification Sound
enum NotificationSound: String, CaseIterable, Codable {
    case defaultSound = "default"
    case alert = "alert"
    case warning = "warning"
    case error = "error"
    case success = "success"
    case custom = "custom"
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var isEnabled: Bool
    let allowSystemNotifications: Bool
    let allowPerformanceNotifications: Bool
    let allowSecurityNotifications: Bool
    let allowDeviceNotifications: Bool
    let allowNetworkNotifications: Bool
    let allowBatteryNotifications: Bool
    let allowThermalNotifications: Bool
    let allowStorageNotifications: Bool
    let allowAINotifications: Bool
    let allowMaintenanceNotifications: Bool
    let allowBackupNotifications: Bool
    let allowSyncNotifications: Bool
    let allowUserNotifications: Bool
    let allowCustomNotifications: Bool
    let soundEnabled: Bool
    let badgeEnabled: Bool
    let bannerEnabled: Bool
    let criticalAlertsEnabled: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: Date?
    let quietHoursEnd: Date?
    let maxNotificationsPerHour: Int
    let autoDismissDelay: TimeInterval
    let groupSimilarNotifications: Bool
    let showNotificationPreview: Bool
    let notificationHistoryRetentionDays: Int
}

// MARK: - Notification Manager Implementation
@MainActor
@preconcurrency
final class NotificationManager: NSObject, ObservableObject, NotificationManagerProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var notificationHistory: [AppNotification] = []
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var settings = NotificationSettings(
        isEnabled: true,
        allowSystemNotifications: true,
        allowPerformanceNotifications: true,
        allowSecurityNotifications: true,
        allowDeviceNotifications: true,
        allowNetworkNotifications: true,
        allowBatteryNotifications: true,
        allowThermalNotifications: true,
        allowStorageNotifications: true,
        allowAINotifications: true,
        allowMaintenanceNotifications: true,
        allowBackupNotifications: true,
        allowSyncNotifications: true,
        allowUserNotifications: true,
        allowCustomNotifications: true,
        soundEnabled: true,
        badgeEnabled: true,
        bannerEnabled: true,
        criticalAlertsEnabled: true,
        quietHoursEnabled: false,
        quietHoursStart: nil,
        quietHoursEnd: nil,
        maxNotificationsPerHour: 50,
        autoDismissDelay: 5.0,
        groupSimilarNotifications: true,
        showNotificationPreview: true,
        notificationHistoryRetentionDays: 30
    )
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var notificationCenter = UNUserNotificationCenter.current()
    private var scheduledNotifications: [String: UNNotificationRequest] = [:]
    private var notificationQueue = DispatchQueue(label: "notification.queue", qos: .userInitiated)
    private var lastNotificationTime: Date = Date()
    private var notificationsThisHour: Int = 0
    private var hourlyResetTimer: Timer?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNotificationCenter()
        setupHourlyResetTimer()
        loadNotificationHistory()
        loadNotificationSettings()
    }
    
    // MARK: - Public Methods
    func requestPermissions() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            if !granted {
                throw NotificationError.permissionDenied
            }
            
            await MainActor.run {
                self.settings.isEnabled = granted
            }
            
        } catch {
            throw NotificationError.permissionRequestFailed(error)
        }
    }
    
    func sendNotification(_ notification: AppNotification) async throws {
        guard settings.isEnabled else {
            throw NotificationError.notificationsDisabled
        }
        
        guard shouldSendNotification(notification) else {
            return
        }
        
        guard !isInQuietHours() else {
            // Store for later delivery
            await storeQuietHoursNotification(notification)
            return
        }
        
        guard notificationsThisHour < settings.maxNotificationsPerHour else {
            throw NotificationError.rateLimitExceeded
        }
        
        do {
            // Create system notification
            let systemNotification = try createSystemNotification(from: notification)
            
            // Create notification request
            let request = UNNotificationRequest(identifier: notification.id, content: systemNotification, trigger: nil)
            
            // Add to notification center
            try await notificationCenter.add(request)
            
            // Update internal state
            await updateNotificationState(notification)
            
            // Store in history
            await addToHistory(notification)
            
            // Update badge
            await updateBadge()
            
            // Send to notification center
            await sendToNotificationCenter(notification)
            
        } catch {
            throw NotificationError.failedToSend(error)
        }
    }
    
    func scheduleNotification(_ notification: AppNotification, at date: Date) async throws {
        guard settings.isEnabled else {
            throw NotificationError.notificationsDisabled
        }
        
        let systemNotification = try createSystemNotification(from: notification)
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date), repeats: false)
        
        let request = UNNotificationRequest(identifier: notification.id, content: systemNotification, trigger: trigger)
        
        try await notificationCenter.add(request)
        scheduledNotifications[notification.id] = request
    }
    
    func cancelNotification(_ notificationId: String) async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        scheduledNotifications.removeValue(forKey: notificationId)
    }
    
    func cancelAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    nonisolated func getNotificationHistory() -> [AppNotification] {
        return notificationHistory
    }
    
    nonisolated func getNotificationSettings() -> NotificationSettings {
        return settings
    }
    
    func updateNotificationSettings(_ newSettings: NotificationSettings) async {
        settings = newSettings
        saveNotificationSettings()
        
        // Update notification center settings
        await updateNotificationCenterSettings()
    }
    
    func markNotificationAsRead(_ notificationId: String) async {
        if let index = notificationHistory.firstIndex(where: { $0.id == notificationId }) {
            var updatedNotification = notificationHistory[index]
            updatedNotification.isRead = true
            notificationHistory[index] = updatedNotification
            
            unreadCount = max(0, unreadCount - 1)
            saveNotificationHistory()
        }
    }
    
    func deleteNotification(_ notificationId: String) async {
        notificationHistory.removeAll { $0.id == notificationId }
        saveNotificationHistory()
        await updateBadge()
    }
    
    // MARK: - Private Methods
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        
        // Request permissions on first launch
        Task {
            do {
                try await requestPermissions()
            } catch {
                print("Failed to request notification permissions: \(error)")
            }
        }
    }
    
    private func setupHourlyResetTimer() {
        hourlyResetTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.resetHourlyCount()
            }
        }
    }
    
    private func shouldSendNotification(_ notification: AppNotification) -> Bool {
        // Check category-specific settings
        switch notification.category {
        case .system:
            return settings.allowSystemNotifications
        case .performance:
            return settings.allowPerformanceNotifications
        case .security:
            return settings.allowSecurityNotifications
        case .device:
            return settings.allowDeviceNotifications
        case .network:
            return settings.allowNetworkNotifications
        case .battery:
            return settings.allowBatteryNotifications
        case .thermal:
            return settings.allowThermalNotifications
        case .storage:
            return settings.allowStorageNotifications
        case .ai:
            return settings.allowAINotifications
        case .maintenance:
            return settings.allowMaintenanceNotifications
        case .backup:
            return settings.allowBackupNotifications
        case .sync:
            return settings.allowSyncNotifications
        case .user:
            return settings.allowUserNotifications
        case .custom:
            return settings.allowCustomNotifications
        }
    }
    
    private func isInQuietHours() -> Bool {
        guard settings.quietHoursEnabled,
              let start = settings.quietHoursStart,
              let end = settings.quietHoursEnd else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        let startMinutes = startComponents.hour! * 60 + startComponents.minute!
        let endMinutes = endComponents.hour! * 60 + endComponents.minute!
        let nowMinutes = nowComponents.hour! * 60 + nowComponents.minute!
        
        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes <= endMinutes
        } else {
            // Crosses midnight
            return nowMinutes >= startMinutes || nowMinutes <= endMinutes
        }
    }
    
    private func createSystemNotification(from notification: AppNotification) throws -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = getNotificationSound(notification.sound)
        content.badge = notification.badge as NSNumber?
        
        // Convert [String: String] to [String: Any] for userInfo
        var userInfo: [String: Any] = [:]
        for (key, value) in notification.userInfo {
            userInfo[key] = value
        }
        content.userInfo = userInfo
        
        content.categoryIdentifier = notification.category.rawValue
        
        // Add custom actions if available
        if !notification.actionButtons.isEmpty {
            content.categoryIdentifier = "\(notification.category.rawValue)_with_actions"
        }
        
        return content
    }
    
    private func getNotificationSound(_ sound: NotificationSound?) -> UNNotificationSound? {
        guard settings.soundEnabled else { return nil }
        
        switch sound {
        case .defaultSound:
            return UNNotificationSound.default
        case .alert:
            return UNNotificationSound(named: UNNotificationSoundName("alert.wav"))
        case .warning:
            return UNNotificationSound(named: UNNotificationSoundName("warning.wav"))
        case .error:
            return UNNotificationSound(named: UNNotificationSoundName("error.wav"))
        case .success:
            return UNNotificationSound(named: UNNotificationSoundName("success.wav"))
        case .custom:
            return UNNotificationSound(named: UNNotificationSoundName("custom.wav"))
        case .none:
            return nil
        }
    }
    
    private func updateNotificationState(_ notification: AppNotification) async {
        notificationsThisHour += 1
        lastNotificationTime = Date()
        
        if !notification.isRead {
            unreadCount += 1
        }
    }
    
    private func addToHistory(_ notification: AppNotification) async {
        await MainActor.run {
            self.notificationHistory.insert(notification, at: 0)
            
            // Limit history size
            let maxHistoryCount = settings.notificationHistoryRetentionDays * 24 * 60 // Approximate notifications per day
            if self.notificationHistory.count > maxHistoryCount {
                self.notificationHistory = Array(self.notificationHistory.prefix(maxHistoryCount))
            }
        }
        
        saveNotificationHistory()
    }
    
    private func updateBadge() async {
        guard settings.badgeEnabled else { return }
        
        await MainActor.run {
            NSApp.dockTile.badgeLabel = unreadCount > 0 ? "\(unreadCount)" : nil
        }
    }
    
    private func sendToNotificationCenter(_ notification: AppNotification) async {
        // Send to macOS notification center
        let systemNotification = NSUserNotification()
        systemNotification.title = notification.title
        systemNotification.informativeText = notification.message
        systemNotification.soundName = getSystemSoundName(notification.sound)
        
        NSUserNotificationCenter.default.deliver(systemNotification)
    }
    
    private func getSystemSoundName(_ sound: NotificationSound?) -> String? {
        switch sound {
        case .defaultSound:
            return NSUserNotificationDefaultSoundName
        case .alert:
            return "alert.wav"
        case .warning:
            return "warning.wav"
        case .error:
            return "error.wav"
        case .success:
            return "success.wav"
        case .custom:
            return "custom.wav"
        case .none:
            return nil
        }
    }
    
    private func resetHourlyCount() async {
        await MainActor.run {
            self.notificationsThisHour = 0
        }
    }
    
    private func storeQuietHoursNotification(_ notification: AppNotification) async {
        // Store notification for delivery after quiet hours
        // This would be implemented with local storage
    }
    
    private func loadNotificationHistory() {
        if let data = UserDefaults.standard.data(forKey: "notification_history"),
           let history = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notificationHistory = history
            unreadCount = history.filter { !$0.isRead }.count
        }
    }
    
    private func saveNotificationHistory() {
        if let data = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(data, forKey: "notification_history")
        }
    }
    
    private func loadNotificationSettings() {
        if let data = UserDefaults.standard.data(forKey: "notification_settings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "notification_settings")
        }
    }
    
    private func updateNotificationCenterSettings() async {
        // Update notification center categories and settings
        let categories = createNotificationCategories()
        await notificationCenter.setNotificationCategories(categories)
    }
    
    private func createNotificationCategories() -> Set<UNNotificationCategory> {
        var categories: Set<UNNotificationCategory> = []
        
        // Create categories for each notification type
        for category in NotificationCategory.allCases {
            let actions = createActionsForCategory(category)
            let notificationCategory = UNNotificationCategory(
                identifier: category.rawValue,
                actions: actions,
                intentIdentifiers: [],
                options: []
            )
            categories.insert(notificationCategory)
            
            // Create category with actions
            let notificationCategoryWithActions = UNNotificationCategory(
                identifier: "\(category.rawValue)_with_actions",
                actions: actions,
                intentIdentifiers: [],
                options: []
            )
            categories.insert(notificationCategoryWithActions)
        }
        
        return categories
    }
    
    private func createActionsForCategory(_ category: NotificationCategory) -> [UNNotificationAction] {
        var actions: [UNNotificationAction] = []
        
        switch category {
        case .system, .performance, .security:
            actions.append(UNNotificationAction(identifier: "view", title: "View Details", options: [.foreground]))
            actions.append(UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: []))
        case .device, .network, .battery, .thermal, .storage:
            actions.append(UNNotificationAction(identifier: "optimize", title: "Optimize", options: [.foreground]))
            actions.append(UNNotificationAction(identifier: "ignore", title: "Ignore", options: []))
        case .ai:
            actions.append(UNNotificationAction(identifier: "analyze", title: "Analyze", options: [.foreground]))
            actions.append(UNNotificationAction(identifier: "learn", title: "Learn More", options: [.foreground]))
        case .maintenance, .backup, .sync:
            actions.append(UNNotificationAction(identifier: "schedule", title: "Schedule", options: [.foreground]))
            actions.append(UNNotificationAction(identifier: "skip", title: "Skip", options: []))
        case .user, .custom:
            actions.append(UNNotificationAction(identifier: "respond", title: "Respond", options: [.foreground]))
            actions.append(UNNotificationAction(identifier: "snooze", title: "Snooze", options: []))
        }
        
        return actions
    }
    
    // MARK: - Convenience Methods
    func sendSystemAlert(title: String, message: String, severity: NotificationSeverity = .medium) async throws {
        let notification = AppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: .alert,
            severity: severity,
            category: .system,
            timestamp: Date(),
            isRead: false,
            isPersistent: true,
            actionButtons: [],
            metadata: [:],
            deviceId: nil,
            componentId: nil,
            relatedMetrics: [:],
            priority: .normal,
            expirationDate: nil,
            groupId: nil,
            sound: .alert,
            badge: nil,
            userInfo: [:]
        )
        
        try await sendNotification(notification)
    }
    
    func sendPerformanceAlert(title: String, message: String, metrics: [String: Double]) async throws {
        let notification = AppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: .warning,
            severity: .high,
            category: .performance,
            timestamp: Date(),
            isRead: false,
            isPersistent: true,
            actionButtons: [
                NotificationAction(id: "optimize", title: "Optimize", action: "optimize", isDestructive: false, requiresConfirmation: false, icon: nil, url: nil)
            ],
            metadata: [:],
            deviceId: nil,
            componentId: nil,
            relatedMetrics: metrics,
            priority: .high,
            expirationDate: nil,
            groupId: nil,
            sound: .warning,
            badge: nil,
            userInfo: [:]
        )
        
        try await sendNotification(notification)
    }
    
    func sendSecurityAlert(title: String, message: String, vulnerability: String) async throws {
        let notification = AppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: .critical,
            severity: .critical,
            category: .security,
            timestamp: Date(),
            isRead: false,
            isPersistent: true,
            actionButtons: [
                NotificationAction(id: "fix", title: "Fix Now", action: "fix", isDestructive: false, requiresConfirmation: true, icon: nil, url: nil),
                NotificationAction(id: "ignore", title: "Ignore", action: "ignore", isDestructive: true, requiresConfirmation: true, icon: nil, url: nil)
            ],
            metadata: ["vulnerability": vulnerability],
            deviceId: nil,
            componentId: nil,
            relatedMetrics: [:],
            priority: .critical,
            expirationDate: nil,
            groupId: nil,
            sound: .error,
            badge: 1,
            userInfo: [:]
        )
        
        try await sendNotification(notification)
    }
    
    func sendAIInsight(title: String, message: String, confidence: Double) async throws {
        let notification = AppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: .ai,
            severity: .medium,
            category: .ai,
            timestamp: Date(),
            isRead: false,
            isPersistent: false,
            actionButtons: [
                NotificationAction(id: "learn", title: "Learn More", action: "learn", isDestructive: false, requiresConfirmation: false, icon: nil, url: nil)
            ],
            metadata: ["confidence": "\(confidence)"],
            deviceId: nil,
            componentId: nil,
            relatedMetrics: [:],
            priority: .normal,
            expirationDate: Date().addingTimeInterval(3600), // Expire in 1 hour
            groupId: nil,
            sound: .success,
            badge: nil,
            userInfo: [:]
        )
        
        try await sendNotification(notification)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification action
        let actionIdentifier = response.actionIdentifier
        let notificationId = response.notification.request.identifier
        
        Task {
            await handleNotificationAction(actionIdentifier, for: notificationId)
        }
        
        completionHandler()
    }
    
    private func handleNotificationAction(_ action: String, for notificationId: String) async {
        switch action {
        case "view", "optimize", "analyze", "schedule", "respond":
            // Open app and navigate to relevant section
            await openAppForNotification(notificationId)
        case "dismiss", "ignore", "skip":
            // Mark as read and remove
            await markNotificationAsRead(notificationId)
        case "fix":
            // Trigger security fix
            await triggerSecurityFix(notificationId)
        case "learn":
            // Open learning material
            await openLearningMaterial(notificationId)
        case "snooze":
            // Snooze notification
            await snoozeNotification(notificationId)
        default:
            break
        }
    }
    
    private func openAppForNotification(_ notificationId: String) async {
        // Bring app to foreground
        NSApp.activate(ignoringOtherApps: true)
        
        // Navigate to relevant section based on notification
        // This would be implemented based on the app's navigation system
    }
    
    private func triggerSecurityFix(_ notificationId: String) async {
        // Trigger security fix process
        // This would be implemented based on the security system
    }
    
    private func openLearningMaterial(_ notificationId: String) async {
        // Open learning material or documentation
        // This would be implemented based on the app's help system
    }
    
    private func snoozeNotification(_ notificationId: String) async {
        // Snooze notification for later
        // This would reschedule the notification
    }
}

// MARK: - Notification Errors
enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case permissionRequestFailed(Error)
    case notificationsDisabled
    case rateLimitExceeded
    case failedToSend(Error)
    case invalidNotification
    case quietHoursActive
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permissions denied"
        case .permissionRequestFailed(let error):
            return "Failed to request notification permissions: \(error.localizedDescription)"
        case .notificationsDisabled:
            return "Notifications are disabled"
        case .rateLimitExceeded:
            return "Notification rate limit exceeded"
        case .failedToSend(let error):
            return "Failed to send notification: \(error.localizedDescription)"
        case .invalidNotification:
            return "Invalid notification data"
        case .quietHoursActive:
            return "Notifications are muted during quiet hours"
        }
    }
} 