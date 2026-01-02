import Foundation

enum FormulaError: Error {
    case invalidFormula
    case invalidCellReference
    case divisionByZero
    case circularReference
    case invalidOperator
}

class FormulaEngine {
    func evaluate(formula: String, getCellValue: @escaping (Int, Int) -> String) throws -> String {
        let processedFormula = try replaceCellReferences(formula: formula, getCellValue: getCellValue)
        let result = try evaluateExpression(processedFormula)
        return formatResult(result)
    }

    private func replaceCellReferences(formula: String, getCellValue: @escaping (Int, Int) -> String) throws -> String {
        var result = formula

        // Match cell references like A1, B2, etc.
        let pattern = "([A-Z]+)([0-9]+)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: formula, options: [], range: NSRange(formula.startIndex..., in: formula))

        // Replace in reverse order to maintain string indices
        for match in matches.reversed() {
            guard let columnRange = Range(match.range(at: 1), in: formula),
                  let rowRange = Range(match.range(at: 2), in: formula) else {
                continue
            }

            let columnStr = String(formula[columnRange])
            let rowStr = String(formula[rowRange])

            guard let row = Int(rowStr), row > 0 else {
                throw FormulaError.invalidCellReference
            }

            let column = columnNameToIndex(columnStr)
            let cellValue = getCellValue(row - 1, column)

            // Convert cell value to number or keep as is
            let valueToReplace = cellValue.isEmpty ? "0" : cellValue

            let fullRange = match.range
            if let swiftRange = Range(fullRange, in: formula) {
                result.replaceSubrange(swiftRange, with: valueToReplace)
            }
        }

        return result
    }

    private func columnNameToIndex(_ name: String) -> Int {
        var index = 0
        for (i, char) in name.uppercased().enumerated() {
            let position = name.count - i - 1
            let value = Int(char.unicodeScalars.first!.value) - 65
            index += value * Int(pow(26.0, Double(position)))
        }
        return index
    }

    private func evaluateExpression(_ expression: String) throws -> Double {
        // Clean up the expression
        let cleanExpression = expression.replacingOccurrences(of: " ", with: "")

        // Use NSExpression for basic math evaluation
        // This handles +, -, *, /, parentheses, and numbers
        do {
            let expr = NSExpression(format: cleanExpression)
            if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
                let value = result.doubleValue
                if value.isInfinite {
                    throw FormulaError.divisionByZero
                }
                return value
            } else {
                throw FormulaError.invalidFormula
            }
        } catch {
            throw FormulaError.invalidFormula
        }
    }

    private func formatResult(_ value: Double) -> String {
        // If it's a whole number, display without decimals
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            // Otherwise, show up to 6 decimal places, removing trailing zeros
            return String(format: "%g", value)
        }
    }
}
