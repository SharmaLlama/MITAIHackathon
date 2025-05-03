**acne-lds iOS Edge Deployment**

An Apple iOS application demonstrating an edge-compatible, quantized acne lesion detection model powered by Core ML. This project builds on the open-source acne-lds repository and includes tools for model quantization, comparison, prototyping YOLO training, and the final iOS app integration.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Setup & Installation](#setup--installation)

   * [Prerequisites](#prerequisites)
   * [Clone the Repository](#clone-the-repository)
   * [Python Environment & Notebook](#python-environment--notebook)
   * [iOS App (Xcode) Setup](#ios-app-xcode-setup)
4. [Usage](#usage)

   * [Model Quantization](#model-quantization)
   * [Quantise\_and\_Compare Notebook](#quantise_and_compare-notebook)
   * [Prototyping YOLO Training](#prototyping-yolo-training)
   * [Running the iOS App](#running-the-ios-app)
5. [Contributing](#contributing)
6. [License](#license)

---

## Project Overview

The objective of this project is to deploy an acne lesion detection system on Apple iOS devices by converting a quantized deep learning model into Core ML format. I leveraged the original [acne-lds](https://github.com/openface-io/acne-lds) repository for baseline architecture and data processing. Key features include:

* **Quantization** of a modified ResNet model to reduce size and latency for edge deployment.
* **Core ML conversion** enabling on-device inference in an Xcode-based iOS application.
* **Comparison notebook** (quantise_and_compare.ipynb) for evaluating performance against ground truth and fine-tuned YOLOv11. This has both accuracy and inference metrics.
* **Prototyping folder** showing experiments with YOLO training workflows.

---

## Repository Structure
├── quantise_and_compare/
│   └── quantise_and_compare.ipynb    # Notebook comparing baseline, YOLO, and quantized per-trained ResNet
├── prototyping/
│   └── yolo_training/                # Scripts and configs for YOLO prototyping
├── app/SkinSnap
│   ├── SkinSnap.xcodeproj             # Xcode project file
│   ├── SkinSnap/                      # App source code and assets
│   └── AcneClassQuantFin.mlpackage    # Final Core ML model converted from quantized pre-trained custom ResNet
│   └── README_ios.md                 # iOS-specific instructions (see below)
├── scripts/                          # Helper scripts for conversion and deployment
├── data/                             # Dataset
└── README.md                         # ← You are here!

---

## Setup & Installation

### Prerequisites

* **Python 3.9+** with virtual environment support
* **Jupyter Notebook** or JupyterLab
* **Xcode 14+** (compatible with iOS 15+)
* **macOS 12+**

### Clone the Repository

### Dataset Download

Download the acne lesion dataset from Roboflow:

- [Acne04 Dataset on Roboflow Universe](https://universe.roboflow.com/andrei-dore-5lz05/acne04)
bash
git clone https://github.com/SharmaLlama/MITAIHackathon.git acne-lds-edge-ios
cd acne-lds-edge-ios


### Python Environment & Notebook

1. Create and activate a virtual environment:

   
bash
   python3 -m venv venv
   source venv/bin/activate

2. Install dependencies:

   
bash
   pip install -r requirements.txt

3. Launch Jupyter Notebook:

   
bash
   jupyter notebook quantise_and_compare/quantise_and_compare.ipynb

4. Follow the notebook to:
   * Load the original and quantized models
   * Run inference on sample images
   * Compare metrics (accuracy, size, latency) - this takes up to 10 mins due to cpu

> **Tip:** You can customise the notebook paths and dataset locations as needed.

### iOS App (Xcode) Setup

1. Open the Xcode project:

   
bash
   open ios_app/AcneLDS.xcodeproj

2. Ensure the AcneClassQuantFin.mlpackage file is added to the project. If not, drag and drop it into Xcode.
3. Select a target device or simulator (iPhone running iOS 15+).
4. Build and run the app (⌘R).

---

## Usage

### Quantise\_and\_Compare Notebook

The notebook walks through:

* Converting models
* Benchmarking on test images
* Plotting performance comparisons

### Prototyping YOLO Training

Inside prototyping/yolo_training/ you will find:

* Dataset preparation scripts
* Training configuration (.yaml files)
* Inference examples on sample images

Use this as a reference if you wish to retrain or fine-tune the YOLO model.

### Running the iOS App

Once built, the app will run inference on the device camera feed, detecting acne lesions in real-time using the quantized Core ML model.

---
