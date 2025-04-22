//
//  RealTimeMetricsView.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/15/25.
//

import SwiftUI

// MARK: - Real-time Surf Metrics View
struct RealTimeMetricsView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @State private var timer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 현재 속도 게이지
                VStack(spacing: 8) {
                    Text("Current Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Gauge(value: manager.currentSpeed, in: 0...20) {
                        Text("Speed")
                    } currentValueLabel: {
                        Text("\(String(format: "%.1f", manager.currentSpeed)) m/s")
                            .font(.caption2)
                    } minimumValueLabel: {
                        Text("0")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("20")
                            .font(.caption2)
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(speedColor(for: manager.currentSpeed))
                }
                
                // 속도 상태 표시
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Max Speed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", manager.maxSpeed)) m/s")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Avg Speed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", manager.averageSpeed)) m/s")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // 거리와 시간 표시
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(manager.distance)) m")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(manager.elapsed))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // 추가 메트릭들
                    VStack(spacing: 8) {
                        if manager.waveCount > 0 || manager.strokeCount > 0 {
                            HStack(spacing: 12) {
                                if manager.waveCount > 0 {
                                    MetricCard(title: "Waves", value: "\(manager.waveCount)", icon: "🌊", color: .cyan)
                                }
                                
                                if manager.strokeCount > 0 {
                                    MetricCard(title: "Strokes", value: "\(manager.strokeCount)", icon: "🏊‍♂️", color: .blue)
                                }
                            }
                        }
                        
                        if manager.heartRate > 0 || manager.activeCalories > 0 {
                            HStack(spacing: 12) {
                                if manager.heartRate > 0 {
                                    MetricCard(title: "Heart Rate", value: "\(Int(manager.heartRate))", icon: "❤️", color: .red)
                                }
                                
                                if manager.activeCalories > 0 {
                                    MetricCard(title: "Calories", value: "\(Int(manager.activeCalories))", icon: "🔥", color: .orange)
                                }
                            }
                        }
                    }
                }
                
                // 세션 상태
                VStack(spacing: 8) {
                    if manager.isRunning {
                        Text("🏄‍♂️ Active Session")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    } else if manager.distance > 0 || manager.elapsed > 0 {
                        Text("📊 Session Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("🌊 Ready to Surf")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // 자동 감지 상태
                    if manager.isAutoDetecting {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Auto Detection ON")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Metrics")
        .onAppear {
            startRealTimeUpdates()
        }
        .onDisappear {
            stopRealTimeUpdates()
        }
    }
    
    private func speedColor(for speed: Double) -> Color {
        switch speed {
        case 0..<2:
            return .gray
        case 2..<5:
            return .blue
        case 5..<10:
            return .green
        case 10..<15:
            return .yellow
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startRealTimeUpdates() {
        // 1초마다 UI 업데이트 (실제 데이터는 SurfWorkoutManager에서 관리)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // @Published 변수들이 자동으로 UI 업데이트를 트리거함
            // 필요시 추가적인 계산이나 로직을 여기에 추가 가능
        }
    }
    
    private func stopRealTimeUpdates() {
        timer?.invalidate()
        timer = nil
    }
}
