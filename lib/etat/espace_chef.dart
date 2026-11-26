import 'package:flutter/foundation.dart';

import '../donnees/planning_repository.dart';
import '../modeles/compte.dart';
import '../modeles/planification.dart';
import '../theme/dates_fr.dart';

/// Planning de la semaine du chef de pôle : groupe, semaine et jour choisis
/// restent en place quand il ouvre puis referme une fiche de séance.
class EspaceChef extends ChangeNotifier {
  EspaceChef({
    required this.planning,
    required this.chef,
    DateTime Function()? horloge,
  }) : _horloge = horloge ?? DateTime.now {
    _allerA(_aujourdhui());
  }

  final PlanningRepository planning;
  final ChefPole chef;
  final DateTime Function() _horloge;

  EspacePole? pole;
  String? groupeId;
  late DateTime lundi;
  late DateTime jour;
  List<SeancePlanifiee> semaine = const [];
  bool chargement = true;
  bool erreur = false;
  bool _ferme = false;
  int _demande = 0;

  DateTime get maintenant => _horloge();

  Groupe? get groupe {
    for (final g in pole?.groupes ?? const <Groupe>[]) {
      if (g.id == groupeId) return g;
    }
    return null;
  }

  /// Lundi à samedi.
  List<DateTime> get jours => [
    for (var i = 0; i < 6; i++)
      DateTime(lundi.year, lundi.month, lundi.day + i),
  ];

  List<SeancePlanifiee> seancesDu(DateTime date) => [
    for (final s in semaine)
      if (memeJour(s.courante.debut, date)) s,
  ];

  List<SeancePlanifiee> get seancesDuJour => seancesDu(jour);

  /// Aujourd'hui, ou lundi prochain si l'on est dimanche.
  DateTime _aujourdhui() {
    final d = minuit(maintenant);
    return d.weekday == DateTime.sunday
        ? DateTime(d.year, d.month, d.day + 1)
        : d;
  }

  void _allerA(DateTime date) {
    jour = minuit(date);
    lundi = lundiDe(jour);
  }

  Future<void> charger() async {
    chargement = true;
    erreur = false;
    _notifier();
    try {
      final p = pole ?? await planning.espacePole(chef);
      pole = p;
      groupeId ??= p.groupes.isEmpty ? null : p.groupes.first.id;
    } catch (_) {
      chargement = false;
      erreur = true;
      _notifier();
      return;
    }
    await recharger();
  }

  /// Relit la semaine affichée sans toucher aux choix du chef.
  Future<void> recharger() async {
    final id = groupeId;
    if (id == null) {
      chargement = false;
      _notifier();
      return;
    }
    final demande = ++_demande;
    try {
      final liste = await planning.semaine(chef, id, lundi);
      if (demande != _demande) return;
      semaine = liste;
      erreur = false;
    } catch (_) {
      if (demande != _demande) return;
      erreur = true;
    }
    chargement = false;
    _notifier();
  }

  Future<void> choisirGroupe(String id) {
    groupeId = id;
    semaine = const [];
    chargement = true;
    _notifier();
    return recharger();
  }

  Future<void> changerDeSemaine(int decalage) {
    _allerA(DateTime(jour.year, jour.month, jour.day + 7 * decalage));
    semaine = const [];
    chargement = true;
    _notifier();
    return recharger();
  }

  Future<void> revenirAujourdhui() {
    final avant = lundi;
    _allerA(_aujourdhui());
    if (lundi == avant) {
      _notifier();
      return Future.value();
    }
    semaine = const [];
    chargement = true;
    _notifier();
    return recharger();
  }

  void choisirJour(DateTime date) {
    jour = minuit(date);
    _notifier();
  }

  void _notifier() {
    if (!_ferme) notifyListeners();
  }

  @override
  void dispose() {
    _ferme = true;
    super.dispose();
  }
}
