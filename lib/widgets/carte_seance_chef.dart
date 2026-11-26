import 'package:material_ui/material_ui.dart';

import '../modeles/planification.dart';
import '../theme/cmc_theme.dart';
import '../theme/dates_fr.dart';
import 'surfaces.dart';

/// Une séance dans le planning du chef : la version sur laquelle il
/// travaille, et son état écrit en toutes lettres.
class CarteSeanceChef extends StatelessWidget {
  const CarteSeanceChef({super.key, required this.seance, this.onTap});

  final SeancePlanifiee seance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    final d = seance.courante;
    return SurfaceCmc(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(plageHoraire(d.debut, d.fin), style: texte.titleLarge),
            const SizedBox(height: 2),
            Text(d.module, style: texte.titleMedium),
            Text(
              'Formateur : ${d.formateur}',
              style: texte.bodyMedium?.copyWith(color: doux),
            ),
            Text(
              'Salle ${d.salle}',
              style: texte.bodyMedium?.copyWith(color: doux),
            ),
            const SizedBox(height: 10),
            PastilleEtat(seance: seance),
          ],
        ),
      ),
    );
  }
}

/// « Publiée », « Brouillon » ou « B12 → B08 · Modification en attente ».
class PastilleEtat extends StatelessWidget {
  const PastilleEtat({super.key, required this.seance});

  final SeancePlanifiee seance;

  static String libelle(SeancePlanifiee seance) => switch (seance.etat) {
    EtatSeance.publiee => 'Publiée',
    EtatSeance.brouillon => 'Brouillon · non visible par le groupe',
    EtatSeance.modificationEnAttente => [
      ...seance.changements,
      'Modification en attente',
    ].join(' · '),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.cmc;
    final schema = Theme.of(context).colorScheme;
    final (fond, encre, bord) = switch (seance.etat) {
      EtatSeance.publiee => (c.alerteFond, c.alerteTexte, null),
      EtatSeance.brouillon => (c.surface, schema.onSurface, c.texteDoux),
      EtatSeance.modificationEnAttente => (c.attenteFond, c.attenteTexte, null),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(12),
          border: bord == null ? null : Border.all(color: bord),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            libelle(seance),
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: encre, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
