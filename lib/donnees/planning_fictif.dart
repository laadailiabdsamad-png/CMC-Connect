import '../modeles/seance.dart';
import '../modeles/stagiaire.dart';
import 'planning_repository.dart';

/// Données de démonstration : personnes, groupes et horaires sont inventés.
///
/// Les dates partent du prochain jour ouvré pour que la démonstration ait
/// toujours la même prochaine séance, quel que soit le jour où on la lance.
class PlanningFictif implements PlanningRepository {
  PlanningFictif({DateTime Function()? horloge})
    : _horloge = horloge ?? DateTime.now;

  final DateTime Function() _horloge;

  static const _ines = Stagiaire(
    id: 'stagiaire-ines',
    prenom: 'Inès',
    groupe: 'DEV 201',
    filiere: 'Développement Digital, option Applications Mobiles',
    pole: 'Digital et Intelligence Artificielle',
  );

  static const _yassine = Stagiaire(
    id: 'stagiaire-yassine',
    prenom: 'Yassine',
    groupe: 'GE 102',
    filiere: 'Gestion des Entreprises',
    pole: 'Gestion et Commerce',
  );

  static const Map<String, List<_Modele>> _planning = {
    'stagiaire-ines': [
      _Modele(0, 10, 0, 'Développement mobile', 'M. Amrani', 'B08', 'B12'),
      _Modele(0, 14, 0, 'Conception d’interfaces', 'Mme Tazi', 'B05'),
      _Modele(1, 8, 30, 'Programmation Dart', 'M. Amrani', 'B12'),
      _Modele(2, 10, 0, 'Gestion de projet', 'Mme Idrissi', 'C03'),
    ],
    'stagiaire-yassine': [
      _Modele(0, 14, 0, 'Comptabilité générale', 'Mme Bennani', 'A04'),
      _Modele(1, 10, 0, 'Droit commercial', 'M. Chraibi', 'A11'),
      _Modele(2, 8, 30, 'Communication professionnelle', 'Mme Alaoui', 'A02'),
    ],
  };

  @override
  Future<List<Stagiaire>> profils() async => const [_ines, _yassine];

  @override
  Future<List<Seance>> seances(Stagiaire stagiaire) async {
    final modeles = _planning[stagiaire.id] ?? const <_Modele>[];
    if (modeles.isEmpty) return const [];

    final maintenant = _horloge();
    var jour = DateTime(maintenant.year, maintenant.month, maintenant.day);
    while (_estWeekend(jour) ||
        !modeles.first.debut(jour).isAfter(maintenant)) {
      jour = DateTime(jour.year, jour.month, jour.day + 1);
    }

    final seances = <Seance>[];
    for (final (index, modele) in modeles.indexed) {
      final debut = modele.debut(_ajouterJoursOuvres(jour, modele.decalage));
      seances.add(
        Seance(
          id: '${stagiaire.id}-$index',
          module: modele.module,
          formateur: modele.formateur,
          debut: debut,
          fin: debut.add(const Duration(hours: 2)),
          salle: modele.salle,
          ancienneSalle: modele.ancienneSalle,
        ),
      );
    }
    return seances;
  }

  static bool _estWeekend(DateTime jour) => jour.weekday > DateTime.friday;

  static DateTime _ajouterJoursOuvres(DateTime depart, int nombre) {
    var jour = depart;
    for (var restant = nombre; restant > 0;) {
      jour = DateTime(jour.year, jour.month, jour.day + 1);
      if (!_estWeekend(jour)) restant--;
    }
    return jour;
  }
}

class _Modele {
  const _Modele(
    this.decalage,
    this.heure,
    this.minute,
    this.module,
    this.formateur,
    this.salle, [
    this.ancienneSalle,
  ]);

  /// Nombre de jours ouvrés après le premier jour affiché.
  final int decalage;
  final int heure;
  final int minute;
  final String module;
  final String formateur;
  final String salle;
  final String? ancienneSalle;

  DateTime debut(DateTime jour) =>
      DateTime(jour.year, jour.month, jour.day, heure, minute);
}
