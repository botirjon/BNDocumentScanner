//
//  RawMRZExtractor.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import Foundation

class RawMRZExtractor {
    
    /// Extracts MRZ lines from the raw scanned text
    static func extractMRZ(from rawText: String) -> [String] {
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var mrzLines: [String] = []
        
        // Look for MRZ pattern indicators
        for (index, line) in lines.enumerated() {
            if isMRZLine(line) {
                // Found first MRZ line, collect consecutive MRZ lines
                mrzLines = collectConsecutiveMRZLines(from: lines, startingAt: index)
                break
            }
        }
        
        return mrzLines
    }
    
    /// Checks if a line appears to be part of MRZ
    private static func isMRZLine(_ line: String) -> Bool {
        // MRZ characteristics:
        // - Contains mostly uppercase letters, numbers, and < symbols
        // - Usually 30 characters long (TD1 format)
        // - Contains patterns like country codes, document numbers, etc.
        
        let patterns: [DocumentTextPattern] = [
            .passportMRZLine1,
            .passportMRZLine2,
            .idCardMRZLine1,
            .idCardMRZLine2,
            .idCardMRZLine3
        ]
        
        let regexs = patterns.compactMap { try? $0.regex() }
        
        
        
        var isMRZ = false
        for regex in regexs {
            let range = NSRange(location: 0, length: line.count)
            // Check if line matches MRZ pattern and has reasonable length
            if regex.firstMatch(in: line, range: range) != nil {
                isMRZ = isMRZ || (line.count >= 25 && line.count <= 44)
            }
        }

        return isMRZ
    }
    
    /// Collects consecutive MRZ lines starting from a given index
    private static func collectConsecutiveMRZLines(from lines: [String], startingAt startIndex: Int) -> [String] {
        var mrzLines: [String] = []
        
        for i in startIndex..<lines.count {
            let line = lines[i]
            if isMRZLine(line) {
                mrzLines.append(line)
            } else if !mrzLines.isEmpty {
                // Stop if we hit a non-MRZ line after collecting MRZ lines
                break
            }
        }
        
        return mrzLines
    }
}
