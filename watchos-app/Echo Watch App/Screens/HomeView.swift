//
//  HomeView.swift
//  Echo Watch App
//

import SwiftUI

struct HomeView: View {
    var detector: StressDetector
    var onNavigate: (EchoScreen) -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Logo + Status
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(Color.blue.opacity(0.6), lineWidth: 2)
                        )
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }

                Text("Echo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(detector.isStreaming ? .green : .gray)
                        .frame(width: 5, height: 5)
                    Text(detector.isStreaming ? "Monitoring Active" : "Monitoring Paused")
                        .font(.system(size: 11))
                        .foregroundStyle(detector.isStreaming ? .green : .gray)
                }
            }

            // Quick stat rows
            VStack(spacing: 6) {
                Button { onNavigate(.vitals) } label: {
                    HStack {
                        Text("Live Vitals")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("\(detector.heartRate) BPM")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button { onNavigate(.risk) } label: {
                    HStack {
                        Text("Stress Risk")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                        Spacer()
                        Text(String(format: "%.1f%%", detector.riskPercent * 100))
                            .font(.system(size: 12))
                            .foregroundStyle(riskColor)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Text("Last analyzed \(detector.secondsSinceAnalysis)s ago")
                .font(.system(size: 9))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .padding(.horizontal, 6)
    }

    private var riskColor: Color {
        switch detector.riskLabel {
        case "HIGH": return .red
        case "MODERATE": return .yellow
        default: return .green
        }
    }
}
