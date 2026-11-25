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
