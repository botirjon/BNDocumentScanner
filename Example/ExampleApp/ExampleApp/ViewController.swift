//
//  ViewController.swift
//  ExampleApp
//
//  Created by MAC-Nasridinov-B on 07/07/25.
//

import UIKit
import BNDocumentScanner

class ViewController: UIViewController {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scannerCoordinator = DocumentScannerCoordinator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

extension ViewController {
    func setupUI() {
        
        let overylayView = UIView()
        overylayView.backgroundColor = .black
        overylayView.alpha = 0.5
        view.addSubview(overylayView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        
        view.addSubview(imageView)
        view.addSubview(overylayView)
        view.addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        overylayView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overylayView.leftAnchor.constraint(equalTo: view.leftAnchor),
            overylayView.topAnchor.constraint(equalTo: view.topAnchor),
            overylayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overylayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        let front = UIButton(primaryAction: .init(title: "ID Front", handler: { _ in
            self.openCardFrontScanner()
        }))
        
        let back = UIButton(primaryAction: .init(title: "ID Back", handler: { _ in
            self.openCardBackScanner()
        }))
        
        let passport = UIButton(primaryAction: .init(title: "Passport", handler: { _ in
            self.openPassportScanner()
        }))
        
        stackView.addArrangedSubview(front)
        stackView.addArrangedSubview(back)
        stackView.addArrangedSubview(passport)
        
    }
    
    func openCardFrontScanner() {
        let scanner = DocumentScannerViewController(maskView: IDCardMaskView(side: .front), instructionProvider: "ID Front") { [weak self] readings in
            self?.validateIDCardFrontReading(readings) ?? false
        }
        scanner.delegate = self
        scanner.view.tag = 1
        
        scannerCoordinator.showScanner(scanner)
    }
    
    func openCardBackScanner() {
        let scanner = DocumentScannerViewController(maskView: IDCardMaskView(side: .back), instructionProvider: "ID Back") { [weak self] readings in
            self?.validateIDCardBackReading(readings) ?? false
        }
        scanner.delegate = self
        scanner.view.tag = 2
        scannerCoordinator.showScanner(scanner)
    }
    
    func openPassportScanner() {
        let scanner = DocumentScannerViewController(maskView: PassportMaskView(), instructionProvider: "Passport") { [weak self] readings in
            self?.validatePassportReading(readings) ?? false
        }
        scanner.delegate = self
        scanner.view.tag = 3
        scannerCoordinator.showScanner(scanner)
    }
    
    func validateIDCardFrontReading(_ readings: [String]) -> Bool {
        let joinedReadings = readings.joined(separator: "\n")
        print("Readings: \(joinedReadings)")
        guard readings.first(where: {
            $0.matches(DocumentTextPattern.documentNumber.rawValue)
        }) != nil else { return false }
        
        // TODO: - Compare with scanned document number
        return true
    }
    
    func validateIDCardBackReading(_ readings: [String]) -> Bool {
        let joinedReadings = readings.joined(separator: "\n")
        print("Readings: \(joinedReadings)")
        guard let mrz = MRZExtractor<UzbekistanIDCardMRZ>.extractAndParseMRZ(from: joinedReadings) else {
            return false
        }
        
        return mrz.isValid
    }
    
    func validatePassportReading(_ readings: [String]) -> Bool {
        let joinedReadings = readings.joined(separator: "\n")
        print("Readings: \(joinedReadings)")
        guard let mrz = MRZExtractor<UzbekistanPassportMRZ>.extractAndParseMRZ(from: joinedReadings) else {
            return false
        }
        
        return mrz.isValid
    }
}

extension ViewController: DocumentScannerViewControllerDelegate {
    func documentScanner(_ controller: DocumentScannerViewController, didScanWithResult result: DocumentScannerViewController.Result) {
        scannerCoordinator.dismissScanner()
        let scanResult: ScanResultViewController.Result
        switch controller.view.tag {
        case 1:
            guard let documentNumber = result.readings.first(where: {
                $0.matches(DocumentTextPattern.documentNumber.rawValue)
            }) else { return }
            
            scanResult = .idFront(image: result.image, documentNumber: documentNumber)
            
        case 2:
            let joinedReadings = result.readings.joined(separator: "\n")
            guard let mrz = MRZExtractor<UzbekistanIDCardMRZ>.extractAndParseMRZ(from: joinedReadings) else {
                return
            }
            
            scanResult = .mrz(image: result.image, mrz: mrz)
            
        case 3:
            let joinedReadings = result.readings.joined(separator: "\n")
            guard let mrz = MRZExtractor<UzbekistanPassportMRZ>.extractAndParseMRZ(from: joinedReadings) else {
                return
            }
            
            scanResult = .mrz(image: result.image, mrz: mrz)
            
        default:
            return
        }
        
        let resultVC = ScanResultViewController(result: scanResult)
        navigationController?.pushViewController(resultVC, animated: true)
    }
}



class DocumentScannerCoordinator: NSObject {
    
    private var scannerWindow: UIWindow?
    private var navigationController: UINavigationController?
    
    func showScanner(_ scanner: DocumentScannerViewController) {
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        
        scanner.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: makeBackButton())
        
        scannerWindow = UIWindow(windowScene: windowScene)
        scannerWindow?.windowLevel = UIWindow.Level.alert
        scannerWindow?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        
        // Create navigation controller
        navigationController = UINavigationController(rootViewController: scanner)
        navigationController?.modalPresentationStyle = .pageSheet
        
        scannerWindow?.rootViewController = navigationController
        scannerWindow?.isHidden = false
    }
    
    private func makeBackButton() -> UIView {
        let button = UIButton()
        button.tintColor = .white
        button.setImage(.init(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.frame = .init(x: -8, y: 0, width: 32, height: 24)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let wrapper = UIView(frame: .init(x: 0, y: 0, width: 32, height: 24))
        wrapper.addSubview(button)
        return wrapper
    }
    
    @objc private func backButtonTapped() {
        dismissScanner()
    }
    
    func dismissScanner() {
        scannerWindow?.isHidden = true
        scannerWindow = nil
        navigationController = nil
    }
}
