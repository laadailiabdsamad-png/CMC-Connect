import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../modeles/travaux.dart';
import '../theme/cmc_theme.dart';
import '../theme/dates_fr.dart';
import 'surfaces.dart';

/// Ouvre le fichier avec l'application du téléphone ; explique un échec.
Future<void> ouvrirPiece(
  BuildContext context,
  Session session,
  PieceJointe piece,
) async {
  final messager = ScaffoldMessenger.of(context);
  final probleme = await session.fichiers.ouvrir(piece);
  if (probleme != null) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(probleme)),
      );
  }
}

/// Un fichier à ouvrir : nom, taille et action.
class TuilePiece extends StatelessWidget {
  const TuilePiece({
    super.key,
    required this.session,
    required this.piece,
    this.titre,
    this.detail,
  });

  final Session session;
  final PieceJointe piece;

  /// Par défaut, le nom du fichier.
  final String? titre;

  /// Ligne sous le titre, par défaut la taille du fichier.
  final String? detail;

  @override
  Widget build(BuildContext context) => SurfaceCmc(
    child: ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(titre ?? piece.nom),
      subtitle: Text(
        detail ?? '${piece.nom} · ${tailleFr(piece.taille)}',
        style: TextStyle(color: context.cmc.texteDoux),
      ),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => ouvrirPiece(context, session, piece),
    ),
  );
}
