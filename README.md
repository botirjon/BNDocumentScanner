![Swift](https://img.shields.io/badge/language-Swift-orange)
![Version](https://img.shields.io/github/v/tag/botirjon/BNDocumentScanner)


# DocumentScannerViewController

A powerful, customizable iOS camera-based document scanner designed specifically to detect and read Uzbekistan identification documents (ID cards and passports). Built using **Vision**, **AVFoundation**, and **Combine**, this library captures the document, detects its boundaries, applies perspective correction, and performs real-time OCR (text recognition) for English, Uzbek, and Russian text.

## Features

- Live document detection with real-time boundary validation
- OCR using Apple's `VNRecognizeTextRequest`
- Perspective-corrected cropping and enhancement
- Auto-capture once a valid document is detected and validated
- Built-in support for English, Uzbek, and Russian
- Clean and modular architecture using Combine and delegation
- Custom overlay mask and UI support
- Designed to be used as a reusable Swift Package

> You can integrate this scanner into apps such as digital onboarding, KYC, or passport/ID validation tools.

## Installation

### Swift Package Manager (SPM)

Add this to your `Package.swift` or via Xcode's **File > Add Packages...**:

```swift
.package(url: "https://github.com/your-username/DocumentScannerViewController.git", from: "1.0.0")

Then import it:

```swift
import DocumentScannerViewController

## Usage

### 1. Subclass or present `DocumentScannerViewController`

```swift
let scannerVC = DocumentScannerViewController(
    maskView: MyCustomMaskView(),
    instructionProvider: "Align the document within the frame",
    validate: { readings in
        return readings.contains(where: { $0.contains("30404954170041") }) // your PINI logic
    }
)
scannerVC.delegate = self
present(scannerVC, animated: true)
```

### 2. Implement the delegate

```swift
extension MyViewController: DocumentScannerViewControllerDelegate {
    func documentScanner(_ controller: DocumentScannerViewController, didScanWithResult result: DocumentScannerViewController.Result) {
        // Access the cropped image and recognized text
        let scannedImage = result.image
        let ocrTexts = result.readings
        print(ocrTexts)
        dismiss(animated: true)
    }
}
```

## Customization

### `DocumentMaskView`

You can provide your own `UIView` subclass for custom overlay shapes and behavior (e.g., aspect ratio, corner highlights, animations).

```swift
class MyCustomMaskView: DocumentMaskView {
    override var aspectRatio: CGFloat {
        return 1.42 // Example ratio for Uzbekistan ID
    }

    override func update(documentBounded: Bool) {
        // Change border color based on detection
        layer.borderColor = documentBounded ? UIColor.green.cgColor : UIColor.red.cgColor
    }
}
```

## Requirements

- iOS 14.0+
- Swift 5.9+
- Works only on physical devices (camera access required)

## Roadmap

 - MRZ line auto-segmentation

 - Built-in ID/passport regex validation

 - Cropped image enhancement (contrast, brightness)

 - Localization support
 
## Author
Botirjon Nasridinov
GitHub: [@botirjon](https://github.com/botirjon)

