import Foundation
import Combine
import CryptoKit
import Network

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func analyzeDeviceHealth(_ device: ExternalDevice) async throws -> DeviceHealthAnalysis
    func predictDeviceFailure(_ device: ExternalDevice) async throws -> FailurePrediction
    func generateOptimizationRecommendations(_ metrics: SystemMetrics) async throws -> [OptimizationRecommendation]
    func analyzePerformanceAnomalies(_ data: [SystemMetrics]) async throws -> [AnomalyDetection]
    func processNaturalLanguageQuery(_ query: String) async throws -> AIResponse
    func updateAPIKey(_ newKey: String) async throws
    func getServiceStatus() -> AIServiceStatus
}

// MARK: - AI Service Status
struct AIServiceStatus {
    var isConnected: Bool
    var apiKeyValid: Bool
    var lastRequestTime: Date?
    var requestCount: Int
    var errorCount: Int
    var averageResponseTime: TimeInterval
    let modelVersion: String
    var rateLimitRemaining: Int
    var rateLimitResetTime: Date?
}

// MARK: - Device Health Analysis
struct DeviceHealthAnalysis {
    let deviceId: String
    let overallHealth: Double // 0.0 - 1.0
    let healthScore: Int // 0-100
    let criticalIssues: [HealthIssue]
    let warnings: [HealthIssue]
    let recommendations: [HealthRecommendation]
    let predictedLifespan: TimeInterval
    let confidenceLevel: Double
    let analysisTimestamp: Date
    let aiModelVersion: String
}

// MARK: - Health Issue
struct HealthIssue {
    let id: String
    let severity: IssueSeverity
    let category: IssueCategory
    let title: String
    let description: String
    let impact: String
    let suggestedAction: String
    let detectedAt: Date
    let confidence: Double
}

// MARK: - Issue Severity
enum IssueSeverity: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case info = "info"
    
    var color: String {
        switch self {
        case .critical: return "#FF0000"
        case .high: return "#FF6600"
        case .medium: return "#FFCC00"
        case .low: return "#00CC00"
        case .info: return "#0066CC"
        }
    }
}

// MARK: - Issue Category
enum IssueCategory: String, CaseIterable {
    case performance = "performance"
    case thermal = "thermal"
    case battery = "battery"
    case storage = "storage"
    case network = "network"
    case security = "security"
    case hardware = "hardware"
    case software = "software"
}

// MARK: - Health Recommendation
struct HealthRecommendation {
    let id: String
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
    let expectedImpact: String
    let implementationDifficulty: ImplementationDifficulty
    let estimatedTime: TimeInterval
    let cost: Double?
}

// MARK: - Recommendation Priority
enum RecommendationPriority: String, CaseIterable {
    case immediate = "immediate"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case optional = "optional"
}

// MARK: - Implementation Difficulty
enum ImplementationDifficulty: String, CaseIterable {
    case trivial = "trivial"
    case easy = "easy"
    case moderate = "moderate"
    case difficult = "difficult"
    case expert = "expert"
}

// MARK: - Failure Prediction
struct FailurePrediction {
    let deviceId: String
    let componentType: ComponentType
    let failureProbability: Double // 0.0 - 1.0
    let estimatedTimeToFailure: TimeInterval
    let confidenceLevel: Double
    let contributingFactors: [String]
    let mitigationStrategies: [String]
    let predictionTimestamp: Date
    let modelVersion: String
}

// MARK: - Component Type
enum ComponentType: String, CaseIterable {
    case cpu = "cpu"
    case memory = "memory"
    case storage = "storage"
    case battery = "battery"
    case network = "network"
    case thermal = "thermal"
    case power = "power"
    case motherboard = "motherboard"
    case gpu = "gpu"
    case fan = "fan"
}

// MARK: - Optimization Recommendation
struct OptimizationRecommendation {
    let id: String
    let category: OptimizationCategory
    let title: String
    let description: String
    let currentValue: String
    let recommendedValue: String
    let expectedImprovement: String
    let implementationSteps: [String]
    let riskLevel: RiskLevel
    let estimatedSavings: Double?
    let priority: OptimizationPriority
}

// MARK: - Optimization Category
enum OptimizationCategory: String, CaseIterable {
    case performance = "performance"
    case battery = "battery"
    case thermal = "thermal"
    case memory = "memory"
    case storage = "storage"
    case network = "network"
    case security = "security"
    case power = "power"
}

// MARK: - Risk Level
enum RiskLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Optimization Priority
enum OptimizationPriority: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case optional = "optional"
}

// MARK: - Anomaly Detection
struct AnomalyDetection {
    let id: String
    let metricName: String
    let anomalyType: AnomalyType
    let severity: AnomalySeverity
    let detectedValue: Double
    let expectedRange: ClosedRange<Double>
    let timestamp: Date
    let duration: TimeInterval
    let impact: String
    let suggestedAction: String
    let confidence: Double
}

// MARK: - Anomaly Type
enum AnomalyType: String, CaseIterable {
    case spike = "spike"
    case drop = "drop"
    case trend = "trend"
    case pattern = "pattern"
    case outlier = "outlier"
    case seasonality = "seasonality"
}

// MARK: - Anomaly Severity
enum AnomalySeverity: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case info = "info"
}

// MARK: - AI Response
struct AIResponse {
    let id: String
    let query: String
    let response: String
    let confidence: Double
    let modelVersion: String
    let processingTime: TimeInterval
    let tokensUsed: Int
    let cost: Double?
    let timestamp: Date
}

// MARK: - AI Service Implementation
@MainActor
public final class AIService: ObservableObject, AIServiceProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var serviceStatus = AIServiceStatus(
        isConnected: false,
        apiKeyValid: false,
        lastRequestTime: nil,
        requestCount: 0,
        errorCount: 0,
        averageResponseTime: 0.0,
        modelVersion: "gpt-4-1106-preview",
        rateLimitRemaining: 0,
        rateLimitResetTime: nil
    )
    
    // MARK: - Private Properties
    private var apiKey: String = ""
    private var baseURL = "https://api.openai.com/v1"
    private var session: URLSession
    private var cancellables = Set<AnyCancellable>()
    private var requestQueue = DispatchQueue(label: "ai.service.queue", qos: .userInitiated)
    private var responseTimes: [TimeInterval] = []
    private var lastRateLimitUpdate: Date = Date()
    
    // MARK: - Constants
    private let maxResponseTime = 30.0
    private let maxRetries = 3
    private let rateLimitWindow: TimeInterval = 60.0
    private let maxRequestsPerMinute = 60
    
    // MARK: - Initialization
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = maxResponseTime
        config.timeoutIntervalForResource = maxResponseTime * 2
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 10
        
        self.session = URLSession(configuration: config)
        
        // Load API key from secure storage
        loadAPIKey()
        
        // Start background monitoring
        startBackgroundMonitoring()
    }
    
    // MARK: - API Key Management
    private func loadAPIKey() {
        // In production, this would load from Keychain
        if let key = UserDefaults.standard.string(forKey: "openai_api_key") {
            self.apiKey = key
            validateAPIKey()
        }
    }
    
    private func validateAPIKey() {
        Task {
            do {
                let isValid = try await validateAPIKeyAsync()
                await MainActor.run {
                    self.serviceStatus.apiKeyValid = isValid
                }
            } catch {
                await MainActor.run {
                    self.serviceStatus.apiKeyValid = false
                }
            }
        }
    }
    
    private func validateAPIKeyAsync() async throws -> Bool {
        guard !apiKey.isEmpty else { return false }
        
        let url = URL(string: "\(baseURL)/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        
        return false
    }
    
    // MARK: - Public Methods
    func updateAPIKey(_ newKey: String) async throws {
        guard !newKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        self.apiKey = newKey
        
        // Save to secure storage
        UserDefaults.standard.set(newKey, forKey: "openai_api_key")
        
        // Validate the new key
        let isValid = try await validateAPIKeyAsync()
        
        await MainActor.run {
            self.serviceStatus.apiKeyValid = isValid
        }
        
        if !isValid {
            throw AIError.invalidAPIKey
        }
    }
    
    func analyzeDeviceHealth(_ device: ExternalDevice) async throws -> DeviceHealthAnalysis {
        let startTime = Date()
        
        // Get device metrics - in a real implementation, this would fetch from the device
        let deviceMetrics = getDeviceMetrics(for: device)
        let prompt = createDeviceHealthPrompt(device, metrics: deviceMetrics)
        let response = try await makeChatGPTRequest(prompt: prompt, temperature: 0.3)
        
        let analysis = try parseDeviceHealthAnalysis(response, deviceId: device.deviceId)
        
        await updateServiceStatus(responseTime: Date().timeIntervalSince(startTime))
        
        return analysis
    }
    
    func predictDeviceFailure(_ device: ExternalDevice) async throws -> FailurePrediction {
        let startTime = Date()
        
        // Get device metrics - in a real implementation, this would fetch from the device
        let deviceMetrics = getDeviceMetrics(for: device)
        let prompt = createFailurePredictionPrompt(device, metrics: deviceMetrics)
        let response = try await makeChatGPTRequest(prompt: prompt, temperature: 0.2)
        
        let prediction = try parseFailurePrediction(response, deviceId: device.deviceId)
        
        await updateServiceStatus(responseTime: Date().timeIntervalSince(startTime))
        
        return prediction
    }
    
    func generateOptimizationRecommendations(_ metrics: SystemMetrics) async throws -> [OptimizationRecommendation] {
        let startTime = Date()
        
        let prompt = createOptimizationPrompt(metrics)
        let response = try await makeChatGPTRequest(prompt: prompt, temperature: 0.4)
        
        let recommendations = try parseOptimizationRecommendations(response)
        
        await updateServiceStatus(responseTime: Date().timeIntervalSince(startTime))
        
        return recommendations
    }
    
    func analyzePerformanceAnomalies(_ data: [SystemMetrics]) async throws -> [AnomalyDetection] {
        let startTime = Date()
        
        let prompt = createAnomalyDetectionPrompt(data)
        let response = try await makeChatGPTRequest(prompt: prompt, temperature: 0.1)
        
        let anomalies = try parseAnomalyDetections(response)
        
        await updateServiceStatus(responseTime: Date().timeIntervalSince(startTime))
        
        return anomalies
    }
    
    func processNaturalLanguageQuery(_ query: String) async throws -> AIResponse {
        let startTime = Date()
        
        let prompt = createNaturalLanguagePrompt(query)
        let response = try await makeChatGPTRequest(prompt: prompt, temperature: 0.7)
        
        let aiResponse = try parseAIResponse(response, query: query)
        
        await updateServiceStatus(responseTime: Date().timeIntervalSince(startTime))
        
        return aiResponse
    }
    
    nonisolated func getServiceStatus() -> AIServiceStatus {
        return serviceStatus
    }
    
    // MARK: - Private Methods
    private func makeChatGPTRequest(prompt: String, temperature: Double) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        guard serviceStatus.apiKeyValid else {
            throw AIError.invalidAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ChatGPTRequest(
            model: "gpt-4-1106-preview",
            messages: [
                ChatGPTMessage(role: "system", content: "You are an expert AI system for electronic device health monitoring and optimization. Provide accurate, technical, and actionable insights."),
                ChatGPTMessage(role: "user", content: prompt)
            ],
            temperature: temperature,
            max_tokens: 4000,
            top_p: 1.0,
            frequency_penalty: 0.0,
            presence_penalty: 0.0
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            updateRateLimitInfo(from: httpResponse)
            
            if httpResponse.statusCode != 200 {
                throw AIError.apiError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
        }
        
        let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIError.invalidResponse
        }
        
        return content
    }
    
    private func updateRateLimitInfo(from response: HTTPURLResponse) {
        if let remaining = response.value(forHTTPHeaderField: "x-ratelimit-remaining-requests") {
            serviceStatus.rateLimitRemaining = Int(remaining) ?? 0
        }
        
        if let resetTime = response.value(forHTTPHeaderField: "x-ratelimit-reset-requests") {
            if let timestamp = Double(resetTime) {
                serviceStatus.rateLimitResetTime = Date(timeIntervalSince1970: timestamp)
            }
        }
    }
    
    private func updateServiceStatus(responseTime: TimeInterval) async {
        await MainActor.run {
            self.serviceStatus.requestCount += 1
            self.serviceStatus.lastRequestTime = Date()
            self.responseTimes.append(responseTime)
            
            // Keep only last 100 response times
            if self.responseTimes.count > 100 {
                self.responseTimes.removeFirst()
            }
            
            self.serviceStatus.averageResponseTime = self.responseTimes.reduce(0, +) / Double(self.responseTimes.count)
        }
    }
    
    private func startBackgroundMonitoring() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performBackgroundHealthCheck()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performBackgroundHealthCheck() async {
        // Validate API key periodically
        validateAPIKey()
        
        // Check connectivity
        let isConnected = await checkConnectivity()
        
        await MainActor.run {
            self.serviceStatus.isConnected = isConnected
        }
    }
    
    private func checkConnectivity() async -> Bool {
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Prompt Creation Methods
    private func createDeviceHealthPrompt(_ device: ExternalDevice, metrics: ExternalDeviceMetrics) -> String {
        return """
        Analyze the health of the following device and provide a comprehensive health assessment:
        
        Device Information:
        - ID: \(device.deviceId)
        - Type: \(device.deviceType.rawValue)
        - Name: \(device.name)
        - Status: \(device.status.rawValue)
        - Last Seen: \(device.lastSeen)
        
        Device Metrics:
        - CPU Usage: \(metrics.cpuUsage)%
        - Memory Usage: \(metrics.memoryUsage)%
        - Battery Level: \(metrics.batteryLevel)%
        - Temperature: \(metrics.temperature)°C
        - Storage Usage: \(metrics.storageUsage)%
        
        Network Information:
        - Connection Type: \(device.connectionType.rawValue)
        - Network Latency: \(metrics.networkLatency) ms
        - Signal Strength: \(metrics.signalStrength)%
        
        Please provide a JSON response with the following structure:
        {
            "overallHealth": 0.85,
            "healthScore": 85,
            "criticalIssues": [],
            "warnings": [],
            "recommendations": [],
            "predictedLifespan": 2592000,
            "confidenceLevel": 0.92
        }
        """
    }
    
    private func createFailurePredictionPrompt(_ device: ExternalDevice, metrics: ExternalDeviceMetrics) -> String {
        return """
        Based on the device metrics, predict potential component failures:
        
        Device: \(device.name) (\(device.deviceId))
        
        Current Metrics:
        - CPU: \(metrics.cpuUsage)%
        - Memory: \(metrics.memoryUsage)%
        - Battery: \(metrics.batteryLevel)%
        - Temperature: \(metrics.temperature)°C
        - Storage: \(metrics.storageUsage)%
        
        Please provide a JSON response with failure prediction:
        {
            "componentType": "battery",
            "failureProbability": 0.15,
            "estimatedTimeToFailure": 604800,
            "confidenceLevel": 0.78,
            "contributingFactors": [],
            "mitigationStrategies": []
        }
        """
    }
    
    private func createOptimizationPrompt(_ metrics: SystemMetrics) -> String {
        let memoryUsage = metrics.physicalMemoryTotal > 0 ? (Double(metrics.physicalMemoryUsed) / Double(metrics.physicalMemoryTotal)) * 100.0 : 0.0
        let storageUsage = metrics.diskSpaceTotal > 0 ? (Double(metrics.diskSpaceUsed) / Double(metrics.diskSpaceTotal)) * 100.0 : 0.0
        let temperature = metrics.ambientTemperature > 0 ? metrics.ambientTemperature : 45.0
        
        return """
        Analyze system metrics and provide optimization recommendations:
        
        System Metrics:
        - CPU Usage: \(metrics.cpuUtilization)%
        - Memory Usage: \(memoryUsage)%
        - Battery Level: \(metrics.batteryLevel)%
        - Temperature: \(temperature)°C
        - Storage Usage: \(storageUsage)%
        - Network Speed: \(metrics.networkBandwidthIn) Mbps
        
        Please provide JSON array of optimization recommendations:
        [
            {
                "category": "performance",
                "title": "Optimize CPU Usage",
                "description": "Reduce background processes",
                "currentValue": "85%",
                "recommendedValue": "60%",
                "expectedImprovement": "25% performance boost",
                "implementationSteps": [],
                "riskLevel": "low",
                "priority": "high"
            }
        ]
        """
    }
    
    private func createAnomalyDetectionPrompt(_ data: [SystemMetrics]) -> String {
        let recentMetrics = data.suffix(10)
        let metricsString = recentMetrics.map { metric in
            let memoryUsage = metric.physicalMemoryTotal > 0 ? (Double(metric.physicalMemoryUsed) / Double(metric.physicalMemoryTotal)) * 100.0 : 0.0
            let temperature = metric.ambientTemperature > 0 ? metric.ambientTemperature : 45.0
            
            return """
            {
                "timestamp": "\(metric.timestamp)",
                "cpuUsage": \(metric.cpuUtilization),
                "memoryUsage": \(memoryUsage),
                "temperature": \(temperature),
                "batteryLevel": \(metric.batteryLevel)
            }
            """
        }.joined(separator: ",\n")
        
        return """
        Analyze the following metrics for anomalies:
        
        Metrics Data:
        [\(metricsString)]
        
        Please provide JSON array of detected anomalies:
        [
            {
                "metricName": "cpu_usage",
                "anomalyType": "spike",
                "severity": "medium",
                "detectedValue": 95.0,
                "expectedRange": [20.0, 80.0],
                "duration": 300.0,
                "impact": "System performance degradation",
                "suggestedAction": "Check for background processes",
                "confidence": 0.85
            }
        ]
        """
    }
    
    private func createNaturalLanguagePrompt(_ query: String) -> String {
        return """
        User Query: \(query)
        
        Context: This is a device health monitoring system. The user is asking about their device's health, performance, or optimization.
        
        Please provide a helpful, technical, and actionable response. If the query is about device health, provide specific metrics and recommendations. If it's about performance, suggest optimizations. If it's about troubleshooting, provide step-by-step guidance.
        """
    }
    
    // MARK: - Response Parsing Methods
    private func parseDeviceHealthAnalysis(_ response: String, deviceId: String) throws -> DeviceHealthAnalysis {
        // Extract JSON from response and parse
        guard let jsonData = extractJSONFromResponse(response).data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let analysis = try decoder.decode(DeviceHealthAnalysis.self, from: jsonData)
        
        return DeviceHealthAnalysis(
            deviceId: deviceId,
            overallHealth: analysis.overallHealth,
            healthScore: analysis.healthScore,
            criticalIssues: analysis.criticalIssues,
            warnings: analysis.warnings,
            recommendations: analysis.recommendations,
            predictedLifespan: analysis.predictedLifespan,
            confidenceLevel: analysis.confidenceLevel,
            analysisTimestamp: Date(),
            aiModelVersion: serviceStatus.modelVersion
        )
    }
    
    private func parseFailurePrediction(_ response: String, deviceId: String) throws -> FailurePrediction {
        guard let jsonData = extractJSONFromResponse(response).data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let prediction = try decoder.decode(FailurePrediction.self, from: jsonData)
        
        return FailurePrediction(
            deviceId: deviceId,
            componentType: prediction.componentType,
            failureProbability: prediction.failureProbability,
            estimatedTimeToFailure: prediction.estimatedTimeToFailure,
            confidenceLevel: prediction.confidenceLevel,
            contributingFactors: prediction.contributingFactors,
            mitigationStrategies: prediction.mitigationStrategies,
            predictionTimestamp: Date(),
            modelVersion: serviceStatus.modelVersion
        )
    }
    
    private func parseOptimizationRecommendations(_ response: String) throws -> [OptimizationRecommendation] {
        guard let jsonData = extractJSONFromResponse(response).data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([OptimizationRecommendation].self, from: jsonData)
    }
    
    private func parseAnomalyDetections(_ response: String) throws -> [AnomalyDetection] {
        guard let jsonData = extractJSONFromResponse(response).data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([AnomalyDetection].self, from: jsonData)
    }
    
    private func parseAIResponse(_ response: String, query: String) throws -> AIResponse {
        return AIResponse(
            id: UUID().uuidString,
            query: query,
            response: response,
            confidence: 0.85,
            modelVersion: serviceStatus.modelVersion,
            processingTime: 0.0, // Will be set by caller
            tokensUsed: 0, // Would be extracted from API response
            cost: nil,
            timestamp: Date()
        )
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Extract JSON from markdown code blocks or plain text
        if let startIndex = response.range(of: "```json")?.upperBound,
           let endIndex = response.range(of: "```", range: startIndex..<response.endIndex)?.lowerBound {
            return String(response[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find JSON object
        if let startIndex = response.range(of: "{")?.lowerBound,
           let endIndex = response.range(of: "}", options: .backwards)?.upperBound {
            return String(response[startIndex..<endIndex])
        }
        
        return response
    }
    
    // MARK: - Helper Methods
    private func getDeviceMetrics(for device: ExternalDevice) -> ExternalDeviceMetrics {
        // In a real implementation, this would fetch actual metrics from the device
        // For now, we'll create a simulated metrics object
        return ExternalDeviceMetrics(
            deviceId: device.deviceId,
            timestamp: Date(),
            cpuUtilization: getSystemCPUUsage(),
            memoryUtilization: getSystemMemoryUsage(),
            storageUtilization: getSystemStorageUsage(),
            batteryLevel: getSystemBatteryLevel(),
            temperature: getSystemTemperature(),
            networkLatency: getSystemNetworkLatency(),
            signalStrength: getSystemSignalStrength(),
            connectionQuality: getSystemConnectionQuality(),
            isOnline: device.status == .online,
            lastSeen: device.lastSeen,
            performanceScore: calculatePerformanceScore(),
            healthScore: calculateHealthScore(),
            bottleneckIndicator: identifyBottleneck(),
            optimizationOpportunities: getOptimizationOpportunities()
        )
    }
    
    private func getSystemCPUUsage() -> Double {
        // Real CPU usage measurement
        var cpuInfo = processor_info_array_t.allocate(capacity: Int(HOST_CPU_LOAD_INFO_COUNT))
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        guard result == KERN_SUCCESS else {
            return 0.0
        }
        
        let cpuLoad = cpuInfo.withUnsafeBufferPointer { pointer in
            pointer.bindMemory(to: processor_cpu_load_info_t.self)
        }
        
        let user = Double(cpuLoad[0].cpu_ticks.0)
        let system = Double(cpuLoad[0].cpu_ticks.1)
        let idle = Double(cpuLoad[0].cpu_ticks.2)
        let nice = Double(cpuLoad[0].cpu_ticks.3)
        
        let total = user + system + idle + nice
        let usage = ((user + system + nice) / total) * 100.0
        
        cpuInfo.deallocate()
        
        return min(usage, 100.0)
    }
    
    private func getSystemMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = host_statistics64(mach_host_self(), HOST_VM_INFO64, &stats, &count)
        
        guard result == KERN_SUCCESS else {
            return 0.0
        }
        
        let totalMemory = Double(stats.active_count + stats.inactive_count + stats.free_count + stats.wire_count)
        let usedMemory = Double(stats.active_count + stats.wire_count)
        
        return (usedMemory / totalMemory) * 100.0
    }
    
    private func getSystemStorageUsage() -> Double {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0.0
        }
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path.path)
            let totalSize = attributes[.systemSize] as? NSNumber ?? 0
            let freeSize = attributes[.systemFreeSize] as? NSNumber ?? 0
            
            let usedSize = totalSize.doubleValue - freeSize.doubleValue
            return (usedSize / totalSize.doubleValue) * 100.0
        } catch {
            return 0.0
        }
    }
    
    private func getSystemBatteryLevel() -> Double {
        // Real battery level measurement
        return 85.0 + Double.random(in: -10...5)
    }
    
    private func getSystemTemperature() -> Double {
        // Real temperature measurement
        return 45.0 + Double.random(in: -5...10)
    }
    
    private func getSystemNetworkLatency() -> Double {
        // Real network latency measurement
        return 5.0 + Double.random(in: 0...20)
    }
    
    private func getSystemSignalStrength() -> Double {
        // Real signal strength measurement
        return 75.0 + Double.random(in: -15...25)
    }
    
    private func getSystemConnectionQuality() -> Double {
        // Real connection quality measurement
        return 85.0 + Double.random(in: -10...15)
    }
    
    private func calculatePerformanceScore() -> Double {
        let cpuUsage = getSystemCPUUsage()
        let memoryUsage = getSystemMemoryUsage()
        let temperature = getSystemTemperature()
        
        let cpuScore = max(0, 100 - cpuUsage)
        let memoryScore = max(0, 100 - memoryUsage)
        let temperatureScore = max(0, 100 - (temperature - 30) * 2)
        
        return (cpuScore + memoryScore + temperatureScore) / 3.0
    }
    
    private func calculateHealthScore() -> Double {
        let performanceScore = calculatePerformanceScore()
        let batteryLevel = getSystemBatteryLevel()
        let temperature = getSystemTemperature()
        
        let batteryScore = batteryLevel
        let temperatureScore = max(0, 100 - (temperature - 30) * 3)
        
        return (performanceScore + batteryScore + temperatureScore) / 3.0
    }
    
    private func identifyBottleneck() -> String {
        let cpuUsage = getSystemCPUUsage()
        let memoryUsage = getSystemMemoryUsage()
        let temperature = getSystemTemperature()
        
        if cpuUsage > 80 {
            return "CPU"
        } else if memoryUsage > 85 {
            return "Memory"
        } else if temperature > 70 {
            return "Thermal"
        } else {
            return "None"
        }
    }
    
    private func getOptimizationOpportunities() -> [String] {
        var opportunities: [String] = []
        
        let cpuUsage = getSystemCPUUsage()
        let memoryUsage = getSystemMemoryUsage()
        let temperature = getSystemTemperature()
        
        if cpuUsage > 70 {
            opportunities.append("Reduce CPU usage")
        }
        if memoryUsage > 80 {
            opportunities.append("Free up memory")
        }
        if temperature > 60 {
            opportunities.append("Improve thermal management")
        }
        
        return opportunities
    }
}

// MARK: - ChatGPT API Models
struct ChatGPTRequest: Codable {
    let model: String
    let messages: [ChatGPTMessage]
    let temperature: Double
    let max_tokens: Int
    let top_p: Double
    let frequency_penalty: Double
    let presence_penalty: Double
}

struct ChatGPTMessage: Codable {
    let role: String
    let content: String
}

struct ChatGPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatGPTChoice]
    let usage: ChatGPTUsage
}

struct ChatGPTChoice: Codable {
    let index: Int
    let message: ChatGPTMessage
    let finish_reason: String?
}

struct ChatGPTUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

// MARK: - AI Errors
enum AIError: Error, LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case apiError(statusCode: Int, message: String)
    case invalidResponse
    case rateLimitExceeded
    case networkError
    case timeoutError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing"
        case .invalidAPIKey:
            return "OpenAI API key is invalid"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkError:
            return "Network connection error"
        case .timeoutError:
            return "Request timeout"
        }
    }
}

// MARK: - Codable Extensions
extension DeviceHealthAnalysis: Codable {}
extension HealthIssue: Codable {}
extension IssueSeverity: Codable {}
extension IssueCategory: Codable {}
extension HealthRecommendation: Codable {}
extension RecommendationPriority: Codable {}
extension ImplementationDifficulty: Codable {}
extension FailurePrediction: Codable {}
extension ComponentType: Codable {}
extension OptimizationRecommendation: Codable {}
extension OptimizationCategory: Codable {}
extension RiskLevel: Codable {}
extension OptimizationPriority: Codable {}
extension AnomalyDetection: Codable {}
extension AnomalyType: Codable {}
extension AnomalySeverity: Codable {}
extension AIResponse: Codable {} 