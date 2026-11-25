import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../modeles/seance.dart';
import '../theme/cmc_theme.dart';
import '../theme/dates_fr.dart';
import '../widgets/carte_seance.dart';
import '../widgets/message_planning.dart';

class Planning extends StatelessWidget {
  const Planning({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final marges = MediaQuery.paddingOf(context);
    final prochaine = session.prochaine;
    final parJour = <DateTime, List<Seance>>{};
    for (final seance in session.seances) {
      final d = seance.debut;
      (parJour[DateTime(d.year, d.month, d.day)] ??= []).add(seance);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, marges.top + 16, 16, marges.bottom + 16),
      children: [
        Text('Planning', style: texte.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Groupe ${session.actif!.groupe}',
          style: texte.titleMedium?.copyWith(
            color: context.cmc.texteDoux,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (parJour.isEmpty) ...[
          const SizedBox(height: 20),
          MessagePlanning(
            erreur: session.erreur,
            onReessayer: session.rafraichir,
          ),
        ],
        for (final MapEntry(key: jour, value: seances) in parJour.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Semantics(
              header: true,
              child: Text(
                jourFr(jour, session.maintenant),
                style: texte.titleMedium,
              ),
            ),
          ),
          for (final seance in seances)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CarteSeance(
                key: ValueKey('planning-${seance.id}'),
                seance: seance,
                titre: seance.id == prochaine?.id ? 'PROCHAINE SÉANCE' : null,
              ),
            ),
        ],
      ],
    );
  }
}
