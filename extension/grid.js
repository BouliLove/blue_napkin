// Grid Component for BlueNapkin
class Grid {
  constructor(rows, cols) {
    this.rows = rows;
    this.cols = cols;
    this.cells = [];
    this.formulaEngine = new FormulaEngine();
    this.editingCell = null;
    this.selectionStart = null;
    this.selectionEnd = null;
    this.isSelecting = false;
    this.isDragging = false;

    this.initializeCells();
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

    // Double-click to edit
    cell.addEventListener('dblclick', (e) => {
      this.startEditing(row, col);
    });

    // Single click for selection during formula editing
    cell.addEventListener('click', (e) => {
      this.handleCellClick(row, col);
    });

    // Mouse down for drag selection
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

  startEditing(row, col) {
    // End any previous editing
    if (this.editingCell) {
      this.endEditing();
    }

    this.editingCell = { row, col };
    this.clearSelection();

    const cellElement = this.getCellElement(row, col);
    const input = document.createElement('input');
    input.className = 'cell-input';
    input.value = this.cells[row][col].input;
    input.autocomplete = 'off';

    cellElement.innerHTML = '';
    cellElement.appendChild(input);
    cellElement.classList.add('focused');

    input.focus();
    input.select();

    // Handle Enter key
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        if (this.selectionStart && this.selectionEnd) {
          // Insert selection reference
          const reference = this.getSelectionReference();
          input.value += reference;
          this.clearSelection();
          input.focus();
          this.updateCellInfo();
        } else {
          // Commit the cell
          this.cells[row][col].input = input.value;
          this.endEditing();
          this.evaluateCell(row, col);
          this.reevaluateAll();
        }
        e.preventDefault();
      } else if (e.key === 'Escape') {
        this.endEditing();
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

    this.editingCell = null;
    this.clearSelection();
    this.updateCellInfo();
    this.saveToStorage();
  }

  handleCellClick(row, col) {
    // Only handle clicks when editing a formula in another cell
    if (this.editingCell &&
        this.isFormulaCell(this.editingCell.row, this.editingCell.col) &&
        !(this.editingCell.row === row && this.editingCell.col === col)) {
      this.startSelection(row, col);
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
    } else {
      document.getElementById('cellInfo').textContent = 'Click a cell to edit';
    }
  }

  clear() {
    this.initializeCells();
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
    } catch (error) {
      console.error('Failed to load from storage:', error);
    }
  }
}
