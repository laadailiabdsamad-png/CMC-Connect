import 'package:material_ui/material_ui.dart';

import 'surfaces.dart';

/// Message affiché quand il n'y a pas de séance à montrer.
class MessagePlanning extends StatelessWidget {
  const MessagePlanning({
    super.key,
    required this.erreur,
    required this.onReessayer,
  });

  final bool erreur;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => SurfaceCmc(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            erreur
                ? 'Les données n’ont pas pu être chargées.'
                : 'Aucune séance à venir pour votre groupe.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (erreur) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onReessayer,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    ),
  );
}
