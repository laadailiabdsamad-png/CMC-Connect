import 'package:material_ui/material_ui.dart';

import '../../donnees/donnees_demo.dart';
import '../../etat/session.dart';
import '../../modeles/travaux.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/pastille.dart';
import '../../widgets/piece_jointe.dart';
import '../../widgets/surfaces.dart';

String _nombreRendus(int n) => switch (n) {
  0 => 'Aucun rendu',
  1 => '1 rendu',
  _ => '$n rendus',
};

/// Un TP dans une liste du formateur.
class CarteTpSuivi extends StatelessWidget {
  const CarteTpSuivi({super.key, required this.session, required this.suivi});

  final Session session;
  final TpSuivi suivi;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final tp = suivi.tp;
    return SurfaceCmc(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SuiviTp(session: session, tpId: tp.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tp.titre, style: texte.titleMedium),
            Text(
              'Groupe ${codeGroupe(tp.groupeId)} · ${tp.module}',
              style: texte.bodyMedium?.copyWith(color: context.cmc.texteDoux),
            ),
            Text(
              'À rendre le ${dateHeureFr(tp.echeance)}',
              style: texte.bodyMedium?.copyWith(color: context.cmc.texteDoux),
            ),
            const SizedBox(height: 8),
            Pastille(
              texte: _nombreRendus(suivi.rendus.length),
              fond: context.cmc.alerteFond,
              encre: context.cmc.alerteTexte,
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet « TP » du formateur : tous ses TP, par échéance.
class MesTp extends StatelessWidget {
  const MesTp({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final marges = MediaQuery.paddingOf(context);
    return RefreshIndicator(
      onRefresh: session.rafraichir,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          marges.top + 16,
          16,
          marges.bottom + 16,
        ),
        children: [
          Text('Mes TP', style: texte.headlineMedium),
          const SizedBox(height: 16),
          if (session.tpsSuivis.isEmpty)
            SurfaceCmc(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Aucun TP publié. Ouvrez une séance de votre planning pour '
                  'en créer un.',
                  style: texte.titleMedium,
                ),
              ),
            ),
          for (final s in session.tpsSuivis)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CarteTpSuivi(session: session, suivi: s),
            ),
        ],
      ),
    );
  }
}

/// Un TP et les fichiers rendus par les stagiaires.
class SuiviTp extends StatelessWidget {
  const SuiviTp({super.key, required this.session, required this.tpId});

  final Session session;
  final String tpId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final texte = Theme.of(context).textTheme;
      final doux = context.cmc.texteDoux;
      final suivi = session.tpsSuivis.where((s) => s.tp.id == tpId).firstOrNull;
      return FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('TP et rendus')),
          body: suivi == null
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ce TP n’existe plus.'),
                )
              : RefreshIndicator(
                  onRefresh: session.rafraichir,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      Text(suivi.tp.titre, style: texte.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Groupe ${codeGroupe(suivi.tp.groupeId)} · '
                        '${suivi.tp.module}',
                        style: texte.titleMedium,
                      ),
                      Text(
                        'À rendre le ${dateHeureFr(suivi.tp.echeance)}',
                        style: texte.bodyMedium?.copyWith(color: doux),
                      ),
                      const SizedBox(height: 16),
                      SurfaceCmc(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Consigne', style: texte.titleMedium),
                              const SizedBox(height: 4),
                              Text(suivi.tp.consigne, style: texte.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                      if (suivi.tp.piece case final p?) ...[
                        const SizedBox(height: 12),
                        TuilePiece(
                          session: session,
                          piece: p,
                          titre: 'Énoncé joint',
                        ),
                      ],
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          'Rendus (${suivi.rendus.length})',
                          style: texte.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (suivi.rendus.isEmpty)
                        Text(
                          'Aucun rendu pour le moment.',
                          style: texte.bodyLarge,
                        ),
                      for (final r in suivi.rendus)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TuilePiece(
                            key: ValueKey('rendu-${r.id}'),
                            session: session,
                            piece: r.piece,
                            titre: r.stagiaireNom,
                            detail:
                                'Déposé le ${dateHeureFr(r.deposeLe)}'
                                '${r.deposeLe.isAfter(suivi.tp.echeance) ? ' · en retard' : ''}'
                                '\n${r.piece.nom} · ${tailleFr(r.piece.taille)}',
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}
