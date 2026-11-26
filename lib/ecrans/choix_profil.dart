import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../modeles/compte.dart';
import '../theme/cmc_theme.dart';
import '../widgets/message_planning.dart';
import '../widgets/surfaces.dart';

class ChoixProfil extends StatelessWidget {
  const ChoixProfil({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    return FondCmc(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const _Logos(),
              const SizedBox(height: 28),
              Text('CMC Connect', style: texte.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Choisissez un compte de démonstration. '
                'Les personnes et les groupes sont fictifs.',
                style: texte.bodyLarge?.copyWith(color: doux),
              ),
              const SizedBox(height: 20),
              if (session.erreur)
                MessagePlanning(erreur: true, onReessayer: session.demarrer),
              for (final profil in session.profils)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCmc(
                    onTap: () => session.choisir(profil),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profil.nom, style: texte.titleLarge),
                                Text(switch (profil) {
                                  Stagiaire() => 'Groupe ${profil.groupe}',
                                  ChefPole() => 'Chef de pôle',
                                }, style: texte.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  switch (profil) {
                                    Stagiaire() => profil.filiere,
                                    ChefPole() =>
                                      'Planning des groupes du pôle ${profil.pole}',
                                  },
                                  style: texte.bodyMedium?.copyWith(
                                    color: doux,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les logos gardent un fond blanc : leur gris disparaîtrait en mode sombre.
class _Logos extends StatelessWidget {
  const _Logos();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          Image.asset(
            'assets/logos/logo_cmc.png',
            height: 92,
            semanticLabel: 'Cités des Métiers et des Compétences',
          ),
          // Le fichier fourni fait 139 × 118 pixels : affiché plus grand, il
          // deviendrait flou sur un écran comme celui du S23+.
          Image.asset(
            'assets/logos/logo_ofppt.png',
            height: 56,
            semanticLabel: 'OFPPT, la voie de l’avenir',
          ),
        ],
      ),
    ),
  );
}
