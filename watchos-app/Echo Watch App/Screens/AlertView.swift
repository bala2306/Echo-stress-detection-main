//
//  AlertView.swift
//  Echo Watch App
//

import SwiftUI

struct AlertView: View {
    var detector: StressDetector
    var onEmergency: () -> Void

    @State private var flash = false

    var body: some View {
        VStack(spacing: 8) {
            // Alert icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().stroke(Color.red.opacity(0.8), lineWidth: 2)
                    )
                    .scaleEffect(flash ? 1.05 : 1.0)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red)
            }

            // Message
            VStack(spacing: 4) {
                Text("Stress Detected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)

                Text("Elevated stress signature identified. Consider taking a break.")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(String(format: "Risk Score: %.1f%%", detector.riskPercent * 100))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.2))
                    .clipShape(Capsule())
            }

            // Emergency button
            Button {
                onEmergency()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 12))
                    Text("Call 911")
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .background(
            flash ? Color.red.opacity(0.08) : Color.red.opacity(0.02)
        )
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: flash)
        .onAppear { flash = true }
    }
}
