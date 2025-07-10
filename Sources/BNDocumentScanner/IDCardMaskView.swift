//
//  IDCardMaskView.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import UIKit

public final class IDCardMaskView: UIView, DocumentMaskView {
    public var aspectRatio: CGFloat { 375 / 240 }
    
    let side: DocumentSide
    
    private lazy var imageView: UIImageView = {
        let image = Self.maskImage(for: side)?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public init(side: DocumentSide) {
        self.side = side
        super.init(frame: .zero)
        tintColor = .white
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        imageView.tintColor = tintColor
    }
    
    private static func maskImage(for side: DocumentSide) -> UIImage? {
        switch side {
        case .front:
            UIImage(named: "img.id-card-mask.front", in: Bundle.documentScanner, with: nil)
        case .back:
            UIImage(named: "img.id-card-mask.back", in: Bundle.documentScanner, with: nil)
        }
    }
    
    public func update(documentBounded: Bool) {
        tintColor = documentBounded ? .green : .white
    }
}
