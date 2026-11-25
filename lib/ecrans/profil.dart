import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../theme/cmc_theme.dart';
import '../widgets/surfaces.dart';
import 'reglage_apparence.dart';

class Profil extends StatelessWidget {
  const Profil({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    final marges = MediaQuery.paddingOf(context);
    final stagiaire = session.actif!;
    final choix = session.apparence;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, marges.top + 16, 16, marges.bottom + 16),
      children: [
        Text('Profil', style: texte.headlineMedium),
        const SizedBox(height: 20),
        SurfaceCmc(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(stagiaire.prenom, style: texte.titleLarge),
                Text('Groupe ${stagiaire.groupe}', style: texte.titleMedium),
                const SizedBox(height: 6),
                Text(
                  stagiaire.filiere,
                  style: texte.bodyMedium?.copyWith(color: doux),
                ),
                Text(
                  'Pôle ${stagiaire.pole}',
                  style: texte.bodyMedium?.copyWith(color: doux),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCmc(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Apparence'),
            subtitle: Text(
              '${choix.style.libelle}, ${choix.luminosite.libelle}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReglageApparence(session: session),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCmc(
          child: ListTile(
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('Changer de compte'),
            onTap: session.changerDeCompte,
          ),
        ),
      ],
    );
  }
}
