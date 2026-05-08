//
//  VitalsView.swift
//  Echo Watch App
//

import SwiftUI

struct VitalsView: View {
    var detector: StressDetector

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Live Vitals")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)

                // PPG Waveform
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("PPG SIGNAL")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                        Spacer()
                        HStack(spacing: 3) {
                            Circle()
                                .fill(.green)
                                .frame(width: 4, height: 4)
                            Text("LIVE")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }

                    PPGWaveformView(points: detector.ppgWaveform)
                        .frame(height: 30)
                }
                .padding(8)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Metrics grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    MetricCard(label: "HEART RATE", value: "\(detector.heartRate)", unit: "BPM", color: .red)
                    MetricCard(label: "HRV", value: "\(detector.hrv)", unit: "ms", color: .blue)
                    MetricCard(label: "SKIN TEMP", value: String(format: "%.1f", detector.skinTemp), unit: "\u{00B0}C", color: .orange)
                    MetricCard(label: "BVP", value: String(format: "%.1f", detector.bvpAmplitude), unit: "a.u.", color: .purple)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - PPG Waveform

struct PPGWaveformView: View {
    var points: [Double]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard points.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(points.count - 1)
                let height = geo.size.height

                path.move(to: CGPoint(x: 0, y: height * (1 - points[0])))
                for i in 1..<points.count {
                    path.addLine(to: CGPoint(
                        x: stepX * CGFloat(i),
                        y: height * (1 - points[i])
                    ))
                }
            }
            .stroke(Color.green, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
