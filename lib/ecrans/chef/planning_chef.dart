import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:material_ui/material_ui.dart';

import '../../etat/espace_chef.dart';
import '../../modeles/compte.dart';
import '../../modeles/planification.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/carte_seance_chef.dart';
import '../../widgets/message_planning.dart';
import '../../widgets/surfaces.dart';
import 'fiche_seance.dart';

/// « Quelles séances dois-je organiser pour ce groupe cette semaine ? »
class PlanningChef extends StatelessWidget {
  const PlanningChef({super.key, required this.espace});

  final EspaceChef espace;

  Future<void> _ouvrirFiche(
    BuildContext context, {
    SeancePlanifiee? seance,
  }) async {
    final messager = ScaffoldMessenger.of(context);
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FicheSeance(espace: espace, seance: seance),
      ),
    );
    // Groupe, semaine et jour restent ceux que le chef avait choisis.
    await espace.recharger();
    if (message != null) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
        );
    }
  }

  Future<void> _choisirGroupe(BuildContext context) async {
    final groupes = espace.pole?.groupes ?? const <Groupe>[];
    final choisi = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<String>(
            groupValue: espace.groupeId,
            onChanged: (id) => Navigator.pop(context, id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Groupes du pôle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final g in groupes)
                  RadioListTile<String>(
                    value: g.id,
                    title: Text('Groupe ${g.code}'),
                    subtitle: Text('${g.filiere} · ${g.annee}'),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
    if (choisi != null && choisi != espace.groupeId) {
      await espace.choisirGroupe(choisi);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: espace,
    builder: (context, _) {
      final texte = Theme.of(context).textTheme;
      final doux = context.cmc.texteDoux;
      final marges = MediaQuery.paddingOf(context);
      final groupe = espace.groupe;
      final seances = espace.seancesDuJour;
      return RefreshIndicator(
        onRefresh: espace.recharger,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            marges.top + 16,
            16,
            marges.bottom + 16,
          ),
          children: [
            Text(
              'Pôle ${espace.chef.pole}',
              style: texte.titleSmall?.copyWith(color: doux),
            ),
            Text('Planning de la semaine', style: texte.headlineMedium),
            const SizedBox(height: 16),
            if (groupe != null)
              _SelecteurGroupe(
                groupe: groupe,
                onTap: () => _choisirGroupe(context),
              ),
            const SizedBox(height: 16),
            _Semaine(espace: espace),
            const SizedBox(height: 12),
            _BandeJours(espace: espace),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(dateLongue(espace.jour), style: texte.titleLarge),
            ),
            const SizedBox(height: 12),
            if (espace.chargement)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (espace.erreur)
              MessagePlanning(erreur: true, onReessayer: espace.charger)
            else if (seances.isEmpty)
              _JourVide(onCreer: () => _ouvrirFiche(context))
            else ...[
              FilledButton.icon(
                onPressed: () => _ouvrirFiche(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une séance'),
              ),
              const SizedBox(height: 12),
              for (final s in seances)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CarteSeanceChef(
                    key: ValueKey('chef-${s.id}'),
                    seance: s,
                    onTap: () => _ouvrirFiche(context, seance: s),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}

class _SelecteurGroupe extends StatelessWidget {
  const _SelecteurGroupe({required this.groupe, required this.onTap});

  final Groupe groupe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          'Groupe ${groupe.code}, ${groupe.filiere}, ${groupe.annee}. '
          'Changer de groupe',
      excludeSemantics: true,
      child: SurfaceCmc(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Groupe ${groupe.code}', style: texte.titleLarge),
                    Text(
                      '${groupe.filiere} · ${groupe.annee}',
                      style: texte.bodyMedium?.copyWith(
                        color: context.cmc.texteDoux,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.unfold_more),
            ],
          ),
        ),
      ),
    );
  }
}

class _Semaine extends StatelessWidget {
  const _Semaine({required this.espace});

  final EspaceChef espace;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    runSpacing: 4,
    children: [
      Text(
        semaineFr(espace.lundi),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Semaine précédente',
            onPressed: () => espace.changerDeSemaine(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Semaine suivante',
            onPressed: () => espace.changerDeSemaine(1),
            icon: const Icon(Icons.chevron_right),
          ),
          TextButton.icon(
            onPressed: espace.revenirAujourdhui,
            icon: const Icon(Icons.today),
            label: const Text('Aujourd’hui'),
          ),
        ],
      ),
    ],
  );
}

/// Bande des six jours. Le jour choisi est ramené à l'écran quand il change,
/// y compris quand « Aujourd'hui » ou un changement de semaine le déplace.
class _BandeJours extends StatefulWidget {
  const _BandeJours({required this.espace});

  final EspaceChef espace;

  @override
  State<_BandeJours> createState() => _BandeJoursState();
}

class _BandeJoursState extends State<_BandeJours> {
  final _choisi = GlobalKey();
  final _defilement = ScrollController();
  DateTime? _montre;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  void _montrerLeJourChoisi() {
    final jour = widget.espace.jour;
    if (_montre == jour) return;
    _montre = jour;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seule la bande défile : la page reste où le chef l'a laissée.
      final cible = _choisi.currentContext?.findRenderObject();
      if (cible == null || !_defilement.hasClients || !mounted) return;
      final position = _defilement.position;
      final decalage = RenderAbstractViewport.of(cible)
          .getOffsetToReveal(cible, 0.5)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (MediaQuery.disableAnimationsOf(context)) {
        position.jumpTo(decalage);
      } else {
        _defilement.animateTo(
          decalage,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final espace = widget.espace;
    _montrerLeJourChoisi();
    return SingleChildScrollView(
      controller: _defilement,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final jour in espace.jours)
            Padding(
              key: memeJour(jour, espace.jour) ? _choisi : null,
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _BoutonJour(
                jour: jour,
                nombre: espace.chargement
                    ? null
                    : espace.seancesDu(jour).length,
                choisi: memeJour(jour, espace.jour),
                aujourdhui: memeJour(jour, espace.maintenant),
                onTap: () => espace.choisirJour(jour),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoutonJour extends StatelessWidget {
  const _BoutonJour({
    required this.jour,
    required this.nombre,
    required this.choisi,
    required this.aujourdhui,
    required this.onTap,
  });

  final DateTime jour;
  final int? nombre;
  final bool choisi;
  final bool aujourdhui;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final c = context.cmc;
    final texte = Theme.of(context).textTheme;
    final encre = choisi ? schema.onPrimary : schema.onSurface;
    final n = nombre;
    final compte = switch (n) {
      null => '',
      0 => 'aucune',
      1 => '1 séance',
      _ => '$n séances',
    };
    return Semantics(
      button: true,
      selected: choisi,
      label: [
        dateLongue(jour),
        if (aujourdhui) 'aujourd’hui',
        if (n != null) n == 0 ? 'aucune séance' : compte,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: choisi ? schema.primary : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: aujourdhui && !choisi
              ? BorderSide(color: schema.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    jourAbrege(jour),
                    style: texte.labelLarge?.copyWith(color: encre),
                  ),
                  Text(
                    '${jour.day}',
                    style: texte.titleLarge?.copyWith(color: encre),
                  ),
                  Text(compte, style: texte.labelSmall?.copyWith(color: encre)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourVide extends StatelessWidget {
  const _JourVide({required this.onCreer});

  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context) => SurfaceCmc(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aucune séance prévue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreer,
            icon: const Icon(Icons.add),
            label: const Text('Créer la première séance'),
          ),
        ],
      ),
    ),
  );
}
