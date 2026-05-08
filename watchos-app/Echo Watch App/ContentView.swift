//
//  ContentView.swift
//  Echo Watch App
//
//  Created by Adwaith Santhosh on 4/9/26.
//

import SwiftUI

enum EchoScreen: Identifiable {
    case watchface
    case home
    case vitals
    case risk
    case alert
    case emergency

    var id: String {
        switch self {
        case .watchface: return "watchface"
        case .home: return "home"
        case .vitals: return "vitals"
        case .risk: return "risk"
        case .alert: return "alert"
        case .emergency: return "emergency"
        }
    }
}

struct ContentView: View {
    @State private var detector = StressDetector()
    @State private var currentScreen: EchoScreen = .watchface
    @State private var showAlertOverlay = false
    @State private var showEmergencyOverlay = false

    private var isHighRisk: Bool {
        detector.riskLabel == "HIGH"
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentScreen) {
                WatchFaceView(detector: detector)
                    .tag(EchoScreen.watchface)

                HomeView(detector: detector, onNavigate: navigate)
                    .tag(EchoScreen.home)

                VitalsView(detector: detector)
                    .tag(EchoScreen.vitals)

                RiskView(detector: detector)
                    .tag(EchoScreen.risk)

                if isHighRisk {
                    AlertView(detector: detector, onEmergency: {
                        showEmergencyOverlay = true
                    })
                    .tag(EchoScreen.alert)

                    EmergencyView(onDismiss: {})
                        .tag(EchoScreen.emergency)
                }
            }
            .id(isHighRisk)
            .tabViewStyle(.verticalPage)
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        // Overlay that auto-pops when stress first detected
        .overlay {
            if showAlertOverlay {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)

                    AlertView(detector: detector, onEmergency: {
                        showAlertOverlay = false
                        showEmergencyOverlay = true
                    })
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .red.opacity(0.3), radius: 12)
                    .padding(.horizontal, 4)
                }
                .transition(.opacity)
                .onTapGesture {
                    withAnimation {
                        showAlertOverlay = false
                    }
                }
            }
        }
        .overlay {
            if showEmergencyOverlay {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)

                    EmergencyView(onDismiss: {
                        withAnimation {
                            showEmergencyOverlay = false
                        }
                    })
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .red.opacity(0.3), radius: 12)
                    .padding(.horizontal, 4)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showAlertOverlay)
        .animation(.easeInOut(duration: 0.3), value: showEmergencyOverlay)
        .onAppear {
            detector.startStreaming()
        }
        .onChange(of: detector.riskLabel) { _, newValue in
            if newValue == "HIGH" {
                showAlertOverlay = true
            } else {
                showAlertOverlay = false
                showEmergencyOverlay = false
            }
        }
    }

    private func navigate(to screen: EchoScreen) {
        withAnimation {
            currentScreen = screen
        }
    }
}

#Preview {
    ContentView()
}
