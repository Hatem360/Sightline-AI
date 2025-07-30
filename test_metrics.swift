#!/usr/bin/env swift

import Foundation

// Simple test to check if metrics would update
class MockSystemMetrics {
    var cpuUtilization: Double = 0.0
    var networkBandwidthIn: Double = 0.0
    var networkBandwidthOut: Double = 0.0
    var batteryLevel: Double = 0.0
    private var timer: Timer?
    
    init() {
        print("Initializing MockSystemMetrics...")
        startUpdates()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startUpdates() {
        print("Starting timer...")
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMetrics()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func updateMetrics() {
        cpuUtilization = Double.random(in: 20...80)
        networkBandwidthIn = Double.random(in: 0...10) * 1_000_000
        networkBandwidthOut = Double.random(in: 0...5) * 1_000_000
        batteryLevel = Double.random(in: 50...100)
        
        print("Updated metrics:")
        print("  CPU: \(cpuUtilization)%")
        print("  Download: \(networkBandwidthIn / 1_000_000) MB/s")
        print("  Upload: \(networkBandwidthOut / 1_000_000) MB/s")
        print("  Battery: \(batteryLevel)%")
        print("---")
    }
}

print("Testing metrics updates...")
let metrics = MockSystemMetrics()

// Run for 5 seconds
RunLoop.current.run(until: Date().addingTimeInterval(5))
print("Test completed.")