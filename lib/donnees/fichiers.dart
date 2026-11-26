import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../modeles/travaux.dart';

/// Où l'application conserve les pièces jointes et les rendus.
abstract interface class CoffreFichiers {
  Future<PieceJointe> ranger(String id, FichierChoisi fichier);
  Future<Uint8List> lire(PieceJointe piece);
  Future<void> supprimer(PieceJointe piece);
  Future<void> vider();
}

/// Dossier privé de l'application sur le téléphone. Les fichiers restent
/// après redémarrage et disparaissent si l'application est désinstallée.
class CoffreAppareil implements CoffreFichiers {
  CoffreAppareil({this.sousDossier = 'pieces'});

  final String sousDossier;

  Future<Directory> _dossier() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/$sousDossier').create(recursive: true);
  }

  static String _nomSur(String nom) =>
      nom.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  @override
  Future<PieceJointe> ranger(String id, FichierChoisi fichier) async {
    final dossier = await _dossier();
    final cible = File('${dossier.path}/$id-${_nomSur(fichier.nom)}');
    await cible.writeAsBytes(fichier.octets, flush: true);
    return PieceJointe(
      id: id,
      nom: fichier.nom,
      taille: fichier.octets.length,
      chemin: cible.path,
    );
  }

  @override
  Future<Uint8List> lire(PieceJointe piece) => File(piece.chemin).readAsBytes();

  @override
  Future<void> supprimer(PieceJointe piece) async {
    final f = File(piece.chemin);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> vider() async {
    final dossier = await _dossier();
    if (await dossier.exists()) await dossier.delete(recursive: true);
  }
}

/// Pour les tests.
class CoffreMemoire implements CoffreFichiers {
  final contenus = <String, Uint8List>{};

  @override
  Future<PieceJointe> ranger(String id, FichierChoisi fichier) async {
    final chemin = 'memoire/$id-${fichier.nom}';
    contenus[chemin] = Uint8List.fromList(fichier.octets);
    return PieceJointe(
      id: id,
      nom: fichier.nom,
      taille: fichier.octets.length,
      chemin: chemin,
    );
  }

  @override
  Future<Uint8List> lire(PieceJointe piece) async =>
      contenus[piece.chemin] ?? (throw const FileSystemException('absent'));

  @override
  Future<void> supprimer(PieceJointe piece) async =>
      contenus.remove(piece.chemin);

  @override
  Future<void> vider() async => contenus.clear();
}

/// Choisir un fichier sur le téléphone et en ouvrir un avec l'application
/// adaptée (lecteur PDF, galerie…).
abstract interface class FichiersAppareil {
  /// Null si la personne a annulé.
  Future<FichierChoisi?> choisir();

  /// Null si le fichier s'est ouvert, sinon le message à afficher.
  Future<String?> ouvrir(PieceJointe piece);
}

class FichiersSysteme implements FichiersAppareil {
  @override
  Future<FichierChoisi?> choisir() async {
    final choix = await FilePicker.pickFiles(dialogTitle: 'Choisir un fichier');
    if (choix.isEmpty) return null;
    final fichier = choix.first;
    final taille = await fichier.length();
    if (taille != null && taille > tailleMaxFichier) {
      // Trop lourd : on ne le lit pas, le formulaire affichera le refus.
      return FichierChoisi(
        nom: fichier.name,
        octets: Uint8List(0),
        taille: taille,
      );
    }
    return FichierChoisi(
      nom: fichier.name,
      octets: await fichier.readAsBytes(),
    );
  }

  @override
  Future<String?> ouvrir(PieceJointe piece) async {
    if (!await File(piece.chemin).exists()) {
      return 'Ce fichier n’est plus disponible sur le téléphone.';
    }
    final resultat = await OpenFilex.open(piece.chemin);
    return switch (resultat.type) {
      ResultType.done => null,
      ResultType.noAppToOpen =>
        'Aucune application de ce téléphone ne sait ouvrir « ${piece.nom} ».',
      ResultType.fileNotFound =>
        'Ce fichier n’est plus disponible sur le téléphone.',
      _ => 'Le fichier n’a pas pu être ouvert.',
    };
  }
}
