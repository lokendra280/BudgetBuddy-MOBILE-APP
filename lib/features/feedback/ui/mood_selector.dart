import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final int? selected; // 1-5
  final ValueChanged<int> onSelect;
  const MoodSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const _moods = ['😞', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(_moods.length, (i) {
      final value = i + 1;
      final isSelected = selected == value;
      return GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(_moods[i], style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
    }),
  );
}
