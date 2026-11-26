# CMC Connect

Prototype Flutter pour Android et iOS, préparé pour le concours de la CMC
Casablanca-Settat. Le rapport et les logos fournis sont dans `docs/`.

Trois espaces :

- **Stagiaire** : accueil avec la prochaine séance et le prochain TP à rendre,
  planning du groupe, onglet Modules (TP et supports de cours, dépôt des
  rendus), apparence (Simple ou Liquid Glass, Clair, Sombre ou Système).
- **Formateur** : planning de la semaine et prochaine séance, fiche d'une
  séance, ajout de supports, création de TP, suivi des rendus.
- **Chef de pôle** : planning de la semaine de chaque groupe du pôle,
  création et modification de séances, brouillon, publication avec contrôle
  des conflits de salle, de formateur et de groupe.

## Comptes de démonstration

| Compte | Rôle | Groupe, pôle ou affectations |
| --- | --- | --- |
| Inès | Stagiaire | DEV 201, pôle Digital et Intelligence Artificielle |
| Yassine | Stagiaire | GE 102, pôle Gestion et Commerce |
| M. Amrani | Formateur | Développement mobile pour DEV 201 (et ses autres cours du planning de départ : Programmation Dart pour DEV 201, Développement mobile pour DEV 101) |
| Chef du pôle Digital | Chef de pôle | DEV 201, DEV 101 et ID 102 |

Le compte se choisit au lancement. « Profil > Changer de compte » revient au
choix. Salles et formateurs sont partagés entre les pôles.

## Lancer sur le Samsung S23+

Téléphone branché en USB, débogage USB autorisé :

```powershell
cd $env:USERPROFILE\Downloads\CMC_Connect
C:\Users\laada\dev\flutter\bin\flutter.bat run -d R5CW51ZYDLP
```

## Préparer la démonstration

1. Compte chef, « Profil > Réinitialiser la démonstration » : le planning
   repart du prochain jour de cours ; TP, supports et rendus sont effacés ;
   les thèmes sont conservés.
2. Mettre sur le téléphone, par exemple dans Téléchargements, un énoncé
   (PDF ou texte) et une réponse d'Inès (une capture d'écran convient).

## Démonstration chef → formateur → stagiaire

1. **Chef du pôle Digital** : choisir le jour de la séance Développement
   mobile de 10 h de DEV 201, la toucher, salle B08, « Publier ».
2. **M. Amrani** : « Mon planning » montre la prochaine séance en B08 avec
   « Salle modifiée · B12 → B08 ». La toucher : groupe, module, date,
   horaire et salle.
3. « Créer un TP » : groupe et module sont repris de la séance. Saisir un
   titre et une consigne ; l'échéance est proposée une semaine après la
   séance, à 18 h. « Joindre un fichier » (facultatif), puis
   « Publier le TP ».
4. **Inès** : l'accueil affiche « TP À RENDRE ». Onglet **Modules**, toucher
   le TP : consigne et énoncé joint. « Déposer mon fichier ».
5. **Yassine** : onglet Modules, « Aucun TP pour votre groupe. »
6. Fermer l'application depuis les applications récentes, la rouvrir.
   **M. Amrani**, onglet **TP** : « 1 rendu ». Toucher le TP, puis
   « Inès » (avec la date de dépôt) : le fichier s'ouvre avec l'application
   choisie par Android.

Depuis la fiche d'une séance, « Ajouter un support » publie un document de
cours que le groupe retrouve dans Modules.

## Démonstration du chef de pôle

1. **Inès** : l'accueil affiche Développement mobile, 10 h 00, salle B12.
2. **Chef** : toucher la séance, salle B08, « Enregistrer le brouillon ». La
   carte affiche « B12 → B08 · Modification en attente ». Inès voit encore
   B12.
3. **Chef** : rouvrir la séance, « Publier ». Inès voit B08 dans Accueil et
   Planning, avec « Salle modifiée · B12 → B08 ».
4. **Yassine** : son planning n'a pas changé.
5. **Chef**, jour de cours qui suit (DEV 201 y a Programmation Dart à
   8 h 30, parfois la semaine suivante) : « Ajouter une séance »,
   Développement mobile, Mme Tazi, salle B08, de 10 h 30 à 12 h 30,
   « Publier ». Refus : « Salle B08 déjà réservée de 11 h à 13 h
   (groupe GE 102). » Passer la salle à B05 et publier de nouveau.

## Tests

Sur ce PC, Smart App Control bloque `flutter_tester.exe`, qui n'est pas signé.
`flutter test` échoue donc avant d'exécuter le moindre test. Les mêmes tests
tournent sur le téléphone :

```powershell
C:\Users\laada\dev\flutter\bin\flutter.bat test integration_test/appareil_test.dart -d R5CW51ZYDLP
```

Laisser le téléphone déverrouillé, sans ouvrir d'autre application, pendant
environ quatre minutes : une application passée au premier plan interrompt la
série. À la fin, `flutter test` désinstalle l'application ; relancer
`flutter run` pour la retrouver. Dans les tests, le choix et l'ouverture des
fichiers sont simulés ; le parcours réel avec le sélecteur d'Android se
vérifie à la main (étapes ci-dessus).

| Fichier | Contenu |
| --- | --- |
| `test/travaux_test.dart` | Séances du formateur, TP, supports, rendus, droits d'affectation, isolation des groupes, échecs d'écriture, fichiers réels sur le téléphone |
| `test/parcours_formateur_test.dart` | Chef → formateur → Inès → formateur dans l'interface, Yassine, petit écran et texte agrandi |
| `test/planification_test.dart` | Brouillon, publication, conflits, chevauchements, droits, publications simultanées |
| `test/parcours_chef_test.dart` | Critères d'acceptation de l'espace chef dans l'interface |
| `test/parcours_test.dart` | Parcours stagiaire et apparence |
| `test/donnees_test.dart`, `test/theme_test.dart` | Données de départ, réglages par compte, contrastes |

## Organisation

| Dossier | Rôle |
| --- | --- |
| `lib/modeles/` | Comptes (stagiaire, formateur et affectations, chef), groupes, séances, planification, TP, supports et rendus |
| `lib/donnees/` | `PlanningRepository` et `TravauxRepository` (contrats), `PlanningFictif` et `TravauxLocaux` (données enregistrées sur le téléphone), fichiers, conflits, données de démonstration |
| `lib/etat/` | `Session` (compte actif, séances, travaux), `EspaceChef` (groupe, semaine et jour choisis) |
| `lib/ecrans/` | `stagiaire/`, `formateur/`, `chef/` et écrans communs |
| `lib/theme/`, `lib/widgets/` | Thèmes Simple et Liquid Glass, composants |

## Mode de données et passage à l'API

Il n'y a pas encore d'API : tout est enregistré sur le téléphone. Les
descriptions (séances, TP, rendus) sont dans `shared_preferences` ; les
pièces jointes et les rendus sont copiés dans le dossier privé de
l'application et y restent après redémarrage. Les repositories appliquent
les règles que le serveur appliquera :

- un chef ne modifie que les groupes de son pôle ;
- un formateur ne publie supports et TP que pour une séance publiée qu'il
  anime, et pour un groupe et un module de ses affectations ;
- un stagiaire ne voit et ne rend que les TP de son groupe.

La démonstration se fait donc sur un seul téléphone, en changeant de compte.
Pour synchroniser plusieurs appareils, il restera à :

1. Écrire l'API PHP : session côté serveur, lecture des séances (groupe,
   formateur, semaine du chef), brouillons et publications, TP, supports,
   rendus, téléchargement des fichiers.
2. Déterminer les droits sur le serveur à partir de la session et des tables
   d'affectations ; l'application n'envoie jamais son rôle. Ne servir un
   fichier qu'à son auteur, au formateur du TP ou au groupe concerné.
3. Publier les séances dans une transaction MySQL qui verrouille les
   réservations concernées avant de vérifier les chevauchements, avec un
   numéro de version par séance.
4. Stocker les fichiers hors de la racine web, avec une taille maximale
   (20 Mo dans l'application) et un contrôle du type.
5. Écrire `PlanningApi` et `TravauxApi`, qui implémentent les contrats, et
   les passer à la place des classes locales dans `lib/main.dart` et
   `Session`. Les écrans ne changent pas.
6. Prévenir le groupe et le formateur après une publication (notification
   push). Aujourd'hui, chacun voit le changement en rouvrant l'application
   ou en tirant l'écran vers le bas.

Les personnes, groupes et horaires sont fictifs.
