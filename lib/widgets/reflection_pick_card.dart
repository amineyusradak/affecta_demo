import 'package:flutter/material.dart';
import '../models/reflection_card.dart';

class ReflectionPickCard extends StatelessWidget {
  final ReflectionCard card;
  final bool selected;
  final VoidCallback onTap;

  const ReflectionPickCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              border: Border.all(width: selected ? 2 : 1, color: borderColor),
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  card.accent.withOpacity(0.16),
                  Colors.white,
                ],
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: card.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(card.icon, color: card.accent),
                  ),
                ),
                const Spacer(),
                Text(
                  card.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  card.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 10),
                if (selected)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: card.accent),
                      const SizedBox(width: 6),
                      Text("Seçildi", style: TextStyle(fontSize: 12, color: card.accent)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
