import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../modeles/compte.dart';
import '../theme/cmc_theme.dart';
import '../widgets/surfaces.dart';
import 'reglage_apparence.dart';

class Profil extends StatelessWidget {
  const Profil({super.key, required this.session, this.apresReinitialisation});

  final Session session;

  /// Appelé quand le chef a remis la démonstration à zéro.
  final Future<void> Function()? apresReinitialisation;

  Future<void> _reinitialiser(BuildContext context) async {
    final messager = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser la démonstration ?'),
        content: const Text(
          'Toutes les séances créées, les brouillons et les publications '
          'seront remplacés par le planning de départ, à partir du prochain '
          'jour de cours. Les réglages d’apparence sont conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await session.planning.reinitialiser();
      await apresReinitialisation?.call();
      messager.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Planning de démonstration réinitialisé.'),
        ),
      );
    } catch (_) {
      messager.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('La réinitialisation a échoué. Réessayez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    final marges = MediaQuery.paddingOf(context);
    final compte = session.actif!;
    final choix = session.apparence;
    final lignes = switch (compte) {
      Stagiaire() => [
        'Groupe ${compte.groupe}',
        compte.filiere,
        'Pôle ${compte.pole}',
      ],
      ChefPole() => ['Chef de pôle', 'Pôle ${compte.pole}'],
    };
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
                Text(compte.nom, style: texte.titleLarge),
                Text(lignes.first, style: texte.titleMedium),
                const SizedBox(height: 6),
                for (final ligne in lignes.skip(1))
                  Text(ligne, style: texte.bodyMedium?.copyWith(color: doux)),
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
        if (compte is ChefPole) ...[
          const SizedBox(height: 12),
          SurfaceCmc(
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Réinitialiser la démonstration'),
              subtitle: const Text('Revenir au planning de départ'),
              onTap: () => _reinitialiser(context),
            ),
          ),
        ],
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
