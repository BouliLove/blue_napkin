import SwiftUI

// Selection state for tracking cell/range selection during formula editing
class SelectionState: ObservableObject {
    @Published var isSelecting = false
    @Published var selectionStart: (row: Int, col: Int)?
    @Published var selectionEnd: (row: Int, col: Int)?
    @Published var editingCell: (row: Int, col: Int)?

    func startSelection(at row: Int, col: Int) {
        selectionStart = (row, col)
        selectionEnd = (row, col)
        isSelecting = true
    }

    func updateSelection(to row: Int, col: Int) {
        selectionEnd = (row, col)
    }

    func endSelection() {
        isSelecting = false
    }

    func clearSelection() {
        selectionStart = nil
        selectionEnd = nil
        isSelecting = false
    }

    func isInSelection(row: Int, col: Int) -> Bool {
        guard let start = selectionStart, let end = selectionEnd else {
            return false
        }

        let minRow = min(start.row, end.row)
        let maxRow = max(start.row, end.row)
        let minCol = min(start.col, end.col)
        let maxCol = max(start.col, end.col)

        return row >= minRow && row <= maxRow && col >= minCol && col <= maxCol
    }

    func getSelectionReference() -> String? {
        guard let start = selectionStart, let end = selectionEnd else {
            return nil
        }

        let startRef = cellReference(row: start.row, col: start.col)
        let endRef = cellReference(row: end.row, col: end.col)

        // If single cell, return just the cell reference
        if start.row == end.row && start.col == end.col {
            return startRef
        }

        // Otherwise return range
        return "\(startRef):\(endRef)"
    }

    private func cellReference(row: Int, col: Int) -> String {
        var name = ""
        var c = col
        while c >= 0 {
            name = String(UnicodeScalar(65 + (c % 26))!) + name
            c = c / 26 - 1
            if c < 0 { break }
        }
        return "\(name)\(row + 1)"
    }
}

class GridViewModel: ObservableObject {
    @Published var cells: [[CellModel]] = []
    let formulaEngine = FormulaEngine()

    let rows = 20
    let columns = 10

    init() {
        // Initialize grid
        for row in 0..<rows {
            var rowCells: [CellModel] = []
            for col in 0..<columns {
                rowCells.append(CellModel(row: row, column: col))
            }
            cells.append(rowCells)
        }
    }

    func getCellValue(row: Int, column: Int) -> String {
        guard row >= 0, row < rows, column >= 0, column < columns else {
            return ""
        }
        return cells[row][column].displayValue
    }

    func updateCell(at row: Int, column: Int) {
        let cell = cells[row][column]
        cell.evaluate(using: formulaEngine, getCellValue: getCellValue)

        // Re-evaluate all cells that might depend on this one
        reevaluateAllCells()
    }

    func reevaluateAllCells() {
        for row in 0..<rows {
            for col in 0..<columns {
                let cell = cells[row][col]
                if cell.input.hasPrefix("=") {
                    cell.evaluate(using: formulaEngine, getCellValue: getCellValue)
                }
            }
        }
    }
}

struct GridView: View {
    @StateObject private var viewModel = GridViewModel()
    @StateObject private var selectionState = SelectionState()
    @FocusState private var focusedCell: UUID?
    @State private var currentEditingCell: (row: Int, col: Int)?

    let cellWidth: CGFloat = 80
    let cellHeight: CGFloat = 30
    let headerWidth: CGFloat = 40
    let headerHeight: CGFloat = 30

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    // Empty corner cell
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: headerWidth, height: headerHeight)
                        .border(Color.gray.opacity(0.3))

                    // Column letters
                    ForEach(0..<viewModel.columns, id: \.self) { col in
                        Text(columnName(col))
                            .font(.system(size: 11, weight: .medium))
                            .frame(width: cellWidth, height: headerHeight)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray.opacity(0.3))
                    }
                }

                // Rows
                ForEach(0..<viewModel.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        // Row number
                        Text("\(row + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .frame(width: headerWidth, height: cellHeight)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray.opacity(0.3))

                        // Cells
                        ForEach(0..<viewModel.columns, id: \.self) { col in
                            CellView(
                                cell: viewModel.cells[row][col],
                                row: row,
                                col: col,
                                isFocused: focusedCell == viewModel.cells[row][col].id,
                                isSelected: selectionState.isInSelection(row: row, col: col),
                                isEditingCell: currentEditingCell?.row == row && currentEditingCell?.col == col,
                                selectionState: selectionState,
                                onStartEditing: {
                                    currentEditingCell = (row, col)
                                    selectionState.editingCell = (row, col)
                                    selectionState.clearSelection()
                                },
                                onEndEditing: {
                                    currentEditingCell = nil
                                    selectionState.editingCell = nil
                                    selectionState.clearSelection()
                                },
                                onCellClick: { clickedRow, clickedCol in
                                    handleCellClick(row: clickedRow, col: clickedCol)
                                },
                                onCellDrag: { draggedRow, draggedCol in
                                    handleCellDrag(row: draggedRow, col: draggedCol)
                                },
                                onCommit: {
                                    viewModel.updateCell(at: row, column: col)
                                }
                            )
                            .focused($focusedCell, equals: viewModel.cells[row][col].id)
                            .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleCellClick(row: Int, col: Int) {
        // Only handle clicks when another cell is being edited with a formula
        guard let editingCell = currentEditingCell,
              viewModel.cells[editingCell.row][editingCell.col].input.hasPrefix("="),
              !(editingCell.row == row && editingCell.col == col) else {
            return
        }

        // Start selection on click
        selectionState.startSelection(at: row, col: col)
    }

    private func handleCellDrag(row: Int, col: Int) {
        // Only handle drags when another cell is being edited with a formula
        guard let editingCell = currentEditingCell,
              viewModel.cells[editingCell.row][editingCell.col].input.hasPrefix("="),
              !(editingCell.row == row && editingCell.col == col),
              selectionState.isSelecting else {
            return
        }

        // Update selection on drag
        selectionState.updateSelection(to: row, col: col)
    }

    private func columnName(_ index: Int) -> String {
        var name = ""
        var col = index
        while col >= 0 {
            name = String(UnicodeScalar(65 + (col % 26))!) + name
            col = col / 26 - 1
            if col < 0 { break }
        }
        return name
    }
}

struct CellView: View {
    @ObservedObject var cell: CellModel
    let row: Int
    let col: Int
    let isFocused: Bool
    let isSelected: Bool
    let isEditingCell: Bool
    @ObservedObject var selectionState: SelectionState
    let onStartEditing: () -> Void
    let onEndEditing: () -> Void
    let onCellClick: (Int, Int) -> Void
    let onCellDrag: (Int, Int) -> Void
    let onCommit: () -> Void

    @State private var isEditing = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        ZStack {
            if isEditing {
                CustomTextField(
                    text: $cell.input,
                    onCommit: {
                        isEditing = false
                        onEndEditing()
                        onCommit()
                    },
                    onInsertReference: { reference in
                        // Insert the selected reference at cursor position
                        cell.input += reference
                        selectionState.clearSelection()
                    },
                    selectionState: selectionState
                )
                .font(.system(size: 12))
                .padding(4)
            } else {
                Text(cell.displayValue)
                    .font(.system(size: 12))
                    .foregroundColor(cell.hasError ? .red : .primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        isEditing = true
                        onStartEditing()
                    }
                    .onTapGesture(count: 1) {
                        // Handle single click for selection during formula editing
                        onCellClick(row, col)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Track drag over this cell
                                if selectionState.isSelecting {
                                    onCellDrag(row, col)
                                }
                            }
                            .onEnded { _ in
                                // End selection on drag end
                                selectionState.endSelection()
                            }
                    )
            }
        }
        .background(backgroundColor)
        .border(borderColor, width: isSelected ? 2 : 1)
        .onChange(of: isFocused) { newValue in
            if !newValue {
                isEditing = false
                onEndEditing()
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.green.opacity(0.2)
        } else if isEditing || isFocused {
            return Color.blue.opacity(0.1)
        } else {
            return Color.white
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.green
        } else if isFocused {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// Custom TextField that handles Enter key for inserting cell references
struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    let onCommit: () -> Void
    let onInsertReference: (String) -> Void
    @ObservedObject var selectionState: SelectionState

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Enter key to insert cell reference
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let reference = parent.selectionState.getSelectionReference() {
                    parent.onInsertReference(reference)
                    parent.selectionState.clearSelection()
                    return true
                } else {
                    // No selection, commit the cell
                    parent.onCommit()
                    return true
                }
            }
            return false
        }
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView()
            .frame(width: 600, height: 400)
    }
}
