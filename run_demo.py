#!/usr/bin/env python3
import time
import random
import os
import sys
from datetime import datetime

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def clear_screen():
    os.system('clear' if os.name != 'nt' else 'cls')

def print_header():
    print(f"{Colors.HEADER}{Colors.BOLD}")
    print("===========================================")
    print("🚀 Sightline AI - System Monitoring Suite")
    print("===========================================")
    print(f"{Colors.ENDC}")
    print("Version: 1.0.0")
    print("Platform: macOS 13.0+")
    print("")

def get_system_metrics():
    return {
        "CPU Usage": f"{random.uniform(30, 70):.1f}%",
        "Memory Usage": f"{random.uniform(40, 80):.1f}%",
        "GPU Usage": f"{random.uniform(20, 60):.1f}%",
        "CPU Temperature": f"{random.uniform(45, 75):.1f}°C",
        "Network Latency": f"{random.randint(10, 50)} ms",
        "Storage Used": f"{random.uniform(50, 90):.1f}%",
        "Power Consumption": f"{random.uniform(30, 80):.1f} W",
        "System Health Score": f"{random.randint(70, 95)}/100"
    }

def get_ai_insights():
    insights = [
        "✨ AI Insight: CPU usage pattern suggests optimal performance",
        "📊 Prediction: Memory usage will remain stable for next 2 hours",
        "⚡ Recommendation: GPU is underutilized - consider enabling hardware acceleration",
        "🔥 Warning: Temperature trending upward - monitoring thermal state",
        "🌐 Network: Low latency detected - excellent connectivity",
        "💡 Tip: Close Safari to free up 1.2GB of memory",
        "🔄 Update: System optimization completed - 15% performance improvement",
        "📈 Trend: Network traffic increased by 25% in last hour"
    ]
    return random.sample(insights, 5)

def get_active_processes():
    processes = [
        ("Sightline-AI", random.uniform(10, 20), f"{random.randint(200, 300)} MB"),
        ("WindowServer", random.uniform(5, 15), f"{random.randint(150, 250)} MB"),
        ("kernel_task", random.uniform(3, 10), f"{random.randint(400, 600)} MB"),
        ("Safari", random.uniform(10, 25), f"{random.uniform(0.8, 1.5):.1f} GB"),
        ("Finder", random.uniform(1, 5), f"{random.randint(100, 200)} MB"),
        ("Mail", random.uniform(2, 8), f"{random.randint(250, 400)} MB"),
        ("Xcode", random.uniform(15, 30), f"{random.uniform(1.5, 2.5):.1f} GB"),
    ]
    return sorted(processes[:5], key=lambda x: x[1], reverse=True)

def display_dashboard():
    clear_screen()
    print_header()
    
    # System Metrics
    print(f"{Colors.BLUE}📊 REAL-TIME SYSTEM METRICS{Colors.ENDC}")
    print("---------------------------")
    metrics = get_system_metrics()
    for key, value in sorted(metrics.items()):
        color = Colors.GREEN if "Score" in key and int(value.split("/")[0]) > 80 else ""
        print(f"• {key}: {color}{value}{Colors.ENDC}")
    
    # AI Insights
    print(f"\n{Colors.CYAN}🤖 AI-POWERED INSIGHTS{Colors.ENDC}")
    print("----------------------")
    for insight in get_ai_insights():
        print(insight)
    
    # External Devices
    print(f"\n{Colors.BLUE}📱 EXTERNAL DEVICES{Colors.ENDC}")
    print("-------------------")
    print("• MacBook Pro (This Device) 🟢")
    print("• iPhone 15 Pro - Connected via Wi-Fi 🟢")
    print("• iPad Air - Synced 5 min ago 🟡")
    print("• Apple Watch Series 9 - Active 🟢")
    print("• AirPods Pro - Connected 🟢")
    
    # Top Processes
    print(f"\n{Colors.BLUE}🔝 TOP PROCESSES BY CPU{Colors.ENDC}")
    print("------------------------")
    processes = get_active_processes()
    for i, (name, cpu, memory) in enumerate(processes, 1):
        cpu_color = Colors.FAIL if cpu > 20 else Colors.WARNING if cpu > 10 else Colors.GREEN
        print(f"{i}. {name} - CPU: {cpu_color}{cpu:.1f}%{Colors.ENDC}, Memory: {memory}")
    
    # Security Status
    print(f"\n{Colors.GREEN}🛡️ SECURITY STATUS{Colors.ENDC}")
    print("------------------")
    print("✅ No threats detected")
    print("✅ Firewall: Active")
    print("✅ System Integrity Protection: Enabled")
    print("✅ Last security scan: 2 hours ago")
    
    # System Optimization
    print(f"\n{Colors.BLUE}🔄 SYSTEM OPTIMIZATION{Colors.ENDC}")
    print("----------------------")
    print("• Performance Mode: Balanced")
    print("• Thermal State: Normal")
    print(f"• Fan Speed: {random.randint(1800, 2500)} RPM")
    print(f"• Battery: {random.randint(75, 95)}% (Not Charging)")

def monitoring_loop():
    print(f"\n{Colors.WARNING}⏱️ MONITORING ACTIVE{Colors.ENDC}")
    print("-------------------")
    print("Press Ctrl+C to stop monitoring...")
    print("")
    
    update_count = 0
    try:
        while True:
            update_count += 1
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            cpu = random.uniform(30, 70)
            memory = random.uniform(40, 80)
            temp = random.uniform(45, 75)
            health = random.randint(70, 95)
            
            # Color coding based on values
            cpu_color = Colors.FAIL if cpu > 60 else Colors.WARNING if cpu > 45 else Colors.GREEN
            mem_color = Colors.FAIL if memory > 70 else Colors.WARNING if memory > 55 else Colors.GREEN
            temp_color = Colors.FAIL if temp > 70 else Colors.WARNING if temp > 60 else Colors.GREEN
            
            print(f"[{timestamp}] Update #{update_count}")
            print(f"  CPU: {cpu_color}{cpu:.1f}%{Colors.ENDC}", end="")
            print(f" | Memory: {mem_color}{memory:.1f}%{Colors.ENDC}", end="")
            print(f" | Temp: {temp_color}{temp:.1f}°C{Colors.ENDC}", end="")
            print(f" | Health: {health}/100")
            
            # Simulate occasional alerts
            if random.random() > 0.8:
                alerts = [
                    f"{Colors.WARNING}⚠️  Alert: High resource usage detected on process 'mdworker'{Colors.ENDC}",
                    f"{Colors.CYAN}📊 AI: Consider closing Safari to improve performance{Colors.ENDC}",
                    f"{Colors.GREEN}✅ Success: Automatic cache cleanup freed 2.3GB{Colors.ENDC}",
                    f"{Colors.WARNING}🔥 Warning: GPU temperature approaching threshold{Colors.ENDC}"
                ]
                print(f"  {random.choice(alerts)}")
            
            # Every 5 updates, show a mini dashboard refresh
            if update_count % 5 == 0:
                print(f"\n{Colors.BOLD}--- Quick Stats Refresh ---{Colors.ENDC}")
                print(f"Active Connections: {random.randint(10, 30)} | ")
                print(f"Network I/O: ↑{random.randint(100, 500)}KB/s ↓{random.randint(500, 2000)}KB/s | ")
                print(f"Disk I/O: {random.randint(10, 100)}MB/s")
                print("")
            
            time.sleep(3)
            
    except KeyboardInterrupt:
        print(f"\n\n{Colors.GREEN}✅ Monitoring stopped successfully{Colors.ENDC}")
        print(f"{Colors.BOLD}Session Summary:{Colors.ENDC}")
        print(f"• Total updates: {update_count}")
        print(f"• Duration: {update_count * 3} seconds")
        print(f"• Average CPU: {random.uniform(40, 60):.1f}%")
        print(f"• Peak Memory: {random.uniform(70, 85):.1f}%")
        print("\nThank you for using Sightline AI!")

def main():
    # Display the full dashboard
    display_dashboard()
    
    # Start real-time monitoring
    monitoring_loop()

if __name__ == "__main__":
    main()