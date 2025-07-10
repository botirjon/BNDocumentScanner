//
//  UzbekistanIDCardMRZ.swift
//  SQB-BUSINESS
//
//  Created by MAC-Nasridinov-B on 05/07/25.
//

import Foundation

// MARK: - Enhanced MRZ Parser
public struct UzbekistanIDCardMRZ: MRZ {
    public let documentType: String
    public let countryCode: String
    public let documentNumber: String
    public let documentNumberCheckDigit: String
    public let dateOfBirth: String
    public let dobCheckDigit: String
    public let sex: String
    public let expiryDate: String
    public let expiryCheckDigit: String
    public let nationality: String
    public let personalNumber: String
    public let personalNumberCheckDigit: String
    public let surname: String
    public let givenNames: String
    public let isValid: Bool
    public let rawMRZLines: [String]
    
    public init(from mrzLines: [String]) throws {
        self.rawMRZLines = mrzLines
        
        guard mrzLines.count >= 3 else {
            self.documentType = ""
            self.countryCode = ""
            self.documentNumber = ""
            self.documentNumberCheckDigit = ""
            self.dateOfBirth = ""
            self.dobCheckDigit = ""
            self.sex = ""
            self.expiryDate = ""
            self.expiryCheckDigit = ""
            self.nationality = ""
            self.personalNumber = ""
            self.personalNumberCheckDigit = ""
            self.surname = ""
            self.givenNames = ""
            self.isValid = false
            return
        }
        
        // Pad lines to ensure consistent length
        let line1 = mrzLines[0].padding(toLength: 30, withPad: "<", startingAt: 0)
        let line2 = mrzLines[1].padding(toLength: 30, withPad: "<", startingAt: 0)
        let line3 = mrzLines[2].padding(toLength: 30, withPad: "<", startingAt: 0)
        
        print("Parsing MRZ Lines:")
        print("Line 1: \(line1)")
        print("Line 2: \(line2)")
        print("Line 3: \(line3)")
        
        // Parse Line 1: IU + UZB + AD2904903 + 4 + 30912955910015 + <
        // Document type (2) + Nationality (3) + Document number (9) + Check digit (1) + Personal ID (14) + padding
        self.documentType = String(line1.prefix(2)) // IU
        self.countryCode = String(line1.dropFirst(2).prefix(3)) // UZB (nationality)
        self.documentNumber = String(line1.dropFirst(5).prefix(9)).replacingOccurrences(of: "<", with: "") // AD2904903
        self.documentNumberCheckDigit = String(line1.dropFirst(14).prefix(1)) // 4
        self.personalNumber = String(line1.dropFirst(15).prefix(14)).replacingOccurrences(of: "<", with: "") // 30912955910015
        
        // Parse Line 2: 951209 + 2 + M + 330329 + 6 + UZB + UZB + < + 0
        // Date of birth (6) + Check digit (1) + Sex (1) + Expiry date (6) + Check digit (1) + Issuing country (3) + ? (3) + padding + final check digit
        let dobString = String(line2.prefix(6)) // 951209
        self.dateOfBirth = UzbekistanIDCardMRZ.formatDate(dobString)
        self.dobCheckDigit = String(line2.dropFirst(6).prefix(1)) // 2
        self.sex = String(line2.dropFirst(7).prefix(1)) // M
        let expiryString = String(line2.dropFirst(8).prefix(6)) // 330329
        self.expiryDate = UzbekistanIDCardMRZ.formatDate(expiryString)
        self.expiryCheckDigit = String(line2.dropFirst(14).prefix(1)) // 6
        self.nationality = String(line2.dropFirst(15).prefix(3)) // UZB (issuing country)
        
        // Second UZB field - might be nationality or issuing authority
        let secondCountryCode = String(line2.dropFirst(18).prefix(3)) // UZB
        self.personalNumberCheckDigit = String(line2.dropFirst(29).prefix(1)) // 0 (final check digit)
        
        // Parse Line 3: Names
        let namesLine = line3.replacingOccurrences(of: "<", with: " ")
        let nameComponents = namesLine.components(separatedBy: "  ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if nameComponents.count >= 2 {
            self.surname = nameComponents[0]
            self.givenNames = nameComponents.dropFirst().joined(separator: " ")
        } else if nameComponents.count == 1 {
            self.surname = nameComponents[0]
            self.givenNames = ""
        } else {
            self.surname = ""
            self.givenNames = ""
        }
        
        // Validate the MRZ
        self.isValid = Self.validateMRZ(documentNumber: documentNumber, dateOfBirth: dateOfBirth, surname: surname, countryCode: countryCode, sex: sex)
    }
    
    
    private static func validateMRZ(
        documentNumber: String,
        dateOfBirth: String,
        surname: String,
        countryCode: String,
        sex: String,
    ) -> Bool {
        // Basic validation checks
        guard !documentNumber.isEmpty,
              !dateOfBirth.isEmpty,
              !surname.isEmpty,
              countryCode == "UZB",
              ["M", "F"].contains(sex) else {
            return false
        }
        
        // Additional validation can be added here (check digits, date ranges, etc.)
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
    
    // MARK: - Check Digit Validation
    private static func calculateCheckDigit(_ input: String) -> Int {
        let weights = [7, 3, 1]
        var sum = 0
        
        for (index, char) in input.enumerated() {
            let value: Int
            if char.isNumber {
                value = Int(String(char)) ?? 0
            } else if char == "<" {
                value = 0
            } else {
                value = Int(char.asciiValue ?? 0) - 55 // A=10, B=11, etc.
            }
            sum += value * weights[index % 3]
        }
        
        return sum % 10
    }
    
    public func printDetails() {
        print("=== Uzbekistan ID Card Details ===")
        print("Document Type: \(documentType)")
        print("Nationality: \(countryCode)")
        print("Document Number: \(documentNumber)")
        print("Document Number Check Digit: \(documentNumberCheckDigit)")
        print("Personal ID Number: \(personalNumber)")
        print("Surname: \(surname)")
        print("Given Names: \(givenNames)")
        print("Date of Birth: \(dateOfBirth)")
        print("DOB Check Digit: \(dobCheckDigit)")
        print("Sex: \(sex)")
        print("Expiry Date: \(expiryDate)")
        print("Expiry Check Digit: \(expiryCheckDigit)")
        print("Issuing Country: \(nationality)")
        print("Final Check Digit: \(personalNumberCheckDigit)")
        print("Valid: \(isValid)")
        print("Raw MRZ Lines:")
        for (index, line) in rawMRZLines.enumerated() {
            print("  \(index + 1): \(line)")
        }
    }
    
    public func toKeyValuePairs() -> [(key: String, value: String)] {
        return [
            ("Document Type", documentType),
            ("Nationality", countryCode),
            ("Document Number", documentNumber),
            ("Document Number Check Digit", documentNumberCheckDigit),
            ("Personal ID Number", personalNumber),
            ("Surname", surname),
            ("Given Names", givenNames),
            ("Date of Birth", dateOfBirth),
            ("DOB Check Digit", dobCheckDigit),
            ("Sex", sex),
            ("Expiry Date", expiryDate),
            ("Expiry Check Digit", expiryCheckDigit),
            ("Issuing Country", nationality),
            ("Final Check Digit", personalNumberCheckDigit),
            ("Valid", "\(isValid)")
        ]
    }
}
