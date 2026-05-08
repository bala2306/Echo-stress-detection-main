//
//  StressDetector.swift
//  Echo Watch App
//
//  Created by Adwaith Santhosh on 4/9/26.
//

import CoreML
import Foundation

/// Loads real sensor CSVs and runs the EdgeStressNet CoreML model
@Observable
class StressDetector {

    enum StressLevel: String {
        case baseline = "Baseline"
        case stressed = "Stressed"
        case unknown = "Unknown"
    }

    enum DatasetMode: String, CaseIterable, Identifiable {
        case aerobic = "Aerobic"
        case anaerobic = "Anaerobic"
        case stress = "Stress"

        var id: String { rawValue }

        var fileName: String {
            switch self {
            case .aerobic: return "aerobic"
            case .anaerobic: return "anaerobic"
            case .stress: return "stress"
            }
        }
    }

    struct PredictionResult: Identifiable {
        let id = UUID()
        let level: StressLevel
        let stressProbability: Double
        let baselineProbability: Double
        let timestamp: Date
    }

    // MARK: - State
    var latestResult: PredictionResult?
    var history: [PredictionResult] = []
    var isStreaming = false
    var errorMessage: String?
    var datasetMode: DatasetMode = .aerobic
    /// Current stress intensity (derived from model output)
    var stressIntensity: Double = 0.0

    // MARK: - Simulated Vitals (driven by CSV data)
    var heartRate: Int = 72
    var hrv: Int = 38
    var skinTemp: Double = 36.6
    var bvpAmplitude: Double = 0.8
    /// PPG waveform points for display (normalized 0-1)
    var ppgWaveform: [Double] = Array(repeating: 0.5, count: 40)
    /// Seconds since last analysis
    var secondsSinceAnalysis: Int = 0

    // MARK: - Model
    private var model: EchoStressDetector_v2_combined?

    // MARK: - Streaming
    private var streamTask: Task<Void, Never>?
    private var vitalsTask: Task<Void, Never>?

    // MARK: - CSV Data
    private var csvData: [[Float]] = []  // Each row: [BVP, TEMP, ACC_x, ACC_y, ACC_z]
    private var currentOffset: Int = 0

    // MARK: - Constants
    private let channelCount = 5       // BVP, TEMP, ACC_x, ACC_y, ACC_z
    private let windowLength = 960     // 30s * 32Hz
    private let maxHistory = 20
    private let streamStepSize = 320   // Advance 10s (320 samples) per prediction

    init() {
        loadModel()
        // Read dataset mode from launch arguments: -datasetMode aerobic|anaerobic|stress
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-datasetMode"), idx + 1 < args.count {
            let value = args[idx + 1].lowercased()
            if let mode = DatasetMode.allCases.first(where: { $0.fileName == value }) {
                datasetMode = mode
            }
        }
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly
            model = try EchoStressDetector_v2_combined(configuration: config)
            errorMessage = nil
        } catch {
            errorMessage = "Model load failed: \(error.localizedDescription)"
        }
    }

    // MARK: - CSV Loading

    private func loadCSV(for mode: DatasetMode) -> [[Float]] {
        guard let url = Bundle.main.url(forResource: mode.fileName, withExtension: "csv") else {
            errorMessage = "CSV not found: \(mode.fileName).csv"
            return []
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            var rows: [[Float]] = []

            for (i, line) in lines.enumerated() {
                // Skip header
                if i == 0 { continue }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { continue }

                let parts = trimmed.components(separatedBy: ",")
                if parts.count >= 5 {
                    let values = parts.prefix(5).compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
                    if values.count == 5 {
                        rows.append(values)
                    }
                }
            }

            return rows
        } catch {
            errorMessage = "Failed to read CSV: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Streaming Control

    func startStreaming() {
        guard !isStreaming else { return }
        isStreaming = true
        history.removeAll()
        secondsSinceAnalysis = 0
        currentOffset = 0

        // Load CSV for current mode
        csvData = loadCSV(for: datasetMode)
        if csvData.isEmpty {
            errorMessage = "No data loaded for \(datasetMode.rawValue)"
            isStreaming = false
            return
        }

        // Vitals update loop (fast - every 0.8s for waveform animation)
        vitalsTask = Task { @MainActor in
            var frame = 0
            while !Task.isCancelled {
                frame += 1
                updateVitalsFromCSV(frame: frame)
                try? await Task.sleep(for: .milliseconds(800))
            }
        }

        // Prediction loop (every 3s, sliding window through CSV)
        streamTask = Task { @MainActor in
            while !Task.isCancelled {
                guard currentOffset + windowLength <= csvData.count else {
                    // Loop back to start
                    currentOffset = 0
                    continue
                }

                secondsSinceAnalysis = 0
                runPredictionFromCSV()
                currentOffset += streamStepSize

                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        vitalsTask?.cancel()
        vitalsTask = nil
        isStreaming = false
    }

    func switchMode(to mode: DatasetMode) {
        stopStreaming()
        datasetMode = mode
        latestResult = nil
        history.removeAll()
        stressIntensity = 0.0
        startStreaming()
    }

    // MARK: - Vitals from CSV

    /// Tracks where the PPG waveform is reading from (advances each tick)
    private var ppgReadOffset: Int = 0
    /// Number of BVP samples to show in the waveform
    private let ppgDisplayCount = 40
    /// How many samples to advance per tick (32Hz * 0.8s ≈ 26 samples)
    private let ppgStepPerTick = 26

    private func updateVitalsFromCSV(frame: Int) {
        guard !csvData.isEmpty else { return }

        // Advance PPG read position (wraps around)
        ppgReadOffset += ppgStepPerTick
        if ppgReadOffset + ppgDisplayCount >= csvData.count {
            ppgReadOffset = 0
        }

        // PPG waveform: read consecutive real BVP samples
        let rawBVP = (ppgReadOffset..<ppgReadOffset + ppgDisplayCount).map { Double(csvData[$0][0]) }
        let minB = rawBVP.min() ?? 0
        let maxB = rawBVP.max() ?? 1
        let range = maxB - minB
        if range > 0.0001 {
            ppgWaveform = rawBVP.map { ($0 - minB) / range }
        }

        // BVP amplitude: RMS of current window
        let bvpRMS = sqrt(rawBVP.map { $0 * $0 }.reduce(0, +) / Double(rawBVP.count))
        bvpAmplitude = (bvpRMS * 100).rounded() / 100

        // Skin temp: average from nearby samples
        let sampleStart = min(currentOffset, csvData.count - 1)
        let sampleEnd = min(sampleStart + 64, csvData.count)
        let tempValues = csvData[sampleStart..<sampleEnd].map { Double($0[1]) }
        if !tempValues.isEmpty {
            skinTemp = ((tempValues.reduce(0, +) / Double(tempValues.count)) * 10).rounded() / 10
        }

        // Derive heart rate from stress intensity (model output)
        let s = stressIntensity
        heartRate = Int(62 + 48 * s) + Int.random(in: -2...2)
        hrv = Int(45 - 27 * s) + Int.random(in: -2...2)

        secondsSinceAnalysis += 1
    }

    // MARK: - Build MLMultiArray from CSV window

    private func buildWindowFromCSV() -> MLMultiArray? {
        guard currentOffset + windowLength <= csvData.count else { return nil }

        guard let array = try? MLMultiArray(shape: [1, 5, 960] as [NSNumber], dataType: .float32) else {
            return nil
        }

        for t in 0..<windowLength {
            let row = csvData[currentOffset + t]
            for ch in 0..<channelCount {
                let idx = ch * windowLength + t
                array[idx] = NSNumber(value: row[ch])
            }
        }

        return array
    }

    // MARK: - Prediction

    private func runPredictionFromCSV() {
        guard let model else {
            errorMessage = "Model not loaded"
            return
        }

        guard let inputArray = buildWindowFromCSV() else {
            errorMessage = "Failed to create input from CSV"
            return
        }

        do {
            let input = EchoStressDetector_v2_combinedInput(wrist_signals: inputArray)
            let output = try model.prediction(input: input)
            let logits = output.stress_logits

            let logit0 = logits[0].doubleValue
            let logit1 = logits[1].doubleValue
            let maxLogit = max(logit0, logit1)
            let exp0 = exp(logit0 - maxLogit)
            let exp1 = exp(logit1 - maxLogit)
            let sumExp = exp0 + exp1

            let baselineProb = exp0 / sumExp
            let stressProb = exp1 / sumExp
            let level: StressLevel = stressProb > 0.5 ? .stressed : .baseline

            stressIntensity = stressProb

            let result = PredictionResult(
                level: level,
                stressProbability: stressProb,
                baselineProbability: baselineProb,
                timestamp: Date()
            )

            latestResult = result
            history.append(result)
            if history.count > maxHistory {
                history.removeFirst()
            }
        } catch {
            errorMessage = "Prediction failed: \(error.localizedDescription)"
        }
    }

    /// Convenience: risk label string
    var riskLabel: String {
        guard let r = latestResult else { return "LOW" }
        if r.stressProbability > 0.7 { return "HIGH" }
        if r.stressProbability > 0.4 { return "MODERATE" }
        return "LOW"
    }

    /// Convenience: risk percentage
    var riskPercent: Double {
        latestResult?.stressProbability ?? 0
    }

    /// Convenience: model confidence (max of the two probabilities)
    var confidence: Double {
        guard let r = latestResult else { return 0 }
        return max(r.stressProbability, r.baselineProbability)
    }
}
