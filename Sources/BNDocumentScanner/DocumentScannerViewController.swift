//
//  DocumentScannerViewController.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 04/07/25.
//

import UIKit
import AVFoundation
import Vision
import AudioToolbox
import Combine

/// Delegate protocol for handling document scanning results
public protocol DocumentScannerViewControllerDelegate: AnyObject {
    /// Called when a document is successfully scanned and processed
    /// - Parameters:
    ///   - controller: The document scanner view controller
    ///   - result: The scan result containing the processed image and extracted text
    func documentScanner(_ controller: DocumentScannerViewController, didScanWithResult result: DocumentScannerViewController.Result)
}

/// A view controller that provides real-time document scanning capabilities using the device's camera.
/// Combines computer vision technologies to detect document boundaries, perform perspective correction,
/// and extract text from captured documents.
///
/// ## Features:
/// - Real-time document detection using Vision framework
/// - Perspective correction for skewed documents
/// - Text recognition with support for multiple languages (English, Uzbek, Russian)
/// - Visual feedback with customizable mask overlay
/// - Document validation with configurable validation rules
/// - Automatic capture when document meets validation criteria
///
/// ## Usage:
/// ```swift
/// let maskView = PassportMaskView(aspectRatio: 1.6)
/// let scanner = DocumentScannerViewController(
///     maskView: maskView,
///     instructionProvider: "Position document within the frame"
/// )
/// scanner.delegate = self
/// present(scanner, animated: true)
/// ```
open class DocumentScannerViewController: UIViewController {
    
    /// Result structure containing the processed document image and extracted text
    public struct Result {
        /// The processed and cropped document image with perspective correction applied
        public let image: UIImage
        /// Array of text strings extracted from the document using OCR
        public let readings: [String]
    }
    
    /// Validation closure type that determines if scanned readings are acceptable
    /// - Parameter readings: Array of text strings extracted from the document
    /// - Returns: Boolean indicating whether the readings pass validation
    public typealias Validator = ([String]) -> Bool
    
    /// Result handler closure type for processing scan results
    /// - Parameter result: The scan result containing image and text data
    public typealias ResultHandler = (DocumentScannerViewController.Result) -> Void
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoOutput = AVCaptureVideoDataOutput()
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue", qos: .background)
    private let didReadQueue = DispatchQueue(label: "didReadQueue", attributes: .concurrent)
    
    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        return view
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    private var didApplyOverlayMask: Bool = false
    private var _didRead: Bool = false
    private var didRead: Bool {
        get {
            return didReadQueue.sync { self._didRead }
        }
        set {
            didReadQueue.async(flags: .barrier) {
                self._didRead = newValue
            }
        }
    }
    
    private let maskView: DocumentMaskView
    private let instructionProvider: () -> String
    private var cancellables = Set<AnyCancellable>()
    private let documentBoundedSubject = CurrentValueSubject<Bool, Never>(false)
    private var maskViewHeightConstraint: NSLayoutConstraint!
        
    private var isDocumentBounded: Bool {
        get { documentBoundedSubject.value }
        set { documentBoundedSubject.send(newValue) }
    }
    
    
    /// Optional validation closure for determining if scanned readings are acceptable
    open var validator: Validator?
    /// Optional result handler closure called when document is successfully scanned
    open var resultHandler: ResultHandler?
    /// Delegate for handling scan results
    open weak var delegate: DocumentScannerViewControllerDelegate?
    
    /// Initializes the document scanner with required components
    /// - Parameters:
    ///   - maskView: Custom view that defines the document capture area
    ///   - instructionProvider: Autoclosure that returns instruction text for users
    ///   - validate: Optional validation closure for captured text
    public init(maskView: DocumentMaskView, instructionProvider: @escaping @autoclosure () -> String, validate: Validator? = nil) {
        self.maskView = maskView
        self.instructionProvider = instructionProvider
        super.init(nibName: nil, bundle: nil)
        self.validator = validate
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupSubscriptions()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
    }
    
    @objc private func sessionRuntimeError(notification: Notification) {
        print("AVCaptureSession runtime error:", notification)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestCameraPermissionIfNeeded { [weak self] granted in
            self?.startSessionIfNeeded()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSessionIfNeeded()
        cancellables.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: session)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
        print("Preview layer size: ", previewLayer.frame.size)
        if !didApplyOverlayMask {
            didApplyOverlayMask = true
            overlayView.applyCutout(rect: maskView.frame)
        }
    }
    
    private func startSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    private func stopSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    // MARK: - Setup
    
    private func requestCameraPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion(false)
            }
            
        @unknown default:
            break
        }
    }
    
    private func setupUI() {
        view.addSubview(previewView)
        view.addSubview(overlayView)
        view.addSubview(maskView)
        view.addSubview(instructionLabel)
        
        maskView.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        previewView.fillSuperview()
        overlayView.fillSuperview()
        
        maskViewHeightConstraint = maskView.heightAnchor.constraint(equalTo: maskView.widthAnchor, multiplier: 1/maskView.aspectRatio)
        
        NSLayoutConstraint.activate([
            maskView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            maskView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            maskView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2*16),
            maskViewHeightConstraint,
            
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 66+44),
            instructionLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -2*16)
        ])
        
        configureInstructionLabel()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Camera not available")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) { session.addInput(input) }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
    }
    
    private func configureInstructionLabel() {
        instructionLabel.text = instructionProvider()
    }
    
    private func setupSubscriptions() {
        documentBoundedSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] bounded in
                self?.maskView.update(documentBounded: bounded)
            }
            .store(in: &cancellables)
    }
}

private extension DocumentScannerViewController {
    func processBuffer(_ buffer: CMSampleBuffer) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        
        detectDocumentRectange(pixelBuffer: pixelBuffer) { [weak self] uiImage, processedBuffer, observation in
            self?.readText(in: uiImage) { [weak self] image, readings in
                guard let self else { return }
                if self.validator?(readings) ?? true {
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        guard let self else { return }
                        let cropped = self.cropImage(from: processedBuffer, using: observation)
                        DispatchQueue.main.async { [weak self] in
                            self?.handleReadings(readings, image: cropped)
                        }
                    }
                }
            }
        }
    }
    
    func detectDocumentRectange(pixelBuffer: CVPixelBuffer, completion: @escaping (UIImage, CVPixelBuffer, VNRectangleObservation) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: .init(block: { [weak self] in
            let request = VNDetectRectanglesRequest { [weak self] request, error in
                
                guard let self else { return }
                
                guard let observation = request.results?.first as? VNRectangleObservation else {
                    self.isDocumentBounded = false
                    return
                }
                
                DispatchQueue.main.async {
                    let isValid = self.isValidDocumentRectangle(
                        observation: observation,
                        in: self.previewLayer,
                        maskFrame: self.maskView.frame
                    )
                    
                    self.isDocumentBounded = true
                    
                    if isValid {
                        DispatchQueue.global(qos: .userInitiated).async {
                            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                            let uiImage = self.convertToUIImage(ciImage)
                            completion(uiImage, pixelBuffer, observation)
                        }
                    }
                }
            }
            
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }))
    }
    
    func readText(in image: UIImage, completion: @escaping (UIImage, [String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: .init(block: {
            guard let cgImage = image.cgImage else { return }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                let results: [String] = observations.map {
                    let text = $0.topCandidates(1).map { $0.string }.joined(separator: "\n")
                    return text
                }
                
                completion(image, results)
            }
            request.recognitionLanguages = ["en", "uz", "ru"]
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }))
    }
    
    func handleReadings(_ readings: [String], image: UIImage) {
        guard !didRead else { return }
        didRead = true
        
        self.playCameraCaptureSound()
        self.stopSessionIfNeeded()
        let result = Result(image: image, readings: readings)
        self.resultHandler?(result)
        self.delegate?.documentScanner(self, didScanWithResult: result)
    }
    
    func isValidDocumentRectangle(
        observation: VNRectangleObservation,
        in previewLayer: AVCaptureVideoPreviewLayer,
        maskFrame: CGRect,
        maxTiltAngle: CGFloat = 15.0,
        aspectRatioTolerance: CGFloat = 0.2,
        sizeTolerance: CGFloat = 0.2
    ) -> Bool {
        
        // 1. Convert corners to screen coordinates
        let boundingBox = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
        let topLeft = boundingBox.origin
        let topRight = CGPoint(x: boundingBox.maxX, y: boundingBox.minY)
        
        // 2. Calculate tilt angle (horizontal misalignment)
        let dx = topRight.x - topLeft.x
        let dy = topRight.y - topLeft.y
        let angleInDegrees = abs(atan2(dy, dx) * 180 / .pi)
        let isAligned = angleInDegrees <= maxTiltAngle
        
        // 3. Containment
        let isContained = maskFrame.contains(boundingBox)
        
        // 4. Aspect ratio comparison
        let observedAspectRatio = boundingBox.width / boundingBox.height
        let maskAspectRatio = maskFrame.width / maskFrame.height
        let aspectRatioDiff = abs(observedAspectRatio - maskAspectRatio) / maskAspectRatio
        let isAspectRatioValid = aspectRatioDiff <= aspectRatioTolerance
        
        // 5. Size proximity check (allow tolerance % difference)
        let widthDiff = abs(boundingBox.width - maskFrame.width) / maskFrame.width
        let heightDiff = abs(boundingBox.height - maskFrame.height) / maskFrame.height
        let isSizeClose = widthDiff <= sizeTolerance && heightDiff <= sizeTolerance
        
        return isAligned && isContained && isAspectRatioValid && isSizeClose
    }
    
    
    
    private func playCameraCaptureSound() { AudioServicesPlaySystemSound(SystemSoundID(1108)) }
}


extension DocumentScannerViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        processBuffer(sampleBuffer)
    }
}



// MARK: - Image helpers
fileprivate extension DocumentScannerViewController {
    func cropImage(from pixelBuffer: CVPixelBuffer, using observation: VNRectangleObservation) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageSize = ciImage.extent.size
        
        // Get the four corners of the detected rectangle
        let topLeft = observation.topLeft
        let topRight = observation.topRight
        let bottomLeft = observation.bottomLeft
        let bottomRight = observation.bottomRight
        
        // Expand the corners outward by a percentage (e.g., 5%)
        let expandFactor: CGFloat = 0.05
        let expandedCorners = expandCorners(
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight,
            expandFactor: expandFactor
        )
        
        // Convert normalized coordinates to image coordinates
        // Fix: Use correct coordinate conversion for Vision framework
        let corners = expandedCorners.map { corner in
            CGPoint(
                x: corner.x * imageSize.width,
                y: corner.y * imageSize.height  // Remove the (1 - corner.y) flip
            )
        }
        
        // Apply perspective correction
        var finalImage = applyPerspectiveCorrection(to: ciImage, corners: corners)
        
        // Apply proper orientation correction
        finalImage = applyOrientationCorrection(to: finalImage, shouldFlipHorizontally: false)
        
        return convertToUIImage(finalImage)
    }

    func expandCorners(
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomLeft: CGPoint,
        bottomRight: CGPoint,
        expandFactor: CGFloat
    ) -> [CGPoint] {
        
        // Calculate the center point of the rectangle
        let centerX = (topLeft.x + topRight.x + bottomLeft.x + bottomRight.x) / 4
        let centerY = (topLeft.y + topRight.y + bottomLeft.y + bottomRight.y) / 4
        let center = CGPoint(x: centerX, y: centerY)
        
        // Expand each corner outward from the center
        let expandedTopLeft = expandPointFromCenter(topLeft, center: center, factor: expandFactor)
        let expandedTopRight = expandPointFromCenter(topRight, center: center, factor: expandFactor)
        let expandedBottomLeft = expandPointFromCenter(bottomLeft, center: center, factor: expandFactor)
        let expandedBottomRight = expandPointFromCenter(bottomRight, center: center, factor: expandFactor)
        
        // Clamp to image bounds (0.0 to 1.0 for normalized coordinates)
        return [
            clampPoint(expandedTopLeft),
            clampPoint(expandedTopRight),
            clampPoint(expandedBottomLeft),
            clampPoint(expandedBottomRight)
        ]
    }

    func expandPointFromCenter(_ point: CGPoint, center: CGPoint, factor: CGFloat) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        return CGPoint(
            x: center.x + dx * (1 + factor),
            y: center.y + dy * (1 + factor)
        )
    }

    func clampPoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: max(0.0, min(1.0, point.x)),
            y: max(0.0, min(1.0, point.y))
        )
    }

    func applyPerspectiveCorrection(to image: CIImage, corners: [CGPoint]) -> CIImage {
        guard corners.count == 4 else { return image }
        
        // Create perspective correction filter
        let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection")!
        perspectiveFilter.setValue(image, forKey: kCIInputImageKey)
        
        // Set the four corners
        perspectiveFilter.setValue(CIVector(cgPoint: corners[0]), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[1]), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[2]), forKey: "inputBottomLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: corners[3]), forKey: "inputBottomRight")
        
        return perspectiveFilter.outputImage ?? image
    }

    func applyOrientationCorrection(to image: CIImage) -> CIImage {
        // Get current device orientation
        let deviceOrientation = UIDevice.current.orientation
        
        // Apply appropriate rotation (back to original logic)
        var correctedImage: CIImage
        switch deviceOrientation {
        case .portrait:
            correctedImage = image.oriented(.right)
        case .portraitUpsideDown:
            correctedImage = image.oriented(.left)
        case .landscapeLeft:
            correctedImage = image.oriented(.up)
        case .landscapeRight:
            correctedImage = image.oriented(.down)
        default:
            correctedImage = image.oriented(.right)
        }
        
        // Fix: Apply horizontal flip to correct the mirroring
        let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
        return correctedImage.transformed(by: flipTransform)
    }

    // Alternative: Apply horizontal flip only if needed
    func applyOrientationCorrection(to image: CIImage, shouldFlipHorizontally: Bool = true) -> CIImage {
        let deviceOrientation = UIDevice.current.orientation
        
        // Apply appropriate rotation
        var correctedImage: CIImage
        switch deviceOrientation {
        case .portrait:
            correctedImage = image.oriented(.right)
        case .portraitUpsideDown:
            correctedImage = image.oriented(.left)
        case .landscapeLeft:
            correctedImage = image.oriented(.up)
        case .landscapeRight:
            correctedImage = image.oriented(.down)
        default:
            correctedImage = image.oriented(.right)
        }
        
        // Apply horizontal flip if needed (common for front camera or mirrored preview)
        if shouldFlipHorizontally {
            let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
            correctedImage = correctedImage.transformed(by: flipTransform)
        }
        
        return correctedImage
    }

    func convertToUIImage(_ ciImage: CIImage) -> UIImage {
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage()
    }
}


