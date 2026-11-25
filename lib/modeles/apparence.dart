enum StyleApp {
  simple('Simple', 'Surfaces unies, sans transparence.'),
  liquidGlass(
    'Liquid Glass',
    'Transparence sur la prochaine séance et la barre de navigation.',
  );

  const StyleApp(this.libelle, this.description);
  final String libelle;
  final String description;
}

enum Luminosite {
  clair('Clair'),
  sombre('Sombre'),
  systeme('Système');

  const Luminosite(this.libelle);
  final String libelle;
}

class Apparence {
  const Apparence({
    this.style = StyleApp.simple,
    this.luminosite = Luminosite.systeme,
  });

  final StyleApp style;
  final Luminosite luminosite;

  Apparence copie({StyleApp? style, Luminosite? luminosite}) => Apparence(
    style: style ?? this.style,
    luminosite: luminosite ?? this.luminosite,
  );

  /// Forme enregistrée sur l'appareil, par exemple « liquidGlass/sombre ».
  String encoder() => '${style.name}/${luminosite.name}';

  /// Une valeur absente ou inconnue redonne l'apparence par défaut.
  static Apparence decoder(String? valeur) {
    final morceaux = valeur?.split('/') ?? const [];
    if (morceaux.length != 2) return const Apparence();
    final style = StyleApp.values.asNameMap()[morceaux[0]];
    final luminosite = Luminosite.values.asNameMap()[morceaux[1]];
    if (style == null || luminosite == null) return const Apparence();
    return Apparence(style: style, luminosite: luminosite);
  }

  @override
  bool operator ==(Object other) =>
      other is Apparence &&
      other.style == style &&
      other.luminosite == luminosite;

  @override
  int get hashCode => Object.hash(style, luminosite);
}
