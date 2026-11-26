import 'package:material_ui/material_ui.dart';

import '../modeles/seance.dart';
import '../theme/cmc_theme.dart';
import '../theme/dates_fr.dart';
import 'surfaces.dart';

/// Même carte sur l'accueil, dans le planning et dans l'aperçu du thème.
class CarteSeance extends StatelessWidget {
  const CarteSeance({
    super.key,
    required this.seance,
    this.titre,
    this.sousTitre,
    this.verre = false,
    this.onTap,
    this.vueFormateur = false,
  });

  final Seance seance;
  final String? titre;
  final String? sousTitre;
  final bool verre;
  final VoidCallback? onTap;

  /// Le formateur voit le groupe à la place de son propre nom.
  final bool vueFormateur;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    return SurfaceCmc(
      verre: verre,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titre case final titre?)
              Text(
                titre,
                style: texte.labelLarge?.copyWith(
                  color: doux,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (sousTitre case final sousTitre?)
              Text(sousTitre, style: texte.bodyMedium?.copyWith(color: doux)),
            if (titre != null || sousTitre != null) const SizedBox(height: 8),
            Text(
              '${heureFr(seance.debut)} · Salle ${seance.salle}',
              style: texte.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(seance.module, style: texte.titleMedium),
            const SizedBox(height: 2),
            Text(
              vueFormateur
                  ? 'Groupe ${seance.groupe}'
                  : 'Formateur : ${seance.formateur}',
              style: texte.bodyMedium?.copyWith(color: doux),
            ),
            Text(
              'Fin à ${heureFr(seance.fin)}',
              style: texte.bodyMedium?.copyWith(color: doux),
            ),
            if (seance.salleModifiee) ...[
              const SizedBox(height: 12),
              _SalleModifiee(seance),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalleModifiee extends StatelessWidget {
  const _SalleModifiee(this.seance);

  final Seance seance;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.cmc;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: couleurs.alerteFond,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Salle modifiée · ${seance.ancienneSalle} → ${seance.salle}',
            semanticsLabel:
                'Salle modifiée : ${seance.salle} remplace '
                '${seance.ancienneSalle}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: couleurs.alerteTexte,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
