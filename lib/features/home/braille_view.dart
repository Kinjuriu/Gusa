import 'package:flutter/material.dart';
import 'ports.dart';

/// Renders Braille cells on screen. The user feels these; this is so the people
/// watching the demo can see what is being felt.
class BrailleView extends StatelessWidget {
  const BrailleView({super.key, required this.cells});
  final List<Cell> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: 'Braille output',
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [for (final c in cells) _CellView(cell: c)],
      ),
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({required this.cell});
  final Cell cell;

  @override
  Widget build(BuildContext context) {
    const dot = 13.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 3; row++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // dots 1,2,3 down the left column; 4,5,6 down the right
                    _dot(cell.dots.length > row ? cell.dots[row] : false, dot),
                    const SizedBox(width: 7),
                    _dot(cell.dots.length > row + 3 ? cell.dots[row + 3] : false, dot),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(cell.char, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _dot(bool on, double size) => Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? const Color(0xFFFFD166) : Colors.white10,
        ),
      );
}
