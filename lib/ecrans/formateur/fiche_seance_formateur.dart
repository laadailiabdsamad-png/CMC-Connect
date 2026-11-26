import 'package:material_ui/material_ui.dart';

import '../../donnees/donnees_demo.dart';
import '../../etat/session.dart';
import '../../modeles/compte.dart';
import '../../modeles/seance.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/piece_jointe.dart';
import '../../widgets/surfaces.dart';
import 'nouveau_travail.dart';
import 'suivi_tp.dart';

/// Une séance du formateur : où et quand, puis supports et TP liés.
class FicheSeanceFormateur extends StatelessWidget {
  const FicheSeanceFormateur({
    super.key,
    required this.session,
    required this.seanceId,
  });

  final Session session;
  final String seanceId;

  Future<void> _ouvrirFormulaire(BuildContext context, Widget page) async {
    final messager = ScaffoldMessenger.of(context);
    final message = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => page));
    await session.rafraichir();
    if (message != null) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final texte = Theme.of(context).textTheme;
      final doux = context.cmc.texteDoux;
      Seance? seance;
      for (final s in session.seances) {
        if (s.id == seanceId) seance = s;
      }
      final formateur = session.formateur;
      return FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Séance')),
          body: seance == null || formateur == null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Cette séance n’est plus dans votre planning. Le chef de '
                    'pôle l’a peut-être déplacée ou confiée à un autre '
                    'formateur.',
                    style: texte.bodyLarge,
                  ),
                )
              : _contenu(context, seance, formateur, texte, doux),
        ),
      );
    },
  );

  Widget _contenu(
    BuildContext context,
    Seance seance,
    Formateur formateur,
    TextTheme texte,
    Color doux,
  ) {
    final groupeId = seance.groupeId ?? '';
    final affecte = formateur.enseigne(groupeId, seance.module);
    final tps = [
      for (final s in session.tpsSuivis)
        if (s.tp.seanceId == seance.id) s,
    ];
    final supports = [
      for (final s in session.supports)
        if (s.seanceId == seance.id) s,
    ];
    Widget ligne(String libelle, String valeur) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        label: '$libelle : $valeur',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(libelle, style: texte.labelLarge?.copyWith(color: doux)),
            Text(valeur, style: texte.titleMedium),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SurfaceCmc(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ligne(
                  'Groupe',
                  'Groupe ${seance.groupe ?? codeGroupe(groupeId)}',
                ),
                ligne('Module', seance.module),
                ligne('Date', dateLongue(seance.debut)),
                ligne('Horaire', plageHoraire(seance.debut, seance.fin)),
                ligne('Salle', 'Salle ${seance.salle}'),
                if (seance.salleModifiee) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Salle modifiée · ${seance.ancienneSalle} → ${seance.salle}',
                    style: texte.titleSmall?.copyWith(
                      color: context.cmc.texteDoux,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (affecte) ...[
          FilledButton.icon(
            onPressed: () => _ouvrirFormulaire(
              context,
              NouveauTp(session: session, seance: seance),
            ),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Créer un TP'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _ouvrirFormulaire(
              context,
              NouveauSupport(session: session, seance: seance),
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('Ajouter un support'),
          ),
        ] else
          Text(
            'Vous n’êtes pas affecté à ce module pour ce groupe : supports '
            'et TP ne sont pas disponibles.',
            style: texte.bodyMedium?.copyWith(color: doux),
          ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text('TP de cette séance', style: texte.titleLarge),
        ),
        const SizedBox(height: 8),
        if (tps.isEmpty)
          Text('Aucun TP pour le moment.', style: texte.bodyLarge)
        else
          for (final s in tps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CarteTpSuivi(session: session, suivi: s),
            ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Supports', style: texte.titleLarge),
        ),
        const SizedBox(height: 8),
        if (supports.isEmpty)
          Text('Aucun support pour le moment.', style: texte.bodyLarge)
        else
          for (final s in supports)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TuilePiece(
                session: session,
                piece: s.piece,
                titre: s.titre,
              ),
            ),
      ],
    );
  }
}
