//
//  UzbekistanPassportMRZ.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import Foundation

// MARK: - Uzbekistan Passport MRZ Parser (TD3 Format)
public struct UzbekistanPassportMRZ: MRZ {
    public let documentType: String
    public let countryCode: String
    public let surname: String
    public let givenNames: String
    public var documentNumber: String
    public let documentNumberCheckDigit: String
    public let nationality: String
    public let dateOfBirth: String
    public let dobCheckDigit: String
    public let sex: String
    public let expiryDate: String
    public let expiryCheckDigit: String
    public let personalNumber: String
    public let personalNumberCheckDigit: String
    public let finalCheckDigit: String
    public let isValid: Bool
    public let rawMRZLines: [String]
    
    public init(from mrzLines: [String]) throws {
        self.rawMRZLines = mrzLines
        
        guard mrzLines.count >= 2 else {
            self.documentType = ""
            self.countryCode = ""
            self.surname = ""
            self.givenNames = ""
            self.documentNumber = ""
            self.documentNumberCheckDigit = ""
            self.nationality = ""
            self.dateOfBirth = ""
            self.dobCheckDigit = ""
            self.sex = ""
            self.expiryDate = ""
            self.expiryCheckDigit = ""
            self.personalNumber = ""
            self.personalNumberCheckDigit = ""
            self.finalCheckDigit = ""
            self.isValid = false
            return
        }
        
        // Pad lines to ensure consistent length (TD3 format is 44 characters)
        let line1 = mrzLines[0].padding(toLength: 44, withPad: "<", startingAt: 0)
        let line2 = mrzLines[1].padding(toLength: 44, withPad: "<", startingAt: 0)
        
        print("Parsing Passport MRZ Lines:")
        print("Line 1: \(line1)")
        print("Line 2: \(line2)")
        
        // Parse Line 1: P< + UZB + Names (surname<<givennames)
        // Document type (1) + < (1) + Country code (3) + Names (39)
        self.documentType = String(line1.prefix(1)) // P
        self.countryCode = String(line1.dropFirst(2).prefix(3)) // UZB
        
        // Parse names from position 5 onwards
        let namesSection = String(line1.dropFirst(5))
        let nameComponents = namesSection.components(separatedBy: "<<")
        
        if nameComponents.count >= 2 {
            self.surname = nameComponents[0].replacingOccurrences(of: "<", with: "")
            self.givenNames = nameComponents[1].replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
        } else {
            // If no << separator, assume it's all surname
            self.surname = namesSection.replacingOccurrences(of: "<", with: "")
            self.givenNames = ""
        }
        
        // Parse Line 2: Passport number (9) + Check digit (1) + Nationality (3) + DOB (6) + Check digit (1) + Sex (1) + Expiry (6) + Check digit (1) + Personal number (14) + Check digit (1) + Final check digit (1)
        self.documentNumber = String(line2.prefix(9)).replacingOccurrences(of: "<", with: "") // ABO7336497
        self.documentNumberCheckDigit = String(line2.dropFirst(9).prefix(1)) // 7 (but seems like part of passport number)
        self.nationality = String(line2.dropFirst(10).prefix(3)) // UZB
        
        let dobString = String(line2.dropFirst(13).prefix(6)) // 950404
        self.dateOfBirth = UzbekistanPassportMRZ.formatDate(dobString)
        self.dobCheckDigit = String(line2.dropFirst(19).prefix(1)) // 0
        self.sex = String(line2.dropFirst(20).prefix(1)) // M
        
        let expiryString = String(line2.dropFirst(21).prefix(6)) // 250812
        self.expiryDate = UzbekistanPassportMRZ.formatDate(expiryString)
        self.expiryCheckDigit = String(line2.dropFirst(27).prefix(1)) // 0
        
        self.personalNumber = String(line2.dropFirst(28).prefix(14)).replacingOccurrences(of: "<", with: "") // 30404954170041
        self.personalNumberCheckDigit = String(line2.dropFirst(42).prefix(1)) // 4
        self.finalCheckDigit = String(line2.dropFirst(43).prefix(1)) // 4
        
        // Validate the MRZ
        self.isValid = Self.validateMRZ(documentNumber: documentNumber, dateOfBirth: dateOfBirth, surname: surname, countryCode: countryCode, documentType: documentType, sex: sex)
    }
    
    private static func validateMRZ(
        documentNumber: String,
        dateOfBirth: String,
        surname: String,
        countryCode: String,
        documentType: String,
        sex: String
    ) -> Bool {
        // Basic validation checks
        guard !documentNumber.isEmpty,
              !dateOfBirth.isEmpty,
              !surname.isEmpty,
              countryCode == "UZB",
              documentType == "P",
              ["M", "F"].contains(sex) else {
            return false
        }
        
        return true
    }
    
    private static func formatDate(_ dateString: String) -> String {
        let onlyDigits = CharacterSet.decimalDigits.isSuperset(of: CharacterSet.init(charactersIn: dateString))
        guard dateString.count == 6 && onlyDigits else { return dateString }
        let year = String(dateString.prefix(2))
        let month = String(dateString.dropFirst(2).prefix(2))
        let day = String(dateString.dropFirst(4).prefix(2))
        
        // Assume years 00-30 are 2000-2030, 31-99 are 1931-1999
        let fullYear = Int(year)! <= 30 ? "20\(year)" : "19\(year)"
        
        return "\(day)/\(month)/\(fullYear)"
    }
    
    public func printDetails() {
        print("=== Uzbekistan Passport Details ===")
        print("Document Type: \(documentType)")
        print("Country Code: \(countryCode)")
        print("Surname: \(surname)")
        print("Given Names: \(givenNames)")
        print("Passport Number: \(documentNumber)")
        print("Passport Check Digit: \(documentNumberCheckDigit)")
        print("Nationality: \(nationality)")
        print("Date of Birth: \(dateOfBirth)")
        print("DOB Check Digit: \(dobCheckDigit)")
        print("Sex: \(sex)")
        print("Expiry Date: \(expiryDate)")
        print("Expiry Check Digit: \(expiryCheckDigit)")
        print("Personal Number: \(personalNumber)")
        print("Personal Check Digit: \(personalNumberCheckDigit)")
        print("Final Check Digit: \(finalCheckDigit)")
        print("Valid: \(isValid)")
        print("Raw MRZ Lines:")
        for (index, line) in rawMRZLines.enumerated() {
            print("  \(index + 1): \(line)")
        }
    }
    
    public func toKeyValuePairs() -> [(key: String, value: String)] {
        [
            ("Document Type", documentType),
            ("Country Code", countryCode),
            ("Surname", surname),
            ("Given Names", givenNames),
            ("Passport Number", documentNumber),
            ("Passport Check Digit", documentNumberCheckDigit),
            ("Nationality", nationality),
            ("Date of Birth", dateOfBirth),
            ("DOB Check Digit", dobCheckDigit),
            ("Sex", sex),
            ("Expiry Date", expiryDate),
            ("Expiry Check Digit", expiryCheckDigit),
            ("Personal Number", personalNumber),
            ("Personal Check Digit", personalNumberCheckDigit),
            ("Final Check Digit", finalCheckDigit),
            ("Valid", "\(isValid)")
        ]
    }
}
