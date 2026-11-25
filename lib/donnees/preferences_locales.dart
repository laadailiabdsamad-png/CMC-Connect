import 'package:shared_preferences/shared_preferences.dart';

import '../modeles/apparence.dart';

/// Réglages conservés sur l'appareil, séparément pour chaque compte.
abstract interface class PreferencesLocales {
  Future<String?> dernierCompte();
  Future<void> retenirCompte(String? stagiaireId);
  Future<Apparence> apparence(String stagiaireId);
  Future<void> enregistrerApparence(String stagiaireId, Apparence apparence);
}

class PreferencesAppareil implements PreferencesLocales {
  final _prefs = SharedPreferencesAsync();

  static const _cleCompte = 'dernier_compte';
  static String _cleApparence(String id) => 'apparence.$id';

  @override
  Future<String?> dernierCompte() => _prefs.getString(_cleCompte);

  @override
  Future<void> retenirCompte(String? stagiaireId) => stagiaireId == null
      ? _prefs.remove(_cleCompte)
      : _prefs.setString(_cleCompte, stagiaireId);

  @override
  Future<Apparence> apparence(String stagiaireId) async =>
      Apparence.decoder(await _prefs.getString(_cleApparence(stagiaireId)));

  @override
  Future<void> enregistrerApparence(String stagiaireId, Apparence apparence) =>
      _prefs.setString(_cleApparence(stagiaireId), apparence.encoder());
}
