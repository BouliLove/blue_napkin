import Foundation

class CellModel: ObservableObject, Identifiable {
    let id = UUID()
    let row: Int
    let column: Int

    @Published var input: String = ""
    @Published var displayValue: String = ""
    @Published var hasError: Bool = false

    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    func evaluate(using engine: FormulaEngine, getCellValue: @escaping (Int, Int) -> String) {
        hasError = false

        if input.isEmpty {
            displayValue = ""
            return
        }

        if input.hasPrefix("=") {
            // It's a formula
            let formula = String(input.dropFirst())
            do {
                let result = try engine.evaluate(formula: formula, getCellValue: getCellValue)
                displayValue = result
            } catch {
                displayValue = "#ERROR"
                hasError = true
            }
        } else {
            // It's a plain value
            displayValue = input
        }
    }

    var columnName: String {
        var name = ""
        var col = column
        while col >= 0 {
            name = String(UnicodeScalar(65 + (col % 26))!) + name
            col = col / 26 - 1
            if col < 0 { break }
        }
        return name
    }

    var cellReference: String {
        return "\(columnName)\(row + 1)"
    }
}
