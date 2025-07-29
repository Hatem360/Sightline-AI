import Foundation
import Network
import CryptoKit

// MARK: - Sync Status Enum

@objc public enum SyncStatus: Int, CaseIterable {
    case notConnected = 0
    case connecting = 1
    case connected = 2
    case syncing = 3
    case synced = 4
    case failed = 5
    case disconnected = 6
    case unknown = 7
}

// MARK: - Device Type Enum

@objc public enum DeviceType: Int, CaseIterable {
    case phone = 0
    case tablet = 1
    case laptop = 2
    case desktop = 3
    case server = 4
    case iot = 5
    case network = 6
    case bluetooth = 7
    case usb = 8
    case firewire = 9
    case serial = 10
    case hid = 11
    case peripheral = 12
    case computer = 13
    case mobile = 14
}

// MARK: - Sync Event Type Enum

@objc public enum SyncEventType: Int, CaseIterable {
    case syncStarted = 0
    case syncCompleted = 1
    case syncFailed = 2
    case conflictDetected = 3
    case conflictResolved = 4
    case deviceConnected = 5
    case deviceDisconnected = 6
    case dataUploaded = 7
    case dataDownloaded = 8
}

// MARK: - Conflict Type Enum

@objc public enum ConflictType: Int, CaseIterable {
    case dataConflict = 0
    case versionConflict = 1
    case timestampConflict = 2
    case mergeConflict = 3
}

// MARK: - Conflict Resolution Enum

@objc public enum ConflictResolution: Int, CaseIterable {
    case automatic = 0
    case manual = 1
    case skip = 2
    case merge = 3
    case useLocal = 4
    case useRemote = 5
}

// MARK: - Data Models

@objc public class DeviceSyncData: NSObject {
    public let deviceId: String
    public let deviceName: String
    public let deviceType: DeviceType
    public let connectionType: Int
    public let status: SyncStatus
    public let lastSeen: Date
    public let metrics: [String: Any]
    public let timestamp: Date
    public let dataSize: Int64
    
    public init(deviceId: String, deviceName: String, deviceType: DeviceType, connectionType: Int, status: SyncStatus, lastSeen: Date, metrics: [String: Any], timestamp: Date, dataSize: Int64) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.connectionType = connectionType
        self.status = status
        self.lastSeen = lastSeen
        self.metrics = metrics
        self.timestamp = timestamp
        self.dataSize = dataSize
        super.init()
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "deviceId": deviceId,
            "deviceName": deviceName,
            "deviceType": deviceType.rawValue,
            "connectionType": connectionType,
            "status": status.rawValue,
            "lastSeen": lastSeen.timeIntervalSince1970,
            "metrics": metrics,
            "timestamp": timestamp.timeIntervalSince1970,
            "dataSize": dataSize
        ]
    }
}

@objc public class CloudDevice: NSObject {
    public let deviceId: String
    public let deviceName: String
    public let deviceType: DeviceType
    public let lastSync: Date
    public let status: SyncStatus
    public let dataSize: Int64
    
    public init(deviceId: String, deviceName: String, deviceType: DeviceType, lastSync: Date, status: SyncStatus, dataSize: Int64) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.lastSync = lastSync
        self.status = status
        self.dataSize = dataSize
        super.init()
    }
}

@objc public class PendingSync: NSObject {
    public let syncId: String
    public let deviceId: String
    public let deviceData: DeviceSyncData
    public let timestamp: Date
    public let priority: Int
    public var retryCount: Int
    
    public init(syncId: String, deviceId: String, deviceData: DeviceSyncData, timestamp: Date, priority: Int, retryCount: Int) {
        self.syncId = syncId
        self.deviceId = deviceId
        self.deviceData = deviceData
        self.timestamp = timestamp
        self.priority = priority
        self.retryCount = retryCount
        super.init()
    }
}

@objc public class SyncConflict: NSObject {
    public let conflictId: String
    public let deviceId: String
    public let localTimestamp: Date
    public let remoteTimestamp: Date
    public let localData: [String: Any]
    public let remoteData: [String: Any]
    public let conflictType: ConflictType
    public let timestamp: Date
    public let resolution: ConflictResolution
    
    public init(conflictId: String, deviceId: String, localTimestamp: Date, remoteTimestamp: Date, localData: [String: Any], remoteData: [String: Any], conflictType: ConflictType, timestamp: Date, resolution: ConflictResolution) {
        self.conflictId = conflictId
        self.deviceId = deviceId
        self.localTimestamp = localTimestamp
        self.remoteTimestamp = remoteTimestamp
        self.localData = localData
        self.remoteData = remoteData
        self.conflictType = conflictType
        self.timestamp = timestamp
        self.resolution = resolution
        super.init()
    }
}

@objc public class SyncEvent: NSObject {
    public let eventId: String
    public let deviceId: String
    public let eventType: SyncEventType
    public let timestamp: Date
    public let eventDescription: String
    public let dataSize: Int64
    public let success: Bool
    
    public init(eventId: String, deviceId: String, eventType: SyncEventType, timestamp: Date, eventDescription: String, dataSize: Int64, success: Bool) {
        self.eventId = eventId
        self.deviceId = deviceId
        self.eventType = eventType
        self.timestamp = timestamp
        self.eventDescription = eventDescription
        self.dataSize = dataSize
        self.success = success
        super.init()
    }
    
    public override var description: String {
        return "SyncEvent(id: \(eventId), device: \(deviceId), type: \(eventType), success: \(success))"
    }
}

@objc public class CloudStorageInfo: NSObject {
    public let used: Int64
    public let total: Int64
    public let free: Int64
    public let percentage: Double
    
    public init(used: Int64, total: Int64, free: Int64, percentage: Double) {
        self.used = used
        self.total = total
        self.free = free
        self.percentage = percentage
        super.init()
    }
}

@objc public class NetworkPerformance: NSObject {
    public let uploadSpeed: Double
    public let downloadSpeed: Double
    public let latency: Double
    public let packetLoss: Double
    public let jitter: Double
    public let connectionQuality: Double
    
    public init(uploadSpeed: Double, downloadSpeed: Double, latency: Double, packetLoss: Double, jitter: Double, connectionQuality: Double) {
        self.uploadSpeed = uploadSpeed
        self.downloadSpeed = downloadSpeed
        self.latency = latency
        self.packetLoss = packetLoss
        self.jitter = jitter
        self.connectionQuality = connectionQuality
        super.init()
    }
}

// MARK: - Extensions

extension Data {
    func encrypt(using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(self, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: self)
        return try AES.GCM.open(sealedBox, using: key)
    }
} 