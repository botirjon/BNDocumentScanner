//
//  Bundle+Ext.swift
//  BNDocumentScanner
//
//  Created by MAC-Nasridinov-B on 10/07/25.
//

import Foundation

extension Bundle {
    static var documentScanner: Bundle {
        // For Swift Package Manager
#if SWIFT_PACKAGE
        return Bundle.module
#else
        // For regular framework/app bundle
        return Bundle(for: DocumentScannerViewController.self)
#endif
    }
}
