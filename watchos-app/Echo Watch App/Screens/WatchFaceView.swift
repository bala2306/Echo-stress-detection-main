//
//  WatchFaceView.swift
//  Echo Watch App
//

import SwiftUI

struct WatchFaceView: View {
    var detector: StressDetector

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            content(now: now)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        VStack(spacing: 6) {
            // Date + Time
            VStack(spacing: 0) {
                Text(now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .regular))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))

                Text(now.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 42, weight: .thin))
                    .foregroundStyle(.white)
            }

            // Echo Complication Card
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(complicationColor)
                        .frame(width: 6, height: 6)
                    Text("ECHO MONITORING")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(complicationColor)
                    Spacer()
                }

                HStack {
                    VStack(spacing: 1) {
                        Text("\(detector.heartRate)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                        Text("BPM")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(spacing: 1) {
                        Text("\(detector.hrv)ms")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                        Text("HRV")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(spacing: 1) {
                        Text(detector.riskLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(riskColor)
                        Text("RISK")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(complicationColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(complicationColor.opacity(0.4), lineWidth: 1)
            )

            // Bottom row
            HStack(spacing: 6) {
                VStack(spacing: 1) {
                    Text(String(format: "%.1f\u{00B0}", detector.skinTemp))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                    Text("TEMP")
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 1) {
                    Text(String(format: "%.1f", detector.bvpAmplitude))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.purple)
                    Text("BVP")
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 8)
    }

    private var complicationColor: Color {
        detector.riskLabel == "HIGH" ? .red : .green
    }

    private var riskColor: Color {
        switch detector.riskLabel {
        case "HIGH": return .red
        case "MODERATE": return .yellow
        default: return .green
        }
    }
}
