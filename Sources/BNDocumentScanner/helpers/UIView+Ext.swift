//
//  UIView+Ext.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import UIKit

extension UIView {
    func applyCutout(rect: CGRect) {
        let path = UIBezierPath(rect: self.bounds)
        let cutout = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        path.append(cutout)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd

        // Apply mask to self (dimmed view)
        self.layer.mask = maskLayer
    }
    
    func fillSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
}
