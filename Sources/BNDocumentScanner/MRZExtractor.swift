//
//  EnhancedMRZExtractor.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

public class MRZExtractor<T: MRZ> {
    public static func extractAndParseMRZ(from rawText: String) -> T? {
        let mrzLines = RawMRZExtractor.extractMRZ(from: rawText)
        debugPrint("Extracted mrzLines: \(mrzLines)")
        return try? T(from: mrzLines)
    }
}
