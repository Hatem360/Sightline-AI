import SwiftUI
import Charts
import CoreGraphics
import simd

// MARK: - System Health Dashboard

@available(macOS 13.0, *)
public struct SystemHealthDashboard: View {
    let healthScore: Double
    let cpuHealth: Double
    let memoryHealth: Double
    let storageHealth: Double
    let networkHealth: Double
    let thermalHealth: Double
    
    @State private var animationProgress: Double = 0
    @State private var selectedComponent: String? = nil
    
    private let healthComponents = ["CPU", "Memory", "Storage", "Network", "Thermal"]
    
    public var body: some View {
        VStack(spacing: 20) {
            // Overall Health Score
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                // Health score arc
                Circle()
                    .trim(from: 0, to: CGFloat(healthScore / 100 * animationProgress))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                healthColor(for: healthScore),
                                healthColor(for: healthScore).opacity(0.7)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180, height: 180)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", healthScore))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(healthColor(for: healthScore))
                    
                    Text("Overall Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Component Health Breakdown
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ComponentHealthCard(
                    title: "CPU",
                    value: cpuHealth,
                    icon: "cpu",
                    isSelected: selectedComponent == "CPU"
                ) {
                    selectedComponent = selectedComponent == "CPU" ? nil : "CPU"
                }
                
                ComponentHealthCard(
                    title: "Memory",
                    value: memoryHealth,
                    icon: "memorychip",
                    isSelected: selectedComponent == "Memory"
                ) {
                    selectedComponent = selectedComponent == "Memory" ? nil : "Memory"
                }
                
                ComponentHealthCard(
                    title: "Storage",
                    value: storageHealth,
                    icon: "externaldrive",
                    isSelected: selectedComponent == "Storage"
                ) {
                    selectedComponent = selectedComponent == "Storage" ? nil : "Storage"
                }
                
                ComponentHealthCard(
                    title: "Network",
                    value: networkHealth,
                    icon: "network",
                    isSelected: selectedComponent == "Network"
                ) {
                    selectedComponent = selectedComponent == "Network" ? nil : "Network"
                }
                
                ComponentHealthCard(
                    title: "Thermal",
                    value: thermalHealth,
                    icon: "thermometer",
                    isSelected: selectedComponent == "Thermal"
                ) {
                    selectedComponent = selectedComponent == "Thermal" ? nil : "Thermal"
                }
            }
            
            // Health Status Summary
            if let component = selectedComponent {
                HealthDetailView(
                    component: component,
                    health: healthValue(for: component)
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func healthColor(for value: Double) -> Color {
        if value >= 80 {
            return .green
        } else if value >= 60 {
            return .yellow
        } else if value >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func healthValue(for component: String) -> Double {
        switch component {
        case "CPU": return cpuHealth
        case "Memory": return memoryHealth
        case "Storage": return storageHealth
        case "Network": return networkHealth
        case "Thermal": return thermalHealth
        default: return 0
        }
    }
}

// MARK: - Component Health Card

struct ComponentHealthCard: View {
    let title: String
    let value: Double
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var healthColor: Color {
        if value >= 80 {
            return .green
        } else if value >= 60 {
            return .yellow
        } else if value >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(healthColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(healthColor)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(String(format: "%.0f%%", value))
                    .font(.headline)
                    .foregroundColor(healthColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? healthColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: isHovered ? healthColor.opacity(0.3) : .black.opacity(0.1),
                        radius: isHovered ? 8 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? healthColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Health Detail View

struct HealthDetailView: View {
    let component: String
    let health: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(component) Health Details")
                .font(.headline)
            
            HStack {
                Text("Status:")
                    .foregroundColor(.secondary)
                Text(healthStatus)
                    .fontWeight(.medium)
                    .foregroundColor(healthColor)
            }
            
            Text(healthDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var healthStatus: String {
        if health >= 80 {
            return "Excellent"
        } else if health >= 60 {
            return "Good"
        } else if health >= 40 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    private var healthColor: Color {
        if health >= 80 {
            return .green
        } else if health >= 60 {
            return .yellow
        } else if health >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var healthDescription: String {
        switch component {
        case "CPU":
            return "CPU health is based on utilization levels, temperature, and throttling frequency. Current performance is \(healthStatus.lowercased())."
        case "Memory":
            return "Memory health considers usage percentage, swap activity, and memory pressure. System memory management is \(healthStatus.lowercased())."
        case "Storage":
            return "Storage health factors in available space, I/O performance, and wear levels. Drive condition is \(healthStatus.lowercased())."
        case "Network":
            return "Network health is determined by latency, packet loss, and bandwidth utilization. Connection quality is \(healthStatus.lowercased())."
        case "Thermal":
            return "Thermal health monitors system temperatures and cooling efficiency. Thermal management is \(healthStatus.lowercased())."
        default:
            return ""
        }
    }
}

// MARK: - Health Trends Chart

@available(macOS 13.0, *)
public struct HealthTrendsChart: View {
    let healthHistory: [HealthDataPoint]
    let timeRange: TimeRange
    
    @State private var selectedMetric: String = "Overall"
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metric Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["Overall", "CPU", "Memory", "Storage", "Network", "Thermal"], id: \.self) { metric in
                        Button(action: { selectedMetric = metric }) {
                            Text(metric)
                                .font(.caption)
                                .fontWeight(selectedMetric == metric ? .semibold : .regular)
                                .foregroundColor(selectedMetric == metric ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedMetric == metric ? Color.accentColor : Color.secondary.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Trends Chart
            Chart(healthHistory) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Health", healthValue(for: selectedMetric, from: point))
                )
                .foregroundStyle(Color.accentColor.gradient)
                
                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Health", healthValue(for: selectedMetric, from: point))
                )
                .foregroundStyle(Color.accentColor.opacity(0.1).gradient)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 10)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.hour().minute())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func healthValue(for metric: String, from point: HealthDataPoint) -> Double {
        switch metric {
        case "Overall": return point.overallHealth
        case "CPU": return point.cpuHealth
        case "Memory": return point.memoryHealth
        case "Storage": return point.storageHealth
        case "Network": return point.networkHealth
        case "Thermal": return point.thermalHealth
        default: return 0
        }
    }
}

// MARK: - CPU Core Distribution View

@available(macOS 13.0, *)
public struct CPUCoreDistributionView: View {
    let cores: [CPUCoreInfo]
    let rotationAngle: Double
    
    @State private var selectedCore: Int? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Core Distribution")
                .font(.headline)
            
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
                
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 2)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                    
                    // Core representations
                    ForEach(0..<cores.count, id: \.self) { index in
                        let core = cores[index]
                        let angle = (Double(index) / Double(cores.count)) * 2 * .pi - .pi / 2
                        let coreRadius: CGFloat = 20
                        let distance = radius - 30
                        
                        ZStack {
                            // Core circle
                            Circle()
                                .fill(coreColor(for: core.utilization))
                                .frame(width: coreRadius * 2, height: coreRadius * 2)
                                .scaleEffect(selectedCore == index ? 1.3 : 1.0)
                                .shadow(
                                    color: coreColor(for: core.utilization).opacity(0.5),
                                    radius: selectedCore == index ? 8 : 4
                                )
                            
                            // Core number
                            Text("\(core.coreId)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .position(
                            x: center.x + CGFloat(cos(angle)) * distance,
                            y: center.y + CGFloat(sin(angle)) * distance
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedCore = selectedCore == index ? nil : index
                            }
                        }
                    }
                    
                    // Center info
                    VStack(spacing: 4) {
                        if let selected = selectedCore {
                            Text("Core \(cores[selected].coreId)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(String(format: "%.1f%%", cores[selected].utilization))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(coreColor(for: cores[selected].utilization))
                            
                            Text(String(format: "%.1f GHz", cores[selected].frequency))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(cores.count) Cores")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(String(format: "%.1f%%", averageCoreUtilization()))
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("Average")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .position(center)
                }
            }
            .frame(height: 200)
            .rotationEffect(.degrees(rotationAngle))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
    
    private func coreColor(for utilization: Double) -> Color {
        if utilization < 30 {
            return .green
        } else if utilization < 60 {
            return .yellow
        } else if utilization < 80 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func averageCoreUtilization() -> Double {
        guard !cores.isEmpty else { return 0 }
        return cores.map { $0.utilization }.reduce(0, +) / Double(cores.count)
    }
}

// MARK: - Memory Distribution View

@available(macOS 13.0, *)
public struct MemoryDistributionView: View {
    let used: UInt64
    let total: UInt64
    let wired: UInt64
    let compressed: UInt64
    let app: UInt64
    
    @State private var selectedSegment: String? = nil
    
    private var segments: [(name: String, value: UInt64, color: Color)] {
        [
            ("App Memory", app, .blue),
            ("Wired", wired, .purple),
            ("Compressed", compressed, .orange),
            ("Cached", total - used, .green),
            ("Free", total - used, .gray)
        ]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Distribution")
                .font(.headline)
            
            // Donut Chart
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
                
                ZStack {
                    // Memory segments
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        let startAngle = angleForIndex(index)
                        let endAngle = angleForIndex(index + 1)
                        
                        Path { path in
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: .degrees(startAngle),
                                endAngle: .degrees(endAngle),
                                clockwise: false
                            )
                            path.addArc(
                                center: center,
                                radius: radius * 0.6,
                                startAngle: .degrees(endAngle),
                                endAngle: .degrees(startAngle),
                                clockwise: true
                            )
                            path.closeSubpath()
                        }
                        .fill(segment.color)
                        .opacity(selectedSegment == nil || selectedSegment == segment.name ? 1.0 : 0.3)
                        .scaleEffect(selectedSegment == segment.name ? 1.1 : 1.0)
                        .animation(.spring(), value: selectedSegment)
                        .onTapGesture {
                            withAnimation {
                                selectedSegment = selectedSegment == segment.name ? nil : segment.name
                            }
                        }
                    }
                    
                    // Center info
                    VStack(spacing: 4) {
                        if let selected = selectedSegment,
                           let segment = segments.first(where: { $0.name == selected }) {
                            Text(segment.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(formatBytes(segment.value))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(segment.color)
                        } else {
                            Text("Total")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(formatBytes(total))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(segments, id: \.name) { segment in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)
                        
                        Text(segment.name)
                            .font(.caption2)
                        
                        Spacer()
                        
                        Text(formatBytes(segment.value))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        let totalValue = segments.map { $0.value }.reduce(0, +)
        var angle: Double = -90
        
        for i in 0..<index {
            angle += (Double(segments[i].value) / Double(totalValue)) * 360
        }
        
        return angle
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - GPU Memory Distribution View

@available(macOS 13.0, *)
public struct GPUMemoryDistributionView: View {
    let used: UInt64
    let total: UInt64
    
    @State private var animationProgress: Double = 0
    
    private var percentage: Double {
        total > 0 ? Double(used) / Double(total) * 100 : 0
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPU Memory")
                .font(.headline)
            
            // Visual representation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                    
                    // Used memory
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100 * animationProgress))
                    
                    // Markers
                    ForEach([25, 50, 75], id: \.self) { marker in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1)
                            .offset(x: geometry.size.width * CGFloat(marker) / 100)
                    }
                }
            }
            .frame(height: 40)
            
            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatBytes(used))
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(String(format: "%.1f%%", percentage))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(percentageColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatBytes(total))
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var percentageColor: Color {
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
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Storage Distribution View

@available(macOS 13.0, *)
public struct StorageDistributionView: View {
    let devices: [StorageDevice]
    
    @State private var selectedDevice: String? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Distribution")
                .font(.headline)
            
            ForEach(devices) { device in
                StorageDeviceRow(
                    device: device,
                    isSelected: selectedDevice == device.id,
                    onTap: {
                        withAnimation {
                            selectedDevice = selectedDevice == device.id ? nil : device.id
                        }
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
}

struct StorageDeviceRow: View {
    let device: StorageDevice
    let isSelected: Bool
    let onTap: () -> Void
    
    private var usagePercentage: Double {
        device.totalCapacity > 0 ? Double(device.usedCapacity) / Double(device.totalCapacity) * 100 : 0
    }
    
    private var usageColor: Color {
        if usagePercentage < 70 {
            return .green
        } else if usagePercentage < 85 {
            return .yellow
        } else if usagePercentage < 95 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: device.isInternal ? "internaldrive" : "externaldrive")
                        .foregroundColor(.secondary)
                    
                    Text(device.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", usagePercentage))
                        .font(.caption)
                        .foregroundColor(usageColor)
                }
                
                // Usage bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(usageColor)
                            .frame(width: geometry.size.width * CGFloat(usagePercentage / 100))
                    }
                }
                .frame(height: 6)
                
                if isSelected {
                    HStack {
                        Text("\(formatBytes(device.usedCapacity)) used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(formatBytes(device.availableCapacity)) free")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? usageColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? usageColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Performance Metrics Grid

public struct PerformanceMetricsGrid: View {
    let metrics: [PerformanceMetric]
    let baseline: PerformanceBaseline
    
    public var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(metrics, id: \.name) { metric in
                PerformanceMetricCard(
                    metric: metric,
                    baseline: baselineValue(for: metric.name)
                )
            }
        }
    }
    
    private func baselineValue(for metricName: String) -> Double {
        switch metricName {
        case "CPU Frequency": return baseline.cpuFrequency
        case "Memory Bandwidth": return baseline.memoryBandwidth
        case "GPU Memory Bandwidth": return baseline.gpuMemoryBandwidth
        case "Storage Read Speed": return baseline.storageReadSpeed
        case "Storage Write Speed": return baseline.storageWriteSpeed
        case "Network Latency": return baseline.networkLatency
        case "Cache Hit Rate": return baseline.cacheHitRate
        case "IPC (Instructions Per Cycle)": return baseline.ipc
        default: return 0
        }
    }
}

struct PerformanceMetricCard: View {
    let metric: PerformanceMetric
    let baseline: Double
    
    private var performanceRatio: Double {
        baseline > 0 ? metric.value / baseline : 1.0
    }
    
    private var performanceColor: Color {
        if performanceRatio >= 1.1 {
            return .green
        } else if performanceRatio >= 0.9 {
            return .blue
        } else if performanceRatio >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.name)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", metric.value))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(performanceColor)
                
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Performance indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(performanceColor)
                        .frame(width: geometry.size.width * min(CGFloat(performanceRatio), 1.5))
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2)
        )
    }
}

// MARK: - Performance Score Visualization

@available(macOS 13.0, *)
public struct PerformanceScoreVisualization: View {
    let score: Double
    let components: [PerformanceComponent]
    
    @State private var animationProgress: Double = 0
    
    public var body: some View {
        VStack(spacing: 16) {
            // Overall Score
            HStack {
                Text("Performance Score")
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.1f", score))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                +
                Text(" / 100")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Component Breakdown
            VStack(spacing: 12) {
                ForEach(components, id: \.name) { component in
                    PerformanceComponentRow(
                        component: component,
                        animationProgress: animationProgress
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .blue
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

struct PerformanceComponentRow: View {
    let component: PerformanceComponent
    let animationProgress: Double
    
    private var componentColor: Color {
        if component.score >= 80 {
            return .green
        } else if component.score >= 60 {
            return .blue
        } else if component.score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(component.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.0f%%", component.score))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(componentColor)
                
                Text("(\(String(format: "%.0f%%", component.weight * 100)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(componentColor)
                        .frame(width: geometry.size.width * CGFloat(component.score / 100 * animationProgress))
                }
            }
            .frame(height: 8)
        }
    }
}

// Additional overview components continue...
// This provides comprehensive UI components for the overview tab with
// professional visualizations and real-time data display.