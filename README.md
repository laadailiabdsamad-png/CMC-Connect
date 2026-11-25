# CMC Connect, parcours stagiaire (version 1)

Prototype Flutter pour Android et iOS, préparé pour le concours de la CMC
Casablanca-Settat. Le rapport et les logos fournis sont dans `docs/`.

## Lancer sur le Samsung S23+

Téléphone branché en USB, débogage USB autorisé :

```powershell
cd $env:USERPROFILE\Downloads\CMC_Connect
C:\Users\laada\dev\flutter\bin\flutter.bat run -d R5CW51ZYDLP
```

## Tests

Sur ce PC, Smart App Control bloque `flutter_tester.exe`, qui n'est pas signé.
`flutter test` échoue donc avant d'exécuter le moindre test. Les mêmes tests
tournent sur le téléphone :

```powershell
C:\Users\laada\dev\flutter\bin\flutter.bat test integration_test/appareil_test.dart -d R5CW51ZYDLP
```

Laisser le téléphone déverrouillé, sans le toucher, pendant environ une minute.

## Organisation

| Dossier | Rôle |
| --- | --- |
| `lib/modeles/` | Stagiaire, séance, apparence |
| `lib/donnees/` | `PlanningRepository` (contrat), `PlanningFictif` (données de démo), réglages par compte |
| `lib/etat/session.dart` | État partagé : l'accueil et le planning lisent la même liste de séances |
| `lib/theme/` | Thèmes Simple et Liquid Glass, en clair et en sombre |
| `lib/ecrans/`, `lib/widgets/` | Écrans et composants |

Pour brancher l'API PHP/MySQL, écrire une classe qui implémente
`PlanningRepository` et la passer à la place de `PlanningFictif()` dans
`lib/main.dart`. Les écrans ne changent pas.

Les personnes, groupes et horaires sont fictifs. Les séances partent toujours
du prochain jour ouvré, pour que la démonstration fonctionne quel que soit le
jour.
