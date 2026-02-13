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
            // It's a formula – auto-close unclosed parentheses before storing
            var formula = String(input.dropFirst())
            let openCount = formula.filter { $0 == "(" }.count
            let closeCount = formula.filter { $0 == ")" }.count
            if openCount > closeCount {
                formula += String(repeating: ")", count: openCount - closeCount)
                input = "=" + formula
            }
            do {
                let result = try engine.evaluate(formula: formula, getCellValue: getCellValue)
                displayValue = result
            } catch {
                displayValue = "#ERROR"
                hasError = true
            }
        } else {
            // It's a plain value – strip leading zeros from numbers (e.g. "007" → "7")
            if let number = Double(input) {
                if number.truncatingRemainder(dividingBy: 1) == 0 && !input.contains(".") {
                    displayValue = String(format: "%.0f", number)
                } else {
                    displayValue = "\(number)"
                }
                input = displayValue
            } else {
                displayValue = input
            }
        }
    }
}
