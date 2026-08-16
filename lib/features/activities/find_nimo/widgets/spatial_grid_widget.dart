import 'package:flutter/material.dart';
import '../models/grid_cell.dart';

/// Dynamic NxN Spatial Grid with 3D tactile tiles & NIMO character reveal.
class SpatialGridWidget extends StatelessWidget {
  final int gridSize;
  final List<GridCell> cells;
  final bool isInteractive;
  final Function(int) onCellTapped;

  const SpatialGridWidget({
    super.key,
    required this.gridSize,
    required this.cells,
    required this.isInteractive,
    required this.onCellTapped,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridDimension = constraints.maxWidth;
          final spacing = gridSize >= 5 ? 8.0 : 12.0;
          final totalSpacing = spacing * (gridSize - 1);
          final cellSize = (gridDimension - totalSpacing) / gridSize;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cells.map((cell) {
              final isNimoVisible = cell.status == GridCellStatus.previewTarget ||
                  cell.status == GridCellStatus.foundCorrect;
              final isWithinError = cell.status == GridCellStatus.withinError;
              final isBetweenError = cell.status == GridCellStatus.betweenError;

              return GestureDetector(
                onTap: isInteractive ? () => onCellTapped(cell.index) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: isNimoVisible
                        ? const Color(0xFF85D64B)
                        : (isWithinError
                            ? const Color(0xFFFFBF27)
                            : (isBetweenError ? const Color(0xFFFF3B63) : const Color(0xFFFFFBF0))),
                    borderRadius: BorderRadius.circular(gridSize >= 5 ? 16 : 20),
                    border: Border.all(
                      color: isNimoVisible ? Colors.white : const Color(0xFFE2D6B5),
                      width: isNimoVisible ? 2.5 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isNimoVisible
                            ? const Color(0xFF4F8528)
                            : (isBetweenError ? const Color(0xFFCC1A40) : const Color(0x200F220A)),
                        offset: Offset(0, isNimoVisible ? 4 : 3),
                        blurRadius: isNimoVisible ? 6 : 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isNimoVisible
                        ? _buildMiniNimoIcon(cellSize * 0.55)
                        : (isWithinError || isBetweenError
                            ? Icon(
                                isBetweenError ? Icons.close_rounded : Icons.priority_high_rounded,
                                color: Colors.white,
                                size: cellSize * 0.45,
                              )
                            : null),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMiniNimoIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF98E65B),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Text('😺', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
