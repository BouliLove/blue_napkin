// Grid Component for BlueNapkin
class Grid {
  constructor(rows, cols) {
    this.rows = rows;
    this.cols = cols;
    this.cells = [];
    this.formulaEngine = new FormulaEngine();
    this.editingCell = null;
    this.selectedCell = null; // Track selected (focused) cell
    this.selectionStart = null;
    this.selectionEnd = null;
    this.isSelecting = false;
    this.isDragging = false;

    this.initializeCells();
    this.setupKeyboardListeners();
  }

  initializeCells() {
    for (let row = 0; row < this.rows; row++) {
      this.cells[row] = [];
      for (let col = 0; col < this.cols; col++) {
        this.cells[row][col] = {
          input: '',
          displayValue: '',
          hasError: false
        };
      }
    }
  }

  setupKeyboardListeners() {
    document.addEventListener('keydown', (e) => {
      // Only handle if not currently editing
      if (this.editingCell) return;

      // Arrow key navigation
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
        e.preventDefault();
        this.handleArrowKey(e.key);
        return;
      }

      // Enter key - start editing selected cell
      if (e.key === 'Enter' && this.selectedCell) {
        e.preventDefault();
        this.startEditing(this.selectedCell.row, this.selectedCell.col);
        return;
      }

      // Any printable character - start editing and insert character
      if (this.selectedCell && !e.ctrlKey && !e.metaKey && !e.altKey && e.key.length === 1) {
        e.preventDefault();
        this.startEditing(this.selectedCell.row, this.selectedCell.col, e.key);
        return;
      }

      // Backspace or Delete - clear cell
      if (this.selectedCell && (e.key === 'Backspace' || e.key === 'Delete')) {
        e.preventDefault();
        this.cells[this.selectedCell.row][this.selectedCell.col].input = '';
        this.evaluateCell(this.selectedCell.row, this.selectedCell.col);
        this.reevaluateAll();
        this.saveToStorage();
        return;
      }
    });
  }

  handleArrowKey(key) {
    if (!this.selectedCell) {
      // No cell selected, select first cell
      this.selectCell(0, 0);
      return;
    }

    let newRow = this.selectedCell.row;
    let newCol = this.selectedCell.col;

    switch (key) {
      case 'ArrowUp':
        newRow = Math.max(0, newRow - 1);
        break;
      case 'ArrowDown':
        newRow = Math.min(this.rows - 1, newRow + 1);
        break;
      case 'ArrowLeft':
        newCol = Math.max(0, newCol - 1);
        break;
      case 'ArrowRight':
        newCol = Math.min(this.cols - 1, newCol + 1);
        break;
    }

    this.selectCell(newRow, newCol);
  }

  selectCell(row, col) {
    // Clear previous selection
    if (this.selectedCell) {
      const prevCell = this.getCellElement(this.selectedCell.row, this.selectedCell.col);
      if (prevCell) {
        prevCell.classList.remove('selected-cell');
      }
    }

    // Set new selection
    this.selectedCell = { row, col };
    const cellElement = this.getCellElement(row, col);
    if (cellElement) {
      cellElement.classList.add('selected-cell');
      // Scroll into view if needed
      cellElement.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }

    this.updateCellInfo();
  }

  render(container) {
    container.innerHTML = '';

    // Create header row
    const headerRow = document.createElement('div');
    headerRow.className = 'grid-row';

    // Corner cell
    const corner = document.createElement('div');
    corner.className = 'cell corner';
    headerRow.appendChild(corner);

    // Column headers
    for (let col = 0; col < this.cols; col++) {
      const header = document.createElement('div');
      header.className = 'cell header';
      header.textContent = this.columnName(col);
      headerRow.appendChild(header);
    }
    container.appendChild(headerRow);

    // Create data rows
    for (let row = 0; row < this.rows; row++) {
      const rowElement = document.createElement('div');
      rowElement.className = 'grid-row';

      // Row header
      const rowHeader = document.createElement('div');
      rowHeader.className = 'cell row-header';
      rowHeader.textContent = (row + 1).toString();
      rowElement.appendChild(rowHeader);

      // Data cells
      for (let col = 0; col < this.cols; col++) {
        const cellElement = this.createCellElement(row, col);
        rowElement.appendChild(cellElement);
      }

      container.appendChild(rowElement);
    }

    // Restore selected cell highlight
    if (this.selectedCell) {
      const cellElement = this.getCellElement(this.selectedCell.row, this.selectedCell.col);
      if (cellElement) {
        cellElement.classList.add('selected-cell');
      }
    }
  }

  createCellElement(row, col) {
    const cell = document.createElement('div');
    cell.className = 'cell';
    cell.dataset.row = row;
    cell.dataset.col = col;

    const content = document.createElement('div');
    content.className = 'cell-content';
    content.textContent = this.cells[row][col].displayValue;
    cell.appendChild(content);

    if (this.cells[row][col].hasError) {
      cell.classList.add('error');
    }

    // Single click to select cell (or for formula selection)
    cell.addEventListener('click', (e) => {
      this.handleCellClick(row, col);
    });

    // Double-click to start editing immediately
    cell.addEventListener('dblclick', (e) => {
      e.preventDefault();
      this.startEditing(row, col);
    });

    // Mouse down for drag selection during formula editing
    cell.addEventListener('mousedown', (e) => {
      if (this.editingCell && this.isFormulaCell(this.editingCell.row, this.editingCell.col)) {
        this.isDragging = true;
        this.startSelection(row, col);
        e.preventDefault();
      }
    });

    // Mouse enter for drag
    cell.addEventListener('mouseenter', (e) => {
      if (this.isDragging && this.isSelecting) {
        this.updateSelection(row, col);
      }
    });

    return cell;
  }

  startEditing(row, col, initialChar = null) {
    // End any previous editing
    if (this.editingCell) {
      this.endEditing();
    }

    this.editingCell = { row, col };
    this.selectedCell = { row, col }; // Keep cell selected
    this.clearSelection();

    const cellElement = this.getCellElement(row, col);
    const input = document.createElement('input');
    input.className = 'cell-input';

    // If initial character provided, start with that, otherwise use cell value
    if (initialChar !== null) {
      input.value = initialChar;
      this.cells[row][col].input = initialChar;
    } else {
      input.value = this.cells[row][col].input;
    }

    input.autocomplete = 'off';

    cellElement.innerHTML = '';
    cellElement.appendChild(input);
    cellElement.classList.add('focused');
    cellElement.classList.remove('selected-cell'); // Remove selection highlight during editing

    input.focus();

    // Move cursor to end if we started with a character
    if (initialChar !== null) {
      input.setSelectionRange(input.value.length, input.value.length);
    } else {
      input.select();
    }

    // Handle keyboard in input
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        if (this.selectionStart && this.selectionEnd) {
          // Insert selection reference
          const reference = this.getSelectionReference();
          const cursorPos = input.selectionStart;
          const newValue = input.value.slice(0, cursorPos) + reference + input.value.slice(input.selectionEnd);
          input.value = newValue;
          this.cells[row][col].input = newValue;
          this.clearSelection();
          input.focus();
          input.setSelectionRange(cursorPos + reference.length, cursorPos + reference.length);
          this.updateCellInfo();
        } else {
          // Commit the cell and move down
          this.cells[row][col].input = input.value;
          this.endEditing();
          this.evaluateCell(row, col);
          this.reevaluateAll();

          // Move to next row
          if (row < this.rows - 1) {
            this.selectCell(row + 1, col);
          }
        }
        e.preventDefault();
      } else if (e.key === 'Escape') {
        this.endEditing();
      } else if (e.key === 'Tab') {
        // Tab to next cell
        e.preventDefault();
        this.cells[row][col].input = input.value;
        this.endEditing();
        this.evaluateCell(row, col);
        this.reevaluateAll();

        // Move to next column (or wrap to next row)
        let newCol = col + 1;
        let newRow = row;
        if (newCol >= this.cols) {
          newCol = 0;
          newRow = row + 1;
        }
        if (newRow < this.rows) {
          this.selectCell(newRow, newCol);
        }
      } else if (e.key.startsWith('Arrow')) {
        // Allow arrow navigation while editing
        e.stopPropagation();
      }
    });

    // Update cell info as user types
    input.addEventListener('input', () => {
      this.cells[row][col].input = input.value;
      this.updateCellInfo();
    });

    // Blur event
    input.addEventListener('blur', () => {
      setTimeout(() => {
        if (this.editingCell && this.editingCell.row === row && this.editingCell.col === col) {
          this.cells[row][col].input = input.value;
          this.endEditing();
          this.evaluateCell(row, col);
          this.reevaluateAll();
        }
      }, 100);
    });

    this.updateCellInfo();
  }

  endEditing() {
    if (!this.editingCell) return;

    const { row, col } = this.editingCell;
    const cellElement = this.getCellElement(row, col);

    cellElement.classList.remove('focused');
    cellElement.innerHTML = '';

    const content = document.createElement('div');
    content.className = 'cell-content';
    content.textContent = this.cells[row][col].displayValue;
    cellElement.appendChild(content);

    if (this.cells[row][col].hasError) {
      cellElement.classList.add('error');
    } else {
      cellElement.classList.remove('error');
    }

    // Restore selected cell highlight
    if (this.selectedCell && this.selectedCell.row === row && this.selectedCell.col === col) {
      cellElement.classList.add('selected-cell');
    }

    this.editingCell = null;
    this.clearSelection();
    this.updateCellInfo();
    this.saveToStorage();
  }

  handleCellClick(row, col) {
    // If editing a formula in another cell, this is for formula cell selection
    if (this.editingCell &&
        this.isFormulaCell(this.editingCell.row, this.editingCell.col) &&
        !(this.editingCell.row === row && this.editingCell.col === col)) {
      this.startSelection(row, col);
    } else if (!this.editingCell) {
      // Not editing, just select the cell
      this.selectCell(row, col);
    }
  }

  startSelection(row, col) {
    this.selectionStart = { row, col };
    this.selectionEnd = { row, col };
    this.isSelecting = true;
    this.updateSelectionUI();
  }

  updateSelection(row, col) {
    if (!this.isSelecting) return;
    this.selectionEnd = { row, col };
    this.updateSelectionUI();
  }

  clearSelection() {
    this.selectionStart = null;
    this.selectionEnd = null;
    this.isSelecting = false;
    this.updateSelectionUI();
  }

  updateSelectionUI() {
    // Clear all selection highlights
    document.querySelectorAll('.cell.selected').forEach(cell => {
      cell.classList.remove('selected');
    });

    // Apply new selection
    if (this.selectionStart && this.selectionEnd) {
      const minRow = Math.min(this.selectionStart.row, this.selectionEnd.row);
      const maxRow = Math.max(this.selectionStart.row, this.selectionEnd.row);
      const minCol = Math.min(this.selectionStart.col, this.selectionEnd.col);
      const maxCol = Math.max(this.selectionStart.col, this.selectionEnd.col);

      for (let row = minRow; row <= maxRow; row++) {
        for (let col = minCol; col <= maxCol; col++) {
          const cellElement = this.getCellElement(row, col);
          if (cellElement) {
            cellElement.classList.add('selected');
          }
        }
      }

      // Update selection info
      const ref = this.getSelectionReference();
      document.getElementById('selectionInfo').textContent = `Selected: ${ref}`;
    } else {
      document.getElementById('selectionInfo').textContent = '';
    }
  }

  getSelectionReference() {
    if (!this.selectionStart || !this.selectionEnd) return '';

    const startRef = this.cellReference(this.selectionStart.row, this.selectionStart.col);
    const endRef = this.cellReference(this.selectionEnd.row, this.selectionEnd.col);

    if (this.selectionStart.row === this.selectionEnd.row &&
        this.selectionStart.col === this.selectionEnd.col) {
      return startRef;
    }

    return `${startRef}:${endRef}`;
  }

  isFormulaCell(row, col) {
    return this.cells[row][col].input.startsWith('=');
  }

  evaluateCell(row, col) {
    const cell = this.cells[row][col];
    cell.hasError = false;

    if (cell.input === '') {
      cell.displayValue = '';
      return;
    }

    if (cell.input.startsWith('=')) {
      // It's a formula
      try {
        const formula = cell.input.substring(1);
        const result = this.formulaEngine.evaluate(formula, (r, c) => {
          return this.getCellValue(r, c);
        });
        cell.displayValue = result;
      } catch (error) {
        cell.displayValue = '#ERROR';
        cell.hasError = true;
      }
    } else {
      // Plain value
      cell.displayValue = cell.input;
    }
  }

  reevaluateAll() {
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        if (this.cells[row][col].input.startsWith('=')) {
          this.evaluateCell(row, col);
        }
      }
    }
    this.render(document.getElementById('grid'));
  }

  getCellValue(row, col) {
    if (row < 0 || row >= this.rows || col < 0 || col >= this.cols) {
      return '';
    }
    return this.cells[row][col].displayValue;
  }

  getCellElement(row, col) {
    return document.querySelector(`.cell[data-row="${row}"][data-col="${col}"]`);
  }

  columnName(index) {
    let name = '';
    let col = index;
    while (col >= 0) {
      name = String.fromCharCode(65 + (col % 26)) + name;
      col = Math.floor(col / 26) - 1;
    }
    return name;
  }

  cellReference(row, col) {
    return this.columnName(col) + (row + 1);
  }

  updateCellInfo() {
    if (this.editingCell) {
      const { row, col } = this.editingCell;
      const ref = this.cellReference(row, col);
      const input = this.cells[row][col].input;
      document.getElementById('cellInfo').textContent = `${ref}: ${input || 'Empty'}`;
    } else if (this.selectedCell) {
      const { row, col } = this.selectedCell;
      const ref = this.cellReference(row, col);
      const value = this.cells[row][col].displayValue || 'Empty';
      document.getElementById('cellInfo').textContent = `${ref}: ${value}`;
    } else {
      document.getElementById('cellInfo').textContent = 'Click a cell to select';
    }
  }

  clear() {
    this.initializeCells();
    this.selectedCell = null;
    this.render(document.getElementById('grid'));
    this.saveToStorage();
  }

  // Storage methods
  async saveToStorage() {
    try {
      await chrome.storage.local.set({ cells: this.cells });
    } catch (error) {
      console.error('Failed to save to storage:', error);
    }
  }

  async loadFromStorage() {
    try {
      const result = await chrome.storage.local.get(['cells']);
      if (result.cells) {
        this.cells = result.cells;
        this.reevaluateAll();
      }
      // Auto-select first cell
      this.selectCell(0, 0);
    } catch (error) {
      console.error('Failed to load from storage:', error);
    }
  }
}
