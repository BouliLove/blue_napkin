import Foundation
import Testing
@testable import BlueNapkin

// MARK: - Helpers

/// Helper to build a mock grid and evaluate formulas against it.
struct TestGrid {
    var cells: [String: String] = [:]
    let engine = FormulaEngine()

    /// Set a cell value. Column is a letter (e.g. "A"), row is 1-indexed.
    mutating func set(_ col: String, _ row: Int, _ value: String) {
        let colIndex = columnLetterToIndex(col)
        cells["\(row - 1),\(colIndex)"] = value
    }

    func eval(_ formula: String) throws -> String {
        return try engine.evaluate(formula: formula) { row, col in
            cells["\(row),\(col)"] ?? ""
        }
    }

    private func columnLetterToIndex(_ letter: String) -> Int {
        var index = 0
        for (i, char) in letter.uppercased().enumerated() {
            let position = letter.count - i - 1
            let value = Int(char.unicodeScalars.first!.value) - 65
            index += value * Int(pow(26.0, Double(position)))
        }
        return index
    }
}

// MARK: - Basic Arithmetic

@Suite("Basic Arithmetic")
struct ArithmeticTests {
    @Test func addition() throws {
        let grid = TestGrid()
        #expect(try grid.eval("5+3") == "8")
    }

    @Test func subtraction() throws {
        let grid = TestGrid()
        #expect(try grid.eval("10-3") == "7")
    }

    @Test func multiplication() throws {
        let grid = TestGrid()
        #expect(try grid.eval("10*2") == "20")
    }

    @Test func division() throws {
        let grid = TestGrid()
        #expect(try grid.eval("10/2") == "5")
    }

    @Test func parentheses() throws {
        let grid = TestGrid()
        #expect(try grid.eval("(5+3)*2") == "16")
    }

    @Test func nestedParentheses() throws {
        let grid = TestGrid()
        #expect(try grid.eval("((2+3)*4)/2") == "10")
    }

    @Test func decimalResult() throws {
        let grid = TestGrid()
        #expect(try grid.eval("7/2") == "3.5")
    }

    @Test func operatorPrecedence() throws {
        let grid = TestGrid()
        #expect(try grid.eval("1+2*3") == "7")
    }

    @Test func multipleOperators() throws {
        let grid = TestGrid()
        #expect(try grid.eval("2+3*4") == "14")
    }
}

// MARK: - Result Formatting

@Suite("Result Formatting")
struct FormattingTests {
    @Test func wholeNumberHasNoDecimals() throws {
        let grid = TestGrid()
        #expect(try grid.eval("4/2") == "2")
    }

    @Test func decimalResultFormatted() throws {
        let grid = TestGrid()
        #expect(try grid.eval("1/3") == "0.333333")
    }

    @Test func largeWholeNumber() throws {
        let grid = TestGrid()
        #expect(try grid.eval("1000*1000") == "1000000")
    }
}

// MARK: - Cell References

@Suite("Cell References")
struct CellReferenceTests {
    @Test func singleCellReference() throws {
        var grid = TestGrid()
        grid.set("A", 1, "42")
        #expect(try grid.eval("A1") == "42")
    }

    @Test func cellReferenceAddition() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("B", 1, "20")
        #expect(try grid.eval("A1+B1") == "30")
    }

    @Test func cellReferenceWithConstant() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        #expect(try grid.eval("A1*3") == "15")
    }

    @Test func cellReferenceComplex() throws {
        var grid = TestGrid()
        grid.set("A", 1, "100")
        grid.set("A", 2, "0.08")
        #expect(try grid.eval("A1*A2") == "8")
    }

    @Test func emptyCellTreatedAsZero() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        // B1 not set → treated as 0
        #expect(try grid.eval("A1+B1") == "5")
    }

    @Test func multipleCellReferences() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("B", 1, "20")
        grid.set("C", 1, "30")
        #expect(try grid.eval("(A1+B1)*C1") == "900")
    }
}

// MARK: - SUM Function

@Suite("SUM Function")
struct SUMTests {
    @Test func sumRange() throws {
        var grid = TestGrid()
        for i in 1...5 {
            grid.set("A", i, "\(i * 10)")
        }
        #expect(try grid.eval("SUM(A1:A5)") == "150")
    }

    @Test func sumIndividualCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("B", 1, "20")
        grid.set("C", 1, "30")
        #expect(try grid.eval("SUM(A1,B1,C1)") == "60")
    }

    @Test func sumRectangularRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "1")
        grid.set("A", 2, "2")
        grid.set("B", 1, "3")
        grid.set("B", 2, "4")
        #expect(try grid.eval("SUM(A1:B2)") == "10")
    }

    @Test func sumWithEmptyCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        // A2, A3 empty
        grid.set("A", 4, "20")
        #expect(try grid.eval("SUM(A1:A4)") == "30")
    }

    @Test func sumWithArithmetic() throws {
        var grid = TestGrid()
        for i in 1...5 {
            grid.set("A", i, "\(i * 10)")
        }
        #expect(try grid.eval("SUM(A1:A5)*2") == "300")
    }

    @Test func sumCaseInsensitive() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        #expect(try grid.eval("sum(A1:A2)") == "30")
    }

    @Test func sumDuplicateCell() throws {
        var grid = TestGrid()
        grid.set("A", 1, "42")
        #expect(try grid.eval("SUM(A1,A1)") == "84")
    }
}

// MARK: - PRODUCT Function

@Suite("PRODUCT Function")
struct PRODUCTTests {
    @Test func productRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2")
        grid.set("A", 2, "3")
        grid.set("A", 3, "4")
        #expect(try grid.eval("PRODUCT(A1:A3)") == "24")
    }

    @Test func productIndividualCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        grid.set("B", 1, "6")
        #expect(try grid.eval("PRODUCT(A1,B1)") == "30")
    }

    @Test func productAllEmpty() throws {
        let grid = TestGrid()
        // All cells empty → returns 0
        #expect(try grid.eval("PRODUCT(A1:A3)") == "0")
    }
}

// MARK: - AVERAGE Function

@Suite("AVERAGE Function")
struct AVERAGETests {
    @Test func averageRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("A", 3, "30")
        #expect(try grid.eval("AVERAGE(A1:A3)") == "20")
    }

    @Test func averageEvenResult() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("A", 3, "30")
        grid.set("A", 4, "40")
        #expect(try grid.eval("AVERAGE(A1:A4)") == "25")
    }

    @Test func averageSingleValue() throws {
        var grid = TestGrid()
        grid.set("A", 1, "42")
        #expect(try grid.eval("AVERAGE(A1,A1)") == "42")
    }

    @Test func averageAllEmpty() throws {
        let grid = TestGrid()
        // All cells empty → returns 0
        #expect(try grid.eval("AVERAGE(A1:A3)") == "0")
    }
}

// MARK: - Combined Functions and Expressions

@Suite("Combined Expressions")
struct CombinedTests {
    @Test func sumPlusCell() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("B", 1, "5")
        grid.set("B", 2, "15")
        #expect(try grid.eval("A1+SUM(B1:B2)") == "30")
    }

    @Test func twoSums() throws {
        var grid = TestGrid()
        grid.set("A", 1, "1")
        grid.set("A", 2, "2")
        grid.set("B", 1, "3")
        grid.set("B", 2, "4")
        #expect(try grid.eval("SUM(A1:A2)+SUM(B1:B2)") == "10")
    }

    @Test func sumDividedByCount() throws {
        var grid = TestGrid()
        for i in 1...4 {
            grid.set("A", i, "\(i * 10)")
        }
        #expect(try grid.eval("SUM(A1:A4)/4") == "25")
    }
}

// MARK: - Column Name Parsing

@Suite("Column Parsing")
struct ColumnParsingTests {
    @Test func columnA() throws {
        var grid = TestGrid()
        grid.set("A", 1, "99")
        #expect(try grid.eval("A1") == "99")
    }

    @Test func columnJ() throws {
        var grid = TestGrid()
        grid.set("J", 1, "77")
        #expect(try grid.eval("J1") == "77")
    }

    @Test func columnZ() throws {
        var grid = TestGrid()
        grid.set("Z", 1, "55")
        #expect(try grid.eval("Z1") == "55")
    }
}

// MARK: - Error Cases

@Suite("Error Cases")
struct ErrorTests {
    @Test func divisionByZero() throws {
        let grid = TestGrid()
        #expect(throws: (any Error).self) {
            try grid.eval("1/0")
        }
    }

    @Test func divisionByZeroCellRef() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        // B1 empty → 0
        #expect(throws: (any Error).self) {
            try grid.eval("A1/B1")
        }
    }

    @Test func invalidExpression() throws {
        let grid = TestGrid()
        #expect(throws: (any Error).self) {
            try grid.eval("+++")
        }
    }

    @Test func nonNumericCellInSum() throws {
        var grid = TestGrid()
        grid.set("A", 1, "hello")
        grid.set("A", 2, "10")
        // Non-numeric treated as 0
        #expect(try grid.eval("SUM(A1:A2)") == "10")
    }

    @Test func nonNumericCellInReference() throws {
        var grid = TestGrid()
        grid.set("A", 1, "hello")
        // Direct reference to non-numeric → expression fails
        #expect(throws: (any Error).self) {
            try grid.eval("A1+1")
        }
    }
}

// MARK: - CellModel Tests

@Suite("CellModel")
struct CellModelTests {
    @Test func plainValue() {
        let cell = CellModel(row: 0, column: 0)
        let engine = FormulaEngine()
        cell.input = "42"
        cell.evaluate(using: engine) { _, _ in "" }
        #expect(cell.displayValue == "42")
        #expect(cell.hasError == false)
    }

    @Test func emptyInput() {
        let cell = CellModel(row: 0, column: 0)
        let engine = FormulaEngine()
        cell.input = ""
        cell.evaluate(using: engine) { _, _ in "" }
        #expect(cell.displayValue == "")
        #expect(cell.hasError == false)
    }

    @Test func formulaEvaluation() {
        let cell = CellModel(row: 0, column: 0)
        let engine = FormulaEngine()
        cell.input = "=5+3"
        cell.evaluate(using: engine) { _, _ in "" }
        #expect(cell.displayValue == "8")
        #expect(cell.hasError == false)
    }

    @Test func formulaError() {
        let cell = CellModel(row: 0, column: 0)
        let engine = FormulaEngine()
        cell.input = "=+++"
        cell.evaluate(using: engine) { _, _ in "" }
        #expect(cell.displayValue == "#ERROR")
        #expect(cell.hasError == true)
    }
}
