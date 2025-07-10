//
//  DocumentTextPattern.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import Foundation

public enum DocumentTextPattern: String, CaseIterable {
    case documentNumber = "^[A-Z]{2}\\d{7}$"
    case passportMRZLine1 = "(P[A-Z0-9<]{1})([A-Z]{3})([A-Z0-9<]{39})"
    case passportMRZLine2 = "([A-Z0-9<]{9})([0-9]{1})([A-Z]{3})([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{14})([0-9]{1})([0-9]{1})"
    case idCardMRZLine1 = "([A|C|I][A-Z0-9<]{1})([A-Z]{3})([A-Z0-9<]{9})([0-9]{1})([A-Z0-9<]{15})"
    case idCardMRZLine2 = "([0-9]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})([0-9]{1})([A-Z]{3})([A-Z0-9<]{11})([0-9]{1})"
    case idCardMRZLine3 = "([A-Z0-9<]{30})"
}

public extension DocumentTextPattern {
    func regex() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: rawValue)
    }
}

