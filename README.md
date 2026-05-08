# ECHO — Stress Detection from Wrist Sensors

**MSML612 Final Project · University of Maryland, College Park**  
Balamurugan Manickaraj · Rupali Patel · Adwaith Santhosh

---

ECHO is a deep learning pipeline that detects psychological stress from wrist-worn sensor data using only the sensors available on the Apple Watch: PPG, skin temperature, and accelerometer. We train two models — EdgeStressNet (40K params, 158 KB) and PatchTST (142K params, 554 KB) — and deploy EdgeStressNet to a native watchOS app via CoreML.

**EdgeStressNet test results:** 92.9% accuracy · 0.981 AUROC · 3.76 ms/window · 80.5 KB after INT8 quantisation

---

## Repository Structure

```
echo-stress-detection/
├── notebooks/
│   ├── echo_wearable_device.ipynb     ← main pipeline (data → train → eval → edge → export)
│   └── echo_apple_watch.ipynb         ← Apple Watch emulator and CoreML demo
├── outputs_wearable/                  ← all artefacts produced by echo_wearable_device.ipynb
│   ├── echo_edgestress_wearable.pt    ← EdgeStressNet float32 weights
│   ├── echo_edgestress_wearable_int8.pt ← EdgeStressNet INT8 weights (80.5 KB)
│   ├── echo_patchtst_wearable.pt      ← PatchTST weights
│   ├── echo_wearable.onnx             ← ONNX export (verified with ONNX Runtime)
│   ├── EchoStressDetector_v2_wearable.mlpackage/ ← CoreML package (watchOS 8+)
│   ├── wearable_splits.npz            ← preprocessed train/val/test arrays
│   ├── wearable_features.csv          ← per-window feature table
│   ├── wearable_metrics.csv           ← evaluation metrics
│   ├── edge/
│   │   ├── edgestress_pruned50.pt     ← 50 % pruned EdgeStressNet
│   │   └── pruning_curves.png
│   └── *.png                          ← training curves, confusion matrices, ROC, etc.
├── data/
│   ├── aerobic.csv                    ← demo sensor data (preprocessed, 32 Hz)
│   ├── anaerobic.csv
│   └── stress.csv
└── watchos-app/                       ← native watchOS app (Swift/SwiftUI + CoreML)
    ├── Echo Watch App/
    │   ├── EchoApp.swift
    │   ├── ContentView.swift
    │   ├── StressDetector.swift
    │   ├── EchoStressDetector.mlpackage/ ← CoreML model bundled with the app
    │   └── Screens/
    │       ├── WatchFaceView.swift
    │       ├── HomeView.swift
    │       ├── VitalsView.swift
    │       ├── RiskView.swift
    │       ├── AlertView.swift
    │       └── EmergencyView.swift
    └── Echo.xcodeproj/
```

---

## Reproducing the Results

### 1. Download the Dataset

The full dataset (216 MB) is too large to include in this repository. It is publicly available on PhysioNet under a Creative Commons licence.

**Direct download page:**  
[https://physionet.org/content/wearable-device-dataset-stress-exercise/1.0.1/](https://physionet.org/content/wearable-device-dataset-stress-exercise/1.0.1/)

**Citation:**  
> A. Hongn, C. P. Garner, B. Karimi, A. Shirali, and A. Jafari, *Wearable Device Dataset from Induced Stress and Structured Exercise Sessions*, PhysioNet, 2025. DOI: [10.13026/hz6m-0p84](https://doi.org/10.13026/hz6m-0p84)

You can also download directly from the command line using the PhysioNet wget script (a free PhysioNet account is required):

```bash
wget -r -N -c -np --user <your-physionet-username> --ask-password \
  https://physionet.org/files/wearable-device-dataset-stress-exercise/1.0.1/
```

Or using the PhysioNet client:

```bash
pip install wfdb
python -c "import wfdb; wfdb.dl_database('wearable-device-dataset-stress-exercise', './Wearable_Dataset')"
```

Once downloaded, place it at the project root so the path resolves automatically:

```
echo-stress-detection/
└── Wearable_Dataset/       ← extracted dataset folder
```

The notebook auto-detects the dataset location whether the kernel starts from the project root or the `notebooks/` directory.

### 2. Run the Pipeline

```bash
pip install torch numpy pandas scipy scikit-learn coremltools onnxruntime matplotlib seaborn jupyterlab
jupyter lab notebooks/echo_wearable_device.ipynb
```

Run all cells in order. The random seed is fixed at 42. All training runs on CPU. Expected runtime: ~15 minutes.

The notebook covers the full pipeline end-to-end:

| Section | What it does |
|---------|-------------|
| §1–3 | Configuration, imports, dataset loading |
| §4–9 | Signal preprocessing, windowing, subject-independent split |
| §10–13 | Model definitions (EdgeStressNet, PatchTST), training, evaluation |
| §14 | Edge optimisation — structured pruning, INT8 quantisation, ONNX export |
| §15 | CoreML export for watchOS 8+ |
| §16 | Apple Watch emulator inference simulation |
| §17 | Benchmark: accuracy vs size vs latency (Pareto) |
| §18 | Save all artefacts to `outputs_wearable/` |

### 3. Open the watchOS App

Open `watchos-app/Echo.xcodeproj` in Xcode 16+. Select any Apple Watch simulator (watchOS 10+) and run. The app loads `EchoStressDetector.mlpackage` and streams inference from the bundled CSV files at the same 32 Hz rate used during training. To use the latest model, copy `outputs_wearable/EchoStressDetector_v2_wearable.mlpackage` into the Xcode project and update the reference in `StressDetector.swift`.

---

## Key Results

| Metric | EdgeStressNet | PatchTST |
|--------|--------------|----------|
| Accuracy | **0.929** | 0.864 |
| F1-Score | **0.918** | 0.861 |
| AUROC | **0.981** | 0.966 |
| Precision | **0.915** | 0.776 |
| Recall | 0.921 | **0.968** |
| Parameters | 40,326 | 141,890 |
| Size (float32) | 158.8 KB | 554.3 KB |
| Size (INT8) | **80.5 KB** | — |

---

## Dependencies

| Library | Version |
|---------|---------|
| Python | 3.11 |
| PyTorch | 2.9.1 |
| NumPy | 1.26 |
| Pandas | 2.2 |
| SciPy | 1.13 |
| scikit-learn | 1.4 |
| coremltools | 8.0 |
| ONNX Runtime | 1.18 |
| Matplotlib | 3.9 |
| Seaborn | 0.13 |
| Xcode | 16 (for watchOS app) |
| Swift | 6 |
