import Foundation
import UniformTypeIdentifiers

struct CSVImporter {
    
    enum CSVError: Error {
        case fileReadError
        case invalidFormat
        case missingColumns
    }
    
    static func parseCSV(url: URL) throws -> [Contact] {
        guard let content = try? String(contentsOf: url) else {
            throw CSVError.fileReadError
        }
        
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let headerRow = rows.first else {
            throw CSVError.invalidFormat
        }
        
        let headers = headerRow.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        guard let nameIndex = headers.firstIndex(of: "name"),
              let emailIndex = headers.firstIndex(of: "email") else {
            throw CSVError.missingColumns
        }
        
        var contacts: [Contact] = []
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let columns = parseCSVRow(row)
            if columns.count > max(nameIndex, emailIndex) {
                let name = columns[nameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let email = columns[emailIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if email.contains("@") {
                    contacts.append(Contact(name: name, email: email))
                }
            }
        }
        
        return contacts
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        return result
    }
}
