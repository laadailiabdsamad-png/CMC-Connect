import 'package:material_ui/material_ui.dart';

import '../../etat/session.dart';
import '../../modeles/travaux.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/pastille.dart';
import '../../widgets/piece_jointe.dart';
import '../../widgets/surfaces.dart';

/// État d'un TP pour le stagiaire, en toutes lettres.
Pastille pastilleTravail(
  BuildContext context,
  TravailStagiaire travail,
  DateTime maintenant,
) {
  final c = context.cmc;
  final schema = Theme.of(context).colorScheme;
  final rendu = travail.rendu;
  final retard = travail.enRetard(maintenant);
  if (rendu != null) {
    return Pastille(
      texte: retard
          ? 'Rendu en retard le ${dateHeureFr(rendu.deposeLe)}'
          : 'Rendu le ${dateHeureFr(rendu.deposeLe)}',
      fond: retard ? c.attenteFond : c.alerteFond,
      encre: retard ? c.attenteTexte : c.alerteTexte,
    );
  }
  return retard
      ? Pastille(
          texte: 'En retard · à rendre le ${dateHeureFr(travail.tp.echeance)}',
          fond: schema.errorContainer,
          encre: schema.onErrorContainer,
        )
      : Pastille(
          texte: 'À rendre avant le ${dateHeureFr(travail.tp.echeance)}',
          fond: c.surface,
          encre: schema.onSurface,
          bord: c.texteDoux,
        );
}

/// Un TP dans l'espace du stagiaire.
class CarteTravail extends StatelessWidget {
  const CarteTravail({
    super.key,
    required this.session,
    required this.travail,
    this.titre,
    this.verre = false,
  });

  final Session session;
  final TravailStagiaire travail;
  final String? titre;
  final bool verre;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    final tp = travail.tp;
    return SurfaceCmc(
      verre: verre,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DetailTp(session: session, tpId: tp.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titre case final t?)
              Text(
                t,
                style: texte.labelLarge?.copyWith(
                  color: doux,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(tp.titre, style: texte.titleMedium),
            Text(
              '${tp.module} · ${tp.formateurNom}',
              style: texte.bodyMedium?.copyWith(color: doux),
            ),
            const SizedBox(height: 8),
            pastilleTravail(context, travail, session.maintenant),
          ],
        ),
      ),
    );
  }
}

/// Onglet « Modules » : TP et supports de cours du groupe.
class Modules extends StatelessWidget {
  const Modules({super.key, required this.session});

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
          Text('Modules', style: texte.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Groupe ${session.stagiaire!.groupe}',
            style: texte.titleMedium?.copyWith(
              color: context.cmc.texteDoux,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text('Travaux pratiques', style: texte.titleLarge),
          ),
          const SizedBox(height: 8),
          if (session.mesTravaux.isEmpty)
            Text('Aucun TP pour votre groupe.', style: texte.bodyLarge),
          for (final t in session.mesTravaux)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CarteTravail(
                key: ValueKey('travail-${t.tp.id}'),
                session: session,
                travail: t,
              ),
            ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('Supports de cours', style: texte.titleLarge),
          ),
          const SizedBox(height: 8),
          if (session.supports.isEmpty)
            Text('Aucun support pour le moment.', style: texte.bodyLarge),
          for (final s in session.supports)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TuilePiece(
                session: session,
                piece: s.piece,
                titre: s.titre,
                detail: '${s.module} · ${s.formateurNom}',
              ),
            ),
        ],
      ),
    );
  }
}

/// Consigne d'un TP et dépôt du rendu.
class DetailTp extends StatefulWidget {
  const DetailTp({super.key, required this.session, required this.tpId});

  final Session session;
  final String tpId;

  @override
  State<DetailTp> createState() => _DetailTpState();
}

class _DetailTpState extends State<DetailTp> {
  bool _enCours = false;
  String? _probleme;

  Future<void> _deposer() async {
    final session = widget.session;
    final messager = ScaffoldMessenger.of(context);
    final fichier = await session.fichiers.choisir();
    if (fichier == null || !mounted) return;
    setState(() {
      _enCours = true;
      _probleme = null;
    });
    try {
      final rendu = await session.travaux.deposer(
        session.stagiaire!,
        widget.tpId,
        fichier,
      );
      await session.rafraichir();
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Rendu déposé : ${rendu.piece.nom}.'),
          ),
        );
    } on TravailRefuse catch (refus) {
      _probleme = refus.problemes.join(' ');
    } on Object {
      _probleme =
          'Le dépôt a échoué. Votre fichier n’a pas été envoyé : '
          'réessayez.';
    }
    if (mounted) setState(() => _enCours = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final texte = Theme.of(context).textTheme;
      final doux = context.cmc.texteDoux;
      final schema = Theme.of(context).colorScheme;
      final travail = session.mesTravaux
          .where((t) => t.tp.id == widget.tpId)
          .firstOrNull;
      return FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('TP')),
          body: travail == null
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ce TP n’est plus disponible.'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(travail.tp.titre, style: texte.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${travail.tp.module} · ${travail.tp.formateurNom}',
                      style: texte.titleMedium,
                    ),
                    Text(
                      'À rendre le ${dateHeureFr(travail.tp.echeance)}',
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
                            Text(travail.tp.consigne, style: texte.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                    if (travail.tp.piece case final p?) ...[
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
                      child: Text('Mon rendu', style: texte.titleLarge),
                    ),
                    const SizedBox(height: 8),
                    pastilleTravail(context, travail, session.maintenant),
                    const SizedBox(height: 8),
                    if (travail.rendu case final r?)
                      TuilePiece(session: session, piece: r.piece)
                    else
                      Text(
                        'Vous n’avez pas encore rendu ce TP.',
                        style: texte.bodyLarge,
                      ),
                    if (_probleme case final p?)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          p,
                          style: texte.bodyLarge?.copyWith(color: schema.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (travail.rendu == null)
                      FilledButton.icon(
                        onPressed: _enCours ? null : _deposer,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _enCours ? 'Envoi…' : 'Déposer mon fichier',
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _enCours ? null : _deposer,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _enCours ? 'Envoi…' : 'Remplacer mon fichier',
                        ),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
