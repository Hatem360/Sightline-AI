import Foundation
import Network
import CoreBluetooth
import IOKit

/// Comprehensive external device data model with 3uTools-level detail
/// Represents real external devices (phones, tablets, IoT devices) with detailed specifications
@objc public class ExternalDevice: NSObject {
    public let deviceId: String
    public let name: String
    public let deviceType: ExternalDeviceType
    public let connectionType: ExternalConnectionType
    public var status: ExternalDeviceStatus
    public var lastSeen: Date
    
    public init(deviceId: String, name: String, deviceType: ExternalDeviceType, connectionType: ExternalConnectionType, status: ExternalDeviceStatus, lastSeen: Date) {
        self.deviceId = deviceId
        self.name = name
        self.deviceType = deviceType
        self.connectionType = connectionType
        self.status = status
        self.lastSeen = lastSeen
        super.init()
    }
}

/// Network-based external device with real network specifications
@objc public class NetworkExternalDevice: ExternalDevice {
    public let endpoint: NWEndpoint?
    public let ipAddress: String?
    public let macAddress: String?
    public let networkInterface: String?
    public let networkSpeed: Double?
    public let networkLatency: Double?
    public let signalStrength: Double?
    public let connectionQuality: Double?
    
    public init(deviceId: String, name: String, endpoint: NWEndpoint?, type: ExternalConnectionType, status: ExternalDeviceStatus, lastSeen: Date, ipAddress: String? = nil, macAddress: String? = nil, networkInterface: String? = nil, networkSpeed: Double? = nil, networkLatency: Double? = nil, signalStrength: Double? = nil, connectionQuality: Double? = nil) {
        self.endpoint = endpoint
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.networkInterface = networkInterface
        self.networkSpeed = networkSpeed
        self.networkLatency = networkLatency
        self.signalStrength = signalStrength
        self.connectionQuality = connectionQuality
        
        super.init(deviceId: deviceId, name: name, deviceType: .network, connectionType: type, status: status, lastSeen: lastSeen)
    }
}

/// Bluetooth external device with real Bluetooth specifications
@objc public class BluetoothExternalDevice: ExternalDevice {
    public let peripheral: CBPeripheral
    public let rssi: NSNumber
    public let advertisementData: [String: Any]
    public let bluetoothClass: String?
    public let bluetoothVersion: String?
    public let bluetoothServices: [String]?
    public let bluetoothCapabilities: [String]?
    
    public init(deviceId: String, name: String, peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any], bluetoothClass: String? = nil, bluetoothVersion: String? = nil, bluetoothServices: [String]? = nil, bluetoothCapabilities: [String]? = nil) {
        self.peripheral = peripheral
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.bluetoothClass = bluetoothClass
        self.bluetoothVersion = bluetoothVersion
        self.bluetoothServices = bluetoothServices
        self.bluetoothCapabilities = bluetoothCapabilities
        
        super.init(deviceId: deviceId, name: name, deviceType: .bluetooth, connectionType: .bluetooth, status: .online, lastSeen: Date())
    }
}

/// USB external device with real USB specifications
@objc public class USBExternalDevice: ExternalDevice {
    public let vendorId: Int
    public let productId: Int
    public let serialNumber: String
    public let manufacturer: String
    public let product: String
    public let speed: Int
    public let powerConsumption: Double
    public let usbVersion: String?
    public let usbClass: String?
    public let usbSubclass: String?
    public let usbProtocol: String?
    public let usbCapabilities: [String]?
    
    public init(deviceId: String, vendorId: Int, productId: Int, serialNumber: String, manufacturer: String, product: String, speed: Int, powerConsumption: Double, usbVersion: String? = nil, usbClass: String? = nil, usbSubclass: String? = nil, usbProtocol: String? = nil, usbCapabilities: [String]? = nil) {
        self.vendorId = vendorId
        self.productId = productId
        self.serialNumber = serialNumber
        self.manufacturer = manufacturer
        self.product = product
        self.speed = speed
        self.powerConsumption = powerConsumption
        self.usbVersion = usbVersion
        self.usbClass = usbClass
        self.usbSubclass = usbSubclass
        self.usbProtocol = usbProtocol
        self.usbCapabilities = usbCapabilities
        
        super.init(deviceId: deviceId, name: product, deviceType: .usb, connectionType: .usb, status: .online, lastSeen: Date())
    }
}

/// Firewire external device with real Firewire specifications
@objc public class FirewireExternalDevice: ExternalDevice {
    public let vendorId: Int
    public let productId: Int
    public let serialNumber: String
    public let manufacturer: String
    public let product: String
    public let speed: Int
    public let firewireVersion: String?
    public let firewireCapabilities: [String]?
    
    public init(deviceId: String, vendorId: Int, productId: Int, serialNumber: String, manufacturer: String, product: String, speed: Int, firewireVersion: String? = nil, firewireCapabilities: [String]? = nil) {
        self.vendorId = vendorId
        self.productId = productId
        self.serialNumber = serialNumber
        self.manufacturer = manufacturer
        self.product = product
        self.speed = speed
        self.firewireVersion = firewireVersion
        self.firewireCapabilities = firewireCapabilities
        
        super.init(deviceId: deviceId, name: product, deviceType: .firewire, connectionType: .firewire, status: .online, lastSeen: Date())
    }
}

/// Serial external device with real serial specifications
@objc public class SerialExternalDevice: ExternalDevice {
    public let manufacturer: String
    public let product: String
    public let baudRate: Int
    public let serialPort: String?
    public let serialCapabilities: [String]?
    
    public init(deviceId: String, manufacturer: String, product: String, baudRate: Int, serialPort: String? = nil, serialCapabilities: [String]? = nil) {
        self.manufacturer = manufacturer
        self.product = product
        self.baudRate = baudRate
        self.serialPort = serialPort
        self.serialCapabilities = serialCapabilities
        
        super.init(deviceId: deviceId, name: product, deviceType: .serial, connectionType: .serial, status: .online, lastSeen: Date())
    }
}

/// HID external device with real HID specifications
@objc public class HIDExternalDevice: ExternalDevice {
    public let manufacturer: String
    public let product: String
    public let usage: Int
    public let hidCapabilities: [String]?
    
    public init(deviceId: String, manufacturer: String, product: String, usage: Int, hidCapabilities: [String]? = nil) {
        self.manufacturer = manufacturer
        self.product = product
        self.usage = usage
        self.hidCapabilities = hidCapabilities
        
        super.init(deviceId: deviceId, name: product, deviceType: .hid, connectionType: .hid, status: .online, lastSeen: Date())
    }
}

/// Comprehensive external device metrics with real-time performance data
@objc public class ExternalDeviceMetrics: NSObject {
    public let deviceId: String
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let storageUsage: Double
    public let batteryLevel: Double
    public let temperature: Double
    public let networkLatency: Double
    public let signalStrength: Double
    public let connectionQuality: Double
    public let isOnline: Bool
    public let lastSeen: Date
    public let performanceScore: Double
    public let healthScore: Double
    public let bottleneckIndicator: String
    public let optimizationOpportunities: [String]
    
    public init(deviceId: String, timestamp: Date, cpuUsage: Double, memoryUsage: Double, storageUsage: Double, batteryLevel: Double, temperature: Double, networkLatency: Double, signalStrength: Double, connectionQuality: Double, isOnline: Bool, lastSeen: Date, performanceScore: Double, healthScore: Double, bottleneckIndicator: String, optimizationOpportunities: [String]) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.storageUsage = storageUsage
        self.batteryLevel = batteryLevel
        self.temperature = temperature
        self.networkLatency = networkLatency
        self.signalStrength = signalStrength
        self.connectionQuality = connectionQuality
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.performanceScore = performanceScore
        self.healthScore = healthScore
        self.bottleneckIndicator = bottleneckIndicator
        self.optimizationOpportunities = optimizationOpportunities
        super.init()
    }
}

/// Comprehensive external device profile with 3uTools-level detail
@objc public class ExternalDeviceProfile: NSObject {
    public let deviceId: String
    public let timestamp: Date
    public let hardwareSpecs: ExternalDeviceHardwareSpecs
    public let firmwareInfo: ExternalDeviceFirmwareInfo
    public let serialNumber: String
    public let manufacturer: String
    public let model: String
    public let partNumber: String
    public let capabilities: [String]
    public let limitations: [String]
    public let recommendations: [String]
    
    public init(deviceId: String, timestamp: Date, hardwareSpecs: ExternalDeviceHardwareSpecs, firmwareInfo: ExternalDeviceFirmwareInfo, serialNumber: String, manufacturer: String, model: String, partNumber: String, capabilities: [String], limitations: [String], recommendations: [String]) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.hardwareSpecs = hardwareSpecs
        self.firmwareInfo = firmwareInfo
        self.serialNumber = serialNumber
        self.manufacturer = manufacturer
        self.model = model
        self.partNumber = partNumber
        self.capabilities = capabilities
        self.limitations = limitations
        self.recommendations = recommendations
        super.init()
    }
}

/// External device hardware specifications (3uTools-level detail)
@objc public class ExternalDeviceHardwareSpecs: NSObject {
    public let cpuModel: String
    public let cpuArchitecture: String
    public let cpuCores: Int
    public let cpuFrequency: Double
    public let memoryTotal: UInt64
    public let memoryType: String
    public let memorySpeed: Double
    public let storageTotal: UInt64
    public let storageType: String
    public let storageSpeed: Double
    public let gpuModel: String
    public let gpuMemory: UInt64
    public let batteryCapacity: UInt64
    public let batteryChemistry: String
    public let networkCapabilities: [String]
    public let bluetoothVersion: String
    public let wifiStandard: String
    public let cellularCapabilities: [String]
    
    public init(cpuModel: String, cpuArchitecture: String, cpuCores: Int, cpuFrequency: Double, memoryTotal: UInt64, memoryType: String, memorySpeed: Double, storageTotal: UInt64, storageType: String, storageSpeed: Double, gpuModel: String, gpuMemory: UInt64, batteryCapacity: UInt64, batteryChemistry: String, networkCapabilities: [String], bluetoothVersion: String, wifiStandard: String, cellularCapabilities: [String]) {
        self.cpuModel = cpuModel
        self.cpuArchitecture = cpuArchitecture
        self.cpuCores = cpuCores
        self.cpuFrequency = cpuFrequency
        self.memoryTotal = memoryTotal
        self.memoryType = memoryType
        self.memorySpeed = memorySpeed
        self.storageTotal = storageTotal
        self.storageType = storageType
        self.storageSpeed = storageSpeed
        self.gpuModel = gpuModel
        self.gpuMemory = gpuMemory
        self.batteryCapacity = batteryCapacity
        self.batteryChemistry = batteryChemistry
        self.networkCapabilities = networkCapabilities
        self.bluetoothVersion = bluetoothVersion
        self.wifiStandard = wifiStandard
        self.cellularCapabilities = cellularCapabilities
        super.init()
    }
}

/// External device firmware information (3uTools-level detail)
@objc public class ExternalDeviceFirmwareInfo: NSObject {
    public let firmwareVersion: String
    public let firmwareDate: String
    public let firmwareManufacturer: String
    public let bootloaderVersion: String
    public let recoveryVersion: String
    public let systemVersion: String
    public let buildNumber: String
    public let securityPatchLevel: String
    public let updateAvailable: Bool
    public let lastUpdateCheck: Date
    
    public init(firmwareVersion: String, firmwareDate: String, firmwareManufacturer: String, bootloaderVersion: String, recoveryVersion: String, systemVersion: String, buildNumber: String, securityPatchLevel: String, updateAvailable: Bool, lastUpdateCheck: Date) {
        self.firmwareVersion = firmwareVersion
        self.firmwareDate = firmwareDate
        self.firmwareManufacturer = firmwareManufacturer
        self.bootloaderVersion = bootloaderVersion
        self.recoveryVersion = recoveryVersion
        self.systemVersion = systemVersion
        self.buildNumber = buildNumber
        self.securityPatchLevel = securityPatchLevel
        self.updateAvailable = updateAvailable
        self.lastUpdateCheck = lastUpdateCheck
        super.init()
    }
}

/// External device synchronization status
@objc public class ExternalDeviceSyncStatus: NSObject {
    public let deviceId: String
    public let syncStatus: SyncStatus
    public let lastSyncTime: Date
    public let syncProgress: Double
    public let dataTransferred: Int64
    public let errorCount: Int
    public let latency: Double
    public let connectionQuality: Double
    
    public init(deviceId: String, syncStatus: SyncStatus, lastSyncTime: Date, syncProgress: Double, dataTransferred: Int64, errorCount: Int, latency: Double, connectionQuality: Double) {
        self.deviceId = deviceId
        self.syncStatus = syncStatus
        self.lastSyncTime = lastSyncTime
        self.syncProgress = syncProgress
        self.dataTransferred = dataTransferred
        self.errorCount = errorCount
        self.latency = latency
        self.connectionQuality = connectionQuality
        super.init()
    }
}

// MARK: - Enums

@objc public enum ExternalDeviceType: Int, CaseIterable {
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
    case unknown = 12
    
    public var description: String {
        switch self {
        case .phone: return "Phone"
        case .tablet: return "Tablet"
        case .laptop: return "Laptop"
        case .desktop: return "Desktop"
        case .server: return "Server"
        case .iot: return "IoT Device"
        case .network: return "Network Device"
        case .bluetooth: return "Bluetooth Device"
        case .usb: return "USB Device"
        case .firewire: return "Firewire Device"
        case .serial: return "Serial Device"
        case .hid: return "HID Device"
        case .unknown: return "Unknown"
        }
    }
}

@objc public enum ExternalConnectionType: Int, CaseIterable {
    case network = 0
    case bluetooth = 1
    case usb = 2
    case firewire = 3
    case serial = 4
    case hid = 5
    case wifi = 6
    case cellular = 7
    case ethernet = 8
    case cloud = 9
    
    public var description: String {
        switch self {
        case .network: return "Network"
        case .bluetooth: return "Bluetooth"
        case .usb: return "USB"
        case .firewire: return "Firewire"
        case .serial: return "Serial"
        case .hid: return "HID"
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .cloud: return "Cloud"
        }
    }
}

@objc public enum ExternalDeviceStatus: Int, CaseIterable {
    case offline = 0
    case online = 1
    case connecting = 2
    case disconnecting = 3
    case error = 4
    case unknown = 5
    
    public var description: String {
        switch self {
        case .offline: return "Offline"
        case .online: return "Online"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }
}

 