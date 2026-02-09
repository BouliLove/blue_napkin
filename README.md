# BlueNapkin

A macOS menu bar calculator with Excel-like formula capabilities, inspired by [Numi](https://numi.app/).

## Features

- **Quick Access**: Lives in your macOS menu bar as a 🧮 icon
- **Excel-like Grid**: 20x10 spreadsheet-style grid for organizing calculations
- **Formula Support**: Create formulas using `=` prefix (e.g., `=A1+B2*C3`)
- **Excel Functions**: SUM, PRODUCT, and AVERAGE with range notation
- **Interactive Cell Selection**: Click or drag to select cells/ranges while building formulas
- **Cell References**: Standard Excel notation (A1, B2, etc.)
- **Auto-calculation**: Formulas automatically recalculate when dependencies change
- **Lightweight**: Native SwiftUI app with minimal resource usage

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

3. Build and run: `Cmd + R`

### Option 2: Build from Command Line

```bash
swift build -c release
open .build/release/BlueNapkin.app
```

### Option 3: Use with VSCode

1. Install the `Swift` extension by Swift Server Work Group
2. Open the project: `code .`
3. Build and run:
   ```bash
   swift build -c release
   open .build/release/BlueNapkin.app
   ```

The app will appear in your menu bar as a 🧮 icon.

## Usage

### Basic Usage

1. Click the 🧮 icon in your menu bar to open BlueNapkin
2. Double-click any cell to start editing
3. Enter a value or formula
4. Press `Enter` to commit the value

### Interactive Cell Selection

1. **Start a formula**: Double-click a cell and type `=`
2. **Click to select**: Click any other cell to insert its reference (highlighted in green)
3. **Click and drag**: Drag across cells to select a range
4. **Continue editing**: Type operators or functions, then select more cells

**Visual feedback:**
- Blue border: Currently editing cell
- Green highlight: Selected cells/range during formula editing

### Formula Syntax

- **Basic math**: `=5+3`, `=10*2`, `=(5+3)*2`
- **Cell references**: `=A1+B1`, `=A1*2`
- **Operators**: `+`, `-`, `*`, `/`, `()`
- **SUM**: `=SUM(A1:A10)`, `=SUM(A1,B2,C3)`
- **PRODUCT**: `=PRODUCT(A1:A5)`
- **AVERAGE**: `=AVERAGE(A1:A10)`
- **Combined**: `=SUM(A1:A10)*2`, `=(SUM(A1:A5)+SUM(B1:B5))/2`

### Examples

| Cell | Input | Result | Description |
|------|-------|--------|-------------|
| A1 | `100` | 100 | Price |
| A2 | `0.08` | 0.08 | Tax rate |
| A3 | `=A1*A2` | 8 | Tax amount |
| A4 | `=A1+A3` | 108 | Total |
| A6 | `=SUM(A1:A5)` | 216.08 | Sum of range |
| A7 | `=AVERAGE(A1:A4)` | 54.02 | Average |

## Project Structure

```
blue_napkin/
├── Package.swift                # Swift Package Manager manifest
├── BlueNapkin/                  # Source directory
│   ├── BlueNapkinApp.swift          # Main app entry point
│   ├── AppDelegate.swift            # App lifecycle management
│   ├── MenuBarController.swift      # Menu bar icon and popover
│   ├── ContentView.swift            # Main popover content view
│   ├── GridView.swift               # Excel-like grid component
│   ├── CellModel.swift              # Cell data model
│   ├── FormulaEngine.swift          # Formula parser and evaluator
│   ├── Info.plist                   # App configuration
│   ├── BlueNapkin.entitlements      # App permissions
│   └── Assets.xcassets/             # App icon and assets
├── .gitignore
└── README.md
```

## Architecture

1. **MenuBarController**: Manages the menu bar status item and popover window
2. **GridView**: Displays the Excel-like grid interface
3. **CellModel**: Represents individual cells with input, display value, and error state
4. **FormulaEngine**: Parses and evaluates formulas with cell references (NSExpression-based)

## Customization

### Grid Size

Edit `GridViewModel` in `GridView.swift`:
```swift
let rows = 20    // Change number of rows
let columns = 10 // Change number of columns
```

### Menu Bar Icon

Edit `MenuBarController.swift`:
```swift
button.title = "🧮"  // Change to your preferred icon
```

## Known Limitations

- Limited Excel function support (currently: SUM, PRODUCT, AVERAGE)
- No data persistence (calculations are lost when app closes)
- No copy/paste functionality
- Limited to 20 rows x 10 columns

## Future Enhancements

- [x] Basic Excel functions (SUM, PRODUCT, AVERAGE)
- [ ] More functions (MIN, MAX, COUNT, IF, ROUND, etc.)
- [ ] Data persistence (save/load calculations)
- [ ] Copy/paste support
- [ ] Cell formatting (colors, alignment, number formats)
- [ ] Multiple sheets/tabs
- [ ] Export to CSV
- [ ] Undo/redo
- [ ] Dark mode support

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

## License

This project is open source and available under the MIT License.

## Credits

Inspired by [Numi](https://numi.app/) - a beautiful calculator app for macOS.
