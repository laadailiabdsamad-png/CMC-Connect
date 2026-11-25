import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../theme/cmc_theme.dart';
import '../theme/dates_fr.dart';
import '../widgets/carte_seance.dart';
import '../widgets/message_planning.dart';

class Accueil extends StatelessWidget {
  const Accueil({
    super.key,
    required this.session,
    required this.ouvrirPlanning,
  });

  final Session session;
  final VoidCallback ouvrirPlanning;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final marges = MediaQuery.paddingOf(context);
    final stagiaire = session.actif!;
    final prochaine = session.prochaine;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, marges.top + 16, 16, marges.bottom + 16),
      children: [
        Text('Accueil', style: texte.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${stagiaire.prenom} · Groupe ${stagiaire.groupe}',
          style: texte.titleMedium?.copyWith(
            color: context.cmc.texteDoux,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        if (prochaine == null)
          MessagePlanning(
            erreur: session.erreur,
            onReessayer: session.rafraichir,
          )
        else ...[
          CarteSeance(
            key: ValueKey('accueil-${prochaine.id}'),
            seance: prochaine,
            titre: 'PROCHAINE SÉANCE',
            sousTitre: jourFr(prochaine.debut, session.maintenant),
            verre: true,
            onTap: ouvrirPlanning,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: ouvrirPlanning,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Voir dans le planning'),
          ),
        ],
      ],
    );
  }
}
