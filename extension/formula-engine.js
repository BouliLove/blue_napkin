// Formula Engine for BlueNapkin
class FormulaEngine {
  evaluate(formula, getCellValue) {
    try {
      // First process functions (SUM, PRODUCT, AVERAGE)
      let processedFormula = this.processFunctions(formula, getCellValue);

      // Then replace cell references
      processedFormula = this.replaceCellReferences(processedFormula, getCellValue);

      // Finally evaluate the expression
      const result = this.evaluateExpression(processedFormula);

      return this.formatResult(result);
    } catch (error) {
      throw new Error('Invalid formula');
    }
  }

  processFunctions(formula, getCellValue) {
    const functionPattern = /(SUM|PRODUCT|AVERAGE)\s*\(([^)]+)\)/gi;

    return formula.replace(functionPattern, (match, funcName, args) => {
      const values = this.parseArguments(args, getCellValue);
      return this.applyFunction(funcName.toUpperCase(), values);
    });
  }

  parseArguments(args, getCellValue) {
    const argList = args.split(',').map(arg => arg.trim());
    const values = [];

    for (const arg of argList) {
      if (arg.includes(':')) {
        // It's a range like A1:A10
        values.push(...this.parseRange(arg, getCellValue));
      } else {
        // It's a single cell reference
        const cellValue = this.parseSingleCell(arg, getCellValue);
        if (cellValue !== null) {
          values.push(cellValue);
        }
      }
    }

    return values;
  }

  parseRange(range, getCellValue) {
    const parts = range.split(':').map(p => p.trim());
    if (parts.length !== 2) {
      throw new Error('Invalid range');
    }

    const start = this.parseCellReference(parts[0]);
    const end = this.parseCellReference(parts[1]);

    const values = [];
    const minRow = Math.min(start.row, end.row);
    const maxRow = Math.max(start.row, end.row);
    const minCol = Math.min(start.col, end.col);
    const maxCol = Math.max(start.col, end.col);

    for (let row = minRow; row <= maxRow; row++) {
      for (let col = minCol; col <= maxCol; col++) {
        const cellValue = getCellValue(row, col);
        const numValue = parseFloat(cellValue);
        if (!isNaN(numValue) && cellValue !== '') {
          values.push(numValue);
        }
      }
    }

    return values;
  }

  parseSingleCell(cell, getCellValue) {
    const ref = this.parseCellReference(cell);
    const cellValue = getCellValue(ref.row, ref.col);
    const numValue = parseFloat(cellValue);
    return !isNaN(numValue) && cellValue !== '' ? numValue : 0;
  }

  parseCellReference(ref) {
    const match = ref.match(/^([A-Z]+)([0-9]+)$/);
    if (!match) {
      throw new Error('Invalid cell reference');
    }

    const col = this.columnNameToIndex(match[1]);
    const row = parseInt(match[2]) - 1;

    return { row, col };
  }

  columnNameToIndex(name) {
    let index = 0;
    for (let i = 0; i < name.length; i++) {
      index = index * 26 + (name.charCodeAt(i) - 65 + 1);
    }
    return index - 1;
  }

  applyFunction(funcName, values) {
    if (values.length === 0) return 0;

    switch (funcName) {
      case 'SUM':
        return values.reduce((a, b) => a + b, 0);
      case 'PRODUCT':
        return values.reduce((a, b) => a * b, 1);
      case 'AVERAGE':
        return values.reduce((a, b) => a + b, 0) / values.length;
      default:
        throw new Error('Unknown function');
    }
  }

  replaceCellReferences(formula, getCellValue) {
    const cellPattern = /([A-Z]+)([0-9]+)/g;

    return formula.replace(cellPattern, (match, col, row) => {
      try {
        const ref = this.parseCellReference(match);
        const cellValue = getCellValue(ref.row, ref.col);
        return cellValue === '' ? '0' : cellValue;
      } catch {
        return match;
      }
    });
  }

  evaluateExpression(expression) {
    // Clean the expression
    const cleaned = expression.replace(/\s/g, '');

    // Use Function constructor for safe evaluation
    // This is safer than eval but still needs validation
    try {
      const result = new Function('return ' + cleaned)();
      if (!isFinite(result)) {
        throw new Error('Invalid result');
      }
      return result;
    } catch {
      throw new Error('Invalid expression');
    }
  }

  formatResult(value) {
    if (Number.isInteger(value)) {
      return value.toString();
    } else {
      // Show up to 6 decimal places, remove trailing zeros
      return parseFloat(value.toFixed(6)).toString();
    }
  }
}
