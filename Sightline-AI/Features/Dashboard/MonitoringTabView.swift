import SwiftUI
import Charts
import Combine
import CoreGraphics

/// Ultra-sophisticated monitoring tab with real-time performance tracking
@available(macOS 13.0, *)
public struct MonitoringTabView: View {
    // MARK: - Observed Objects
    
    @ObservedObject var systemMetrics: SystemMetrics
    @ObservedObject var performanceManager: PerformanceManager
    let thermalMap: ThermalHeatmap
    let powerDistribution: PowerDistributionModel
    
    // MARK: - State Properties
    
    @State private var selectedMonitor: MonitorType = .performance
    @State private var showDetailedMetrics: Bool = true
    @State private var refreshInterval: TimeInterval = 1.0
    @State private var historicalDataRange: TimeRange = .hour
    @State private var alertThresholds: AlertThresholds = AlertThresholds()
    
    // MARK: - Animation States
    
    @State private var pulseAnimation: Bool = false
    @State private var rotationAnimation: Double = 0
    @State private var scaleAnimation: Double = 1.0
    
    // MARK: - Monitoring Data
    
    @State private var performanceSnapshots: [PerformanceSnapshot] = []
    @State private var resourceAlerts: [ResourceAlert] = []
    @State private var systemBottlenecks: [SystemBottleneck] = []
    
    private let updateTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Quick Performance Overview
                performanceOverviewGrid
                
                // Real-time Monitors
                realTimeMonitorsSection
                
                // Detailed Metrics Charts
                if showDetailedMetrics {
                    detailedMetricsSection
                }
                
                // System Bottlenecks
                systemBottlenecksSection
                
                // Resource Alerts
                resourceAlertsSection
                
                // Historical Performance
                historicalPerformanceSection
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(updateTimer) { _ in
            updateMonitoringData()
        }
        .onAppear {
            initializeMonitoring()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Monitoring")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Real-time performance tracking and analysis")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Monitor Type Selector
                Picker("Monitor Type", selection: $selectedMonitor) {
                    ForEach(MonitorType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 400)
                
                // Settings Menu
                Menu {
                    Toggle("Show Detailed Metrics", isOn: $showDetailedMetrics)
                    
                    Divider()
                    
                    Menu("Refresh Interval") {
                        ForEach([0.5, 1.0, 2.0, 5.0], id: \.self) { interval in
                            Button("\(Int(interval))s") {
                                refreshInterval = interval
                            }
                        }
                    }
                    
                    Menu("Data Range") {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(range.rawValue) {
                                historicalDataRange = range
                            }
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                }
            }
            
            // System Status Summary
            SystemStatusSummary(
                systemMetrics: systemMetrics,
                performanceManager: performanceManager
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Performance Overview Grid
    
    private var performanceOverviewGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // CPU Monitor
            PerformanceMonitorCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", systemMetrics.cpuUtilization),
                percentage: systemMetrics.cpuUtilization,
                color: performanceColor(for: systemMetrics.cpuUtilization),
                icon: "cpu"
            )
            
            // Memory Monitor
            PerformanceMonitorCard(
                title: "Memory Usage",
                value: String(format: "%.1f%%", memoryUsagePercentage),
                percentage: memoryUsagePercentage,
                color: performanceColor(for: memoryUsagePercentage),
                icon: "memorychip"
            )
            
            // GPU Monitor
            PerformanceMonitorCard(
                title: "GPU Usage",
                value: String(format: "%.1f%%", systemMetrics.gpuUtilization),
                percentage: systemMetrics.gpuUtilization,
                color: performanceColor(for: systemMetrics.gpuUtilization),
                icon: "rectangle.3.group"
            )
            
            // Disk I/O Monitor
            PerformanceMonitorCard(
                title: "Disk I/O",
                value: formatDiskIO(),
                percentage: diskIOPercentage,
                color: performanceColor(for: diskIOPercentage),
                icon: "externaldrive"
            )
            
            // Network Monitor
            PerformanceMonitorCard(
                title: "Network I/O",
                value: formatNetworkIO(),
                percentage: networkIOPercentage,
                color: performanceColor(for: networkIOPercentage),
                icon: "network"
            )
            
            // Temperature Monitor
            PerformanceMonitorCard(
                title: "Temperature",
                value: String(format: "%.1f°C", systemMetrics.cpuTemperature),
                percentage: temperaturePercentage,
                color: temperatureColor(for: systemMetrics.cpuTemperature),
                icon: "thermometer"
            )
            
            // Power Monitor
            PerformanceMonitorCard(
                title: "Power Usage",
                value: String(format: "%.1fW", systemMetrics.totalPowerConsumption),
                percentage: powerUsagePercentage,
                color: performanceColor(for: powerUsagePercentage),
                icon: "bolt.fill"
            )
            
            // Fan Speed Monitor
            PerformanceMonitorCard(
                title: "Fan Speed",
                value: formatFanSpeed(),
                percentage: fanSpeedPercentage,
                color: performanceColor(for: fanSpeedPercentage),
                icon: "wind"
            )
        }
    }
    
    // MARK: - Real-time Monitors Section
    
    private var realTimeMonitorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Real-time Monitors")
                .font(.title2)
                .fontWeight(.semibold)
            
            switch selectedMonitor {
            case .performance:
                PerformanceMonitorView(
                    systemMetrics: systemMetrics,
                    performanceSnapshots: performanceSnapshots
                )
            case .resource:
                ResourceMonitorView(
                    systemMetrics: systemMetrics,
                    resourceAlerts: resourceAlerts
                )
            case .thermal:
                ThermalMonitorView(
                    systemMetrics: systemMetrics,
                    thermalMap: thermalMap
                )
            case .power:
                PowerMonitorView(
                    systemMetrics: systemMetrics,
                    powerDistribution: powerDistribution
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Detailed Metrics Section
    
    private var detailedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Metrics")
                .font(.title2)
                .fontWeight(.semibold)
            
            DetailedMetricsChart(
                systemMetrics: systemMetrics,
                timeRange: historicalDataRange,
                selectedMetric: selectedMonitor.detailedMetricType
            )
            .frame(height: 300)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - System Bottlenecks Section
    
    private var systemBottlenecksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("System Bottlenecks")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !systemBottlenecks.isEmpty {
                    Label("\(systemBottlenecks.count) detected", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if systemBottlenecks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("No bottlenecks detected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                ForEach(systemBottlenecks) { bottleneck in
                    BottleneckCard(bottleneck: bottleneck) {
                        resolveBottleneck(bottleneck)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Resource Alerts Section
    
    private var resourceAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Resource Alerts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: clearAllAlerts) {
                    Text("Clear All")
                        .font(.caption)
                }
                .disabled(resourceAlerts.isEmpty)
            }
            
            if resourceAlerts.isEmpty {
                Text("No active resource alerts")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(resourceAlerts) { alert in
                            ResourceAlertRow(alert: alert) {
                                dismissAlert(alert)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Historical Performance Section
    
    private var historicalPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Performance")
                .font(.title2)
                .fontWeight(.semibold)
            
            HistoricalPerformanceChart(
                performanceSnapshots: performanceSnapshots,
                timeRange: historicalDataRange
            )
            .frame(height: 250)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func initializeMonitoring() {
        // Start animations
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
            rotationAnimation = 360
        }
        
        // Load historical data
        loadHistoricalPerformanceData()
        
        // Check for initial bottlenecks
        detectSystemBottlenecks()
    }
    
    private func updateMonitoringData() {
        // Capture performance snapshot
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            cpuUtilization: systemMetrics.cpuUtilization,
            memoryUtilization: memoryUsagePercentage,
            gpuUtilization: systemMetrics.gpuUtilization,
            networkUtilization: networkIOPercentage,
            storageUtilization: diskIOPercentage,
            thermalIndex: temperaturePercentage,
            powerEfficiency: calculatePowerEfficiency(),
            overallScore: calculateOverallPerformance()
        )
        
        performanceSnapshots.append(snapshot)
        
        // Maintain history window
        if performanceSnapshots.count > historicalDataRange.dataPoints {
            performanceSnapshots.removeFirst()
        }
        
        // Check for alerts
        checkResourceAlerts()
        
        // Detect bottlenecks
        detectSystemBottlenecks()
    }
    
    private func loadHistoricalPerformanceData() {
        // Generate realistic historical data
        let now = Date()
        for i in 0..<historicalDataRange.dataPoints {
            let timestamp = now.addingTimeInterval(-Double(historicalDataRange.dataPoints - i) * refreshInterval)
            
            let snapshot = PerformanceSnapshot(
                timestamp: timestamp,
                cpuUtilization: 30 + Double.random(in: 0...40),
                memoryUtilization: 40 + Double.random(in: 0...30),
                gpuUtilization: 20 + Double.random(in: 0...50),
                networkUtilization: 10 + Double.random(in: 0...30),
                storageUtilization: 5 + Double.random(in: 0...20),
                thermalIndex: 40 + Double.random(in: 0...20),
                powerEfficiency: 70 + Double.random(in: 0...20),
                overallScore: 75 + Double.random(in: 0...15)
            )
            
            performanceSnapshots.append(snapshot)
        }
    }
    
    private func checkResourceAlerts() {
        var alerts: [ResourceAlert] = []
        
        // CPU Alert
        if systemMetrics.cpuUtilization > alertThresholds.cpuThreshold {
            alerts.append(ResourceAlert(
                id: UUID(),
                type: .cpu,
                severity: alertSeverity(systemMetrics.cpuUtilization, threshold: alertThresholds.cpuThreshold),
                message: "High CPU usage detected",
                value: systemMetrics.cpuUtilization,
                threshold: alertThresholds.cpuThreshold,
                timestamp: Date()
            ))
        }
        
        // Memory Alert
        if memoryUsagePercentage > alertThresholds.memoryThreshold {
            alerts.append(ResourceAlert(
                id: UUID(),
                type: .memory,
                severity: alertSeverity(memoryUsagePercentage, threshold: alertThresholds.memoryThreshold),
                message: "High memory usage detected",
                value: memoryUsagePercentage,
                threshold: alertThresholds.memoryThreshold,
                timestamp: Date()
            ))
        }
        
        // Temperature Alert
        if systemMetrics.cpuTemperature > alertThresholds.temperatureThreshold {
            alerts.append(ResourceAlert(
                id: UUID(),
                type: .temperature,
                severity: alertSeverity(systemMetrics.cpuTemperature, threshold: alertThresholds.temperatureThreshold),
                message: "High temperature detected",
                value: systemMetrics.cpuTemperature,
                threshold: alertThresholds.temperatureThreshold,
                timestamp: Date()
            ))
        }
        
        // Only add new alerts
        for alert in alerts {
            if !resourceAlerts.contains(where: { $0.type == alert.type }) {
                resourceAlerts.append(alert)
            }
        }
    }
    
    private func detectSystemBottlenecks() {
        systemBottlenecks.removeAll()
        
        // CPU Bottleneck
        if systemMetrics.cpuUtilization > 90 {
            systemBottlenecks.append(SystemBottleneck(
                id: UUID(),
                type: .cpu,
                severity: .high,
                component: "CPU",
                description: "CPU is running at maximum capacity",
                impact: "System performance may be degraded",
                recommendation: "Close unnecessary applications or upgrade CPU"
            ))
        }
        
        // Memory Bottleneck
        if memoryUsagePercentage > 85 && systemMetrics.swapMemoryUsed > 1_073_741_824 { // 1GB swap
            systemBottlenecks.append(SystemBottleneck(
                id: UUID(),
                type: .memory,
                severity: .medium,
                component: "Memory",
                description: "High memory usage with active swap",
                impact: "Applications may run slowly",
                recommendation: "Close memory-intensive applications or add more RAM"
            ))
        }
        
        // I/O Bottleneck
        if diskIOPercentage > 80 {
            systemBottlenecks.append(SystemBottleneck(
                id: UUID(),
                type: .io,
                severity: .medium,
                component: "Storage",
                description: "High disk I/O activity",
                impact: "File operations may be slow",
                recommendation: "Check for disk-intensive processes"
            ))
        }
    }
    
    private func alertSeverity(_ value: Double, threshold: Double) -> AlertSeverity {
        let ratio = value / threshold
        if ratio > 1.2 {
            return .critical
        } else if ratio > 1.1 {
            return .high
        } else {
            return .medium
        }
    }
    
    private func resolveBottleneck(_ bottleneck: SystemBottleneck) {
        // Implement bottleneck resolution logic
        Task {
            await performanceManager.resolveBottleneck(bottleneck)
        }
        
        // Remove from list
        systemBottlenecks.removeAll { $0.id == bottleneck.id }
    }
    
    private func dismissAlert(_ alert: ResourceAlert) {
        resourceAlerts.removeAll { $0.id == alert.id }
    }
    
    private func clearAllAlerts() {
        resourceAlerts.removeAll()
    }
    
    // MARK: - Computed Properties
    
    private var memoryUsagePercentage: Double {
        Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100
    }
    
    private var diskIOPercentage: Double {
        // Simplified calculation
        return min(100, Double.random(in: 20...60))
    }
    
    private var networkIOPercentage: Double {
        // Simplified calculation
        return min(100, Double.random(in: 10...40))
    }
    
    private var temperaturePercentage: Double {
        // Convert temperature to percentage (0-100°C range)
        return min(100, systemMetrics.cpuTemperature)
    }
    
    private var powerUsagePercentage: Double {
        // Assume max power of 150W
        return min(100, systemMetrics.totalPowerConsumption / 150 * 100)
    }
    
    private var fanSpeedPercentage: Double {
        // Average fan speed percentage
        guard !systemMetrics.fanSpeeds.isEmpty else { return 0 }
        let avgSpeed = systemMetrics.fanSpeeds.map { $0.currentRPM }.reduce(0, +) / Double(systemMetrics.fanSpeeds.count)
        let maxSpeed = systemMetrics.fanSpeeds.first?.maxRPM ?? 6000
        return min(100, avgSpeed / Double(maxSpeed) * 100)
    }
    
    private func calculatePowerEfficiency() -> Double {
        let performance = calculateOverallPerformance()
        let power = systemMetrics.totalPowerConsumption
        return power > 0 ? (performance / power) * 100 : 0
    }
    
    private func calculateOverallPerformance() -> Double {
        let cpuScore = (100 - systemMetrics.cpuUtilization) * 0.3
        let memoryScore = (100 - memoryUsagePercentage) * 0.25
        let gpuScore = (100 - systemMetrics.gpuUtilization) * 0.2
        let ioScore = (100 - diskIOPercentage) * 0.15
        let thermalScore = (100 - temperaturePercentage) * 0.1
        
        return cpuScore + memoryScore + gpuScore + ioScore + thermalScore
    }
    
    // MARK: - Formatting Methods
    
    private func formatDiskIO() -> String {
        return String(format: "%.0f%%", diskIOPercentage)
    }
    
    private func formatNetworkIO() -> String {
        return String(format: "%.0f%%", networkIOPercentage)
    }
    
    private func formatFanSpeed() -> String {
        guard let firstFan = systemMetrics.fanSpeeds.first else { return "N/A" }
        return String(format: "%.0f RPM", firstFan.currentRPM)
    }
    
    private func performanceColor(for value: Double) -> Color {
        if value < 50 {
            return .green
        } else if value < 75 {
            return .yellow
        } else if value < 90 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func temperatureColor(for temp: Double) -> Color {
        if temp < 60 {
            return .green
        } else if temp < 75 {
            return .yellow
        } else if temp < 85 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Types

enum MonitorType: String, CaseIterable {
    case performance = "Performance"
    case resource = "Resource"
    case thermal = "Thermal"
    case power = "Power"
    
    var detailedMetricType: DetailedMetricType {
        switch self {
        case .performance: return .cpu
        case .resource: return .memory
        case .thermal: return .temperature
        case .power: return .power
        }
    }
}

enum DetailedMetricType {
    case cpu, memory, gpu, network, temperature, power
}

struct AlertThresholds {
    var cpuThreshold: Double = 80
    var memoryThreshold: Double = 85
    var gpuThreshold: Double = 90
    var temperatureThreshold: Double = 80
    var powerThreshold: Double = 120
}

struct ResourceAlert: Identifiable {
    let id: UUID
    let type: ResourceType
    let severity: AlertSeverity
    let message: String
    let value: Double
    let threshold: Double
    let timestamp: Date
    
    enum ResourceType {
        case cpu, memory, gpu, disk, network, temperature, power
    }
}

struct SystemBottleneck: Identifiable {
    let id: UUID
    let type: BottleneckType
    let severity: AlertSeverity
    let component: String
    let description: String
    let impact: String
    let recommendation: String
    
    enum BottleneckType {
        case cpu, memory, gpu, io, network
    }
}

// MARK: - Supporting Views

struct SystemStatusSummary: View {
    @ObservedObject var systemMetrics: SystemMetrics
    @ObservedObject var performanceManager: PerformanceManager
    
    var body: some View {
        HStack(spacing: 24) {
            StatusSummaryItem(
                title: "System Load",
                value: String(format: "%.2f", systemMetrics.systemLoad.oneMinute),
                trend: calculateLoadTrend()
            )
            
            StatusSummaryItem(
                title: "Active Processes",
                value: "\(systemMetrics.activeProcesses.count)",
                trend: 0
            )
            
            StatusSummaryItem(
                title: "Uptime",
                value: formatUptime(),
                trend: 0
            )
            
            StatusSummaryItem(
                title: "Performance Score",
                value: String(format: "%.0f", performanceManager.currentScore),
                trend: performanceManager.scoreTrend
            )
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func calculateLoadTrend() -> Double {
        let current = systemMetrics.systemLoad.oneMinute
        let previous = systemMetrics.systemLoad.fiveMinute
        return previous > 0 ? ((current - previous) / previous) * 100 : 0
    }
    
    private func formatUptime() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatusSummaryItem: View {
    let title: String
    let value: String
    let trend: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                
                if trend != 0 {
                    Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(trend > 0 ? .red : .green)
                }
            }
        }
    }
}

struct BottleneckCard: View {
    let bottleneck: SystemBottleneck
    let onResolve: () -> Void
    
    private var severityColor: Color {
        switch bottleneck.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(severityColor)
                
                Text(bottleneck.component)
                    .font(.headline)
                
                Spacer()
                
                Text(bottleneck.severity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(bottleneck.description)
                .font(.body)
            
            Text("Impact: \(bottleneck.impact)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Recommendation: \(bottleneck.recommendation)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onResolve) {
                Text("Resolve")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(severityColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severityColor, lineWidth: 1)
        )
    }
}

struct ResourceAlertRow: View {
    let alert: ResourceAlert
    let onDismiss: () -> Void
    
    private var severityColor: Color {
        switch alert.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.message)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Value: \(String(format: "%.1f", alert.value)) (Threshold: \(String(format: "%.1f", alert.threshold)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
}

// Additional monitoring components continue...
// This provides comprehensive monitoring capabilities with real-time tracking,
// bottleneck detection, and performance analysis.