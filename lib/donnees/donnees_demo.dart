import '../modeles/compte.dart';
import '../modeles/planification.dart';

/// Comptes, groupes et séances inventés pour la démonstration.
/// Avec l'API, tout cela viendra de la base MySQL.

const poleDigital = 'pole-digital';
const poleGestion = 'pole-gestion';

const nomsPoles = {
  poleDigital: 'Digital et Intelligence Artificielle',
  poleGestion: 'Gestion et Commerce',
};

const groupesDemo = [
  Groupe(
    id: 'dev-201',
    code: 'DEV 201',
    filiere: 'Développement Digital, option Applications Mobiles',
    annee: '2e année',
    poleId: poleDigital,
  ),
  Groupe(
    id: 'dev-101',
    code: 'DEV 101',
    filiere: 'Développement Digital',
    annee: '1re année',
    poleId: poleDigital,
  ),
  Groupe(
    id: 'id-102',
    code: 'ID 102',
    filiere: 'Infrastructure Digitale',
    annee: '1re année',
    poleId: poleDigital,
  ),
  Groupe(
    id: 'ge-102',
    code: 'GE 102',
    filiere: 'Gestion des Entreprises',
    annee: '1re année',
    poleId: poleGestion,
  ),
];

const comptesDemo = <Compte>[
  Stagiaire(
    id: 'stagiaire-ines',
    prenom: 'Inès',
    groupeId: 'dev-201',
    groupe: 'DEV 201',
    filiere: 'Développement Digital, option Applications Mobiles',
    pole: 'Digital et Intelligence Artificielle',
  ),
  Stagiaire(
    id: 'stagiaire-yassine',
    prenom: 'Yassine',
    groupeId: 'ge-102',
    groupe: 'GE 102',
    filiere: 'Gestion des Entreprises',
    pole: 'Gestion et Commerce',
  ),
  ChefPole(
    id: 'chef-digital',
    nom: 'Chef du pôle Digital',
    poleId: poleDigital,
    pole: 'Digital et Intelligence Artificielle',
  ),
];

const modulesParPole = {
  poleDigital: [
    'Bases de données',
    'Conception d’interfaces',
    'Développement mobile',
    'Gestion de projet',
    'Programmation Dart',
    'Réseaux informatiques',
    'Systèmes d’exploitation',
  ],
  poleGestion: [
    'Bureautique',
    'Communication professionnelle',
    'Comptabilité générale',
    'Droit commercial',
  ],
};

/// Formateurs et salles sont partagés entre les pôles.
const formateursDemo = [
  'M. Amrani',
  'M. Berrada',
  'M. Chraibi',
  'Mme Alaoui',
  'Mme Bennani',
  'Mme Idrissi',
  'Mme Tazi',
];

const sallesDemo = ['A02', 'A04', 'A11', 'B05', 'B08', 'B12', 'C03', 'C07'];

/// Planning de départ. [ancrage] est le premier jour ouvré où la séance de
/// 10 h d'Inès est encore à venir.
List<SeancePlanifiee> planningInitial(DateTime ancrage) {
  SeancePlanifiee s(
    int n,
    String groupe,
    int jour,
    int h,
    int m,
    int duree,
    String module,
    String formateur,
    String salle, {
    bool publiee = true,
  }) {
    final date = ajouterJoursOuvres(ancrage, jour);
    final debut = DateTime(date.year, date.month, date.day, h, m);
    final details = DetailsSeance(
      groupeId: groupe,
      module: module,
      formateur: formateur,
      salle: salle,
      debut: debut,
      fin: debut.add(Duration(minutes: duree)),
    );
    return SeancePlanifiee(
      id: 'demo-$n',
      publiee: publiee ? details : null,
      brouillon: publiee ? null : details,
    );
  }

  return [
    s(1, 'dev-201', 0, 10, 0, 120, 'Développement mobile', 'M. Amrani', 'B12'),
    s(
      2,
      'dev-201',
      0,
      14,
      0,
      120,
      'Conception d’interfaces',
      'Mme Tazi',
      'B05',
    ),
    s(3, 'dev-201', 1, 8, 30, 120, 'Programmation Dart', 'M. Amrani', 'B12'),
    s(4, 'dev-201', 2, 10, 0, 120, 'Gestion de projet', 'Mme Idrissi', 'C03'),
    s(5, 'dev-101', 0, 8, 0, 120, 'Bases de données', 'M. Berrada', 'B08'),
    s(6, 'dev-101', 1, 14, 0, 120, 'Développement mobile', 'M. Amrani', 'C07'),
    s(7, 'id-102', 1, 10, 0, 120, 'Réseaux informatiques', 'M. Berrada', 'C03'),
    s(
      8,
      'id-102',
      2,
      8,
      30,
      120,
      'Systèmes d’exploitation',
      'M. Berrada',
      'C07',
      publiee: false,
    ),
    s(
      9,
      'ge-102',
      0,
      14,
      0,
      120,
      'Comptabilité générale',
      'Mme Bennani',
      'A04',
    ),
    s(10, 'ge-102', 1, 8, 30, 120, 'Droit commercial', 'M. Chraibi', 'A11'),
    s(11, 'ge-102', 1, 11, 0, 120, 'Bureautique', 'M. Chraibi', 'B08'),
    s(
      12,
      'ge-102',
      2,
      8,
      30,
      120,
      'Communication professionnelle',
      'Mme Alaoui',
      'A02',
    ),
  ];
}

/// Premier jour ouvré dont 10 h est encore à venir.
DateTime ancrageDemo(DateTime maintenant) {
  var jour = DateTime(maintenant.year, maintenant.month, maintenant.day);
  while (_estWeekend(jour) ||
      !DateTime(jour.year, jour.month, jour.day, 10).isAfter(maintenant)) {
    jour = DateTime(jour.year, jour.month, jour.day + 1);
  }
  return jour;
}

DateTime ajouterJoursOuvres(DateTime depart, int nombre) {
  var jour = depart;
  for (var restant = nombre; restant > 0;) {
    jour = DateTime(jour.year, jour.month, jour.day + 1);
    if (!_estWeekend(jour)) restant--;
  }
  return jour;
}

bool _estWeekend(DateTime jour) => jour.weekday > DateTime.friday;
