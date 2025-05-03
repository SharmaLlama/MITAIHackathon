Acne-LDS: Quantised Model for Edge Devices
Project Overview
Acne-LDS is an open-source project designed to detect acne using machine learning models. The project includes a trained YOLO model and a modified ResNet model, which has been quantised to run efficiently on edge devices. The quantisation process and comparison of the models are handled in the quantise_and_compare notebook.

This repository is divided into two main components:

Acne-LDS Folder: Contains the original open-source code and models for acne detection.
Quantisation and Comparison: Focused on quantising the ResNet model and comparing its performance with the ground truth and the YOLO model.
Additionally, this project includes an iOS app built using Xcode, which integrates the quantised model for real-time acne detection on iOS devices.

Features
Quantised ResNet Model: Optimised for edge devices to ensure efficient performance.
YOLO Model: Pre-trained for acne detection.
Comparison Notebook: quantise_and_compare.ipynb for evaluating the performance of the models.
iOS App: A user-friendly app for real-time acne detection.
Setup Instructions
1. Clone the Repository
2. Install Dependencies
Ensure you have Python 3.8+ installed. Install the required Python packages:

3. Quantisation and Comparison
Navigate to the quantise_and_compare.ipynb notebook to:

Quantise the ResNet model.
Compare the performance of the YOLO model, quantised ResNet model, and ground truth.
Run the notebook using Jupyter:

iOS App Setup
Prerequisites
Xcode 14.0 or later.
macOS 12.0 or later.
An iOS device or simulator running iOS 15.0 or later.
Steps to Install and Run the App
Open the ios-app folder in Xcode.
Connect your iOS device or select a simulator.
Build and run the app:
Click on the Run button in Xcode or press Cmd + R.
The app will launch on your device or simulator.
Folder Structure
Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes.

License
This project is licensed under the MIT License. See the LICENSE file for details.

Acknowledgements
Special thanks to the contributors of the original Acne-LDS project and the open-source community for their support.