import SwiftUI
import Charts
import CoreGraphics

// MARK: - Performance Monitor Card

@available(macOS 13.0, *)
public struct PerformanceMonitorCard: View {
    let title: String
    let value: String
    let percentage: Double
    let color: Color
    let icon: String
    
    @State private var isHovered: Bool = false
    @State private var animationProgress: Double = 0
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                color.opacity(0.6),
                color
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Value Display
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressGradient)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100 * animationProgress))
                    
                    // Glow effect when high usage
                    if percentage > 80 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.3))
                            .frame(width: geometry.size.width * CGFloat(percentage / 100 * animationProgress))
                            .blur(radius: 4)
                    }
                }
            }
            .frame(height: 12)
            
            // Status Text
            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusTextColor)
                
                Spacer()
                
                if percentage > 80 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? color.opacity(0.2) : .black.opacity(0.1),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? color.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var statusText: String {
        if percentage < 50 {
            return "Normal"
        } else if percentage < 75 {
            return "Moderate"
        } else if percentage < 90 {
            return "High"
        } else {
            return "Critical"
        }
    }
    
    private var statusTextColor: Color {
        if percentage < 50 {
            return .green
        } else if percentage < 75 {
            return .yellow
        } else if percentage < 90 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Performance Monitor View

@available(macOS 13.0, *)
public struct PerformanceMonitorView: View {
    @ObservedObject var systemMetrics: SystemMetrics
    let performanceSnapshots: [PerformanceSnapshot]
    
    @State private var selectedMetric: String = "CPU"
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Metric Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["CPU", "Memory", "GPU", "Network", "Storage"], id: \.self) { metric in
                        MetricSelectorButton(
                            title: metric,
                            isSelected: selectedMetric == metric,
                            action: { selectedMetric = metric }
                        )
                    }
                }
            }
            
            // Real-time Chart
            Chart(performanceSnapshots) { snapshot in
                LineMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Usage", metricValue(for: selectedMetric, from: snapshot))
                )
                .foregroundStyle(metricColor(for: selectedMetric).gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Usage", metricValue(for: selectedMetric, from: snapshot))
                )
                .foregroundStyle(metricColor(for: selectedMetric).opacity(0.1).gradient)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .second, count: 30)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.second())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Current Metrics
            CurrentMetricsGrid(
                systemMetrics: systemMetrics,
                selectedMetric: selectedMetric
            )
        }
    }
    
    private func metricValue(for metric: String, from snapshot: PerformanceSnapshot) -> Double {
        switch metric {
        case "CPU": return snapshot.cpuUtilization
        case "Memory": return snapshot.memoryUtilization
        case "GPU": return snapshot.gpuUtilization
        case "Network": return snapshot.networkUtilization
        case "Storage": return snapshot.storageUtilization
        default: return 0
        }
    }
    
    private func metricColor(for metric: String) -> Color {
        switch metric {
        case "CPU": return .blue
        case "Memory": return .purple
        case "GPU": return .green
        case "Network": return .orange
        case "Storage": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Resource Monitor View

@available(macOS 13.0, *)
public struct ResourceMonitorView: View {
    @ObservedObject var systemMetrics: SystemMetrics
    let resourceAlerts: [ResourceAlert]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Resource Usage Summary
            ResourceUsageSummary(systemMetrics: systemMetrics)
            
            // Process List
            Text("Top Processes")
                .font(.headline)
            
            ProcessResourceList(
                processes: systemMetrics.activeProcesses.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(5)
            )
            
            // Resource Distribution
            ResourceDistributionChart(systemMetrics: systemMetrics)
                .frame(height: 150)
        }
    }
}

// MARK: - Thermal Monitor View

@available(macOS 13.0, *)
public struct ThermalMonitorView: View {
    @ObservedObject var systemMetrics: SystemMetrics
    let thermalMap: ThermalHeatmap
    
    @State private var selectedSensor: String? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Temperature Overview
            HStack(spacing: 16) {
                TemperatureCard(
                    title: "CPU",
                    temperature: systemMetrics.cpuTemperature,
                    icon: "cpu"
                )
                
                TemperatureCard(
                    title: "GPU",
                    temperature: systemMetrics.gpuTemperature,
                    icon: "rectangle.3.group"
                )
                
                TemperatureCard(
                    title: "System",
                    temperature: systemMetrics.systemTemperature,
                    icon: "macpro.gen3"
                )
            }
            
            // Thermal Zones Visualization
            ThermalZonesView(
                sensors: systemMetrics.thermalSensors,
                selectedSensor: $selectedSensor
            )
            .frame(height: 200)
            
            // Fan Control
            FanStatusView(fans: systemMetrics.fans)
        }
    }
}

// MARK: - Power Monitor View

@available(macOS 13.0, *)
public struct PowerMonitorView: View {
    @ObservedObject var systemMetrics: SystemMetrics
    let powerDistribution: PowerDistributionModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Power Overview
            PowerOverviewCard(
                totalPower: systemMetrics.totalPowerConsumption,
                cpuPower: systemMetrics.cpuPower,
                gpuPower: systemMetrics.gpuPower,
                systemPower: systemMetrics.systemPower
            )
            
            // Power Distribution Chart
            PowerDistributionChart(
                cpuPower: systemMetrics.cpuPower,
                gpuPower: systemMetrics.gpuPower,
                systemPower: systemMetrics.systemPower,
                otherPower: max(0, systemMetrics.totalPowerConsumption - systemMetrics.cpuPower - systemMetrics.gpuPower - systemMetrics.systemPower)
            )
            .frame(height: 200)
            
            // Battery Status (if applicable)
            if let batteryLevel = systemMetrics.batteryLevel {
                BatteryStatusView(
                    level: batteryLevel,
                    isCharging: systemMetrics.isCharging,
                    timeRemaining: systemMetrics.batteryTimeRemaining
                )
            }
        }
    }
}

// MARK: - Supporting Components

struct MetricSelectorButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

struct CurrentMetricsGrid: View {
    @ObservedObject var systemMetrics: SystemMetrics
    let selectedMetric: String
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            switch selectedMetric {
            case "CPU":
                MetricDetailCard(title: "Frequency", value: String(format: "%.1f GHz", systemMetrics.cpuFrequency))
                MetricDetailCard(title: "Cores Active", value: "\(systemMetrics.cpuCores.filter { $0.isActive }.count)")
                MetricDetailCard(title: "Processes", value: "\(systemMetrics.activeProcesses.count)")
                
            case "Memory":
                MetricDetailCard(title: "Used", value: formatBytes(systemMetrics.physicalMemoryUsed))
                MetricDetailCard(title: "Available", value: formatBytes(systemMetrics.physicalMemoryAvailable))
                MetricDetailCard(title: "Swap", value: formatBytes(systemMetrics.swapMemoryUsed))
                
            case "GPU":
                MetricDetailCard(title: "Memory Used", value: formatBytes(systemMetrics.gpuMemoryUsed))
                MetricDetailCard(title: "Frequency", value: String(format: "%.0f MHz", systemMetrics.gpuFrequency))
                MetricDetailCard(title: "Power", value: String(format: "%.1f W", systemMetrics.gpuPower))
                
            default:
                EmptyView()
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MetricDetailCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
}

struct ResourceUsageSummary: View {
    @ObservedObject var systemMetrics: SystemMetrics
    
    var body: some View {
        VStack(spacing: 12) {
            ResourceBar(
                title: "CPU",
                usage: systemMetrics.cpuUtilization,
                color: .blue
            )
            
            ResourceBar(
                title: "Memory",
                usage: Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100,
                color: .purple
            )
            
            ResourceBar(
                title: "GPU",
                usage: systemMetrics.gpuUtilization,
                color: .green
            )
        }
    }
}

struct ResourceBar: View {
    let title: String
    let usage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", usage))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(usage / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

struct ProcessResourceList: View {
    let processes: any Sequence<SystemProcessInfo>
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(processes), id: \.pid) { process in
                ProcessResourceRow(process: process)
            }
        }
    }
}

struct ProcessResourceRow: View {
    let process: SystemProcessInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("PID: \(process.pid)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("CPU")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatBytes(process.memoryUsage))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Memory")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

@available(macOS 13.0, *)
struct ResourceDistributionChart: View {
    @ObservedObject var systemMetrics: SystemMetrics
    
    var body: some View {
        Chart {
            SectorMark(
                angle: .value("CPU", systemMetrics.cpuUtilization),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(.blue)
            
            SectorMark(
                angle: .value("Memory", Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(.purple)
            
            SectorMark(
                angle: .value("GPU", systemMetrics.gpuUtilization),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(.green)
        }
    }
}

struct TemperatureCard: View {
    let title: String
    let temperature: Double
    let icon: String
    
    private var temperatureColor: Color {
        if temperature < 60 {
            return .green
        } else if temperature < 75 {
            return .yellow
        } else if temperature < 85 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(temperatureColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f°C", temperature))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(temperatureColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(temperatureColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(temperatureColor, lineWidth: 1)
        )
    }
}

// Additional monitoring components would continue...
// This provides comprehensive monitoring UI components with
// real-time visualization and performance tracking.