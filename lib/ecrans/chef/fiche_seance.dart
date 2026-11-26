import 'package:material_ui/material_ui.dart';

import '../../etat/espace_chef.dart';
import '../../modeles/compte.dart';
import '../../modeles/planification.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/carte_seance_chef.dart';
import '../../widgets/surfaces.dart';

/// Création ou modification d'une séance. Renvoie le message à afficher au
/// retour dans le planning, ou null si le chef est revenu sans enregistrer.
class FicheSeance extends StatefulWidget {
  const FicheSeance({super.key, required this.espace, this.seance});

  final EspaceChef espace;
  final SeancePlanifiee? seance;

  @override
  State<FicheSeance> createState() => _FicheSeanceState();
}

class _FicheSeanceState extends State<FicheSeance> {
  final _defilement = ScrollController();
  late SeancePlanifiee? _seance = widget.seance;
  late final ValeursFiche _v = switch (widget.seance) {
    final s? => ValeursFiche.depuis(s.courante),
    null => ValeursFiche(
      groupeId: widget.espace.groupeId,
      date: widget.espace.jour,
    ),
  };
  List<Probleme> _problemes = const [];
  bool _publicationRefusee = false;
  bool _modifie = false;
  bool _enCours = false;

  EspaceChef get _espace => widget.espace;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  void _changer(VoidCallback modification) => setState(() {
    modification();
    _modifie = true;
  });

  String? _erreur(Champ champ) {
    for (final p in _problemes) {
      if (p.champ == champ) return p.message;
    }
    return null;
  }

  String _nomGroupe(String? id) {
    for (final g in _espace.pole?.groupes ?? const <Groupe>[]) {
      if (g.id == id) return g.code;
    }
    return id ?? '';
  }

  Future<void> _enregistrer({required bool publier}) async {
    final problemes = _v.verifier();
    if (problemes.isNotEmpty) {
      setState(() {
        _problemes = problemes;
        _publicationRefusee = false;
      });
      _montrerErreurs();
      return;
    }
    final details = _v.enDetails()!;
    final planning = _espace.planning;
    final chef = _espace.chef;
    setState(() => _enCours = true);
    try {
      var seance = _seance;
      if (seance == null || _modifie) {
        seance = await planning.enregistrerBrouillon(
          chef,
          details,
          seanceId: seance?.id,
        );
        setState(() {
          _seance = seance;
          _modifie = false;
        });
      }
      if (!publier) {
        _fermer(
          seance.publiee == null
              ? 'Brouillon enregistré. Il n’est pas encore visible par le groupe.'
              : seance.brouillon == null
              ? 'Aucune modification en attente : la version publiée est '
                    'inchangée.'
              : 'Brouillon enregistré. Le groupe voit toujours la version '
                    'publiée.',
        );
        return;
      }
      final publiee = await planning.publier(chef, seance.id);
      final p = publiee.publiee!;
      _fermer(
        'Séance publiée pour le groupe ${_nomGroupe(p.groupeId)} '
        'et ${p.formateur}.',
      );
    } on PlanningRefuse catch (refus) {
      if (!mounted) return;
      setState(() {
        _problemes = refus.problemes;
        _publicationRefusee = publier && _seance != null;
        _enCours = false;
      });
      _montrerErreurs();
    } on Object {
      if (!mounted) return;
      setState(() {
        _problemes = const [
          Probleme(
            'L’enregistrement a échoué. Vos saisies sont toujours à l’écran : '
            'réessayez.',
          ),
        ];
        _publicationRefusee = false;
        _enCours = false;
      });
      _montrerErreurs();
    }
  }

  void _fermer(String message) {
    if (mounted) Navigator.of(context).pop(message);
  }

  void _montrerErreurs() {
    if (_defilement.hasClients) {
      _defilement.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _choisirDate() async {
    final aujourdhui = minuit(_espace.maintenant);
    final actuelle = _v.date ?? _espace.jour;
    final premiere = actuelle.isBefore(aujourdhui) ? actuelle : aujourdhui;
    final date = await showDatePicker(
      context: context,
      initialDate: actuelle,
      firstDate: premiere,
      lastDate: DateTime(aujourdhui.year + 1, aujourdhui.month),
      helpText: 'Date de la séance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (date != null) _changer(() => _v.date = minuit(date));
  }

  Future<void> _choisirHeure({required bool debut}) async {
    final valeur = debut ? _v.debut : _v.fin;
    final initiale = valeur ?? (debut ? 8 * 60 + 30 : (_v.debut ?? 510) + 120);
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initiale ~/ 60 % 24, minute: initiale % 60),
      // Saisie au clavier : plus rapide et plus précise qu'un cadran pour
      // « 10 h 30 ». Le cadran reste accessible depuis la boîte de dialogue.
      initialEntryMode: TimePickerEntryMode.input,
      helpText: debut ? 'Heure de début' : 'Heure de fin',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (heure == null) return;
    final minutes = heure.hour * 60 + heure.minute;
    _changer(() => debut ? _v.debut = minutes : _v.fin = minutes);
  }

  Future<bool> _confirmerAbandon() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quitter sans enregistrer ?'),
          content: const Text(
            'Les modifications que vous venez de faire seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer la saisie'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitter'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final pole = _espace.pole;
    final seance = _seance;
    final peutPublier = _modifie || seance == null || seance.brouillon != null;
    String? heure(int? minutes) => minutes == null
        ? null
        : heureFr(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

    return PopScope(
      canPop: !_modifie,
      onPopInvokedWithResult: (sorti, _) async {
        if (sorti) return;
        final navigateur = Navigator.of(context);
        if (await _confirmerAbandon()) navigateur.pop();
      },
      child: FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.seance == null ? 'Nouvelle séance' : 'Modifier la séance',
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: _enCours || (!_modifie && seance != null)
                      ? null
                      : () => _enregistrer(publier: false),
                  child: const Text('Enregistrer le brouillon'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _enCours || !peutPublier
                      ? null
                      : () => _enregistrer(publier: true),
                  child: Text(_enCours ? 'Enregistrement…' : 'Publier'),
                ),
              ],
            ),
          ),
          body: ListView(
            controller: _defilement,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (seance != null) ...[
                _Etat(seance: seance),
                const SizedBox(height: 16),
              ],
              if (_problemes.isNotEmpty) ...[
                _Erreurs(
                  problemes: _problemes,
                  publicationRefusee: _publicationRefusee,
                ),
                const SizedBox(height: 16),
              ],
              _Liste(
                label: 'Groupe',
                valeur: _v.groupeId,
                options: {
                  for (final g in pole?.groupes ?? const <Groupe>[])
                    g.id: 'Groupe ${g.code} · ${g.annee}',
                },
                erreur: _erreur(Champ.groupe),
                onChanged: (v) => _changer(() => _v.groupeId = v),
              ),
              _Liste(
                label: 'Module',
                valeur: _v.module,
                options: {for (final m in pole?.modules ?? const []) m: m},
                erreur: _erreur(Champ.module),
                onChanged: (v) => _changer(() => _v.module = v),
              ),
              _Liste(
                label: 'Formateur',
                valeur: _v.formateur,
                options: {for (final f in pole?.formateurs ?? const []) f: f},
                erreur: _erreur(Champ.formateur),
                onChanged: (v) => _changer(() => _v.formateur = v),
              ),
              _Liste(
                label: 'Salle',
                valeur: _v.salle,
                options: {
                  for (final s in pole?.salles ?? const []) s: 'Salle $s',
                },
                erreur: _erreur(Champ.salle),
                onChanged: (v) => _changer(() => _v.salle = v),
              ),
              _ChampChoix(
                label: 'Date',
                valeur: switch (_v.date) {
                  final d? => dateLongue(d),
                  null => null,
                },
                icone: Icons.event,
                erreur: _erreur(Champ.date),
                onTap: _choisirDate,
              ),
              _ChampChoix(
                label: 'Heure de début',
                valeur: heure(_v.debut),
                icone: Icons.schedule,
                erreur: _erreur(Champ.debut),
                onTap: () => _choisirHeure(debut: true),
              ),
              _ChampChoix(
                label: 'Heure de fin',
                valeur: heure(_v.fin),
                icone: Icons.schedule,
                erreur: _erreur(Champ.fin),
                onTap: () => _choisirHeure(debut: false),
              ),
              Text(
                'Publier rend la séance visible au groupe et au formateur. '
                'Un brouillon reste visible par vous seul.',
                style: texte.bodyMedium?.copyWith(color: context.cmc.texteDoux),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// État de la séance et version que voit le groupe.
class _Etat extends StatelessWidget {
  const _Etat({required this.seance});

  final SeancePlanifiee seance;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final p = seance.publiee;
    return SurfaceCmc(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PastilleEtat(seance: seance),
            const SizedBox(height: 8),
            Text(switch (seance.etat) {
              EtatSeance.brouillon =>
                'Le groupe ne voit pas encore cette séance.',
              EtatSeance.publiee =>
                'Le groupe voit cette version. Vos changements resteront '
                    'en brouillon jusqu’à la publication.',
              EtatSeance.modificationEnAttente =>
                'Le groupe voit encore : ${dateLongue(p!.debut)}, '
                    '${plageHoraire(p.debut, p.fin)}, salle ${p.salle}.',
            }, style: texte.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Erreurs extends StatelessWidget {
  const _Erreurs({required this.problemes, required this.publicationRefusee});

  final List<Probleme> problemes;
  final bool publicationRefusee;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final encre = schema.onErrorContainer;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: schema.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                publicationRefusee ? 'Publication impossible' : 'À corriger',
                style: texte.titleMedium?.copyWith(color: encre),
              ),
              const SizedBox(height: 6),
              for (final p in problemes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    p.message,
                    style: texte.bodyLarge?.copyWith(color: encre),
                  ),
                ),
              if (publicationRefusee) ...[
                const SizedBox(height: 6),
                Text(
                  'Le brouillon est enregistré et la version publiée reste '
                  'en place. Corrigez le champ concerné, puis publiez à '
                  'nouveau.',
                  style: texte.bodyMedium?.copyWith(color: encre),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({
    required this.label,
    required this.valeur,
    required this.options,
    required this.erreur,
    required this.onChanged,
  });

  final String label;
  final String? valeur;
  final Map<String, String> options;
  final String? erreur;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Une valeur enregistrée qui n'est plus proposée reste affichée.
    final choix = {...options, ?valeur: options[valeur] ?? valeur ?? ''};
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$valeur'),
        initialValue: valeur,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, errorText: erreur),
        hint: Text('Choisir'),
        items: [
          for (final MapEntry(:key, :value) in choix.entries)
            DropdownMenuItem(value: key, child: Text(value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ChampChoix extends StatelessWidget {
  const _ChampChoix({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.erreur,
    required this.onTap,
  });

  final String label;
  final String? valeur;
  final IconData icone;
  final String? erreur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      button: true,
      label: '$label : ${valeur ?? 'à choisir'}',
      excludeSemantics: erreur == null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: erreur,
            suffixIcon: Icon(icone),
          ),
          isEmpty: valeur == null,
          child: Text(valeur ?? ''),
        ),
      ),
    ),
  );
}
