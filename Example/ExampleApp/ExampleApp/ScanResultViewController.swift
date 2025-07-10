//
//  ScanResultViewController.swift
//  ExampleApp
//
//  Created by MAC-Nasridinov-B on 10/07/25.
//

import UIKit
import BNDocumentScanner

final class ScanResultViewController: UIViewController {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    let result: Result
    enum Result {
        case idFront(image: UIImage, documentNumber: String)
        case mrz(image: UIImage, mrz: MRZ)
        
        var image: UIImage {
            switch self {
            case .idFront(image: let image, _):
                return image
                
            case .mrz(image: let image, _):
                return image
            }
        }
    }
    
    init(result: Result) {
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stackView.layoutIfNeeded()
        scrollView.contentSize.height = stackView.bounds.size.height
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        scrollView.contentInset.top = 100
        scrollView.contentInset.bottom = 50
    }
    
    private func setupContent() {
        let imageView = UIImageView(image: result.image)
        stackView.addArrangedSubview(imageView)
        
        switch result {
        case .idFront(_, documentNumber: let number):
            let v = KeyValueView()
            v.value = ("Номер документа", number)
            stackView.addArrangedSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                v.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            ])
            
        case .mrz(_, mrz: let mrz):
            let values = mrz.toKeyValuePairs()
            values.forEach { value in
                let v = KeyValueView()
                v.value = value
                stackView.addArrangedSubview(v)
                v.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalTo: stackView.widthAnchor)
                ])
            }
        }
    }
}

fileprivate class KeyValueView: UIStackView {
    private lazy var keyLabel: UILabel = {
       let label = UILabel()
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    private lazy var valueLabel: UILabel = {
       let label = UILabel()
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    var value: (String, String) = ("", "") {
        didSet {
            keyLabel.text = value.0
            valueLabel.text = value.1
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        distribution = .fill
        alignment = .center
        addArrangedSubview(keyLabel)
        addArrangedSubview(valueLabel)
        
        arrangedSubviews.forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                subview.widthAnchor.constraint(equalTo: self.widthAnchor)
            ])
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
