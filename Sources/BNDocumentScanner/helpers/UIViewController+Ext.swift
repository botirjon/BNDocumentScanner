//
//  UIViewController+Ext.swift
//  BNDocumentScanner
//
//  Created by MAC-Nasridinov-B on 07/07/25.
//

import UIKit

extension UIViewController {
    
    var isModal: Bool {
        
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController
        
        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
    
    func close(animated: Bool = true, completion: (() -> Void)? = nil) {
        if isModal {
            dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: animated)
            completion?()
        }
    }
}
