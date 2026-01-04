# BlueNapkin

A macOS menu bar calculator app with Excel-like formula capabilities, inspired by Numi.

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar for quick access
- **Excel-like Grid**: 20x10 spreadsheet-style grid for organizing calculations
- **Formula Support**: Create formulas using `=` prefix (e.g., `=A1+B2*C3`)
- **Excel Functions**: Support for SUM, PRODUCT, and AVERAGE with range notation
- **Interactive Cell Selection**: Click or drag to select cells/ranges while building formulas
- **Cell References**: Reference other cells using standard Excel notation (A1, B2, etc.)
- **Auto-calculation**: Formulas automatically recalculate when dependencies change
- **Lightweight**: Native SwiftUI app with minimal resource usage

## Screenshots

Click the 🧮 icon in your menu bar to open the calculator popover.

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later
- Xcode 14.0+ (for building) OR Swift command-line tools

## Installation

### Option 1: Build with Xcode (Easiest)

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd blue_napkin
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```

3. Build and run:
   - Press `Cmd + R` to build and run
   - Or select `Product > Run` from the menu

### Option 2: Build from Command Line

```bash
# Build the project
swift build -c release

# Run the app
open .build/release/BlueNapkin.app
```

### Option 3: Use with VSCode

1. **Install VSCode Swift Extension**:
   - Install `Swift` extension by Swift Server Work Group
   - Or `Swift Language` by swift-server

2. **Open the project**:
   ```bash
   code .
   ```

3. **Build and run**:
   ```bash
   # In VSCode terminal
   swift build -c release
   open .build/release/BlueNapkin.app

   # Or for development
   swift run
   ```

4. **VSCode Tasks** (optional) - Create `.vscode/tasks.json`:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Build BlueNapkin",
         "type": "shell",
         "command": "swift",
         "args": ["build", "-c", "release"],
         "group": {
           "kind": "build",
           "isDefault": true
         }
       },
       {
         "label": "Run BlueNapkin",
         "type": "shell",
         "command": "swift",
         "args": ["run"],
         "group": {
           "kind": "test",
           "isDefault": true
         }
       }
     ]
   }
   ```

### Building from Source

The project uses **Swift Package Manager**, so it works with:
- ✅ Xcode (open `Package.swift`)
- ✅ VSCode (with Swift extension)
- ✅ Command line (`swift build`)

The app will appear in your menu bar as a 🧮 icon.

## Usage

### Basic Usage

1. Click the 🧮 icon in your menu bar to open BlueNapkin
2. Double-click any cell to start editing
3. Enter a value or formula
4. Press `Enter` to commit the value

### Interactive Cell Selection

BlueNapkin supports visual cell selection while building formulas - no need to type cell references manually!

**How to use:**

1. **Start a formula**: Double-click a cell and type `=` to begin a formula
2. **Click to select**: Click any other cell to select it (highlighted in green)
3. **Click and drag**: Click and drag across cells to select a range
4. **Insert reference**: Press `Enter` to insert the cell/range reference into your formula
5. **Continue editing**: Type operators or functions, then select more cells as needed

**Examples:**

- **Single cell reference**:
  1. In cell C1, type `=`
  2. Click cell A1 (it turns green)
  3. Press `Enter` → formula becomes `=A1`
  4. Type `+`
  5. Click cell B1
  6. Press `Enter` → formula becomes `=A1+B1`
  7. Press `Enter` again to commit

- **Range selection for SUM**:
  1. In cell A11, type `=SUM(`
  2. Click and drag from A1 to A10 (range turns green)
  3. Press `Enter` → formula becomes `=SUM(A1:A10`
  4. Type `)`
  5. Press `Enter` to commit

- **Multiple ranges**:
  1. Type `=SUM(`
  2. Click-drag A1:A5, press `Enter`
  3. Type `,`
  4. Click-drag B1:B5, press `Enter`
  5. Formula becomes `=SUM(A1:A5,B1:B5)`

**Visual feedback:**
- 🔵 **Blue border**: Currently editing cell
- 🟢 **Green highlight**: Selected cells/range during formula editing
- **Green border**: Selected range boundary

### Formula Syntax

- **Basic math**: Enter formulas starting with `=`
  - Example: `=5+3` → `8`
  - Example: `=10*2` → `20`
  - Example: `=(5+3)*2` → `16`

- **Cell references**: Reference other cells using column letter + row number
  - Example: `=A1+B1` → Adds values from cells A1 and B1
  - Example: `=A1*2` → Multiplies A1 by 2
  - Example: `=(A1+A2)/2` → Calculates average of A1 and A2

- **Supported operators**:
  - Addition: `+`
  - Subtraction: `-`
  - Multiplication: `*`
  - Division: `/`
  - Parentheses: `()`

- **Excel functions**: Use built-in functions for common calculations
  - **SUM**: Adds all values in a range
    - Example: `=SUM(A1:A10)` → Sums cells A1 through A10
    - Example: `=SUM(A1:B5)` → Sums rectangular range A1 to B5
    - Example: `=SUM(A1,B2,C3)` → Sums specific cells

  - **PRODUCT**: Multiplies all values in a range
    - Example: `=PRODUCT(A1:A5)` → Multiplies cells A1 through A5
    - Example: `=PRODUCT(A1,B1,C1)` → Multiplies specific cells

  - **AVERAGE**: Calculates the average of values in a range
    - Example: `=AVERAGE(A1:A10)` → Averages cells A1 through A10
    - Example: `=AVERAGE(B1:B20)` → Averages cells B1 through B20

- **Combining functions and operators**:
  - Example: `=SUM(A1:A10)*2` → Sums A1:A10 and multiplies result by 2
  - Example: `=(SUM(A1:A5)+SUM(B1:B5))/2` → Averages two sums
  - Example: `=A1+SUM(B1:B10)` → Adds A1 to the sum of B1:B10

### Examples

1. **Simple calculation**:
   - Cell A1: `100`
   - Cell A2: `50`
   - Cell A3: `=A1+A2` → Result: `150`

2. **Tax calculation**:
   - Cell A1: `100` (Price)
   - Cell A2: `0.08` (Tax rate)
   - Cell A3: `=A1*A2` → Result: `8` (Tax amount)
   - Cell A4: `=A1+A3` → Result: `108` (Total)

3. **Complex formula**:
   - Cell A1: `10`
   - Cell B1: `20`
   - Cell C1: `30`
   - Cell D1: `=(A1+B1)*C1` → Result: `900`

4. **Using SUM function**:
   - Cells A1-A5: `10`, `20`, `30`, `40`, `50`
   - Cell A6: `=SUM(A1:A5)` → Result: `150`
   - Cell A7: `=SUM(A1:A5)/5` → Result: `30` (manual average)

5. **Using AVERAGE function**:
   - Cells B1-B10: `5`, `10`, `15`, `20`, `25`, `30`, `35`, `40`, `45`, `50`
   - Cell B11: `=AVERAGE(B1:B10)` → Result: `27.5`

6. **Using PRODUCT function**:
   - Cell C1: `2`
   - Cell C2: `3`
   - Cell C3: `4`
   - Cell C4: `=PRODUCT(C1:C3)` → Result: `24`

7. **Combining functions**:
   - Cells A1-A5: Monthly sales
   - Cell A6: `=SUM(A1:A5)` → Total sales
   - Cell A7: `=AVERAGE(A1:A5)` → Average sales
   - Cell A8: `=A6*0.1` → 10% commission on total

## Project Structure

```
blue_napkin/
├── Package.swift             # Swift Package Manager manifest
├── BlueNapkin/              # Source directory
│   ├── BlueNapkinApp.swift       # Main app entry point
│   ├── AppDelegate.swift         # App lifecycle management
│   ├── MenuBarController.swift   # Menu bar icon and popover management
│   ├── ContentView.swift         # Main popover content view
│   ├── GridView.swift            # Excel-like grid component
│   ├── CellModel.swift           # Data model for cells
│   ├── FormulaEngine.swift       # Formula parser and evaluator
│   ├── Info.plist                # App configuration
│   ├── BlueNapkin.entitlements   # App permissions
│   └── Assets.xcassets/          # App icon and assets
├── .gitignore
└── README.md
```

## Architecture

### Components

1. **MenuBarController**: Manages the menu bar status item and popover window
2. **GridView**: Displays the Excel-like grid interface
3. **CellModel**: Represents individual cells with input, display value, and error state
4. **FormulaEngine**: Parses and evaluates formulas with cell references

### Formula Evaluation

The formula engine works in three stages:

1. **Function Processing**: Recognizes and evaluates Excel functions (SUM, PRODUCT, AVERAGE) with range support
2. **Cell Reference Replacement**: Replaces cell references (e.g., `A1`, `B2`) with their actual values
3. **Expression Evaluation**: Evaluates the mathematical expression using `NSExpression`

### Auto-recalculation

When a cell is updated, all cells containing formulas are re-evaluated to ensure consistency.

## Customization

### Grid Size

To change the grid dimensions, edit `GridViewModel` in `GridView.swift`:

```swift
let rows = 20    // Change number of rows
let columns = 10 // Change number of columns
```

### Cell Dimensions

To adjust cell size, edit the constants in `GridView`:

```swift
let cellWidth: CGFloat = 80   // Cell width in pixels
let cellHeight: CGFloat = 30  // Cell height in pixels
```

### Menu Bar Icon

To change the menu bar icon, edit `MenuBarController.swift`:

```swift
button.title = "🧮"  // Change to your preferred icon
```

Or use an image:

```swift
button.image = NSImage(named: "YourIconName")
```

## Known Limitations

- Limited Excel function support (currently: SUM, PRODUCT, AVERAGE)
- No data persistence (calculations are lost when app closes)
- No copy/paste functionality
- No keyboard navigation between cells
- Limited to 20 rows × 10 columns

## Future Enhancements

- [x] Implement basic Excel functions (SUM, PRODUCT, AVERAGE) ✓
- [ ] Add more Excel functions (MIN, MAX, COUNT, IF, ROUND, etc.)
- [ ] Add data persistence (save/load calculations)
- [ ] Add keyboard navigation (arrow keys, Tab)
- [ ] Add copy/paste support
- [ ] Add cell formatting (colors, alignment, number formats)
- [ ] Add multiple sheets/tabs
- [ ] Add export to CSV/Excel
- [ ] Add customizable keyboard shortcuts
- [ ] Add themes (dark mode support)
- [ ] Add history/undo functionality
- [ ] Add named ranges
- [ ] Add conditional formatting

## Troubleshooting

### App doesn't appear in menu bar

- Make sure the app is running (check Activity Monitor)
- The app has `LSUIElement` set to `true`, so it won't appear in the Dock
- Look for the 🧮 icon in your menu bar

### Formulas show #ERROR

- Check formula syntax (must start with `=`)
- Ensure cell references are valid (e.g., A1-J20)
- Avoid circular references (A1 = B1, B1 = A1)
- Check for division by zero

### Build errors in Xcode

- Ensure you're using macOS 13.0+ and Xcode 14.0+
- Clean build folder: `Product > Clean Build Folder` (Cmd+Shift+K)
- Restart Xcode

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests

## License

This project is open source and available under the MIT License.

## Credits

Inspired by [Numi](https://numi.app/) - a beautiful calculator app for macOS.
