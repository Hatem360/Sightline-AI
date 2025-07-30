import SwiftUI
import Charts
import CoreGraphics
import AppKit

// MARK: - Status Indicator Component

public struct StatusIndicator: View {
    let title: String
    let value: Double
    let unit: String
    let status: SystemStatus
    
    private var statusColor: Color {
        switch status {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - System Status Bar

@available(macOS 13.0, *)
public struct SystemStatusBar: View {
    let healthScore: Double
    let performanceIndex: Double
    let activeAnomalies: [SystemAnomaly]
    
    @State private var isExpanded: Bool = false
    @State private var pulseAnimation: Bool = false
    
    private var overallStatus: SystemStatus {
        if healthScore < 50 || !activeAnomalies.filter({ $0.severity == .critical }).isEmpty {
            return .critical
        } else if healthScore < 70 || !activeAnomalies.filter({ $0.severity == .high }).isEmpty {
            return .warning
        } else {
            return .normal
        }
    }
    
    private var statusColor: Color {
        switch overallStatus {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Status Bar
            HStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 24, height: 24)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.7 : 1.0)
                    
                    Image(systemName: overallStatus == .normal ? "checkmark" : "exclamationmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                
                // Health Score
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.0f%%", healthScore))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Mini health gauge
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(statusColor)
                                    .frame(width: geometry.size.width * (healthScore / 100))
                            }
                        }
                        .frame(width: 60, height: 8)
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Performance Index
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance Index")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", performanceIndex))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("/ 100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Anomalies Badge
                if !activeAnomalies.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("\(activeAnomalies.count) Anomalies")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Expand/Collapse Button
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            
            // Expanded Details
            if isExpanded {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Critical Systems Status
                    Text("Critical Systems")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SystemStatusItem(
                            icon: "cpu",
                            label: "CPU",
                            status: healthScore > 70 ? .normal : .warning
                        )
                        
                        SystemStatusItem(
                            icon: "memorychip",
                            label: "Memory",
                            status: healthScore > 60 ? .normal : .warning
                        )
                        
                        SystemStatusItem(
                            icon: "network",
                            label: "Network",
                            status: .normal
                        )
                        
                        SystemStatusItem(
                            icon: "thermometer",
                            label: "Thermal",
                            status: healthScore > 65 ? .normal : .warning
                        )
                    }
                    
                    // Recent Anomalies
                    if !activeAnomalies.isEmpty {
                        Divider()
                        
                        Text("Recent Anomalies")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(activeAnomalies.prefix(3)) { anomaly in
                            HStack {
                                Image(systemName: anomaly.severity == .critical ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(anomaly.severity == .critical ? .red : .orange)
                                    .font(.caption)
                                
                                Text(anomaly.description)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(anomaly.detectedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            if overallStatus != .normal {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
    }
}

// MARK: - System Status Item

struct SystemStatusItem: View {
    let icon: String
    let label: String
    let status: SystemStatus
    
    private var statusColor: Color {
        switch status {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(statusColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Stat Card

@available(macOS 13.0, *)
public struct QuickStatCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    let sparklineData: [ChartDataPoint]
    let glowIntensity: Double
    
    @State private var isHovered: Bool = false
    @State private var showDetails: Bool = false
    
    private var trendIcon: String {
        if trend > 5 {
            return "arrow.up.right"
        } else if trend < -5 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        if trend > 10 {
            return .red
        } else if trend > 5 {
            return .orange
        } else if trend < -5 {
            return .green
        } else {
            return .secondary
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Trend Indicator
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.caption)
                        .foregroundColor(trendColor)
                    
                    Text(String(format: "%.1f%%", abs(trend)))
                        .font(.caption)
                        .foregroundColor(trendColor)
                }
                .opacity(trend != 0 ? 1 : 0)
            }
            
            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Sparkline Chart
            if !sparklineData.isEmpty {
                Chart(sparklineData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.gradient)
                    
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.opacity(0.1).gradient)
                }
                .frame(height: 40)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? color.opacity(0.3 * glowIntensity) : .black.opacity(0.1),
                    radius: isHovered ? 12 : 4,
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
    }
}

// MARK: - Combined Performance Chart

@available(macOS 13.0, *)
public struct CombinedPerformanceChart: View {
    let cpuData: [ChartDataPoint]
    let memoryData: [ChartDataPoint]
    let gpuData: [ChartDataPoint]
    let networkData: [NetworkChartDataPoint]
    let timeRange: TimeRange
    let animationProgress: Double
    
    @State private var selectedMetric: String? = nil
    @State private var hoveredPoint: Date? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Legend
            HStack(spacing: 24) {
                ChartLegendItem(color: .blue, label: "CPU", isSelected: selectedMetric == "CPU") {
                    selectedMetric = selectedMetric == "CPU" ? nil : "CPU"
                }
                
                ChartLegendItem(color: .purple, label: "Memory", isSelected: selectedMetric == "Memory") {
                    selectedMetric = selectedMetric == "Memory" ? nil : "Memory"
                }
                
                ChartLegendItem(color: .green, label: "GPU", isSelected: selectedMetric == "GPU") {
                    selectedMetric = selectedMetric == "GPU" ? nil : "GPU"
                }
                
                ChartLegendItem(color: .orange, label: "Network", isSelected: selectedMetric == "Network") {
                    selectedMetric = selectedMetric == "Network" ? nil : "Network"
                }
                
                Spacer()
            }
            
            // Main Chart
            Chart {
                // CPU Data
                if selectedMetric == nil || selectedMetric == "CPU" {
                    ForEach(cpuData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", point.value * animationProgress)
                        )
                        .foregroundStyle(.blue)
                        .opacity(selectedMetric == nil || selectedMetric == "CPU" ? 1.0 : 0.3)
                        
                        if hoveredPoint == point.timestamp {
                            RuleMark(x: .value("Time", point.timestamp))
                                .foregroundStyle(.gray.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            
                            PointMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Usage", point.value)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(100)
                        }
                    }
                }
                
                // Memory Data
                if selectedMetric == nil || selectedMetric == "Memory" {
                    ForEach(memoryData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", point.value * animationProgress)
                        )
                        .foregroundStyle(.purple)
                        .opacity(selectedMetric == nil || selectedMetric == "Memory" ? 1.0 : 0.3)
                    }
                }
                
                // GPU Data
                if selectedMetric == nil || selectedMetric == "GPU" {
                    ForEach(gpuData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", point.value * animationProgress)
                        )
                        .foregroundStyle(.green)
                        .opacity(selectedMetric == nil || selectedMetric == "GPU" ? 1.0 : 0.3)
                    }
                }
                
                // Network Data (normalized to percentage)
                if selectedMetric == nil || selectedMetric == "Network" {
                    ForEach(networkData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", min(100, point.totalBandwidth / 10) * animationProgress)
                        )
                        .foregroundStyle(.orange)
                        .opacity(selectedMetric == nil || selectedMetric == "Network" ? 1.0 : 0.3)
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                        .foregroundStyle(Color.secondary)
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
                AxisMarks(values: .stride(by: .minute, count: 5)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisTick()
                        .foregroundStyle(Color.secondary)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .border(Color.secondary.opacity(0.3), width: 1)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    // Convert location to date
                    hoveredPoint = nil // Simplified for now
                case .ended:
                    hoveredPoint = nil
                }
            }
        }
    }
}

// MARK: - Chart Legend Item

struct ChartLegendItem: View {
    let color: Color
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detailed Category Chart

@available(macOS 13.0, *)
public struct DetailedCategoryChart: View {
    let category: MetricCategory
    @ObservedObject var systemMetrics: SystemMetrics
    @ObservedObject var networkManager: NetworkManager
    let timeRange: TimeRange
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(category.rawValue) Detailed Metrics")
                .font(.headline)
            
            // Category-specific detailed charts would be implemented here
            // This is a placeholder implementation
            Text("Detailed metrics for \(category.rawValue)")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Additional Supporting Views

public struct PredictiveInsightsView: View {
    let predictions: PredictiveMetrics
    @ObservedObject var aiService: AIService
    let onActionTaken: (AIAction) -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Predictions content
            Text("AI Predictions")
                .font(.headline)
            
            // Placeholder for predictions UI
            Text("Predictive insights will be displayed here")
                .foregroundColor(.secondary)
        }
    }
}

public struct AnomalyCardsView: View {
    let anomalies: [SystemAnomaly]
    let onDismiss: (SystemAnomaly) -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            ForEach(anomalies) { anomaly in
                AnomalyCard(anomaly: anomaly, onDismiss: {
                    onDismiss(anomaly)
                })
            }
        }
    }
}

struct AnomalyCard: View {
    let anomaly: SystemAnomaly
    let onDismiss: () -> Void
    
    private var severityColor: Color {
        switch anomaly.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(severityColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(anomaly.component)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(anomaly.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Confidence: \(Int(anomaly.confidence * 100))%")
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
        .background(severityColor.opacity(0.1))
        .cornerRadius(8)
    }
}

public struct AIRecommendationsView: View {
    @ObservedObject var systemMetrics: SystemMetrics
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var aiService: AIService
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations")
                .font(.headline)
            
            // Placeholder for recommendations
            Text("AI-powered recommendations will appear here")
                .foregroundColor(.secondary)
        }
    }
}

// Additional dashboard components continue...
// This provides comprehensive UI components for the dashboard with
// professional design and advanced functionality.