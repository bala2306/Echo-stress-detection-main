//
//  EmergencyView.swift
//  Echo Watch App
//

import SwiftUI

struct EmergencyView: View {
    var onDismiss: () -> Void

    @State private var calling = false
    @State private var notified = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Emergency")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)

                // Location card
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Location shared")
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                        Text("37.334\u{00B0}N, 122.009\u{00B0}W")
                            .font(.system(size: 9))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(10)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Call 911
                Button {
                    calling = true
                } label: {
                    if calling {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Text("Calling 911...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.11))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.red, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text("Call 911")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .buttonStyle(.plain)

                // Notify contacts
                Button {
                    notified = true
                } label: {
                    if notified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10))
                            Text("Contacts Notified")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text("Notify Contacts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .buttonStyle(.plain)

                Text("Alert sent \u{2022} \(Date().formatted(.dateTime.hour().minute().second()))")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray.opacity(0.6))
            }
            .padding(.horizontal, 8)
        }
    }
}
