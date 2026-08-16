/// Visual & logical state of an individual tile on the spatial grid.
enum GridCellStatus {
  normal,
  previewTarget,
  foundCorrect,
  withinError,
  betweenError,
}

/// Coordinate model for spatial grid cells.
class GridCell {
  final int row;
  final int col;
  final int index;
  final GridCellStatus status;

  const GridCell({
    required this.row,
    required this.col,
    required this.index,
    this.status = GridCellStatus.normal,
  });

  GridCell copyWith({GridCellStatus? status}) {
    return GridCell(
      row: row,
      col: col,
      index: index,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCell && runtimeType == other.runtimeType && index == other.index;

  @override
  int get hashCode => index.hashCode;
}
