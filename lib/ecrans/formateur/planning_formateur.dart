import 'package:material_ui/material_ui.dart';

import '../../etat/session.dart';
import '../../modeles/seance.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/carte_seance.dart';
import '../../widgets/message_planning.dart';
import '../../widgets/surfaces.dart';
import 'fiche_seance_formateur.dart';

/// Prochaine séance du formateur, puis sa semaine, lues dans le planning
/// publié par les chefs de pôle.
class PlanningFormateur extends StatefulWidget {
  const PlanningFormateur({super.key, required this.session});

  final Session session;

  @override
  State<PlanningFormateur> createState() => _PlanningFormateurState();
}

class _PlanningFormateurState extends State<PlanningFormateur> {
  late DateTime _lundi = _semaineCourante();

  Session get _session => widget.session;

  /// Semaine en cours, ou la suivante le dimanche.
  DateTime _semaineCourante() {
    final aujourdhui = minuit(_session.maintenant);
    return lundiDe(
      aujourdhui.weekday == DateTime.sunday
          ? DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day + 1)
          : aujourdhui,
    );
  }

  void _decaler(int semaines) => setState(
    () =>
        _lundi = DateTime(_lundi.year, _lundi.month, _lundi.day + 7 * semaines),
  );

  Future<void> _ouvrir(Seance seance) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FicheSeanceFormateur(session: _session, seanceId: seance.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final doux = context.cmc.texteDoux;
    final marges = MediaQuery.paddingOf(context);
    final prochaine = _session.prochaine;
    final fin = DateTime(_lundi.year, _lundi.month, _lundi.day + 7);
    final parJour = <DateTime, List<Seance>>{};
    for (final s in _session.seances) {
      if (s.debut.isBefore(_lundi) || !s.debut.isBefore(fin)) continue;
      (parJour[minuit(s.debut)] ??= []).add(s);
    }

    return RefreshIndicator(
      onRefresh: _session.rafraichir,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          marges.top + 16,
          16,
          marges.bottom + 16,
        ),
        children: [
          Text('Mon planning', style: texte.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${_session.actif!.nom} · Formateur',
            style: texte.titleMedium?.copyWith(
              color: doux,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (prochaine == null)
            MessagePlanning(
              erreur: _session.erreur,
              onReessayer: _session.rafraichir,
            )
          else
            CarteSeance(
              key: ValueKey('prochaine-${prochaine.id}'),
              seance: prochaine,
              titre: 'PROCHAINE SÉANCE',
              sousTitre: jourFr(prochaine.debut, _session.maintenant),
              verre: true,
              vueFormateur: true,
              onTap: () => _ouvrir(prochaine),
            ),
          const SizedBox(height: 24),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Semantics(
                header: true,
                child: Text(semaineFr(_lundi), style: texte.titleLarge),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Semaine précédente',
                    onPressed: () => _decaler(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Semaine suivante',
                    onPressed: () => _decaler(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _lundi = _semaineCourante()),
                    icon: const Icon(Icons.today),
                    label: const Text('Aujourd’hui'),
                  ),
                ],
              ),
            ],
          ),
          if (parJour.isEmpty)
            SurfaceCmc(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Aucune séance cette semaine.',
                  style: texte.titleMedium,
                ),
              ),
            ),
          for (final MapEntry(key: jour, value: seances)
              in parJour.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  jourFr(jour, _session.maintenant),
                  style: texte.titleMedium,
                ),
              ),
            ),
            for (final s in seances)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CarteSeance(
                  key: ValueKey('formateur-${s.id}'),
                  seance: s,
                  vueFormateur: true,
                  onTap: () => _ouvrir(s),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
