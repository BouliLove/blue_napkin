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

// MARK: - Negative Numbers & Edge Cases

@Suite("Negative Numbers & Edge Cases")
struct NegativeEdgeCaseTests {
    @Test func negativeResult() throws {
        let grid = TestGrid()
        #expect(try grid.eval("3-10") == "-7")
    }

    @Test func negativeMultiplication() throws {
        var grid = TestGrid()
        grid.set("A", 1, "-5")
        grid.set("B", 1, "3")
        #expect(try grid.eval("A1*B1") == "-15")
    }

    @Test func negativeCellInSum() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "-3")
        grid.set("A", 3, "5")
        #expect(try grid.eval("SUM(A1:A3)") == "12")
    }

    @Test func zeroCellArithmetic() throws {
        var grid = TestGrid()
        grid.set("A", 1, "0")
        #expect(try grid.eval("A1+100") == "100")
    }

    @Test func veryLargeNumber() throws {
        let grid = TestGrid()
        #expect(try grid.eval("999999*999999") == "999998000001")
    }

    @Test func decimalPrecision() throws {
        let grid = TestGrid()
        #expect(try grid.eval("0.1+0.2") == "0.3")
    }
}

// MARK: - Reversed & Single-Cell Ranges

@Suite("Range Variations")
struct RangeVariationTests {
    @Test func reversedRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("A", 3, "30")
        // B3:A1 reversed → should still work
        #expect(try grid.eval("SUM(A3:A1)") == "60")
    }

    @Test func singleCellRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "42")
        #expect(try grid.eval("SUM(A1:A1)") == "42")
    }

    @Test func rectangularRangeProduct() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2")
        grid.set("A", 2, "3")
        grid.set("B", 1, "4")
        grid.set("B", 2, "5")
        #expect(try grid.eval("PRODUCT(A1:B2)") == "120")
    }

    @Test func averageWithNegatives() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "-10")
        #expect(try grid.eval("AVERAGE(A1:A2)") == "0")
    }
}

// MARK: - Chained References & Complex Formulas

@Suite("Complex Formulas")
struct ComplexFormulaTests {
    @Test func multipleOperatorsWithCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("B", 1, "5")
        grid.set("C", 1, "2")
        #expect(try grid.eval("A1+B1*C1") == "20")
    }

    @Test func sumMinusAverage() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("A", 3, "30")
        // SUM=60, AVERAGE=20 → 60-20=40
        #expect(try grid.eval("SUM(A1:A3)-AVERAGE(A1:A3)") == "40")
    }

    @Test func productTimesConstant() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2")
        grid.set("A", 2, "3")
        #expect(try grid.eval("PRODUCT(A1:A2)+10") == "16")
    }

    @Test func formulaWithSpacesInFunction() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        // SUM( A1 , A2 ) with spaces around args
        #expect(try grid.eval("SUM( A1 , A2 )") == "30")
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

// MARK: - Dependency Extraction

@Suite("Dependency Extraction")
struct DependencyTests {
    @Test func simpleCellReference() {
        let engine = FormulaEngine()
        let deps = engine.dependencies(from: "B2")
        #expect(deps.count == 1)
        #expect(deps[0].row == 1)
        #expect(deps[0].col == 1)
    }

    @Test func multipleCellReferences() {
        let engine = FormulaEngine()
        let deps = engine.dependencies(from: "A1+B2+C3")
        #expect(deps.count == 3)
    }

    @Test func rangeReferences() {
        let engine = FormulaEngine()
        let deps = engine.dependencies(from: "SUM(A1:A3)")
        #expect(deps.count == 2) // A1 and A3 are the refs in the text
    }

    @Test func noCellReferences() {
        let engine = FormulaEngine()
        let deps = engine.dependencies(from: "1+2+3")
        #expect(deps.count == 0)
    }
}

// MARK: - Circular Reference Detection

@Suite("Circular Reference Detection")
struct CircularReferenceTests {
    @Test func directCircularReference() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        // A1 = =B1, B1 = =A1
        vm.cells[0][0].input = "=B1"
        vm.cells[0][1].input = "=A1"
        vm.reevaluateAllCells()
        #expect(vm.cells[0][0].hasError == true)
        #expect(vm.cells[0][0].displayValue == "#ERROR")
        #expect(vm.cells[0][1].hasError == true)
        #expect(vm.cells[0][1].displayValue == "#ERROR")
    }

    @Test func selfReference() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        // A1 = =A1
        vm.cells[0][0].input = "=A1"
        vm.reevaluateAllCells()
        #expect(vm.cells[0][0].hasError == true)
        #expect(vm.cells[0][0].displayValue == "#ERROR")
    }

    @Test func indirectCircularReference() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        // A1 = =B1, B1 = =C1, C1 = =A1
        vm.cells[0][0].input = "=B1"
        vm.cells[0][1].input = "=C1"
        vm.cells[0][2].input = "=A1"
        vm.reevaluateAllCells()
        #expect(vm.cells[0][0].hasError == true)
        #expect(vm.cells[0][1].hasError == true)
        #expect(vm.cells[0][2].hasError == true)
    }

    @Test func nonCircularCellsUnaffected() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        // A1 = =B1, B1 = =A1 (circular), C1 = 42 (not circular)
        vm.cells[0][0].input = "=B1"
        vm.cells[0][1].input = "=A1"
        vm.cells[0][2].input = "42"
        vm.reevaluateAllCells()
        #expect(vm.cells[0][2].displayValue == "42")
        #expect(vm.cells[0][2].hasError == false)
    }

    @Test func formulaDependingOnCircularShowsError() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        // A1 = =A1 (circular), B1 depends on A1
        vm.cells[0][0].input = "=A1"
        vm.cells[0][1].input = "=A1+1"
        vm.reevaluateAllCells()
        #expect(vm.cells[0][0].hasError == true)
        // B1 depends on a circular cell — it should also error
        #expect(vm.cells[0][1].hasError == true)
    }
}

// MARK: - Undo/Redo

@Suite("Undo/Redo")
struct UndoRedoTests {
    @Test func undoSingleCellChange() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "hello"
        }
        vm.updateCell(at: 0, column: 0)
        #expect(vm.cells[0][0].displayValue == "hello")
        vm.undo()
        #expect(vm.cells[0][0].input == "")
        #expect(vm.cells[0][0].displayValue == "")
    }

    @Test func redoAfterUndo() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "42"
        }
        vm.updateCell(at: 0, column: 0)
        vm.undo()
        #expect(vm.cells[0][0].input == "")
        vm.redo()
        #expect(vm.cells[0][0].input == "42")
        #expect(vm.cells[0][0].displayValue == "42")
    }

    @Test func multipleUndos() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "first"
        }
        vm.updateCell(at: 0, column: 0)
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "second"
        }
        vm.updateCell(at: 0, column: 0)
        #expect(vm.cells[0][0].displayValue == "second")
        vm.undo()
        #expect(vm.cells[0][0].displayValue == "first")
        vm.undo()
        #expect(vm.cells[0][0].displayValue == "")
    }

    @Test func undoMultiCellDelete() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.cells[0][0].input = "A"
        vm.cells[0][1].input = "B"
        vm.reevaluateAllCells()
        // Simulate multi-cell delete
        vm.beginChangeGroup()
        vm.recordCellChange(row: 0, col: 0)
        vm.cells[0][0].input = ""
        vm.recordCellChange(row: 0, col: 1)
        vm.cells[0][1].input = ""
        vm.commitChangeGroup()
        vm.reevaluateAllCells()
        #expect(vm.cells[0][0].input == "")
        #expect(vm.cells[0][1].input == "")
        vm.undo()
        #expect(vm.cells[0][0].input == "A")
        #expect(vm.cells[0][1].input == "B")
    }

    @Test func newChangeClearsRedoStack() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "first"
        }
        vm.updateCell(at: 0, column: 0)
        vm.undo()
        #expect(vm.canRedo == true)
        // New change should clear redo stack
        vm.withUndo(row: 0, col: 0) {
            vm.cells[0][0].input = "different"
        }
        vm.updateCell(at: 0, column: 0)
        #expect(vm.canRedo == false)
    }

    @Test func undoOnEmptyStackDoesNothing() {
        GridViewModel.clearStorage()
        let vm = GridViewModel()
        vm.cells[0][0].input = "keep"
        vm.reevaluateAllCells()
        vm.undo() // Should be no-op
        #expect(vm.cells[0][0].input == "keep")
    }
}

// MARK: - MIN Function

@Suite("MIN Function")
struct MinTests {
    @Test func minRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "3")
        grid.set("A", 3, "7")
        #expect(try grid.eval("MIN(A1:A3)") == "3")
    }

    @Test func minIndividualCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        grid.set("B", 1, "2")
        grid.set("C", 1, "8")
        #expect(try grid.eval("MIN(A1,B1,C1)") == "2")
    }

    @Test func minWithNegatives() throws {
        var grid = TestGrid()
        grid.set("A", 1, "-3")
        grid.set("A", 2, "5")
        grid.set("A", 3, "-7")
        #expect(try grid.eval("MIN(A1:A3)") == "-7")
    }
}

// MARK: - MAX Function

@Suite("MAX Function")
struct MaxTests {
    @Test func maxRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "3")
        grid.set("A", 3, "7")
        #expect(try grid.eval("MAX(A1:A3)") == "10")
    }

    @Test func maxIndividualCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        grid.set("B", 1, "2")
        grid.set("C", 1, "8")
        #expect(try grid.eval("MAX(A1,B1,C1)") == "8")
    }

    @Test func maxWithNegatives() throws {
        var grid = TestGrid()
        grid.set("A", 1, "-3")
        grid.set("A", 2, "-5")
        grid.set("A", 3, "-1")
        #expect(try grid.eval("MAX(A1:A3)") == "-1")
    }
}

// MARK: - COUNT Function

@Suite("COUNT Function")
struct CountTests {
    @Test func countRange() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("A", 3, "30")
        #expect(try grid.eval("COUNT(A1:A3)") == "3")
    }

    @Test func countWithEmptyCells() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        // A2 is empty
        grid.set("A", 3, "30")
        #expect(try grid.eval("COUNT(A1:A3)") == "2")
    }
}

// MARK: - ABS Function

@Suite("ABS Function")
struct AbsTests {
    @Test func absNegative() throws {
        let grid = TestGrid()
        #expect(try grid.eval("ABS(-5)") == "5")
    }

    @Test func absPositive() throws {
        let grid = TestGrid()
        #expect(try grid.eval("ABS(3)") == "3")
    }

    @Test func absCellReference() throws {
        var grid = TestGrid()
        grid.set("A", 1, "-42")
        #expect(try grid.eval("ABS(A1)") == "42")
    }
}

// MARK: - ROUND Function

@Suite("ROUND Function")
struct RoundTests {
    @Test func roundToInteger() throws {
        let grid = TestGrid()
        #expect(try grid.eval("ROUND(3.7)") == "4")
    }

    @Test func roundToTwoDecimals() throws {
        let grid = TestGrid()
        #expect(try grid.eval("ROUND(3.14159;2)") == "3.14")
    }

    @Test func roundCellReference() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2.567")
        #expect(try grid.eval("ROUND(A1;1)") == "2.6")
    }

    @Test func roundNegative() throws {
        let grid = TestGrid()
        #expect(try grid.eval("ROUND(-2.5)") == "-3")
    }
}

@Suite("Nested Functions")
struct NestedFunctionTests {
    @Test func minOfSumAndProduct() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2")
        grid.set("A", 2, "3")
        grid.set("B", 1, "4")
        grid.set("B", 2, "5")
        // SUM(A1:A2) = 5, PRODUCT(B1:B2) = 20 → MIN = 5
        #expect(try grid.eval("MIN(SUM(A1:A2);PRODUCT(B1:B2))") == "5")
    }

    @Test func minOfSumAndProductWithExtraParens() throws {
        var grid = TestGrid()
        grid.set("A", 1, "2")
        grid.set("A", 2, "3")
        grid.set("B", 1, "4")
        grid.set("B", 2, "5")
        // Extra parens like user's example: =MIN((SUM(A2:B4);PRODUCT(C2:D4))
        // After auto-close: MIN((SUM(A1:A2);PRODUCT(B1:B2)))
        #expect(try grid.eval("MIN((SUM(A1:A2);PRODUCT(B1:B2)))") == "5")
    }

    @Test func sumOfMinAndMax() throws {
        var grid = TestGrid()
        grid.set("A", 1, "10")
        grid.set("A", 2, "20")
        grid.set("B", 1, "30")
        grid.set("B", 2, "40")
        // MIN(A1;A2) = 10, MAX(B1;B2) = 40 → SUM = 50
        #expect(try grid.eval("SUM(MIN(A1;A2);MAX(B1;B2))") == "50")
    }

    @Test func threeLevelNesting() throws {
        var grid = TestGrid()
        grid.set("A", 1, "-7")
        grid.set("A", 2, "3")
        // ABS(MIN(A1;A2)) → ABS(-7) = 7
        #expect(try grid.eval("ABS(MIN(A1;A2))") == "7")
    }

    @Test func nestedFunctionPlusArithmetic() throws {
        var grid = TestGrid()
        grid.set("A", 1, "1")
        grid.set("A", 2, "2")
        grid.set("B", 1, "10")
        grid.set("B", 2, "20")
        // SUM(A1:A2) + MIN(B1;B2) = 3 + 10 = 13
        #expect(try grid.eval("SUM(A1:A2)+MIN(B1;B2)") == "13")
    }

    @Test func semicolonAsSeparator() throws {
        var grid = TestGrid()
        grid.set("A", 1, "5")
        grid.set("A", 2, "3")
        grid.set("A", 3, "8")
        // Semicolons as separators for MIN without nesting
        #expect(try grid.eval("MIN(A1;A2;A3)") == "3")
    }

    @Test func roundNestedFunction() throws {
        var grid = TestGrid()
        grid.set("A", 1, "1.111")
        grid.set("A", 2, "2.222")
        // ROUND(SUM(A1:A2);1) → ROUND(3.333;1) = 3.3
        #expect(try grid.eval("ROUND(SUM(A1:A2);1)") == "3.3")
    }
}
