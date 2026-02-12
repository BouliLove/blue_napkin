import Foundation

enum FormulaError: Error {
    case invalidFormula
    case invalidCellReference
    case divisionByZero
    case circularReference
    case invalidOperator
    case invalidFunction
    case invalidRange
}

class FormulaEngine {
    func evaluate(formula: String, getCellValue: @escaping (Int, Int) -> String) throws -> String {
        // Auto-close unclosed parentheses
        let open = formula.filter { $0 == "(" }.count
        let close = formula.filter { $0 == ")" }.count
        let balanced = open > close ? formula + String(repeating: ")", count: open - close) : formula

        // First process functions (SUM, PRODUCT, AVERAGE)
        var processedFormula = try processFunctions(formula: balanced, getCellValue: getCellValue)

        // Then replace any remaining cell references
        processedFormula = try replaceCellReferences(formula: processedFormula, getCellValue: getCellValue)

        // Finally evaluate the expression
        let result = try evaluateExpression(processedFormula)
        return formatResult(result)
    }

    private func processFunctions(formula: String, getCellValue: @escaping (Int, Int) -> String) throws -> String {
        var result = formula

        // Match function calls like SUM(A1:A10), AVERAGE(B1:B5), MIN(A1:A3), etc.
        let pattern = "(SUM|PRODUCT|AVERAGE|MIN|MAX|COUNT|ROUND|ABS)\\s*\\(([^)]+)\\)"
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        // Process functions in reverse order to maintain string indices
        let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let functionRange = Range(match.range(at: 1), in: result),
                  let argsRange = Range(match.range(at: 2), in: result) else {
                continue
            }

            let functionName = String(result[functionRange]).uppercased()
            let args = String(result[argsRange])

            // Evaluate the function
            let functionResult = try evaluateFunction(functionName: functionName, args: args, getCellValue: getCellValue)

            // Replace the function call with the result
            let fullRange = match.range
            if let swiftRange = Range(fullRange, in: result) {
                result.replaceSubrange(swiftRange, with: String(functionResult))
            }
        }

        return result
    }

    private func evaluateFunction(functionName: String, args: String, getCellValue: @escaping (Int, Int) -> String) throws -> Double {
        // Split on semicolons (for ROUND's second arg) then commas within each part
        let semiParts = args.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }

        // Parse the main arguments (first semicolon segment, or all if no semicolons)
        let mainArgs = semiParts[0]
        let argList = mainArgs.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var values: [Double] = []

        for arg in argList {
            if arg.contains(":") {
                let rangeValues = try parseRange(range: arg, getCellValue: getCellValue)
                values.append(contentsOf: rangeValues)
            } else if let num = Double(arg) {
                // Plain numeric literal
                values.append(num)
            } else {
                let cellValue = try parseSingleCell(cell: arg, getCellValue: getCellValue)
                values.append(cellValue)
            }
        }

        // Apply the function
        switch functionName {
        case "SUM":
            return values.reduce(0, +)
        case "PRODUCT":
            return values.isEmpty ? 0 : values.reduce(1, *)
        case "AVERAGE":
            return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        case "MIN":
            guard let result = values.min() else { return 0 }
            return result
        case "MAX":
            guard let result = values.max() else { return 0 }
            return result
        case "COUNT":
            return Double(values.count)
        case "ABS":
            guard let first = values.first else { return 0 }
            return abs(first)
        case "ROUND":
            guard let first = values.first else { return 0 }
            let places = semiParts.count > 1 ? (Int(semiParts[1].trimmingCharacters(in: .whitespaces)) ?? 0) : 0
            let multiplier = pow(10.0, Double(places))
            return (first * multiplier).rounded() / multiplier
        default:
            throw FormulaError.invalidFunction
        }
    }

    private func parseRange(range: String, getCellValue: @escaping (Int, Int) -> String) throws -> [Double] {
        let parts = range.split(separator: ":").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else {
            throw FormulaError.invalidRange
        }

        let (startRow, startCol) = try parseCellReference(parts[0])
        let (endRow, endCol) = try parseCellReference(parts[1])

        var values: [Double] = []

        // Handle both row ranges (A1:A10) and rectangular ranges (A1:B10)
        for row in min(startRow, endRow)...max(startRow, endRow) {
            for col in min(startCol, endCol)...max(startCol, endCol) {
                let cellValue = getCellValue(row, col)
                if let numValue = Double(cellValue), !cellValue.isEmpty {
                    values.append(numValue)
                } else if !cellValue.isEmpty {
                    // Try to handle non-numeric values
                    values.append(0)
                }
            }
        }

        return values
    }

    private func parseSingleCell(cell: String, getCellValue: @escaping (Int, Int) -> String) throws -> Double {
        let (row, col) = try parseCellReference(cell)
        let cellValue = getCellValue(row, col)

        if let numValue = Double(cellValue), !cellValue.isEmpty {
            return numValue
        } else {
            return 0
        }
    }

    private func parseCellReference(_ reference: String) throws -> (row: Int, col: Int) {
        let pattern = "^([A-Z]+)([0-9]+)$"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(reference.startIndex..., in: reference)

        guard let match = regex.firstMatch(in: reference, options: [], range: nsRange),
              let columnRange = Range(match.range(at: 1), in: reference),
              let rowRange = Range(match.range(at: 2), in: reference) else {
            throw FormulaError.invalidCellReference
        }

        let columnStr = String(reference[columnRange])
        let rowStr = String(reference[rowRange])

        guard let row = Int(rowStr), row > 0 else {
            throw FormulaError.invalidCellReference
        }

        let column = columnNameToIndex(columnStr)
        return (row - 1, column)
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

        // Validate before passing to NSExpression. NSExpression(format:) throws
        // ObjC exceptions on invalid input that Swift do/catch cannot intercept.
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/()eE")
        guard cleanExpression.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              !cleanExpression.isEmpty,
              cleanExpression.rangeOfCharacter(from: .decimalDigits) != nil else {
            throw FormulaError.invalidFormula
        }

        // Convert integer literals to doubles so NSExpression uses floating-point
        // division (e.g. 7/2 → 7.0/2.0 = 3.5 instead of integer 3).
        let floatExpression = cleanExpression.replacingOccurrences(
            of: "(?<![.\\d])(\\d+)(?![.\\d])",
            with: "$1.0",
            options: .regularExpression
        )

        let expr = NSExpression(format: floatExpression)
        if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
            let value = result.doubleValue
            if value.isInfinite {
                throw FormulaError.divisionByZero
            }
            return value
        } else {
            throw FormulaError.invalidFormula
        }
    }

    /// Extract all cell references from a formula string as (row, col) pairs.
    func dependencies(from formula: String) -> [(row: Int, col: Int)] {
        let pattern = "([A-Z]+)([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let matches = regex.matches(in: formula, options: [], range: NSRange(formula.startIndex..., in: formula))
        var refs: [(row: Int, col: Int)] = []
        for match in matches {
            guard let colRange = Range(match.range(at: 1), in: formula),
                  let rowRange = Range(match.range(at: 2), in: formula),
                  let rowNum = Int(String(formula[rowRange])), rowNum > 0 else { continue }
            let col = columnNameToIndex(String(formula[colRange]))
            refs.append((rowNum - 1, col))
        }
        return refs
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
