import SwiftUI

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
    @FocusState private var focusedCell: UUID?

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
                                isFocused: focusedCell == viewModel.cells[row][col].id,
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
    let isFocused: Bool
    let onCommit: () -> Void

    @State private var isEditing = false

    var body: some View {
        ZStack {
            if isEditing {
                TextField("", text: $cell.input, onCommit: {
                    isEditing = false
                    onCommit()
                })
                .textFieldStyle(PlainTextFieldStyle())
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
                    }
            }
        }
        .background(isEditing || isFocused ? Color.blue.opacity(0.1) : Color.white)
        .border(isFocused ? Color.blue : Color.gray.opacity(0.3))
        .onChange(of: isFocused) { newValue in
            if !newValue {
                isEditing = false
            }
        }
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView()
            .frame(width: 600, height: 400)
    }
}
