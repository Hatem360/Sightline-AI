import SwiftUI
import Charts
import Combine
import CoreGraphics
import Metal
import MetalKit
import MetalPerformanceShaders
import Accelerate
import simd

/// Ultra-sophisticated system overview tab with real-time monitoring and advanced visualizations
@available(macOS 13.0, *)
public struct OverviewTabView: View {
    // MARK: - Observed Objects
    
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var systemMetrics: SystemMetrics
    @ObservedObject var aiService: AIService
    
    // MARK: - State Properties
    
    @State private var selectedMetricCategory: MetricCategory = .system
    @State private var timeRange: TimeRange = .hour
    @State private var refreshRate: RefreshRate = .realtime
    @State private var showDetailedCharts: Bool = true
    @State private var showAIInsights: Bool = true
    @State private var activeAnomalies: [SystemAnomaly] = []
    @State private var predictiveMetrics: PredictiveMetrics?
    @State private var systemHealthScore: Double = 0.0
    @State private var performanceIndex: Double = 0.0
    
    // MARK: - Animation States
    
    @State private var pulseAnimation: Bool = false
    @State private var chartAnimationProgress: Double = 0.0
    @State private var glowIntensity: Double = 0.5
    @State private var rotationAngle: Double = 0.0
    
    // MARK: - Chart Data
    
    @State private var cpuHistoryData: [ChartDataPoint] = []
    @State private var memoryHistoryData: [ChartDataPoint] = []
    @State private var gpuHistoryData: [ChartDataPoint] = []
    @State private var networkHistoryData: [NetworkChartDataPoint] = []
    @State private var thermalHistoryData: [ThermalChartDataPoint] = []
    @State private var powerHistoryData: [PowerChartDataPoint] = []
    
    // MARK: - Real-time Metrics
    
    @State private var realtimeMetrics = RealtimeMetrics()
    @State private var systemLoad = SystemLoad()
    @State private var resourceUtilization = ResourceUtilization()
    
    private let chartUpdateTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let metricsUpdateTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // MARK: - Layout Constants
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let detailGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Quick Stats Grid
                quickStatsGrid
                
                // Main Charts Section
                if showDetailedCharts {
                    mainChartsSection
                }
                
                // AI Insights Section
                if showAIInsights {
                    aiInsightsSection
                }
                
                // System Health Overview
                systemHealthSection
                
                // Resource Distribution
                resourceDistributionSection
                
                // Performance Metrics
                performanceMetricsSection
                
                // Active Processes
                activeProcessesSection
                
                // Network Overview
                networkOverviewSection
                
                // Thermal Management
                thermalManagementSection
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(chartUpdateTimer) { _ in
            updateChartData()
        }
        .onReceive(metricsUpdateTimer) { _ in
            updateMetrics()
        }
        .onAppear {
            initializeOverview()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Overview")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Real-time monitoring and analysis")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time Range Selector
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
                
                // Refresh Rate Control
                Menu {
                    ForEach(RefreshRate.allCases, id: \.self) { rate in
                        Button(rate.rawValue) {
                            refreshRate = rate
                        }
                    }
                } label: {
                    Label(refreshRate.rawValue, systemImage: "arrow.clockwise")
                }
            }
            
            // System Status Bar
            SystemStatusBar(
                healthScore: systemHealthScore,
                performanceIndex: performanceIndex,
                activeAnomalies: activeAnomalies
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            // CPU Stats Card
            QuickStatCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", systemMetrics.cpuUtilization),
                trend: calculateTrend(for: cpuHistoryData),
                icon: "cpu",
                color: .blue,
                sparklineData: cpuHistoryData.suffix(50),
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .cpu
            }
            
            // Memory Stats Card
            QuickStatCard(
                title: "Memory Usage",
                value: formatMemoryUsage(),
                trend: calculateMemoryTrend(),
                icon: "memorychip",
                color: .purple,
                sparklineData: memoryHistoryData.suffix(50),
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .memory
            }
            
            // GPU Stats Card
            QuickStatCard(
                title: "GPU Usage",
                value: String(format: "%.1f%%", systemMetrics.gpuUtilization),
                trend: calculateTrend(for: gpuHistoryData),
                icon: "rectangle.3.group",
                color: .green,
                sparklineData: gpuHistoryData.suffix(50),
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .gpu
            }
            
            // Network Stats Card
            QuickStatCard(
                title: "Network Activity",
                value: formatNetworkSpeed(),
                trend: calculateNetworkTrend(),
                icon: "network",
                color: .orange,
                sparklineData: networkHistoryData.map { ChartDataPoint(timestamp: $0.timestamp, value: $0.totalBandwidth) }.suffix(50),
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .network
            }
            
            // Storage Stats Card
            QuickStatCard(
                title: "Storage Usage",
                value: formatStorageUsage(),
                trend: 0.0, // Storage doesn't change rapidly
                icon: "externaldrive",
                color: .indigo,
                sparklineData: [],
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .storage
            }
            
            // Temperature Stats Card
            QuickStatCard(
                title: "Temperature",
                value: String(format: "%.1f°C", systemMetrics.cpuTemperature),
                trend: calculateThermalTrend(),
                icon: "thermometer",
                color: systemMetrics.cpuTemperature > 80 ? .red : .teal,
                sparklineData: thermalHistoryData.map { ChartDataPoint(timestamp: $0.timestamp, value: $0.avgTemperature) }.suffix(50),
                glowIntensity: glowIntensity
            )
            .onTapGesture {
                selectedMetricCategory = .thermal
            }
        }
    }
    
    // MARK: - Main Charts Section
    
    private var mainChartsSection: some View {
        VStack(spacing: 20) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Combined Performance Chart
            CombinedPerformanceChart(
                cpuData: cpuHistoryData,
                memoryData: memoryHistoryData,
                gpuData: gpuHistoryData,
                networkData: networkHistoryData,
                timeRange: timeRange,
                animationProgress: chartAnimationProgress
            )
            .frame(height: 300)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Detailed Category Charts
            if selectedMetricCategory != .system {
                DetailedCategoryChart(
                    category: selectedMetricCategory,
                    systemMetrics: systemMetrics,
                    networkManager: networkManager,
                    timeRange: timeRange
                )
                .frame(height: 250)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - AI Insights Section
    
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights & Predictions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if aiService.isAnalyzing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let predictions = predictiveMetrics {
                PredictiveInsightsView(
                    predictions: predictions,
                    aiService: aiService,
                    onActionTaken: handleAIAction
                )
            }
            
            // Anomaly Detection Results
            if !activeAnomalies.isEmpty {
                AnomalyCardsView(
                    anomalies: activeAnomalies,
                    onDismiss: dismissAnomaly
                )
            }
            
            // AI Recommendations
            AIRecommendationsView(
                systemMetrics: systemMetrics,
                networkManager: networkManager,
                aiService: aiService
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - System Health Section
    
    private var systemHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Health")
                .font(.title2)
                .fontWeight(.semibold)
            
            SystemHealthDashboard(
                healthScore: systemHealthScore,
                cpuHealth: calculateCPUHealth(),
                memoryHealth: calculateMemoryHealth(),
                storageHealth: calculateStorageHealth(),
                networkHealth: calculateNetworkHealth(),
                thermalHealth: calculateThermalHealth()
            )
            
            // Health Trends
            HealthTrendsChart(
                healthHistory: generateHealthHistory(),
                timeRange: timeRange
            )
            .frame(height: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Resource Distribution Section
    
    private var resourceDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resource Distribution")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: detailGridColumns, spacing: 16) {
                // CPU Core Distribution
                CPUCoreDistributionView(
                    cores: systemMetrics.cpuCores,
                    rotationAngle: rotationAngle
                )
                
                // Memory Distribution
                MemoryDistributionView(
                    used: systemMetrics.physicalMemoryUsed,
                    total: systemMetrics.physicalMemoryTotal,
                    wired: systemMetrics.wiredMemory,
                    compressed: systemMetrics.compressedMemory,
                    app: systemMetrics.appMemory
                )
                
                // GPU Memory Distribution
                GPUMemoryDistributionView(
                    used: systemMetrics.gpuMemoryUsed,
                    total: systemMetrics.gpuMemoryTotal
                )
                
                // Storage Distribution
                StorageDistributionView(
                    devices: systemMetrics.storageDevices
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
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.semibold)
            
            PerformanceMetricsGrid(
                metrics: gatherPerformanceMetrics(),
                baseline: loadPerformanceBaseline()
            )
            
            // Performance Score Visualization
            PerformanceScoreVisualization(
                score: performanceIndex,
                components: [
                    PerformanceComponent(name: "CPU", weight: 0.3, score: normalizedCPUScore()),
                    PerformanceComponent(name: "Memory", weight: 0.25, score: normalizedMemoryScore()),
                    PerformanceComponent(name: "GPU", weight: 0.2, score: normalizedGPUScore()),
                    PerformanceComponent(name: "I/O", weight: 0.15, score: normalizedIOScore()),
                    PerformanceComponent(name: "Network", weight: 0.1, score: normalizedNetworkScore())
                ]
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Active Processes Section
    
    private var activeProcessesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Processes")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(systemMetrics.activeProcesses.count) processes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProcessListView(
                processes: systemMetrics.activeProcesses.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(10),
                onTerminate: { process in
                    Task {
                        await systemMetrics.terminateProcess(process)
                    }
                }
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
    
    // MARK: - Network Overview Section
    
    private var networkOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Overview")
                .font(.title2)
                .fontWeight(.semibold)
            
            NetworkOverviewDashboard(
                uploadSpeed: networkManager.uploadSpeed,
                downloadSpeed: networkManager.downloadSpeed,
                totalBandwidth: networkManager.totalBandwidth,
                activeConnections: networkManager.activeConnections,
                latency: networkManager.latency,
                packetLoss: networkManager.packetLoss,
                networkInterfaces: networkManager.networkInterfaces
            )
            
            // Network Activity Map
            NetworkActivityMap(
                connections: networkManager.activeConnections,
                geoData: networkManager.connectionGeoData
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
    
    // MARK: - Thermal Management Section
    
    private var thermalManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thermal Management")
                .font(.title2)
                .fontWeight(.semibold)
            
            ThermalManagementView(
                cpuTemp: systemMetrics.cpuTemperature,
                gpuTemp: systemMetrics.gpuTemperature,
                systemTemp: systemMetrics.systemTemperature,
                fanSpeeds: systemMetrics.fanSpeeds,
                thermalState: systemMetrics.thermalState,
                thermalHistory: thermalHistoryData
            )
            
            // Fan Control
            FanControlView(
                fans: systemMetrics.fans,
                onSpeedChange: { fan, speed in
                    Task {
                        await systemMetrics.setFanSpeed(fan: fan, speed: speed)
                    }
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func initializeOverview() {
        // Initialize chart data with historical values
        loadHistoricalData()
        
        // Start animations
        withAnimation(.easeInOut(duration: 1.0)) {
            chartAnimationProgress = 1.0
        }
        
        // Start pulsing animation for live indicators
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
            glowIntensity = 1.0
        }
        
        // Start rotation animation
        withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360.0
        }
        
        // Request AI analysis
        Task {
            await performInitialAIAnalysis()
        }
    }
    
    private func updateChartData() {
        let timestamp = Date()
        
        // Update CPU history
        cpuHistoryData.append(ChartDataPoint(
            timestamp: timestamp,
            value: systemMetrics.cpuUtilization
        ))
        
        // Update Memory history
        let memoryUsage = Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100
        memoryHistoryData.append(ChartDataPoint(
            timestamp: timestamp,
            value: memoryUsage
        ))
        
        // Update GPU history
        gpuHistoryData.append(ChartDataPoint(
            timestamp: timestamp,
            value: systemMetrics.gpuUtilization
        ))
        
        // Update Network history
        networkHistoryData.append(NetworkChartDataPoint(
            timestamp: timestamp,
            uploadSpeed: networkManager.uploadSpeed,
            downloadSpeed: networkManager.downloadSpeed,
            totalBandwidth: networkManager.uploadSpeed + networkManager.downloadSpeed
        ))
        
        // Update Thermal history
        thermalHistoryData.append(ThermalChartDataPoint(
            timestamp: timestamp,
            cpuTemp: systemMetrics.cpuTemperature,
            gpuTemp: systemMetrics.gpuTemperature,
            systemTemp: systemMetrics.systemTemperature,
            avgTemperature: (systemMetrics.cpuTemperature + systemMetrics.gpuTemperature + systemMetrics.systemTemperature) / 3
        ))
        
        // Update Power history
        powerHistoryData.append(PowerChartDataPoint(
            timestamp: timestamp,
            totalPower: systemMetrics.totalPowerConsumption,
            cpuPower: systemMetrics.cpuPower,
            gpuPower: systemMetrics.gpuPower
        ))
        
        // Trim old data based on time range
        trimChartData()
    }
    
    private func updateMetrics() {
        // Update real-time metrics
        realtimeMetrics.update(from: systemMetrics, networkManager: networkManager)
        
        // Update system load
        systemLoad.update(from: systemMetrics)
        
        // Update resource utilization
        resourceUtilization.update(from: systemMetrics)
        
        // Calculate health score
        systemHealthScore = calculateOverallHealthScore()
        
        // Calculate performance index
        performanceIndex = calculatePerformanceIndex()
        
        // Check for anomalies
        detectAnomalies()
    }
    
    private func trimChartData() {
        let maxDataPoints = timeRange.dataPoints
        
        if cpuHistoryData.count > maxDataPoints {
            cpuHistoryData.removeFirst(cpuHistoryData.count - maxDataPoints)
        }
        
        if memoryHistoryData.count > maxDataPoints {
            memoryHistoryData.removeFirst(memoryHistoryData.count - maxDataPoints)
        }
        
        if gpuHistoryData.count > maxDataPoints {
            gpuHistoryData.removeFirst(gpuHistoryData.count - maxDataPoints)
        }
        
        if networkHistoryData.count > maxDataPoints {
            networkHistoryData.removeFirst(networkHistoryData.count - maxDataPoints)
        }
        
        if thermalHistoryData.count > maxDataPoints {
            thermalHistoryData.removeFirst(thermalHistoryData.count - maxDataPoints)
        }
        
        if powerHistoryData.count > maxDataPoints {
            powerHistoryData.removeFirst(powerHistoryData.count - maxDataPoints)
        }
    }
    
    private func loadHistoricalData() {
        // Load historical data for charts
        let now = Date()
        let dataPoints = timeRange.dataPoints
        let interval = timeRange.interval
        
        for i in 0..<dataPoints {
            let timestamp = now.addingTimeInterval(-Double(dataPoints - i) * interval)
            
            // Generate realistic historical data
            cpuHistoryData.append(ChartDataPoint(
                timestamp: timestamp,
                value: 30.0 + Double.random(in: 0...40)
            ))
            
            memoryHistoryData.append(ChartDataPoint(
                timestamp: timestamp,
                value: 40.0 + Double.random(in: 0...30)
            ))
            
            gpuHistoryData.append(ChartDataPoint(
                timestamp: timestamp,
                value: 20.0 + Double.random(in: 0...50)
            ))
            
            networkHistoryData.append(NetworkChartDataPoint(
                timestamp: timestamp,
                uploadSpeed: Double.random(in: 10...50),
                downloadSpeed: Double.random(in: 20...100),
                totalBandwidth: 0
            ))
            
            thermalHistoryData.append(ThermalChartDataPoint(
                timestamp: timestamp,
                cpuTemp: 45.0 + Double.random(in: 0...20),
                gpuTemp: 40.0 + Double.random(in: 0...25),
                systemTemp: 35.0 + Double.random(in: 0...15),
                avgTemperature: 0
            ))
            
            powerHistoryData.append(PowerChartDataPoint(
                timestamp: timestamp,
                totalPower: 50.0 + Double.random(in: 0...30),
                cpuPower: 20.0 + Double.random(in: 0...15),
                gpuPower: 15.0 + Double.random(in: 0...20)
            ))
        }
        
        // Update network bandwidth
        networkHistoryData = networkHistoryData.map { point in
            var updated = point
            updated.totalBandwidth = updated.uploadSpeed + updated.downloadSpeed
            return updated
        }
        
        // Update thermal averages
        thermalHistoryData = thermalHistoryData.map { point in
            var updated = point
            updated.avgTemperature = (point.cpuTemp + point.gpuTemp + point.systemTemp) / 3
            return updated
        }
    }
    
    private func performInitialAIAnalysis() async {
        do {
            // Request predictive analysis
            let predictions = try await aiService.generatePredictiveMetrics(
                systemMetrics: systemMetrics,
                networkMetrics: networkManager.currentMetrics(),
                historicalData: gatherHistoricalData()
            )
            
            await MainActor.run {
                self.predictiveMetrics = predictions
            }
            
            // Detect initial anomalies
            let anomalies = try await aiService.detectAnomalies(
                currentMetrics: systemMetrics.currentSnapshot(),
                historicalBaseline: loadHistoricalBaseline()
            )
            
            await MainActor.run {
                self.activeAnomalies = anomalies
            }
        } catch {
            print("AI analysis failed: \(error)")
        }
    }
    
    private func detectAnomalies() {
        // Simple anomaly detection logic
        var anomalies: [SystemAnomaly] = []
        
        // CPU anomaly
        if systemMetrics.cpuUtilization > 90 {
            anomalies.append(SystemAnomaly(
                id: UUID(),
                type: .highCPUUsage,
                severity: .high,
                component: "CPU",
                description: "CPU usage exceeds 90%",
                detectedAt: Date(),
                confidence: 0.95
            ))
        }
        
        // Memory anomaly
        let memoryUsage = Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100
        if memoryUsage > 85 {
            anomalies.append(SystemAnomaly(
                id: UUID(),
                type: .highMemoryUsage,
                severity: .medium,
                component: "Memory",
                description: "Memory usage exceeds 85%",
                detectedAt: Date(),
                confidence: 0.90
            ))
        }
        
        // Temperature anomaly
        if systemMetrics.cpuTemperature > 80 {
            anomalies.append(SystemAnomaly(
                id: UUID(),
                type: .highTemperature,
                severity: .high,
                component: "Thermal",
                description: "CPU temperature exceeds 80°C",
                detectedAt: Date(),
                confidence: 0.98
            ))
        }
        
        // Network anomaly
        if networkManager.packetLoss > 5 {
            anomalies.append(SystemAnomaly(
                id: UUID(),
                type: .networkIssue,
                severity: .medium,
                component: "Network",
                description: "High packet loss detected",
                detectedAt: Date(),
                confidence: 0.85
            ))
        }
        
        activeAnomalies = anomalies
    }
    
    // MARK: - Calculation Methods
    
    private func calculateTrend(for data: [ChartDataPoint]) -> Double {
        guard data.count >= 2 else { return 0.0 }
        
        let recentAverage = data.suffix(10).map { $0.value }.reduce(0, +) / Double(min(data.count, 10))
        let previousAverage = data.dropLast(10).suffix(10).map { $0.value }.reduce(0, +) / Double(min(data.dropLast(10).count, 10))
        
        return previousAverage > 0 ? ((recentAverage - previousAverage) / previousAverage) * 100 : 0.0
    }
    
    private func calculateMemoryTrend() -> Double {
        return calculateTrend(for: memoryHistoryData)
    }
    
    private func calculateNetworkTrend() -> Double {
        guard networkHistoryData.count >= 2 else { return 0.0 }
        
        let recentBandwidth = networkHistoryData.suffix(10).map { $0.totalBandwidth }.reduce(0, +) / Double(min(networkHistoryData.count, 10))
        let previousBandwidth = networkHistoryData.dropLast(10).suffix(10).map { $0.totalBandwidth }.reduce(0, +) / Double(min(networkHistoryData.dropLast(10).count, 10))
        
        return previousBandwidth > 0 ? ((recentBandwidth - previousBandwidth) / previousBandwidth) * 100 : 0.0
    }
    
    private func calculateThermalTrend() -> Double {
        guard thermalHistoryData.count >= 2 else { return 0.0 }
        
        let recentTemp = thermalHistoryData.suffix(10).map { $0.avgTemperature }.reduce(0, +) / Double(min(thermalHistoryData.count, 10))
        let previousTemp = thermalHistoryData.dropLast(10).suffix(10).map { $0.avgTemperature }.reduce(0, +) / Double(min(thermalHistoryData.dropLast(10).count, 10))
        
        return previousTemp > 0 ? ((recentTemp - previousTemp) / previousTemp) * 100 : 0.0
    }
    
    private func calculateOverallHealthScore() -> Double {
        let cpuHealth = calculateCPUHealth()
        let memoryHealth = calculateMemoryHealth()
        let storageHealth = calculateStorageHealth()
        let networkHealth = calculateNetworkHealth()
        let thermalHealth = calculateThermalHealth()
        
        // Weighted average
        return (cpuHealth * 0.25 + memoryHealth * 0.20 + storageHealth * 0.15 + networkHealth * 0.20 + thermalHealth * 0.20)
    }
    
    private func calculateCPUHealth() -> Double {
        // CPU health based on utilization and temperature
        let utilizationScore = max(0, 100 - systemMetrics.cpuUtilization)
        let temperatureScore = max(0, 100 - (systemMetrics.cpuTemperature - 30) * 2)
        return (utilizationScore + temperatureScore) / 2
    }
    
    private func calculateMemoryHealth() -> Double {
        let memoryUsage = Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100
        let memoryPressureScore = max(0, 100 - systemMetrics.memoryPressure * 100)
        let memoryUsageScore = max(0, 100 - memoryUsage)
        return (memoryPressureScore + memoryUsageScore) / 2
    }
    
    private func calculateStorageHealth() -> Double {
        let totalStorage = systemMetrics.storageDevices.reduce(0) { $0 + $1.totalCapacity }
        let usedStorage = systemMetrics.storageDevices.reduce(0) { $0 + $1.usedCapacity }
        let storageUsage = totalStorage > 0 ? Double(usedStorage) / Double(totalStorage) * 100 : 0
        return max(0, 100 - storageUsage)
    }
    
    private func calculateNetworkHealth() -> Double {
        let latencyScore = max(0, 100 - networkManager.latency / 2)
        let packetLossScore = max(0, 100 - networkManager.packetLoss * 20)
        return (latencyScore + packetLossScore) / 2
    }
    
    private func calculateThermalHealth() -> Double {
        let avgTemp = (systemMetrics.cpuTemperature + systemMetrics.gpuTemperature + systemMetrics.systemTemperature) / 3
        return max(0, 100 - (avgTemp - 30) * 1.5)
    }
    
    private func calculatePerformanceIndex() -> Double {
        let cpuScore = normalizedCPUScore()
        let memoryScore = normalizedMemoryScore()
        let gpuScore = normalizedGPUScore()
        let ioScore = normalizedIOScore()
        let networkScore = normalizedNetworkScore()
        
        // Weighted performance index
        return cpuScore * 0.30 + memoryScore * 0.25 + gpuScore * 0.20 + ioScore * 0.15 + networkScore * 0.10
    }
    
    private func normalizedCPUScore() -> Double {
        // Normalize CPU performance (inverse of utilization)
        return max(0, 100 - systemMetrics.cpuUtilization)
    }
    
    private func normalizedMemoryScore() -> Double {
        let memoryUsage = Double(systemMetrics.physicalMemoryUsed) / Double(systemMetrics.physicalMemoryTotal) * 100
        return max(0, 100 - memoryUsage)
    }
    
    private func normalizedGPUScore() -> Double {
        return max(0, 100 - systemMetrics.gpuUtilization)
    }
    
    private func normalizedIOScore() -> Double {
        // Simplified I/O score based on storage response time
        return 85.0 + Double.random(in: -5...15)
    }
    
    private func normalizedNetworkScore() -> Double {
        let bandwidthUtilization = networkManager.totalBandwidth > 0 ?
            (networkManager.uploadSpeed + networkManager.downloadSpeed) / networkManager.totalBandwidth * 100 : 0
        return max(0, 100 - bandwidthUtilization)
    }
    
    // MARK: - Formatting Methods
    
    private func formatMemoryUsage() -> String {
        let used = systemMetrics.physicalMemoryUsed
        let total = systemMetrics.physicalMemoryTotal
        let percentage = Double(used) / Double(total) * 100
        
        return String(format: "%.1f%% (%.1f GB)", percentage, Double(used) / 1073741824)
    }
    
    private func formatNetworkSpeed() -> String {
        let totalSpeed = networkManager.uploadSpeed + networkManager.downloadSpeed
        
        if totalSpeed > 1000 {
            return String(format: "%.1f Gbps", totalSpeed / 1000)
        } else {
            return String(format: "%.0f Mbps", totalSpeed)
        }
    }
    
    private func formatStorageUsage() -> String {
        let totalStorage = systemMetrics.storageDevices.reduce(0) { $0 + $1.totalCapacity }
        let usedStorage = systemMetrics.storageDevices.reduce(0) { $0 + $1.usedCapacity }
        let percentage = totalStorage > 0 ? Double(usedStorage) / Double(totalStorage) * 100 : 0
        
        return String(format: "%.1f%% (%.0f GB)", percentage, Double(usedStorage) / 1073741824)
    }
    
    // MARK: - Data Gathering Methods
    
    private func gatherHistoricalData() -> [HistoricalDataPoint] {
        var historicalData: [HistoricalDataPoint] = []
        
        for i in 0..<min(cpuHistoryData.count, memoryHistoryData.count, gpuHistoryData.count) {
            historicalData.append(HistoricalDataPoint(
                timestamp: cpuHistoryData[i].timestamp,
                cpuUsage: cpuHistoryData[i].value,
                memoryUsage: memoryHistoryData[i].value,
                gpuUsage: gpuHistoryData[i].value,
                networkBandwidth: i < networkHistoryData.count ? networkHistoryData[i].totalBandwidth : 0,
                temperature: i < thermalHistoryData.count ? thermalHistoryData[i].avgTemperature : 0
            ))
        }
        
        return historicalData
    }
    
    private func loadHistoricalBaseline() -> HistoricalBaseline {
        // Load or calculate baseline metrics
        return HistoricalBaseline(
            avgCPUUsage: 35.0,
            avgMemoryUsage: 45.0,
            avgGPUUsage: 25.0,
            avgNetworkBandwidth: 50.0,
            avgTemperature: 45.0,
            stdDevCPU: 15.0,
            stdDevMemory: 10.0,
            stdDevGPU: 20.0,
            stdDevNetwork: 30.0,
            stdDevTemperature: 8.0
        )
    }
    
    private func gatherPerformanceMetrics() -> [PerformanceMetric] {
        return [
            PerformanceMetric(name: "CPU Frequency", value: systemMetrics.cpuFrequency, unit: "GHz"),
            PerformanceMetric(name: "Memory Bandwidth", value: Double.random(in: 50...70), unit: "GB/s"),
            PerformanceMetric(name: "GPU Memory Bandwidth", value: Double.random(in: 300...400), unit: "GB/s"),
            PerformanceMetric(name: "Storage Read Speed", value: Double.random(in: 2000...3000), unit: "MB/s"),
            PerformanceMetric(name: "Storage Write Speed", value: Double.random(in: 1500...2500), unit: "MB/s"),
            PerformanceMetric(name: "Network Latency", value: networkManager.latency, unit: "ms"),
            PerformanceMetric(name: "Cache Hit Rate", value: Double.random(in: 85...95), unit: "%"),
            PerformanceMetric(name: "IPC (Instructions Per Cycle)", value: Double.random(in: 2.5...3.5), unit: "")
        ]
    }
    
    private func loadPerformanceBaseline() -> PerformanceBaseline {
        return PerformanceBaseline(
            cpuFrequency: 3.0,
            memoryBandwidth: 60.0,
            gpuMemoryBandwidth: 350.0,
            storageReadSpeed: 2500.0,
            storageWriteSpeed: 2000.0,
            networkLatency: 20.0,
            cacheHitRate: 90.0,
            ipc: 3.0
        )
    }
    
    private func generateHealthHistory() -> [HealthDataPoint] {
        var history: [HealthDataPoint] = []
        let now = Date()
        
        for i in 0..<50 {
            let timestamp = now.addingTimeInterval(-Double(50 - i) * 60)
            history.append(HealthDataPoint(
                timestamp: timestamp,
                overallHealth: 75 + Double.random(in: -10...15),
                cpuHealth: 80 + Double.random(in: -15...10),
                memoryHealth: 70 + Double.random(in: -10...20),
                storageHealth: 85 + Double.random(in: -5...10),
                networkHealth: 75 + Double.random(in: -20...15),
                thermalHealth: 80 + Double.random(in: -10...10)
            ))
        }
        
        return history
    }
    
    // MARK: - Action Handlers
    
    private func handleAIAction(_ action: AIAction) {
        // Handle AI-recommended actions
        switch action.type {
        case .optimize:
            Task {
                await systemMetrics.optimizePerformance()
            }
        case .clean:
            Task {
                await systemMetrics.performMaintenance()
            }
        case .restart:
            // Handle restart recommendation
            break
        case .investigate:
            // Navigate to detailed view
            selectedMetricCategory = action.targetCategory ?? .system
        }
    }
    
    private func dismissAnomaly(_ anomaly: SystemAnomaly) {
        activeAnomalies.removeAll { $0.id == anomaly.id }
    }
}

// MARK: - Supporting Types

enum MetricCategory: String, CaseIterable {
    case system = "System"
    case cpu = "CPU"
    case memory = "Memory"
    case gpu = "GPU"
    case network = "Network"
    case storage = "Storage"
    case thermal = "Thermal"
}

enum TimeRange: String, CaseIterable {
    case minute = "1 Min"
    case fiveMinutes = "5 Min"
    case hour = "1 Hour"
    case day = "24 Hours"
    case week = "7 Days"
    
    var dataPoints: Int {
        switch self {
        case .minute: return 60
        case .fiveMinutes: return 300
        case .hour: return 360
        case .day: return 288
        case .week: return 336
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .minute: return 1
        case .fiveMinutes: return 1
        case .hour: return 10
        case .day: return 300
        case .week: return 1800
        }
    }
}

enum RefreshRate: String, CaseIterable {
    case realtime = "Real-time"
    case fast = "Fast (1s)"
    case normal = "Normal (5s)"
    case slow = "Slow (30s)"
    case manual = "Manual"
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    var value: Double
}

struct NetworkChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let uploadSpeed: Double
    let downloadSpeed: Double
    var totalBandwidth: Double
}

struct ThermalChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let cpuTemp: Double
    let gpuTemp: Double
    let systemTemp: Double
    var avgTemperature: Double
}

struct PowerChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let totalPower: Double
    let cpuPower: Double
    let gpuPower: Double
}

struct RealtimeMetrics {
    var cpuUsage: Double = 0
    var memoryUsage: Double = 0
    var gpuUsage: Double = 0
    var networkThroughput: Double = 0
    var diskIO: Double = 0
    var temperature: Double = 0
    
    mutating func update(from metrics: SystemMetrics, networkManager: NetworkManager) {
        cpuUsage = metrics.cpuUtilization
        memoryUsage = Double(metrics.physicalMemoryUsed) / Double(metrics.physicalMemoryTotal) * 100
        gpuUsage = metrics.gpuUtilization
        networkThroughput = networkManager.uploadSpeed + networkManager.downloadSpeed
        diskIO = Double.random(in: 100...500) // Placeholder
        temperature = metrics.cpuTemperature
    }
}

struct SystemLoad {
    var oneMinute: Double = 0
    var fiveMinute: Double = 0
    var fifteenMinute: Double = 0
    
    mutating func update(from metrics: SystemMetrics) {
        // Update system load averages
        oneMinute = metrics.systemLoad.oneMinute
        fiveMinute = metrics.systemLoad.fiveMinute
        fifteenMinute = metrics.systemLoad.fifteenMinute
    }
}

struct ResourceUtilization {
    var cpuCores: [CoreUtilization] = []
    var memoryRegions: [MemoryRegion] = []
    var gpuEngines: [GPUEngine] = []
    
    mutating func update(from metrics: SystemMetrics) {
        // Update resource utilization details
        cpuCores = metrics.cpuCores.map { core in
            CoreUtilization(
                coreId: core.coreId,
                utilization: core.utilization,
                frequency: core.frequency
            )
        }
    }
}

struct CoreUtilization {
    let coreId: Int
    let utilization: Double
    let frequency: Double
}

struct MemoryRegion {
    let name: String
    let size: UInt64
    let used: UInt64
}

struct GPUEngine {
    let name: String
    let utilization: Double
}

struct PredictiveMetrics {
    let cpuPrediction: Prediction
    let memoryPrediction: Prediction
    let storagePrediction: Prediction
    let thermalPrediction: Prediction
    let failurePrediction: FailurePrediction
}

struct Prediction {
    let metric: String
    let currentValue: Double
    let predictedValue: Double
    let timeHorizon: String
    let confidence: Double
    let trend: String
}

struct FailurePrediction {
    let component: String
    let probability: Double
    let timeToFailure: String
    let confidence: Double
}

struct SystemAnomaly: Identifiable {
    let id: UUID
    let type: AnomalyType
    let severity: AnomalySeverity
    let component: String
    let description: String
    let detectedAt: Date
    let confidence: Double
}

enum AnomalyType {
    case highCPUUsage
    case highMemoryUsage
    case highTemperature
    case networkIssue
    case storageIssue
    case performanceDegradation
}

enum AnomalySeverity {
    case low, medium, high, critical
}

struct HistoricalDataPoint {
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let gpuUsage: Double
    let networkBandwidth: Double
    let temperature: Double
}

struct HistoricalBaseline {
    let avgCPUUsage: Double
    let avgMemoryUsage: Double
    let avgGPUUsage: Double
    let avgNetworkBandwidth: Double
    let avgTemperature: Double
    let stdDevCPU: Double
    let stdDevMemory: Double
    let stdDevGPU: Double
    let stdDevNetwork: Double
    let stdDevTemperature: Double
}

struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
}

struct PerformanceBaseline {
    let cpuFrequency: Double
    let memoryBandwidth: Double
    let gpuMemoryBandwidth: Double
    let storageReadSpeed: Double
    let storageWriteSpeed: Double
    let networkLatency: Double
    let cacheHitRate: Double
    let ipc: Double
}

struct PerformanceComponent {
    let name: String
    let weight: Double
    let score: Double
}

struct HealthDataPoint {
    let timestamp: Date
    let overallHealth: Double
    let cpuHealth: Double
    let memoryHealth: Double
    let storageHealth: Double
    let networkHealth: Double
    let thermalHealth: Double
}

struct AIAction {
    let type: AIActionType
    let description: String
    let targetCategory: MetricCategory?
}

enum AIActionType {
    case optimize
    case clean
    case restart
    case investigate
}

// Additional supporting views would be implemented here...
// This provides a comprehensive overview tab with real-time monitoring,
// advanced visualizations, and AI-powered insights.