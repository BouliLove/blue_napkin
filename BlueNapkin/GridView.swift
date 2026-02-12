import SwiftUI
import AppKit

// MARK: - Cursor Modifier

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}

enum EditAction {
    case commit
    case commitUp
    case cancel
    case tabForward
    case tabBack
}

// Selection state for tracking cell/range selection during formula editing
class SelectionState: ObservableObject {
    @Published var isSelecting = false
    @Published var selectionStart: (row: Int, col: Int)?
    @Published var selectionEnd: (row: Int, col: Int)?
    func startSelection(at row: Int, col: Int) {
        selectionStart = (row, col)
        selectionEnd = (row, col)
        isSelecting = true
    }

    func updateSelection(to row: Int, col: Int) {
        selectionEnd = (row, col)
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

        if start.row == end.row && start.col == end.col {
            return startRef
        }

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

struct CellChange {
    let row: Int
    let col: Int
    let oldInput: String
    let newInput: String
}

class GridViewModel: ObservableObject {
    @Published var cells: [[CellModel]] = []
    let formulaEngine = FormulaEngine()

    let rows = 20
    let columns = 10

    private static let storageKey = "BlueNapkin.gridData"

    // MARK: - Undo/Redo

    var undoStack: [[CellChange]] = []
    var redoStack: [[CellChange]] = []
    private var pendingChanges: [CellChange] = []

    /// Begin recording a group of changes (e.g. multi-cell paste/delete).
    func beginChangeGroup() { pendingChanges = [] }

    /// Record a single cell change. Call before modifying the cell's input.
    func recordCellChange(row: Int, col: Int) {
        pendingChanges.append(CellChange(row: row, col: col, oldInput: cells[row][col].input, newInput: ""))
    }

    /// Finalize the change group after modifications are applied.
    func commitChangeGroup() {
        let changes = pendingChanges.map { change in
            CellChange(row: change.row, col: change.col, oldInput: change.oldInput, newInput: cells[change.row][change.col].input)
        }.filter { $0.oldInput != $0.newInput }
        if !changes.isEmpty {
            undoStack.append(changes)
            redoStack.removeAll()
        }
        pendingChanges = []
    }

    /// Convenience: record a single cell change, apply a closure, and commit.
    func withUndo(row: Int, col: Int, apply: () -> Void) {
        beginChangeGroup()
        recordCellChange(row: row, col: col)
        apply()
        commitChangeGroup()
    }

    func undo() {
        guard let changes = undoStack.popLast() else { return }
        for change in changes {
            cells[change.row][change.col].input = change.oldInput
        }
        redoStack.append(changes)
        reevaluateAllCells()
        save()
    }

    func redo() {
        guard let changes = redoStack.popLast() else { return }
        for change in changes {
            cells[change.row][change.col].input = change.newInput
        }
        undoStack.append(changes)
        reevaluateAllCells()
        save()
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    static func clearStorage() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Build CSV string from the grid, trimming empty trailing rows/columns.
    func exportCSV() -> String {
        // Find the bounding box of non-empty cells
        var maxRow = -1, maxCol = -1
        for r in 0..<rows {
            for c in 0..<columns {
                if !cells[r][c].input.isEmpty {
                    maxRow = max(maxRow, r)
                    maxCol = max(maxCol, c)
                }
            }
        }
        guard maxRow >= 0, maxCol >= 0 else { return "" }

        var lines: [String] = []
        for r in 0...maxRow {
            var fields: [String] = []
            for c in 0...maxCol {
                let value = cells[r][c].displayValue
                // Quote fields that contain commas, quotes, or newlines
                if value.contains(",") || value.contains("\"") || value.contains("\n") {
                    fields.append("\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"")
                } else {
                    fields.append(value)
                }
            }
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    init() {
        for row in 0..<rows {
            var rowCells: [CellModel] = []
            for col in 0..<columns {
                rowCells.append(CellModel(row: row, column: col))
            }
            cells.append(rowCells)
        }
        load()
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
        reevaluateAllCells()
        save()
    }

    func reevaluateAllCells() {
        // Build dependency graph and detect circular references
        typealias CellKey = Int // row * columns + col
        func key(_ r: Int, _ c: Int) -> CellKey { r * columns + c }

        var deps: [CellKey: [CellKey]] = [:]
        for r in 0..<rows {
            for c in 0..<columns {
                let cell = cells[r][c]
                if cell.input.hasPrefix("=") {
                    let formula = String(cell.input.dropFirst())
                    let refs = formulaEngine.dependencies(from: formula)
                        .filter { $0.row >= 0 && $0.row < rows && $0.col >= 0 && $0.col < columns }
                    deps[key(r, c)] = refs.map { key($0.row, $0.col) }
                }
            }
        }

        // Topological sort with cycle detection (Kahn's algorithm)
        var inDegree: [CellKey: Int] = [:]
        var reverseAdj: [CellKey: [CellKey]] = [:] // dependency -> dependents
        for (cell, cellDeps) in deps {
            if inDegree[cell] == nil { inDegree[cell] = 0 }
            for dep in cellDeps {
                reverseAdj[dep, default: []].append(cell)
                inDegree[cell, default: 0] += 1
            }
        }

        var queue: [CellKey] = []
        for (cell, degree) in inDegree where degree == 0 {
            queue.append(cell)
        }
        // Also include formula cells with no dependencies
        for (cell, _) in deps where inDegree[cell, default: 0] == 0 && !queue.contains(cell) {
            queue.append(cell)
        }

        var evalOrder: [CellKey] = []
        var idx = 0
        while idx < queue.count {
            let cell = queue[idx]; idx += 1
            evalOrder.append(cell)
            for dependent in reverseAdj[cell, default: []] {
                inDegree[dependent, default: 0] -= 1
                if inDegree[dependent] == 0 {
                    queue.append(dependent)
                }
            }
        }

        let circularCells = Set(deps.keys.filter { !evalOrder.contains($0) })

        // Evaluate in topological order
        for cellKey in evalOrder {
            let r = cellKey / columns, c = cellKey % columns
            cells[r][c].evaluate(using: formulaEngine, getCellValue: getCellValue)
        }

        // Also evaluate non-formula cells and plain values
        for r in 0..<rows {
            for c in 0..<columns {
                let cell = cells[r][c]
                if circularCells.contains(key(r, c)) {
                    cell.displayValue = "#ERROR"
                    cell.hasError = true
                } else if !cell.input.hasPrefix("=") {
                    cell.displayValue = cell.input
                    cell.hasError = false
                }
            }
        }

        objectWillChange.send()
    }

    // MARK: - Persistence

    func save() {
        var data: [String: String] = [:]
        for row in 0..<rows {
            for col in 0..<columns {
                let input = cells[row][col].input
                if !input.isEmpty {
                    data["\(row),\(col)"] = input
                }
            }
        }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: String] else {
            return
        }
        for (key, input) in data {
            let parts = key.split(separator: ",")
            guard parts.count == 2,
                  let row = Int(parts[0]),
                  let col = Int(parts[1]),
                  row >= 0, row < rows, col >= 0, col < columns else {
                continue
            }
            cells[row][col].input = input
        }
        reevaluateAllCells()
    }
}

struct GridView: View {
    @StateObject private var viewModel = GridViewModel()
    @StateObject private var selectionState = SelectionState()
    @State private var currentEditingCell: (row: Int, col: Int)?
    @State private var selectedCell: (row: Int, col: Int)?
    @State private var eventMonitor: Any?
    @State private var originalEditInput: String = ""
    @State private var formulaRefStart: Int?
    @State private var formulaRefLength: Int = 0
    @State private var formulaBarText: String = ""

    @State private var columnWidths: [CGFloat] = []
    let defaultCellWidth: CGFloat = 80
    let minCellWidth: CGFloat = 40
    let cellHeight: CGFloat = 30
    let headerWidth: CGFloat = 40
    let headerHeight: CGFloat = 30
    @State private var dragColumnIndex: Int? = nil
    @State private var dragStartWidth: CGFloat = 0

    private var activeCell: (row: Int, col: Int)? {
        currentEditingCell ?? selectedCell
    }

    private func colWidth(_ col: Int) -> CGFloat {
        col < columnWidths.count ? columnWidths[col] : defaultCellWidth
    }

    private func colX(_ col: Int) -> CGFloat {
        var x = headerWidth
        for c in 0..<col { x += colWidth(c) }
        return x
    }

    var body: some View {
        VStack(spacing: 0) {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Column headers
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(NSColor.windowBackgroundColor))
                        .frame(width: headerWidth, height: headerHeight)
                        .overlay(alignment: .bottom) {
                            Color(NSColor.separatorColor).opacity(0.5).frame(height: 0.5)
                        }

                    ForEach(0..<viewModel.columns, id: \.self) { col in
                        Text(columnName(col))
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                            .frame(width: colWidth(col), height: headerHeight)
                            .background(Color(NSColor.windowBackgroundColor))
                            .overlay(alignment: .bottom) {
                                Color(NSColor.separatorColor).opacity(0.5).frame(height: 0.5)
                            }
                            .overlay(alignment: .trailing) {
                                // Drag handle for column resizing
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 6)
                                    .contentShape(Rectangle())
                                    .cursor(.resizeLeftRight)
                                    .gesture(
                                        DragGesture(minimumDistance: 1)
                                            .onChanged { value in
                                                if dragColumnIndex == nil {
                                                    dragColumnIndex = col
                                                    dragStartWidth = colWidth(col)
                                                }
                                                let newWidth = max(minCellWidth, dragStartWidth + value.translation.width)
                                                columnWidths[col] = newWidth
                                            }
                                            .onEnded { _ in
                                                dragColumnIndex = nil
                                            }
                                    )
                                    .overlay(Color(NSColor.separatorColor).opacity(0.3).frame(width: 0.5))
                            }
                    }
                }

                // Rows
                ForEach(0..<viewModel.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        Text("\(row + 1)")
                            .font(.system(size: 10, weight: .medium).monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: headerWidth, height: cellHeight)
                            .background(Color(NSColor.windowBackgroundColor))
                            .overlay(alignment: .trailing) {
                                Color(NSColor.separatorColor).opacity(0.3).frame(width: 0.5)
                            }

                        ForEach(0..<viewModel.columns, id: \.self) { col in
                            CellView(
                                displayValue: viewModel.cells[row][col].displayValue,
                                hasError: viewModel.cells[row][col].hasError,
                                row: row,
                                col: col,
                                isSelected: selectionState.isInSelection(row: row, col: col),
                                isCursorCell: selectedCell?.row == row && selectedCell?.col == col && currentEditingCell == nil,
                                isEditing: currentEditingCell?.row == row && currentEditingCell?.col == col,
                                inputValue: viewModel.cells[row][col].input,
                                inputBinding: Binding(
                                    get: { viewModel.cells[row][col].input },
                                    set: {
                                        viewModel.cells[row][col].input = $0
                                        formulaBarText = $0
                                    }
                                ),
                                onFinishEditing: { action in
                                    if action != .cancel {
                                        let newInput = viewModel.cells[row][col].input
                                        if originalEditInput != newInput {
                                            viewModel.undoStack.append([CellChange(row: row, col: col, oldInput: originalEditInput, newInput: newInput)])
                                            viewModel.redoStack.removeAll()
                                        }
                                        viewModel.updateCell(at: row, column: col)
                                    } else {
                                        viewModel.cells[row][col].input = originalEditInput
                                    }
                                    currentEditingCell = nil
                                    formulaBarText = ""

                                    selectionState.clearSelection()
                                    formulaRefStart = nil
                                    formulaRefLength = 0
                                    switch action {
                                    case .commit:
                                        if row + 1 < viewModel.rows {
                                            selectedCell = (row + 1, col)
                                        }
                                    case .commitUp:
                                        if row - 1 >= 0 {
                                            selectedCell = (row - 1, col)
                                        }
                                    case .cancel:
                                        break
                                    case .tabForward:
                                        if col + 1 < viewModel.columns {
                                            selectedCell = (row, col + 1)
                                        } else if row + 1 < viewModel.rows {
                                            selectedCell = (row + 1, 0)
                                        }
                                    case .tabBack:
                                        if col - 1 >= 0 {
                                            selectedCell = (row, col - 1)
                                        } else if row - 1 >= 0 {
                                            selectedCell = (row - 1, viewModel.columns - 1)
                                        }
                                    }
                                },
                                onCellClick: { clickedRow, clickedCol in
                                    handleCellClick(row: clickedRow, col: clickedCol)
                                }
                            )
                            .equatable()
                            .frame(width: colWidth(col), height: cellHeight)
                            .zIndex(currentEditingCell?.row == row && currentEditingCell?.col == col ? 1 : 0)
                        }
                    }
                }
            }
            .coordinateSpace(name: "gridContent")
            .overlay {
                // Drag and tap overlay for formula range selection
                if currentEditingCell != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if let cell = cellAt(location: location) {
                                handleCellClick(row: cell.row, col: cell.col)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 5, coordinateSpace: .named("gridContent"))
                                .onChanged { value in
                                    handleFormulaDrag(location: value.location, isStart: false, startLocation: value.startLocation)
                                }
                        )
                        .allowsHitTesting(true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

            Color(NSColor.separatorColor).opacity(0.4).frame(height: 0.5)

            // Formula bar
            HStack(spacing: 6) {
                if let cell = activeCell {
                    let text = currentEditingCell != nil ? formulaBarText : viewModel.cells[cell.row][cell.col].input
                    if !text.isEmpty {
                        Text("\(columnName(cell.col))\(cell.row + 1)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .fixedSize()
                        Text(text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))
                            .fixedSize()
                            .lineLimit(1)
                    } else {
                        tipText
                    }
                } else {
                    tipText
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear {
            if columnWidths.isEmpty {
                columnWidths = Array(repeating: defaultCellWidth, count: viewModel.columns)
            }
            installEventMonitor()
        }
        .onDisappear { removeEventMonitor() }
        .onReceive(NotificationCenter.default.publisher(for: .exportCSV)) { _ in
            exportCSV()
        }
    }

    // MARK: - Keyboard Event Monitor

    private func installEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // While editing a formula, intercept arrow keys for cell reference selection
            if let editingCell = currentEditingCell {
                let isFormula = viewModel.cells[editingCell.row][editingCell.col].input.hasPrefix("=")
                if isFormula {
                    switch event.keyCode {
                    case 126, 125, 123, 124: // Arrow keys → select cells for reference
                        handleFormulaArrowKey(keyCode: event.keyCode, shift: event.modifierFlags.contains(.shift))
                        return nil
                    default:
                        // Any other key: commit the reference position and pass to text field
                        if formulaRefStart != nil {
                            formulaRefStart = nil
                            formulaRefLength = 0
                            selectionState.clearSelection()
                        }
                        return event
                    }
                }
                return event
            }

            let shift = event.modifierFlags.contains(.shift)
            let cmd = event.modifierFlags.contains(.command)

            // Cmd shortcuts
            if cmd {
                if event.charactersIgnoringModifiers == "a" {
                    selectedCell = (0, 0)
                    selectionState.startSelection(at: 0, col: 0)
                    selectionState.updateSelection(to: viewModel.rows - 1, col: viewModel.columns - 1)
                    return nil
                }
                if event.charactersIgnoringModifiers == "z" {
                    if shift {
                        viewModel.redo()
                    } else {
                        viewModel.undo()
                    }
                    return nil
                }
                if event.charactersIgnoringModifiers == "e" {
                    exportCSV()
                    return nil
                }
                guard let selected = selectedCell else { return event }
                switch event.charactersIgnoringModifiers {
                case "c":
                    copyCell(row: selected.row, col: selected.col)
                    return nil
                case "v":
                    pasteCell(row: selected.row, col: selected.col)
                    return nil
                case "x":
                    cutCell(row: selected.row, col: selected.col)
                    return nil
                default:
                    return event
                }
            }

            switch event.keyCode {
            case 126: // Up
                if shift { extendSelection(dr: -1, dc: 0) }
                else { moveSelection(dr: -1, dc: 0) }
                return nil
            case 125: // Down
                if shift { extendSelection(dr: 1, dc: 0) }
                else { moveSelection(dr: 1, dc: 0) }
                return nil
            case 123: // Left
                if shift { extendSelection(dr: 0, dc: -1) }
                else { moveSelection(dr: 0, dc: -1) }
                return nil
            case 124: // Right
                if shift { extendSelection(dr: 0, dc: 1) }
                else { moveSelection(dr: 0, dc: 1) }
                return nil
            case 36: // Return/Enter
                if shift {
                    // Shift+Enter: move up
                    if let current = selectedCell, current.row - 1 >= 0 {
                        selectedCell = (current.row - 1, current.col)
                        selectionState.clearSelection()
                    }
                    return nil
                }
                if let selected = selectedCell {
                    originalEditInput = viewModel.cells[selected.row][selected.col].input
                    currentEditingCell = selected
                    formulaBarText = viewModel.cells[selected.row][selected.col].input

                    selectionState.clearSelection()
                    return nil
                }
                return event
            case 48: // Tab
                let current = selectedCell ?? (row: 0, col: 0)
                if shift {
                    if current.col - 1 >= 0 {
                        selectedCell = (current.row, current.col - 1)
                    } else if current.row - 1 >= 0 {
                        selectedCell = (current.row - 1, viewModel.columns - 1)
                    }
                } else {
                    if current.col + 1 < viewModel.columns {
                        selectedCell = (current.row, current.col + 1)
                    } else if current.row + 1 < viewModel.rows {
                        selectedCell = (current.row + 1, 0)
                    }
                }
                selectionState.clearSelection()
                return nil
            case 53: // Escape
                selectedCell = nil
                selectionState.clearSelection()
                return nil
            case 51, 117: // Delete/Backspace, Forward Delete
                if selectionState.selectionStart != nil {
                    // Clear all cells in selection range
                    viewModel.beginChangeGroup()
                    for r in 0..<viewModel.rows {
                        for c in 0..<viewModel.columns {
                            if selectionState.isInSelection(row: r, col: c) {
                                viewModel.recordCellChange(row: r, col: c)
                                viewModel.cells[r][c].input = ""
                                viewModel.cells[r][c].displayValue = ""
                                viewModel.cells[r][c].hasError = false
                            }
                        }
                    }
                    viewModel.commitChangeGroup()
                    selectionState.clearSelection()
                    viewModel.reevaluateAllCells()
                    viewModel.save()
                } else if let selected = selectedCell {
                    viewModel.withUndo(row: selected.row, col: selected.col) {
                        viewModel.cells[selected.row][selected.col].input = ""
                    }
                    viewModel.updateCell(at: selected.row, column: selected.col)
                }
                return nil
            default:
                // Printable character starts editing (replaces cell content)
                if let selected = selectedCell,
                   let chars = event.characters,
                   let scalar = chars.unicodeScalars.first,
                   scalar.value >= 32, scalar.value < 0xF700 {
                    originalEditInput = viewModel.cells[selected.row][selected.col].input
                    viewModel.cells[selected.row][selected.col].input = chars
                    currentEditingCell = selected
                    formulaBarText = chars

                    selectionState.clearSelection()
                    return nil
                }
                return event
            }
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Clipboard Operations

    private func copyCell(row: Int, col: Int) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.cells[row][col].input, forType: .string)
    }

    private func pasteCell(row: Int, col: Int) {
        guard let content = NSPasteboard.general.string(forType: .string) else { return }
        let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        if rows.count > 1 || rows.first?.contains("\t") == true {
            pasteMultiCell(content: rows, startRow: row, startCol: col)
        } else {
            viewModel.withUndo(row: row, col: col) {
                viewModel.cells[row][col].input = content
            }
            viewModel.updateCell(at: row, column: col)
        }
    }

    private func pasteMultiCell(content: [String], startRow: Int, startCol: Int) {
        viewModel.beginChangeGroup()
        for (rowOffset, line) in content.enumerated() {
            let columns = line.components(separatedBy: "\t")
            for (colOffset, value) in columns.enumerated() {
                let targetRow = startRow + rowOffset
                let targetCol = startCol + colOffset
                guard targetRow < viewModel.rows, targetCol < viewModel.columns else { continue }
                viewModel.recordCellChange(row: targetRow, col: targetCol)
                viewModel.cells[targetRow][targetCol].input = value
            }
        }
        viewModel.commitChangeGroup()
        viewModel.reevaluateAllCells()
        viewModel.save()
    }

    private func cutCell(row: Int, col: Int) {
        copyCell(row: row, col: col)
        viewModel.withUndo(row: row, col: col) {
            viewModel.cells[row][col].input = ""
        }
        viewModel.updateCell(at: row, column: col)
    }

    // MARK: - CSV Export

    private func exportCSV() {
        let csv = viewModel.exportCSV()
        guard !csv.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "BlueNapkin.csv"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    // MARK: - Cell Click Handling

    private func handleCellClick(row: Int, col: Int) {
        let shift = NSEvent.modifierFlags.contains(.shift)

        if let editingCell = currentEditingCell {
            if viewModel.cells[editingCell.row][editingCell.col].input.hasPrefix("="),
               !(editingCell.row == row && editingCell.col == col) {
                if shift && selectionState.selectionStart != nil {
                    // Shift+click: extend existing range
                    selectionState.updateSelection(to: row, col: col)
                } else {
                    // Normal click: start new single-cell reference
                    selectionState.startSelection(at: row, col: col)
                }
                if formulaRefStart == nil {
                    formulaRefStart = viewModel.cells[editingCell.row][editingCell.col].input.count
                    formulaRefLength = 0
                }
                updateFormulaReference()
            } else if !(editingCell.row == row && editingCell.col == col) {
                let newInput = viewModel.cells[editingCell.row][editingCell.col].input
                if originalEditInput != newInput {
                    viewModel.undoStack.append([CellChange(row: editingCell.row, col: editingCell.col, oldInput: originalEditInput, newInput: newInput)])
                    viewModel.redoStack.removeAll()
                }
                viewModel.updateCell(at: editingCell.row, column: editingCell.col)
                currentEditingCell = nil
                formulaBarText = ""
                selectionState.clearSelection()
                formulaRefStart = nil
                formulaRefLength = 0
                selectedCell = (row, col)
            }
        } else if selectedCell?.row == row && selectedCell?.col == col {
            // Click on already-selected cell → enter edit mode
            originalEditInput = viewModel.cells[row][col].input
            currentEditingCell = (row, col)
            formulaBarText = viewModel.cells[row][col].input
            selectionState.clearSelection()
        } else {
            selectedCell = (row, col)
            selectionState.clearSelection()
        }
    }

    // MARK: - Keyboard Navigation

    private func moveSelection(dr: Int, dc: Int) {
        let current = selectedCell ?? (row: 0, col: 0)
        let newRow = max(0, min(viewModel.rows - 1, current.row + dr))
        let newCol = max(0, min(viewModel.columns - 1, current.col + dc))
        selectedCell = (newRow, newCol)
        selectionState.clearSelection()
    }

    private func extendSelection(dr: Int, dc: Int) {
        let anchor = selectedCell ?? (row: 0, col: 0)
        if selectionState.selectionStart == nil {
            selectionState.startSelection(at: anchor.row, col: anchor.col)
        }
        guard let end = selectionState.selectionEnd else { return }
        let newRow = max(0, min(viewModel.rows - 1, end.row + dr))
        let newCol = max(0, min(viewModel.columns - 1, end.col + dc))
        selectionState.updateSelection(to: newRow, col: newCol)
    }

    // MARK: - Formula Reference Selection

    private func cellAt(location: CGPoint) -> (row: Int, col: Int)? {
        let row = Int((location.y - headerHeight) / cellHeight)
        var x = headerWidth
        var col = -1
        for c in 0..<viewModel.columns {
            let w = colWidth(c)
            if location.x >= x && location.x < x + w {
                col = c
                break
            }
            x += w
        }
        guard row >= 0, row < viewModel.rows, col >= 0, col < viewModel.columns else { return nil }
        return (row, col)
    }

    private func handleFormulaDrag(location: CGPoint, isStart: Bool, startLocation: CGPoint) {
        guard let editingCell = currentEditingCell,
              viewModel.cells[editingCell.row][editingCell.col].input.hasPrefix("=") else { return }

        guard let startCell = cellAt(location: startLocation),
              let currentCell = cellAt(location: location) else { return }

        // Don't reference the editing cell itself
        if startCell.row == editingCell.row && startCell.col == editingCell.col { return }

        if formulaRefStart == nil {
            formulaRefStart = viewModel.cells[editingCell.row][editingCell.col].input.count
            formulaRefLength = 0
        }

        selectionState.startSelection(at: startCell.row, col: startCell.col)
        if currentCell.row != startCell.row || currentCell.col != startCell.col {
            selectionState.updateSelection(to: currentCell.row, col: currentCell.col)
        }
        updateFormulaReference()
    }

    private func handleFormulaArrowKey(keyCode: UInt16, shift: Bool) {
        guard let editingCell = currentEditingCell else { return }

        let dr: Int, dc: Int
        switch keyCode {
        case 126: (dr, dc) = (-1, 0)
        case 125: (dr, dc) = (1, 0)
        case 123: (dr, dc) = (0, -1)
        case 124: (dr, dc) = (0, 1)
        default: return
        }

        if shift && selectionState.selectionStart != nil {
            // Extend existing selection to range
            guard let end = selectionState.selectionEnd else { return }
            let newRow = max(0, min(viewModel.rows - 1, end.row + dr))
            let newCol = max(0, min(viewModel.columns - 1, end.col + dc))
            selectionState.updateSelection(to: newRow, col: newCol)
        } else if shift && selectionState.selectionStart == nil {
            // Start new range from editing cell, extend in direction
            let startRow = max(0, min(viewModel.rows - 1, editingCell.row + dr))
            let startCol = max(0, min(viewModel.columns - 1, editingCell.col + dc))
            selectionState.startSelection(at: editingCell.row, col: editingCell.col)
            selectionState.updateSelection(to: startRow, col: startCol)
            if formulaRefStart == nil {
                formulaRefStart = viewModel.cells[editingCell.row][editingCell.col].input.count
                formulaRefLength = 0
            }
        } else if !shift && selectionState.selectionStart != nil {
            // Move selection to new single cell
            guard let end = selectionState.selectionEnd else { return }
            let newRow = max(0, min(viewModel.rows - 1, end.row + dr))
            let newCol = max(0, min(viewModel.columns - 1, end.col + dc))
            selectionState.startSelection(at: newRow, col: newCol)
        } else {
            // Start new selection from editing cell + direction
            let newRow = max(0, min(viewModel.rows - 1, editingCell.row + dr))
            let newCol = max(0, min(viewModel.columns - 1, editingCell.col + dc))
            selectionState.startSelection(at: newRow, col: newCol)
            formulaRefStart = viewModel.cells[editingCell.row][editingCell.col].input.count
            formulaRefLength = 0
        }

        updateFormulaReference()
    }

    private func updateFormulaReference() {
        guard let editingCell = currentEditingCell,
              let refStart = formulaRefStart,
              let ref = selectionState.getSelectionReference() else { return }

        var input = viewModel.cells[editingCell.row][editingCell.col].input
        guard refStart <= input.count else { return }

        let startIndex = input.index(input.startIndex, offsetBy: refStart)
        let endOffset = min(refStart + formulaRefLength, input.count)
        let endIndex = input.index(input.startIndex, offsetBy: endOffset)

        input.replaceSubrange(startIndex..<endIndex, with: ref)
        viewModel.cells[editingCell.row][editingCell.col].input = input
        formulaBarText = input
        formulaRefLength = ref.count
        viewModel.objectWillChange.send()
    }

    private var tipText: some View {
        Text("SUM  AVERAGE  MIN  MAX  COUNT  PRODUCT  ROUND  ABS")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(Color(NSColor.tertiaryLabelColor))
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

struct CellView: View, Equatable {
    let displayValue: String
    let hasError: Bool
    let row: Int
    let col: Int
    let isSelected: Bool
    let isCursorCell: Bool
    let isEditing: Bool
    let inputValue: String
    var inputBinding: Binding<String>
    let onFinishEditing: (EditAction) -> Void
    let onCellClick: (Int, Int) -> Void

    static func == (lhs: CellView, rhs: CellView) -> Bool {
        lhs.displayValue == rhs.displayValue &&
        lhs.hasError == rhs.hasError &&
        lhs.row == rhs.row &&
        lhs.col == rhs.col &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isCursorCell == rhs.isCursorCell &&
        lhs.isEditing == rhs.isEditing &&
        lhs.inputValue == rhs.inputValue
    }

    private static let gridLine = Color(NSColor.separatorColor).opacity(0.4)

    var body: some View {
        ZStack(alignment: .leading) {
            if isEditing {
                CustomTextField(
                    text: inputBinding,
                    onAction: { action in onFinishEditing(action) }
                )
                .font(.system(size: 12, design: .default))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            } else {
                Text(displayValue)
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundColor(hasError ? Color(NSColor.systemRed) : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCellClick(row, col)
                    }
            }
        }
        .background(backgroundColor)
        .overlay(alignment: .bottom) {
            if !isCursorCell && !isEditing {
                Self.gridLine.frame(height: 0.5)
            }
        }
        .overlay(alignment: .trailing) {
            if !isCursorCell && !isEditing {
                Self.gridLine.frame(width: 0.5)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(focusBorderColor, lineWidth: focusBorderWidth)
        )
    }

    private var backgroundColor: Color {
        if isEditing {
            return Color(NSColor.controlBackgroundColor)
        } else if isSelected {
            return Color.accentColor.opacity(0.10)
        } else if isCursorCell {
            return Color.accentColor.opacity(0.04)
        } else if row % 2 == 1 {
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        } else {
            return .clear
        }
    }

    private var focusBorderColor: Color {
        if isCursorCell || isEditing {
            return Color.accentColor
        } else if isSelected {
            return Color.accentColor.opacity(0.35)
        } else {
            return .clear
        }
    }

    private var focusBorderWidth: CGFloat {
        (isCursorCell || isEditing) ? 2 : isSelected ? 1 : 0
    }
}

// NSTextField subclass that reports intrinsic width based on text content
private class ExpandingTextField: NSTextField {
    override var intrinsicContentSize: NSSize {
        let textWidth = attributedStringValue.size().width + 8
        let width = max(72, textWidth) // at least the cell padding area
        return NSSize(width: width, height: super.intrinsicContentSize.height)
    }
}

// Custom TextField that handles Enter, Escape, and Tab keys
struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    let onAction: (EditAction) -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = ExpandingTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
            if let editor = textField.currentEditor() {
                editor.selectedRange = NSRange(location: textField.stringValue.count, length: 0)
            }
        }
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.invalidateIntrinsicContentSize()
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
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                    parent.onAction(.commitUp)
                } else {
                    parent.onAction(.commit)
                }
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onAction(.cancel)
                return true
            }
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                parent.onAction(.tabForward)
                return true
            }
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                parent.onAction(.tabBack)
                return true
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
