import 'package:flutter/material.dart';

import '../model/rubric_spec.dart';

/// One part's name and its score: a chip per point for parts out of 10 or
/// less, a number box otherwise.
class RubricPartScorer extends StatelessWidget {
  const RubricPartScorer({
    super.key,
    required this.part,
    required this.score,
    required this.onScore,
  });

  final RubricPart part;
  final int? score;
  final ValueChanged<int?> onScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${part.label} (out of ${part.maxPoints})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (part.maxPoints <= 10)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var points = 0; points <= part.maxPoints; points++)
                ChoiceChip(
                  label: Text('$points'),
                  selected: score == points,
                  onSelected: (_) => onScore(points),
                ),
            ],
          )
        else
          TextFormField(
            initialValue: score?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '0 to ${part.maxPoints}'),
            onChanged: (value) => onScore(int.tryParse(value.trim())),
          ),
      ],
    );
  }
}
