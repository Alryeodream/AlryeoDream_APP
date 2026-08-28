import 'package:flutter/material.dart';
import '../../../../models/benefit.dart';

class WishlistedBenefitTile extends StatelessWidget {
  final Benefit benefit;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const WishlistedBenefitTile({
    super.key,
    required this.benefit,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        title: Text(benefit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${benefit.organization} · ${benefit.category}'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.redAccent),
          tooltip: '찜 해제',
          onPressed: onRemove,
        ),
      ),
    );
  }
}
