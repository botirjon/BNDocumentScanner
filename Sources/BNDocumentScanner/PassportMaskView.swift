//
//  PassportMaskView.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import UIKit

public final class PassportMaskView: UIView, DocumentMaskView {
    public var aspectRatio: CGFloat { 375 / 528 }
    
    private lazy var imageView: UIImageView = {
        let image = Self.maskImage?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
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
    
    private static var maskImage: UIImage? {
        UIImage(named: "img.passport-mask")
    }
    
    public func update(documentBounded: Bool) {
        tintColor = documentBounded ? .green : .white
    }
}
