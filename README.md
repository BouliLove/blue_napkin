# BlueNapkin

When you want to quickly work something with formulas, but don't want to open up a new GSheet or Excel file: meet BlueNapkin.
A fast, lightweight macOS menu bar spreadsheet with Excel-like formula support.

I have been using Numi, a calculator living in my navbar since 2015, and it inspired me the same thing, but for table calculations.

## Features

- **Menu bar app** — lives in your macOS menu bar, opens as a popover
- **Excel-like editing** — click to select, type to replace, Enter to edit existing content
- **Keyboard navigation** — arrow keys, Tab, Shift+Arrow for range selection, Cmd+A to select all
- **Formula engine** — `=A1+B2*C3`, `=SUM(A1:A10)`, `=AVERAGE(B1:B5)`, `=PRODUCT(C1:C3)`
- **Formula reference selection** — while typing a formula, use arrow keys or click cells to insert references
- **Formula bar** — shows the raw formula of the selected cell at the bottom
- **Copy/paste** — Cmd+C/V/X, with multi-cell TSV paste support
- **Data persistence** — cell data saved to UserDefaults, survives app restarts
- **Launch at login** — auto-starts with your Mac, like Numi
- **Performance optimized** — Equatable views, value-type props, only changed cells re-render
- **Dark mode** — follows system appearance

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+

## Install

```bash
./scripts/bundle.sh
cp -r .build/BlueNapkin.app /Applications/
open /Applications/BlueNapkin.app
```

This builds a release binary, packages it as a `.app` bundle, and copies it to Applications. The app auto-registers as a login item on first launch — you can manage it in **System Settings > General > Login Items**.

## Development

```bash
swift build && .build/debug/BlueNapkin &
```

To rebuild after changes:

```bash
pkill -f BlueNapkin; swift build && .build/debug/BlueNapkin &
```

## Run Tests

```bash
swift test
```

47 tests covering the formula engine, cell references, and cell model.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Arrow keys | Move selection |
| Shift+Arrow | Extend selection range |
| Enter | Start editing selected cell |
| Type any character | Start editing (replaces content) |
| Tab / Shift+Tab | Move to next/previous cell |
| Escape | Cancel editing / deselect |
| Delete | Clear selected cell(s) |
| Cmd+A | Select all cells |
| Cmd+C / Cmd+V / Cmd+X | Copy / Paste / Cut |

While editing a formula (starts with `=`):

| Shortcut | Action |
|----------|--------|
| Arrow keys | Select a cell reference |
| Shift+Arrow | Extend to a range reference |
| Click another cell | Insert cell reference |

## Formula Syntax

- **Math**: `=5+3`, `=10*2`, `=(5+3)*2`
- **Cell references**: `=A1+B1`, `=A1*2`
- **SUM**: `=SUM(A1:A10)` or `=SUM(A1,B2,C3)`
- **AVERAGE**: `=AVERAGE(A1:A10)`
- **PRODUCT**: `=PRODUCT(A1:A5)`
- **Combined**: `=SUM(A1:A5)*2`, `=(SUM(A1:A5)+SUM(B1:B5))/2`

## Project Structure

```
blue_napkin/
├── Package.swift              # SPM manifest
├── BlueNapkin/
│   ├── BlueNapkinApp.swift    # App entry point
│   ├── AppDelegate.swift      # App lifecycle
│   ├── MenuBarController.swift # Menu bar icon and popover
│   ├── ContentView.swift      # Main content wrapper
│   ├── GridView.swift         # Grid, cell views, keyboard handling
│   ├── CellModel.swift        # Cell data model
│   └── FormulaEngine.swift    # Formula parser/evaluator
├── Tests/
│   └── FormulaEngineTests.swift
├── scripts/
│   └── bundle.sh             # Packages .app bundle for /Applications
└── README.md
```

## License

MIT
