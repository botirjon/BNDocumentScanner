//
//  DocumentMaskView.swift
//  BNDocumentScanner
//
//  Created by MAC-Nasridinov-B on 07/07/25.
//

import UIKit

public protocol DocumentMaskView: UIView {
    var aspectRatio: CGFloat { get }
    func update(documentBounded: Bool)
}

public extension DocumentMaskView {
    func update(documentBounded: Bool) {}
}
