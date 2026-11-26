const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

// Espaces insécables : « 10 h 00 » ne se coupe pas en fin de ligne.
String heureFr(DateTime d) =>
    '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';

String jourFr(DateTime d, DateTime maintenant) {
  // En UTC, l'écart entre deux minuits est toujours un multiple de 24 heures.
  final ecart = DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(maintenant.year, maintenant.month, maintenant.day));
  final date = '${d.day} ${_mois[d.month - 1]}';
  return switch (ecart.inDays) {
    0 => 'Aujourd’hui, $date',
    1 => 'Demain, $date',
    _ => '${_jours[d.weekday - 1]} $date',
  };
}

const _nbsp = ' ';

bool memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime minuit(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lundi de la semaine de [d].
DateTime lundiDe(DateTime d) =>
    DateTime(d.year, d.month, d.day - d.weekday + 1);

/// « 11 h » ou « 8 h 30 », pour les messages.
String heureCourte(DateTime d) => d.minute == 0
    ? '${d.hour}${_nbsp}h'
    : '${d.hour}${_nbsp}h$_nbsp${d.minute.toString().padLeft(2, '0')}';

/// « 10 h 00 – 12 h 00 ».
String plageHoraire(DateTime debut, DateTime fin) =>
    '${heureFr(debut)}$_nbsp– ${heureFr(fin)}';

/// « 26 novembre ».
String jourMois(DateTime d) => '${d.day}$_nbsp${_mois[d.month - 1]}';

/// « Jeudi 26 novembre ».
String dateLongue(DateTime d) => '${_jours[d.weekday - 1]} ${jourMois(d)}';

/// « jeu. ».
String jourAbrege(DateTime d) =>
    '${_jours[d.weekday - 1].substring(0, 3).toLowerCase()}.';

/// « Semaine du 23 au 28 novembre », sur six jours de cours.
String semaineFr(DateTime lundi) {
  final samedi = DateTime(lundi.year, lundi.month, lundi.day + 5);
  final debut = lundi.month == samedi.month ? '${lundi.day}' : jourMois(lundi);
  return 'Semaine du $debut au ${jourMois(samedi)}';
}

/// « jeudi 26 novembre à 16 h 40 », au fil d'une phrase.
String dateHeureFr(DateTime d) {
  final jour = dateLongue(d);
  return '${jour[0].toLowerCase()}${jour.substring(1)} à ${heureCourte(d)}';
}

/// « 1,2 Mo », « 350 ko ».
String tailleFr(int octets) {
  if (octets < 1024) return '$octets${_nbsp}o';
  if (octets < 1024 * 1024) return '${(octets / 1024).round()}${_nbsp}ko';
  final mo = (octets / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
  return '$mo${_nbsp}Mo';
}
