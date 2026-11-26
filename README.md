# CMC Connect

Prototype Flutter pour Android et iOS, préparé pour le concours de la CMC
Casablanca-Settat. Le rapport et les logos fournis sont dans `docs/`.

Deux espaces :

- **Stagiaire** : accueil avec la prochaine séance, planning du groupe,
  apparence (Simple ou Liquid Glass, Clair, Sombre ou Système).
- **Chef de pôle** : planning de la semaine de chaque groupe du pôle,
  création et modification de séances, brouillon, publication avec contrôle
  des conflits de salle, de formateur et de groupe.

## Comptes de démonstration

| Compte | Rôle | Groupe ou pôle |
| --- | --- | --- |
| Inès | Stagiaire | DEV 201, pôle Digital et Intelligence Artificielle |
| Yassine | Stagiaire | GE 102, pôle Gestion et Commerce |
| Chef du pôle Digital | Chef de pôle | DEV 201, DEV 101 et ID 102 |

Le compte se choisit au lancement. « Profil > Changer de compte » revient au
choix. Salles et formateurs sont partagés entre les pôles : une réservation de
GE 102 bloque donc aussi le chef du pôle Digital.

## Lancer sur le Samsung S23+

Téléphone branché en USB, débogage USB autorisé :

```powershell
cd $env:USERPROFILE\Downloads\CMC_Connect
C:\Users\laada\dev\flutter\bin\flutter.bat run -d R5CW51ZYDLP
```

## Scénario de vérification

Le planning de départ commence au premier jour ouvré où 10 h est encore à
venir. Pour repartir de zéro avant une présentation : compte chef, « Profil >
Réinitialiser la démonstration » (les thèmes sont conservés).

1. **Inès** : l'accueil affiche Développement mobile, 10 h 00, salle B12.
2. **Chef du pôle Digital** : le planning de la semaine s'ouvre sur
   DEV 201. Choisir le jour de cette séance, la toucher, mettre la salle B08,
   puis « Enregistrer le brouillon ». La carte affiche
   « B12 → B08 · Modification en attente ».
   Revenir sur **Inès** : elle voit toujours B12.
3. **Chef** : rouvrir la séance, « Publier ». **Inès** voit B08 dans Accueil
   et dans Planning, avec « Salle modifiée · B12 → B08 », une seule fois.
4. **Yassine** : son planning n'a pas changé.
5. **Chef**, jour de cours qui suit celui de l'étape 1 (DEV 201 y a
   Programmation Dart à 8 h 30, parfois la semaine suivante) : « Ajouter une séance »,
   Développement mobile, Mme Tazi, salle B08, de 10 h 30 à 12 h 30,
   « Publier ». Refus : « Salle B08 déjà réservée de 11 h à 13 h
   (groupe GE 102). » Le brouillon reste ouvert : passer la salle à B05, puis
   « Publier » de nouveau.
6. Fermer l'application (balayage depuis les applications récentes), la
   rouvrir : le dernier compte, ses séances, ses brouillons et son thème
   reviennent. Chaque compte garde son propre thème.

## Tests

Sur ce PC, Smart App Control bloque `flutter_tester.exe`, qui n'est pas signé.
`flutter test` échoue donc avant d'exécuter le moindre test. Les mêmes tests
tournent sur le téléphone :

```powershell
C:\Users\laada\dev\flutter\bin\flutter.bat test integration_test/appareil_test.dart -d R5CW51ZYDLP
```

Laisser le téléphone déverrouillé, sans ouvrir d'autre application, pendant
environ trois minutes : une application passée au premier plan interrompt la
série. À la fin, `flutter test` désinstalle l'application ; relancer
`flutter run` pour la retrouver.

| Fichier | Contenu |
| --- | --- |
| `test/planification_test.dart` | Brouillon, publication, conflits, chevauchements, droits, échec d'écriture, publications simultanées |
| `test/parcours_chef_test.dart` | Critères d'acceptation 1 à 6 dans l'interface, petit écran et texte agrandi |
| `test/parcours_test.dart` | Parcours stagiaire et apparence |
| `test/donnees_test.dart`, `test/theme_test.dart` | Données de départ, réglages par compte, contrastes |

## Organisation

| Dossier | Rôle |
| --- | --- |
| `lib/modeles/` | Comptes, groupes, séances, planification (brouillon et version publiée) |
| `lib/donnees/` | `PlanningRepository` (contrat), `PlanningFictif` (données enregistrées sur le téléphone), conflits, données de démonstration |
| `lib/etat/` | `Session` (compte actif, séances du stagiaire), `EspaceChef` (groupe, semaine et jour choisis) |
| `lib/ecrans/`, `lib/ecrans/chef/` | Écrans stagiaire et chef de pôle |
| `lib/theme/`, `lib/widgets/` | Thèmes Simple et Liquid Glass, composants |

## Mode de données et passage à l'API

Il n'y a pas encore d'API : `PlanningFictif` enregistre tout sur le téléphone
(`shared_preferences`) et applique les règles qu'appliquera le serveur. La
démonstration se fait donc sur un seul téléphone, en changeant de compte.
L'espace chef, l'accueil et le planning stagiaire lisent tous la même source.

Pour synchroniser deux appareils, il restera à :

1. Écrire l'API PHP : connexion avec session côté serveur, puis lecture des
   séances publiées d'un groupe, lecture de la semaine d'un groupe pour le
   chef, enregistrement d'un brouillon et publication.
2. Déterminer les droits sur le serveur, à partir de la session : un chef ne
   modifie que les groupes de son pôle. L'application n'envoie jamais son rôle.
3. Publier dans une transaction MySQL qui verrouille les réservations
   concernées (salle, formateur, groupe) avant de vérifier les chevauchements.
   Deux publications simultanées ne peuvent alors pas réserver le même
   créneau. Ajouter un numéro de version par séance, pour refuser
   l'enregistrement d'une fiche modifiée entre-temps sur un autre appareil.
4. Écrire une classe `PlanningApi` qui implémente `PlanningRepository`, et la
   passer à la place de `PlanningFictif()` dans `lib/main.dart`. Les écrans ne
   changent pas.
5. Prévenir le groupe et le formateur après une publication (notification
   push). Aujourd'hui, le stagiaire voit le changement en rouvrant
   l'application ou en tirant l'écran vers le bas. L'espace formateur reste à
   faire.

Les personnes, groupes et horaires sont fictifs.
