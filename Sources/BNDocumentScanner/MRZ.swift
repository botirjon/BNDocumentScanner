//
//  MRZ.swift
//  BNDocumentScanner
//
//  Created by MAC-Nasridinov-B on 07/07/25.
//

import Foundation

public protocol MRZ {
    var countryCode: String { get }
    var documentNumber: String { get }
    var dateOfBirth: String { get }
    var sex: String { get }
    var expiryDate: String { get }
    var nationality: String { get }
    var personalNumber: String { get }
    var surname: String { get }
    var givenNames: String { get }
    var isValid: Bool { get }
    var rawMRZLines: [String] { get }
    
    init(from mrzLines: [String]) throws
    func toKeyValuePairs() -> [(key: String, value: String)]
}
