# BlueNapkin

A macOS menu bar calculator app with Excel-like formula capabilities, inspired by Numi.

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar for quick access
- **Excel-like Grid**: 20x10 spreadsheet-style grid for organizing calculations
- **Formula Support**: Create formulas using `=` prefix (e.g., `=A1+B2*C3`)
- **Cell References**: Reference other cells using standard Excel notation (A1, B2, etc.)
- **Auto-calculation**: Formulas automatically recalculate when dependencies change
- **Lightweight**: Native SwiftUI app with minimal resource usage

## Screenshots

Click the 🧮 icon in your menu bar to open the calculator popover.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.9 or later

## Installation

### Building from Source

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd blue_napkin
   ```

2. Open the project in Xcode:
   ```bash
   open BlueNapkin.xcodeproj
   ```

3. Build and run the project:
   - Press `Cmd + R` to build and run
   - Or select `Product > Run` from the menu

4. The app will launch and appear in your menu bar as a 🧮 icon

## Usage

### Basic Usage

1. Click the 🧮 icon in your menu bar to open BlueNapkin
2. Double-click any cell to start editing
3. Enter a value or formula
4. Press `Enter` to commit the value

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

## Project Structure

```
BlueNapkin/
├── BlueNapkinApp.swift       # Main app entry point
├── AppDelegate.swift         # App lifecycle management
├── MenuBarController.swift   # Menu bar icon and popover management
├── ContentView.swift         # Main popover content view
├── GridView.swift            # Excel-like grid component
├── CellModel.swift           # Data model for cells
├── FormulaEngine.swift       # Formula parser and evaluator
├── Info.plist                # App configuration
├── BlueNapkin.entitlements   # App permissions
└── Assets.xcassets/          # App icon and assets
```

## Architecture

### Components

1. **MenuBarController**: Manages the menu bar status item and popover window
2. **GridView**: Displays the Excel-like grid interface
3. **CellModel**: Represents individual cells with input, display value, and error state
4. **FormulaEngine**: Parses and evaluates formulas with cell references

### Formula Evaluation

The formula engine works in two stages:

1. **Cell Reference Replacement**: Replaces cell references (e.g., `A1`, `B2`) with their actual values
2. **Expression Evaluation**: Evaluates the mathematical expression using `NSExpression`

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

- No support for advanced Excel functions (SUM, AVERAGE, etc.) yet
- No data persistence (calculations are lost when app closes)
- No copy/paste functionality
- No keyboard navigation between cells
- Limited to 20 rows × 10 columns

## Future Enhancements

- [ ] Add data persistence (save/load calculations)
- [ ] Implement Excel functions (SUM, AVERAGE, MIN, MAX, etc.)
- [ ] Add keyboard navigation (arrow keys, Tab)
- [ ] Add copy/paste support
- [ ] Add cell formatting (colors, alignment)
- [ ] Add multiple sheets/tabs
- [ ] Add export to CSV/Excel
- [ ] Add customizable keyboard shortcuts
- [ ] Add themes (dark mode support)
- [ ] Add history/undo functionality

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
