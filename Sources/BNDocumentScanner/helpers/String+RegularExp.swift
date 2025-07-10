//
//  String+Ext.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import Foundation

public extension String {
    func matches(_ pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    func extract(_ pattern: String) -> String? {
        if let range = self.range(of: pattern, options: .regularExpression) {
            return String(self[range])
        }
        return nil
    }

}
