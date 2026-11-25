import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/theme/cmc_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Rapport de contraste WCAG entre deux couleurs opaques.
double contraste(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  for (final style in StyleApp.values) {
    for (final luminosite in Brightness.values) {
      test('contraste du texte : ${style.libelle} ${luminosite.name}', () {
        final theme = themeCmc(style, luminosite);
        final c = theme.extension<CmcCouleurs>()!;
        final derriere = [c.fond, c.halo, c.halo2, c.surface];
        final fonds = [
          ...derriere,
          // Le verre posé sur chacune des couleurs possibles.
          for (final d in derriere) Color.alphaBlend(c.teinteVerre, d),
        ];
        final textes = [
          theme.colorScheme.onSurface,
          c.texteDoux,
          theme.colorScheme.primary,
        ];
        for (final fond in fonds) {
          for (final texte in textes) {
            expect(
              contraste(texte, fond),
              greaterThanOrEqualTo(4.5),
              reason: 'texte $texte sur $fond',
            );
          }
        }
        expect(
          contraste(c.alerteTexte, c.alerteFond),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}
