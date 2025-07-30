import Foundation
import Network
import CoreBluetooth
import IOKit
import IOKit.usb
import IOKit.firewire
import IOKit.serial
import IOKit.hid
import Darwin

/// Comprehensive device discovery service for real-time external device detection
/// Uses actual network scanning, Bluetooth discovery, and hardware enumeration
@objc public class DeviceDiscoveryService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var discoveredDevices: [DiscoveredDevice] = []
    @Published public var networkDevices: [NetworkDevice] = []
    @Published public var bluetoothDevices: [BluetoothDevice] = []
    @Published public var usbDevices: [USBDevice] = []
    @Published public var firewireDevices: [FirewireDevice] = []
    @Published public var serialDevices: [SerialDevice] = []
    @Published public var hidDevices: [HIDDevice] = []
    
    @Published public var discoveryStatus: DiscoveryStatus = .idle
    @Published public var scanProgress: Double = 0.0
    @Published public var lastScanTime: Date = Date()
    @Published public var deviceCount: Int = 0
    
    // MARK: - Private Properties
    
    private var networkBrowser: NWBrowser?
    private var bluetoothManager: CBCentralManager?
    private var discoveryTimer: Timer?
    private var isScanning: Bool = false
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        initializeDiscoveryService()
    }
    
    // MARK: - Public Methods
    
    public func startDiscovery() {
        guard !isScanning else { return }
        
        isScanning = true
        discoveryStatus = .scanning
        scanProgress = 0.0
        
        startNetworkDiscovery()
        startBluetoothDiscovery()
        startHardwareDiscovery()
        startPeriodicDiscovery()
        
        print("Device discovery started")
    }
    
    public func stopDiscovery() {
        guard isScanning else { return }
        
        isScanning = false
        discoveryStatus = .idle
        scanProgress = 0.0
        
        stopNetworkDiscovery()
        stopBluetoothDiscovery()
        stopHardwareDiscovery()
        stopPeriodicDiscovery()
        
        print("Device discovery stopped")
    }
    
    public func refreshDiscovery() {
        discoveredDevices.removeAll()
        networkDevices.removeAll()
        bluetoothDevices.removeAll()
        usbDevices.removeAll()
        firewireDevices.removeAll()
        serialDevices.removeAll()
        hidDevices.removeAll()
        
        startDiscovery()
    }
    
    // MARK: - Private Methods
    
    private func initializeDiscoveryService() {
        setupNetworkDiscovery()
        setupBluetoothDiscovery()
        setupHardwareDiscovery()
    }
    
    private func setupNetworkDiscovery() {
        // Network discovery setup
    }
    
    private func setupBluetoothDiscovery() {
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func setupHardwareDiscovery() {
        // Hardware discovery setup
    }
    
    private func startNetworkDiscovery() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_device-info._tcp", domain: nil), using: parameters)
        
        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleNetworkBrowserState(state)
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                self?.handleNetworkBrowserResults(results, changes: Array(changes))
            }
        }
        
        browser.start(queue: .global())
        networkBrowser = browser
    }
    
    private func stopNetworkDiscovery() {
        networkBrowser?.cancel()
        networkBrowser = nil
    }
    
    private func startBluetoothDiscovery() {
        guard let manager = bluetoothManager, manager.state == .poweredOn else { return }
        
        let services = [CBUUID(string: "1800"), CBUUID(string: "1801")]
        manager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    private func stopBluetoothDiscovery() {
        bluetoothManager?.stopScan()
    }
    
    private func startHardwareDiscovery() {
        discoverUSBDevices()
        discoverFirewireDevices()
        discoverSerialDevices()
        discoverHIDDevices()
    }
    
    private func stopHardwareDiscovery() {
        // Cleanup hardware discovery
    }
    
    private func discoverUSBDevices() {
        var masterPort: mach_port_t = 0
        let portResult = IOMasterPort(kIOMainPortDefault, &masterPort)
        guard portResult == kIOReturnSuccess else { return }
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        if matchResult == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != IO_OBJECT_NULL {
                processUSBDevice(device)
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func processUSBDevice(_ device: io_object_t) {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(device, &properties, nil, 0)
        
        if result == kIOReturnSuccess, let props = properties?.takeRetainedValue() as? [String: Any] {
            if let vendorId = props["idVendor"] as? Int,
               let productId = props["idProduct"] as? Int,
               let serialNumber = props["USB Serial Number"] as? String {
                
                let usbDevice = USBDevice(
                    deviceId: serialNumber,
                    vendorId: vendorId,
                    productId: productId,
                    serialNumber: serialNumber,
                    manufacturer: props["USB Vendor Name"] as? String ?? "",
                    product: props["USB Product Name"] as? String ?? "",
                    speed: props["bcdDevice"] as? Int ?? 0,
                    powerConsumption: props["MaxPower"] as? Double ?? 0.0
                )
                
                usbDevices.append(usbDevice)
                addDiscoveredDevice(usbDevice)
            }
        }
    }
    
    private func discoverFirewireDevices() {
        var masterPort: mach_port_t = 0
        let portResult = IOMasterPort(kIOMainPortDefault, &masterPort)
        guard portResult == kIOReturnSuccess else { return }
        let matchingDict = IOServiceMatching("IOFireWireDevice")
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        if matchResult == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != IO_OBJECT_NULL {
                processFirewireDevice(device)
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func processFirewireDevice(_ device: io_object_t) {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(device, &properties, nil, 0)
        
        if result == kIOReturnSuccess, let props = properties?.takeRetainedValue() as? [String: Any] {
            if let guid = props["GUID"] as? UInt64,
               let vendorId = props["Vendor ID"] as? Int,
               let productId = props["Product ID"] as? Int {
                
                let firewireDevice = FirewireDevice(
                    deviceId: String(guid),
                    guid: guid,
                    vendorId: vendorId,
                    productId: productId,
                    manufacturer: props["Vendor Name"] as? String ?? "",
                    product: props["Product Name"] as? String ?? "",
                    speed: props["Speed"] as? Int ?? 0
                )
                
                firewireDevices.append(firewireDevice)
                addDiscoveredDevice(firewireDevice)
            }
        }
    }
    
    private func discoverSerialDevices() {
        var masterPort: mach_port_t = 0
        let portResult = IOMasterPort(kIOMainPortDefault, &masterPort)
        guard portResult == kIOReturnSuccess else { return }
        let matchingDict = IOServiceMatching(kIOSerialBSDServiceValue)
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        if matchResult == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != IO_OBJECT_NULL {
                processSerialDevice(device)
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func processSerialDevice(_ device: io_object_t) {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(device, &properties, nil, 0)
        
        if result == kIOReturnSuccess, let props = properties?.takeRetainedValue() as? [String: Any] {
            if let devicePath = props["IODialinDevice"] as? String,
               let baudRate = props["baud rate"] as? Int {
                
                let serialDevice = SerialDevice(
                    deviceId: devicePath,
                    devicePath: devicePath,
                    manufacturer: props["USB Vendor Name"] as? String ?? "",
                    product: props["USB Product Name"] as? String ?? "",
                    baudRate: baudRate,
                    dataBits: props["data bits"] as? Int ?? 8,
                    stopBits: props["stop bits"] as? Int ?? 1,
                    parity: props["parity"] as? String ?? "none"
                )
                
                serialDevices.append(serialDevice)
                addDiscoveredDevice(serialDevice)
            }
        }
    }
    
    private func discoverHIDDevices() {
        var masterPort: mach_port_t = 0
        let portResult = IOMasterPort(kIOMainPortDefault, &masterPort)
        guard portResult == kIOReturnSuccess else { return }
        let matchingDict = IOServiceMatching(kIOHIDDeviceKey)
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        if matchResult == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != IO_OBJECT_NULL {
                processHIDDevice(device)
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func processHIDDevice(_ device: io_object_t) {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(device, &properties, nil, 0)
        
        if result == kIOReturnSuccess, let props = properties?.takeRetainedValue() as? [String: Any] {
            if let usage = props["PrimaryUsage"] as? Int,
               let vendorId = props["VendorID"] as? Int,
               let productId = props["ProductID"] as? Int {
                
                let hidDevice = HIDDevice(
                    deviceId: "\(vendorId)-\(productId)-\(usage)",
                    vendorId: vendorId,
                    productId: productId,
                    usage: usage,
                    manufacturer: props["Manufacturer"] as? String ?? "",
                    product: props["Product"] as? String ?? "",
                    serialNumber: props["SerialNumber"] as? String ?? "",
                    version: props["VersionNumber"] as? Int ?? 0
                )
                
                hidDevices.append(hidDevice)
                addDiscoveredDevice(hidDevice)
            }
        }
    }
    
    private func addDiscoveredDevice(_ device: Any) {
        let discoveredDevice = DiscoveredDevice(
            deviceId: getDeviceId(from: device),
            name: getDeviceName(from: device),
            deviceType: getDeviceType(from: device),
            connectionType: getConnectionType(from: device),
            status: .online,
            lastSeen: Date()
        )
        
        discoveredDevices.append(discoveredDevice)
        deviceCount = discoveredDevices.count
        updateScanProgress()
    }
    
    private func getDeviceId(from device: Any) -> String {
        if let usbDevice = device as? USBDevice {
            return usbDevice.deviceId
        } else if let firewireDevice = device as? FirewireDevice {
            return firewireDevice.deviceId
        } else if let serialDevice = device as? SerialDevice {
            return serialDevice.deviceId
        } else if let hidDevice = device as? HIDDevice {
            return hidDevice.deviceId
        } else if let networkDevice = device as? NetworkDevice {
            return networkDevice.deviceId
        } else if let bluetoothDevice = device as? BluetoothDevice {
            return bluetoothDevice.deviceId
        }
        return UUID().uuidString
    }
    
    private func getDeviceName(from device: Any) -> String {
        if let usbDevice = device as? USBDevice {
            return usbDevice.product.isEmpty ? "USB Device" : usbDevice.product
        } else if let firewireDevice = device as? FirewireDevice {
            return firewireDevice.product.isEmpty ? "Firewire Device" : firewireDevice.product
        } else if let serialDevice = device as? SerialDevice {
            return serialDevice.product.isEmpty ? "Serial Device" : serialDevice.product
        } else if let hidDevice = device as? HIDDevice {
            return hidDevice.product.isEmpty ? "HID Device" : hidDevice.product
        } else if let networkDevice = device as? NetworkDevice {
            return networkDevice.name.isEmpty ? "Network Device" : networkDevice.name
        } else if let bluetoothDevice = device as? BluetoothDevice {
            return bluetoothDevice.name.isEmpty ? "Bluetooth Device" : bluetoothDevice.name
        }
        return "Unknown Device"
    }
    
    private func getDeviceType(from device: Any) -> DeviceType {
        if device is HIDDevice {
            return .peripheral
        } else if device is SerialDevice {
            return .peripheral
        }
        return .computer
    }
    
    private func getConnectionType(from device: Any) -> ConnectionType {
        if device is USBDevice {
            return .usb
        } else if device is FirewireDevice {
            return .firewire
        } else if device is SerialDevice {
            return .serial
        } else if device is HIDDevice {
            return .hid
        } else if device is NetworkDevice {
            return .network
        } else if device is BluetoothDevice {
            return .bluetooth
        }
        return .network
    }
    
    private func updateScanProgress() {
        scanProgress = min(1.0, Double(discoveredDevices.count) / 100.0)
        if scanProgress >= 1.0 {
            discoveryStatus = .completed
            lastScanTime = Date()
        }
    }
    
    private func startPeriodicDiscovery() {
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performPeriodicDiscovery()
        }
    }
    
    private func stopPeriodicDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }
    
    private func performPeriodicDiscovery() {
        // Periodic device discovery
        startHardwareDiscovery()
    }
    
    private func handleNetworkBrowserState(_ state: NWBrowser.State) {
        switch state {
        case .ready:
            print("Network browser ready")
        case .failed(let error):
            print("Network browser failed: \(error)")
        case .cancelled:
            print("Network browser cancelled")
        default:
            break
        }
    }
    
    private func handleNetworkBrowserResults(_ results: Set<NWBrowser.Result>, changes: [NWBrowser.Result.Change]) {
        for change in changes {
            switch change {
            case .added(let result):
                let networkDevice = NetworkDevice(
                    deviceId: result.endpoint.debugDescription,
                    name: result.endpoint.debugDescription,
                    endpoint: result.endpoint,
                    type: .network,
                    status: .online,
                    lastSeen: Date()
                )
                networkDevices.append(networkDevice)
                addDiscoveredDevice(networkDevice)
            case .removed(let result):
                networkDevices.removeAll { $0.deviceId == result.endpoint.debugDescription }
                discoveredDevices.removeAll { $0.deviceId == result.endpoint.debugDescription }
            case .changed(let oldResult, _, _):
                // No mutation of let properties
                _ = networkDevices.firstIndex(where: { $0.deviceId == oldResult.endpoint.debugDescription })
            case .identical:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DeviceDiscoveryService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isScanning {
                startBluetoothDiscovery()
            }
        case .poweredOff:
            stopBluetoothDiscovery()
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let bluetoothDevice = BluetoothDevice(
            deviceId: peripheral.identifier.uuidString,
            name: peripheral.name ?? "Unknown Bluetooth Device",
            peripheral: peripheral,
            rssi: RSSI,
            advertisementData: advertisementData
        )
        
        bluetoothDevices.append(bluetoothDevice)
        addDiscoveredDevice(bluetoothDevice)
    }
}

// MARK: - Data Models

@objc public class DiscoveredDevice: NSObject {
    public let deviceId: String
    public let name: String
    public let deviceType: DeviceType
    public let connectionType: ConnectionType
    public var status: DeviceStatus
    public var lastSeen: Date
    
    public init(deviceId: String, name: String, deviceType: DeviceType, connectionType: ConnectionType, status: DeviceStatus, lastSeen: Date) {
        self.deviceId = deviceId
        self.name = name
        self.deviceType = deviceType
        self.connectionType = connectionType
        self.status = status
        self.lastSeen = lastSeen
        super.init()
    }
}

@objc public enum DiscoveryStatus: Int, CaseIterable {
    case idle = 0
    case scanning = 1
    case completed = 2
    case failed = 3
} 