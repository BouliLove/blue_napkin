# BlueNapkin Browser Extension

A quick calculator with Excel-like formulas, accessible from your browser toolbar. Works in Chrome, Arc, Edge, Brave, and any Chromium-based browser!

## ✨ Features

- **Excel-like Grid**: 20x10 spreadsheet interface
- **Formula Support**: Use `=A1+B2`, `=A1*2`, etc.
- **Excel Functions**: `SUM`, `PRODUCT`, `AVERAGE` with range support
- **Interactive Selection**: Click or drag cells to build formulas visually
- **Auto-save**: Your calculations are automatically saved
- **Fast Access**: One-click from browser toolbar

## 🚀 Installation

### Option 1: Install from Chrome Web Store (Coming Soon)
*Extension will be published soon*

### Option 2: Install Locally (Developer Mode)

1. **Download the extension**:
   - Clone or download this repository
   - Navigate to the `extension/` folder

2. **Create icon files** (if not already present):
   ```bash
   # The extension needs icon.png files
   # You can use any 128x128 image or create from the icon.svg:
   # - Use an online SVG to PNG converter
   # - Or just use any calculator emoji image
   ```

3. **Open Chrome/Arc Extensions page**:
   - Chrome: Go to `chrome://extensions/`
   - Arc: Go to `arc://extensions/` or use Chrome's URL
   - Edge: Go to `edge://extensions/`

4. **Enable Developer Mode**:
   - Toggle the "Developer mode" switch in the top-right corner

5. **Load the extension**:
   - Click "Load unpacked"
   - Select the `extension/` folder
   - BlueNapkin will appear in your extensions!

6. **Pin to toolbar** (optional):
   - Click the puzzle piece icon in your browser toolbar
   - Find "BlueNapkin" and click the pin icon
   - Now it's always visible!

## 📖 How to Use

### Basic Usage

1. **Open BlueNapkin**: Click the 🧮 icon in your toolbar
2. **Enter data**: Double-click any cell to start typing
3. **Create formulas**: Start with `=` (e.g., `=A1+B2`)
4. **Press Enter**: Commit your changes

### Interactive Cell Selection

Build formulas visually without typing cell references!

1. **Start a formula**: Double-click a cell and type `=`
2. **Click to select**: Click another cell (it turns green)
3. **Press Enter**: The cell reference is inserted
4. **Drag for ranges**: Click and drag to select multiple cells
5. **Continue**: Type `+`, `-`, `*`, `/` or functions, then select more cells

**Example - Building `=A1+B1`**:
1. Double-click C1, type `=`
2. Click A1 → turns green
3. Press Enter → formula becomes `=A1`
4. Type `+`
5. Click B1 → turns green
6. Press Enter → formula becomes `=A1+B1`
7. Press Enter again → calculation complete!

**Example - Building `=SUM(A1:A10)`**:
1. Double-click A11, type `=SUM(`
2. Click and drag from A1 to A10 → range turns green
3. Press Enter → formula becomes `=SUM(A1:A10`
4. Type `)`
5. Press Enter → sum is calculated!

### Formula Syntax

**Basic Math**:
```
=5+3         → 8
=10*2        → 20
=(5+3)*2     → 16
```

**Cell References**:
```
=A1+B1       → Adds A1 and B1
=A1*2        → Multiplies A1 by 2
=(A1+A2)/2   → Average of A1 and A2
```

**Excel Functions**:

- **SUM**: Add values
  ```
  =SUM(A1:A10)      → Sum cells A1 through A10
  =SUM(A1:B5)       → Sum rectangular range
  =SUM(A1,B2,C3)    → Sum specific cells
  ```

- **PRODUCT**: Multiply values
  ```
  =PRODUCT(A1:A5)   → Multiply A1 through A5
  =PRODUCT(2,3,4)   → 24
  ```

- **AVERAGE**: Calculate mean
  ```
  =AVERAGE(A1:A10)  → Average of A1 through A10
  =AVERAGE(B1:B20)  → Average of B1 through B20
  ```

**Combining Functions**:
```
=SUM(A1:A10)*2           → Sum times 2
=(SUM(A1:A5)+SUM(B1:B5))/2  → Average of two sums
=A1+SUM(B1:B10)          → A1 plus sum of B1:B10
```

### Visual Feedback

- **Blue border**: Currently editing cell
- **Green highlight**: Selected cells/range during formula building
- **Red text**: Formula error

## 🎯 Use Cases

### Budget Tracker
```
A1: 100 (Groceries)
A2: 50  (Gas)
A3: 200 (Rent)
A4: =SUM(A1:A3)  → 350 (Total)
```

### Sales Calculator
```
A1: 1000 (Price)
A2: 0.15 (Commission rate)
A3: =A1*A2  → 150 (Commission)
A4: =A1-A3  → 850 (Net)
```

### Quick Calculations
```
A1: 123
A2: 456
A3: =A1+A2     → 579
A4: =A3*0.08   → 46.32 (8% tax)
A5: =A3+A4     → 625.32 (Total with tax)
```

## 🛠️ Development

### File Structure
```
extension/
├── manifest.json       # Extension configuration
├── popup.html          # Main UI
├── popup.css           # Styling
├── popup.js            # Main script
├── grid.js             # Grid component
├── formula-engine.js   # Formula evaluator
├── icon.svg            # Icon source
├── icon16.png          # 16x16 icon
├── icon48.png          # 48x48 icon
├── icon128.png         # 128x128 icon
└── README.md           # This file
```

### Making Changes

1. Edit the files in the `extension/` folder
2. Go to `chrome://extensions/`
3. Click the refresh icon on the BlueNapkin extension
4. Test your changes

### Customization

**Change grid size** (in `popup.js`):
```javascript
grid = new Grid(20, 10); // rows, columns
```

**Change popup size** (in `popup.css`):
```css
body {
  width: 600px;   /* Change width */
  height: 500px;  /* Change height */
}
```

## 🔒 Privacy

- **All data stays local**: Calculations are saved in your browser's local storage
- **No tracking**: No analytics, no data collection
- **No internet required**: Works completely offline
- **No permissions needed**: Only uses local storage permission

## 🐛 Troubleshooting

### Extension doesn't load
- Make sure Developer Mode is enabled
- Check that you selected the `extension/` folder, not a parent folder
- Look for error messages in the extensions page

### Formulas show #ERROR
- Check formula syntax (must start with `=`)
- Verify cell references are valid (A1-J20)
- Avoid circular references (A1=B1, B1=A1)
- Check for division by zero

### Data not saving
- Check browser storage settings
- Try clearing browser cache and reloading extension
- Make sure you're pressing Enter to commit changes

### Icons not showing
- Convert `icon.svg` to PNG files (16x16, 48x48, 128x128)
- Or use any calculator emoji image
- Name them: `icon16.png`, `icon48.png`, `icon128.png`

## 📝 Keyboard Shortcuts

- **Double-click**: Start editing cell
- **Enter**: Insert selection reference (when selecting) or commit cell (when done)
- **Escape**: Cancel editing
- **Click**: Select single cell (during formula editing)
- **Click + Drag**: Select range (during formula editing)

## 🎨 Browser Compatibility

✅ **Tested and works on**:
- Chrome (v88+)
- Arc Browser
- Microsoft Edge (Chromium)
- Brave Browser
- Vivaldi
- Opera (Chromium-based)

## 🚧 Known Limitations

- Limited to 20 rows × 10 columns
- Only 3 Excel functions (SUM, PRODUCT, AVERAGE)
- No keyboard navigation between cells (yet)
- No copy/paste between cells (yet)
- No cell formatting (colors, alignment)

## 🔮 Future Enhancements

- [ ] More Excel functions (MIN, MAX, COUNT, IF, ROUND)
- [ ] Keyboard navigation (arrow keys, Tab)
- [ ] Copy/paste support
- [ ] Export to CSV
- [ ] Import from clipboard
- [ ] Cell formatting
- [ ] Multiple sheets
- [ ] Dark mode
- [ ] Custom grid size
- [ ] Named ranges

## 📜 License

MIT License - Feel free to use, modify, and distribute!

## 🤝 Contributing

Found a bug? Want a feature?
- Open an issue
- Submit a pull request
- Fork and customize for your needs!

---

**Made with ❤️ for quick calculations**

Inspired by Numi and Excel, but simpler and always one click away in your browser!
