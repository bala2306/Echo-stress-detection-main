//
//  RiskView.swift
//  Echo Watch App
//

import SwiftUI

struct RiskView: View {
    var detector: StressDetector

    private var riskPercent: Double {
        detector.riskPercent * 100
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Stress Risk")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            // Circular gauge
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 6)
                    .frame(width: 84, height: 84)

                Circle()
                    .trim(from: 0, to: detector.riskPercent)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: detector.riskPercent)

                VStack(spacing: 1) {
                    Text(String(format: "%.1f%%", riskPercent))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(gaugeColor)
                    Text("RISK")
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                }
            }

            // Status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(gaugeColor)
                    .frame(width: 6, height: 6)
                Text("\(detector.riskLabel) RISK")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(gaugeColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(gaugeColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(gaugeColor.opacity(0.3), lineWidth: 1)
            )

            // Model info
            VStack(spacing: 4) {
                HStack {
                    Text("Model confidence")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(String(format: "%.0f%%", detector.confidence * 100))
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
                HStack {
                    Text("Last window")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("30s")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
            }
            .padding(10)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 8)
    }

    private var gaugeColor: Color {
        switch detector.riskLabel {
        case "HIGH": return .red
        case "MODERATE": return .yellow
        default: return .green
        }
    }
}
