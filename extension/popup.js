// Main popup script
let grid;

// Initialize when popup opens
document.addEventListener('DOMContentLoaded', async () => {
  // Create grid (20 rows x 10 columns)
  grid = new Grid(20, 10);

  // Load saved data
  await grid.loadFromStorage();

  // Render grid
  grid.render(document.getElementById('grid'));

  // Clear button
  document.getElementById('clearBtn').addEventListener('click', () => {
    if (confirm('Clear all cells? This cannot be undone.')) {
      grid.clear();
    }
  });

  // Stop drag selection on mouse up anywhere
  document.addEventListener('mouseup', () => {
    if (grid.isDragging) {
      grid.isDragging = false;
    }
  });
});
