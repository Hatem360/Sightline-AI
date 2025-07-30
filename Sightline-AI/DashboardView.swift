import SwiftUI

struct DashboardView: View {
    @StateObject private var systemMetrics = SystemMetrics()
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Sightline AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Label("System", systemImage: "cpu")
                        Label("Network", systemImage: "network")
                        Label("AI", systemImage: "brain")
                    }
                    .foregroundColor(.gray)
                    .font(.caption)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Text("System Intelligence")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                // Status indicators
                HStack(spacing: 40) {
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("0%")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("100%")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.black.opacity(0.9))
            
            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                // Overview Card
                MetricCard(
                    icon: "chart.bar.fill",
                    title: "Overview",
                    iconColor: .blue
                )
                
                // Analytics Card
                MetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Analytics",
                    iconColor: .blue
                )
                
                // Network Quality Card
                MetricCard(
                    icon: "wifi",
                    title: "Network Quality",
                    value: "\(Int(systemMetrics.networkQuality))%",
                    subtitle: "Connection Quality",
                    iconColor: .green,
                    valueColor: .green
                )
                
                // Upload Speed Card
                MetricCard(
                    icon: "arrow.up.circle.fill",
                    title: "Upload Speed",
                    value: String(format: "%.1fMB/s", systemMetrics.networkBandwidthOut / 1_000_000),
                    subtitle: "Current Upload",
                    iconColor: .blue,
                    valueColor: .white
                )
                
                // Download Speed Card
                MetricCard(
                    icon: "arrow.down.circle.fill",
                    title: "Download Speed",
                    value: String(format: "%.1fMB/s", systemMetrics.networkBandwidthIn / 1_000_000),
                    subtitle: "Current Download",
                    iconColor: .blue,
                    valueColor: .white,
                    hasError: true
                )
                
                // Settings Card
                MetricCard(
                    icon: "gearshape.fill",
                    title: "Settings",
                    iconColor: .gray
                )
                
                // Battery Status Card
                MetricCard(
                    icon: "battery.100",
                    title: "Battery Status",
                    value: "\(Int(systemMetrics.batteryLevel))%",
                    subtitle: systemMetrics.batteryIsCharging ? "Charging" : "Discharging",
                    iconColor: .yellow,
                    valueColor: .yellow,
                    hasError: systemMetrics.batteryLevel < 20
                )
            }
            .padding(20)
            .background(Color.black.opacity(0.8))
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.black)
        .onAppear {
            startMetricsTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startMetricsTimer() {
        // Update metrics every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Metrics are already being updated by SystemMetrics internal timer
            // This timer is just for triggering UI updates if needed
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    var value: String? = nil
    var subtitle: String? = nil
    let iconColor: Color
    var valueColor: Color = .white
    var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Spacer()
                
                if hasError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let value = value {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(valueColor)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(height: 150)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// Extension to add network quality to SystemMetrics
extension SystemMetrics {
    var networkQuality: Double {
        // Calculate network quality based on various factors
        let latencyScore = max(0, 100 - (networkLatency * 0.5))
        let bandwidthScore = min(100, (networkBandwidthIn + networkBandwidthOut) / 1_000_000 * 10)
        let errorScore = networkErrorsIn + networkErrorsOut == 0 ? 100 : 50
        
        return (latencyScore + bandwidthScore + errorScore) / 3
    }
}

#Preview {
    DashboardView()
}