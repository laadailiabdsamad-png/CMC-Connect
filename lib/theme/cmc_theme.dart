import 'package:material_ui/material_ui.dart';

import '../modeles/apparence.dart';

/// Couleurs propres à CMC Connect, reprises de la maquette du rapport.
@immutable
class CmcCouleurs extends ThemeExtension<CmcCouleurs> {
  const CmcCouleurs({
    required this.verre,
    required this.fond,
    required this.halo,
    required this.halo2,
    required this.surface,
    required this.teinteVerre,
    required this.bordVerre,
    required this.texteDoux,
    required this.alerteFond,
    required this.alerteTexte,
    required this.attenteFond,
    required this.attenteTexte,
  });

  final bool verre;
  final Color fond;
  final Color halo;
  final Color halo2;
  final Color surface;
  final Color teinteVerre;
  final Color bordVerre;
  final Color texteDoux;
  final Color alerteFond;
  final Color alerteTexte;

  /// Pastille « Modification en attente ».
  final Color attenteFond;
  final Color attenteTexte;

  @override
  CmcCouleurs copyWith() => this;

  @override
  CmcCouleurs lerp(CmcCouleurs? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return CmcCouleurs(
      verre: t < 0.5 ? verre : other.verre,
      fond: c(fond, other.fond),
      halo: c(halo, other.halo),
      halo2: c(halo2, other.halo2),
      surface: c(surface, other.surface),
      teinteVerre: c(teinteVerre, other.teinteVerre),
      bordVerre: c(bordVerre, other.bordVerre),
      texteDoux: c(texteDoux, other.texteDoux),
      alerteFond: c(alerteFond, other.alerteFond),
      alerteTexte: c(alerteTexte, other.alerteTexte),
      attenteFond: c(attenteFond, other.attenteFond),
      attenteTexte: c(attenteTexte, other.attenteTexte),
    );
  }
}

extension CmcContexte on BuildContext {
  CmcCouleurs get cmc => Theme.of(this).extension<CmcCouleurs>()!;
}

ThemeMode modeDe(Luminosite luminosite) => switch (luminosite) {
  Luminosite.clair => ThemeMode.light,
  Luminosite.sombre => ThemeMode.dark,
  Luminosite.systeme => ThemeMode.system,
};

Brightness luminositeResolue(Luminosite choix, Brightness telephone) =>
    switch (choix) {
      Luminosite.clair => Brightness.light,
      Luminosite.sombre => Brightness.dark,
      Luminosite.systeme => telephone,
    };

ThemeData themeCmc(StyleApp style, Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final verre = style == StyleApp.liquidGlass;

  final encre = sombre ? Colors.white : const Color(0xFF17332F);
  final accent = sombre ? const Color(0xFFB4F7E1) : const Color(0xFF1A5F55);

  final couleurs = sombre
      ? CmcCouleurs(
          verre: verre,
          fond: const Color(0xFF163A48),
          halo: const Color(0xFF2A6776),
          halo2: const Color(0xFF1D4F5A),
          surface: const Color(0xFF28505E),
          teinteVerre: const Color(0xB3355E6C),
          bordVerre: const Color(0x80C9E9E6),
          texteDoux: const Color(0xFFDCEBEA),
          alerteFond: const Color(0xFFB4F7E1),
          alerteTexte: const Color(0xFF0F3A33),
          attenteFond: const Color(0xFFFFD48A),
          attenteTexte: const Color(0xFF3A2500),
        )
      : CmcCouleurs(
          verre: verre,
          fond: const Color(0xFFF0F5F2),
          halo: const Color(0xFFA9DDE6),
          halo2: const Color(0xFFBFEBD9),
          surface: Colors.white,
          teinteVerre: const Color(0xA6FFFFFF),
          bordVerre: Colors.white,
          texteDoux: const Color(0xFF3E5853),
          alerteFond: const Color(0xFFA6EBCF),
          alerteTexte: const Color(0xFF0F3A33),
          attenteFond: const Color(0xFFFFE1A8),
          attenteTexte: const Color(0xFF4A2F00),
        );

  final schema =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A5F55),
        brightness: luminosite,
      ).copyWith(
        primary: accent,
        onPrimary: sombre ? const Color(0xFF0F3A33) : Colors.white,
        secondaryContainer: couleurs.alerteFond,
        onSecondaryContainer: couleurs.alerteTexte,
        surface: couleurs.fond,
        onSurface: encre,
        onSurfaceVariant: couleurs.texteDoux,
      );

  final base = ThemeData(colorScheme: schema, brightness: luminosite);
  final texte = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: couleurs.fond,
    extensions: [couleurs],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: encre,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: texte
        .copyWith(
          headlineMedium: texte.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: texte.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          titleLarge: texte.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: texte.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: encre, displayColor: encre),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: couleurs.surface,
      labelStyle: TextStyle(color: couleurs.texteDoux),
      floatingLabelStyle: TextStyle(color: encre),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: couleurs.texteDoux),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: couleurs.alerteFond,
      iconTheme: WidgetStateProperty.resolveWith(
        (etats) => IconThemeData(
          color: etats.contains(WidgetState.selected)
              ? couleurs.alerteTexte
              : couleurs.texteDoux,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (etats) => texte.labelMedium?.copyWith(
          color: encre,
          fontWeight: etats.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}
