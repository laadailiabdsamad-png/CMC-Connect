import 'package:material_ui/material_ui.dart';

import '../../etat/session.dart';
import '../../modeles/seance.dart';
import '../../modeles/travaux.dart';
import '../../theme/cmc_theme.dart';
import '../../theme/dates_fr.dart';
import '../../widgets/champ_choix.dart';
import '../../widgets/surfaces.dart';

/// Création d'un TP depuis une séance : groupe et module viennent d'elle.
/// Renvoie le message à afficher au retour.
class NouveauTp extends StatefulWidget {
  const NouveauTp({super.key, required this.session, required this.seance});

  final Session session;
  final Seance seance;

  @override
  State<NouveauTp> createState() => _NouveauTpState();
}

class _NouveauTpState extends State<NouveauTp> {
  final _titre = TextEditingController();
  final _consigne = TextEditingController();
  late DateTime? _date = minuit(widget.seance.debut)
      .add(const Duration(days: 7));
  int? _heure = 18 * 60;
  FichierChoisi? _piece;
  List<ProblemeTravail> _problemes = const [];
  bool _enCours = false;
  bool _modifie = false;

  @override
  void dispose() {
    _titre.dispose();
    _consigne.dispose();
    super.dispose();
  }

  DateTime? get _echeance {
    final (d, h) = (_date, _heure);
    if (d == null || h == null) return null;
    return DateTime(d.year, d.month, d.day, h ~/ 60, h % 60);
  }

  String? _erreur(ChampTravail champ) =>
      _problemes.where((p) => p.champ == champ).firstOrNull?.message;

  Future<void> _choisirDate() async {
    final aujourdhui = minuit(widget.session.maintenant);
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? aujourdhui,
      firstDate: aujourdhui,
      lastDate: DateTime(aujourdhui.year + 1, aujourdhui.month),
      helpText: 'Date d’échéance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (date != null) {
      setState(() {
        _date = minuit(date);
        _modifie = true;
      });
    }
  }

  Future<void> _choisirHeure() async {
    final h = _heure ?? 18 * 60;
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h ~/ 60, minute: h % 60),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Heure d’échéance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (heure != null) {
      setState(() {
        _heure = heure.hour * 60 + heure.minute;
        _modifie = true;
      });
    }
  }

  Future<void> _joindre() async {
    final fichier = await widget.session.fichiers.choisir();
    if (fichier == null || !mounted) return;
    setState(() {
      _piece = fichier;
      _modifie = true;
      _problemes = verifierFichier(fichier);
    });
  }

  Future<void> _publier() async {
    final session = widget.session;
    final problemes = verifierTp(
      titre: _titre.text,
      consigne: _consigne.text,
      echeance: _echeance,
      maintenant: session.maintenant,
      piece: _piece,
    );
    if (problemes.isNotEmpty) {
      setState(() => _problemes = problemes);
      return;
    }
    setState(() => _enCours = true);
    try {
      final tp = await session.travaux.publierTp(
        session.formateur!,
        seanceId: widget.seance.id,
        titre: _titre.text,
        consigne: _consigne.text,
        echeance: _echeance,
        piece: _piece,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        'TP publié pour le groupe ${widget.seance.groupe}, à rendre le '
        '${dateHeureFr(tp.echeance)}.',
      );
    } on TravailRefuse catch (refus) {
      if (!mounted) return;
      setState(() {
        _problemes = refus.problemes;
        _enCours = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _problemes = const [
          ProblemeTravail(
            'Le TP n’a pas pu être enregistré. Vos saisies sont toujours à '
            'l’écran : réessayez.',
          ),
        ];
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final piece = _piece;
    return FormulaireTravail(
      titrePage: 'Nouveau TP',
      seance: widget.seance,
      modifie: _modifie,
      problemesGeneraux: [
        for (final p in _problemes)
          if (p.champ == null) p.message,
      ],
      action: FilledButton(
        onPressed: _enCours ? null : _publier,
        child: Text(_enCours ? 'Publication…' : 'Publier le TP'),
      ),
      champs: [
        TextField(
          controller: _titre,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _modifie = true,
          decoration: InputDecoration(
            labelText: 'Titre',
            hintText: 'Exercice Flutter',
            errorText: _erreur(ChampTravail.titre),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _consigne,
          minLines: 4,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _modifie = true,
          decoration: InputDecoration(
            labelText: 'Consigne',
            alignLabelWithHint: true,
            errorText: _erreur(ChampTravail.consigne),
          ),
        ),
        const SizedBox(height: 14),
        ChampChoix(
          label: 'Date d’échéance',
          valeur: switch (_date) {
            final d? => dateLongue(d),
            null => null,
          },
          icone: Icons.event,
          erreur: _erreur(ChampTravail.echeance),
          onTap: _choisirDate,
        ),
        ChampChoix(
          label: 'Heure d’échéance',
          valeur: switch (_heure) {
            final h? => heureFr(DateTime(2000, 1, 1, h ~/ 60, h % 60)),
            null => null,
          },
          icone: Icons.schedule,
          erreur: null,
          onTap: _choisirHeure,
        ),
        Text('Pièce jointe (facultative)', style: texte.titleMedium),
        const SizedBox(height: 8),
        if (piece == null)
          OutlinedButton.icon(
            onPressed: _joindre,
            icon: const Icon(Icons.attach_file),
            label: const Text('Joindre un fichier'),
          )
        else
          _FichierRetenu(
            fichier: piece,
            onRetirer: () => setState(() {
              _piece = null;
              _problemes = const [];
            }),
          ),
        if (_erreur(ChampTravail.fichier) case final e?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              e,
              style: texte.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Ajout d'un support de cours depuis une séance.
class NouveauSupport extends StatefulWidget {
  const NouveauSupport({
    super.key,
    required this.session,
    required this.seance,
  });

  final Session session;
  final Seance seance;

  @override
  State<NouveauSupport> createState() => _NouveauSupportState();
}

class _NouveauSupportState extends State<NouveauSupport> {
  final _titre = TextEditingController();
  FichierChoisi? _fichier;
  List<ProblemeTravail> _problemes = const [];
  bool _enCours = false;
  bool _modifie = false;

  @override
  void dispose() {
    _titre.dispose();
    super.dispose();
  }

  String? _erreur(ChampTravail champ) =>
      _problemes.where((p) => p.champ == champ).firstOrNull?.message;

  Future<void> _choisir() async {
    final fichier = await widget.session.fichiers.choisir();
    if (fichier == null || !mounted) return;
    setState(() {
      _fichier = fichier;
      _modifie = true;
      if (_titre.text.trim().isEmpty) {
        final point = fichier.nom.lastIndexOf('.');
        _titre.text = point > 0 ? fichier.nom.substring(0, point) : fichier.nom;
      }
      _problemes = verifierFichier(fichier);
    });
  }

  Future<void> _ajouter() async {
    final session = widget.session;
    final problemes = verifierSupport(titre: _titre.text, fichier: _fichier);
    if (problemes.isNotEmpty) {
      setState(() => _problemes = problemes);
      return;
    }
    setState(() => _enCours = true);
    try {
      await session.travaux.ajouterSupport(
        session.formateur!,
        seanceId: widget.seance.id,
        titre: _titre.text,
        fichier: _fichier,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pop('Support ajouté pour le groupe ${widget.seance.groupe}.');
    } on TravailRefuse catch (refus) {
      if (!mounted) return;
      setState(() {
        _problemes = refus.problemes;
        _enCours = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _problemes = const [
          ProblemeTravail('Le support n’a pas pu être enregistré. Réessayez.'),
        ];
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fichier = _fichier;
    return FormulaireTravail(
      titrePage: 'Nouveau support',
      seance: widget.seance,
      modifie: _modifie,
      problemesGeneraux: [
        for (final p in _problemes)
          if (p.champ == null) p.message,
      ],
      action: FilledButton(
        onPressed: _enCours ? null : _ajouter,
        child: Text(_enCours ? 'Enregistrement…' : 'Ajouter le support'),
      ),
      champs: [
        if (fichier == null)
          OutlinedButton.icon(
            onPressed: _choisir,
            icon: const Icon(Icons.attach_file),
            label: const Text('Choisir le fichier'),
          )
        else
          _FichierRetenu(
            fichier: fichier,
            onRetirer: () => setState(() => _fichier = null),
          ),
        if (_erreur(ChampTravail.fichier) case final e?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              e,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _titre,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _modifie = true,
          decoration: InputDecoration(
            labelText: 'Titre',
            hintText: 'Cours : navigation entre écrans',
            errorText: _erreur(ChampTravail.titre),
          ),
        ),
      ],
    );
  }
}

/// Mise en page commune : la séance d'origine en tête, les champs, puis
/// l'action principale en bas d'écran.
class FormulaireTravail extends StatelessWidget {
  const FormulaireTravail({
    super.key,
    required this.titrePage,
    required this.seance,
    required this.modifie,
    required this.problemesGeneraux,
    required this.champs,
    required this.action,
  });

  final String titrePage;
  final Seance seance;
  final bool modifie;
  final List<String> problemesGeneraux;
  final List<Widget> champs;
  final Widget action;

  Future<bool> _confirmerAbandon(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quitter sans publier ?'),
          content: const Text('Ce que vous avez saisi sera perdu.'),
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
    final doux = context.cmc.texteDoux;
    final schema = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !modifie,
      onPopInvokedWithResult: (sorti, _) async {
        if (sorti) return;
        final navigateur = Navigator.of(context);
        if (await _confirmerAbandon(context)) navigateur.pop();
      },
      child: FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(titrePage)),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: action,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              SurfaceCmc(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Groupe ${seance.groupe}', style: texte.titleMedium),
                      Text(seance.module, style: texte.titleMedium),
                      Text(
                        'Séance du ${dateHeureFr(seance.debut)}',
                        style: texte.bodyMedium?.copyWith(color: doux),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (problemesGeneraux.isNotEmpty) ...[
                Semantics(
                  liveRegion: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: schema.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        problemesGeneraux.join('\n'),
                        style: texte.bodyLarge?.copyWith(
                          color: schema.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...champs,
            ],
          ),
        ),
      ),
    );
  }
}

class _FichierRetenu extends StatelessWidget {
  const _FichierRetenu({required this.fichier, required this.onRetirer});

  final FichierChoisi fichier;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) => SurfaceCmc(
    child: ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(fichier.nom),
      subtitle: Text(tailleFr(fichier.taille)),
      trailing: IconButton(
        tooltip: 'Retirer ce fichier',
        onPressed: onRetirer,
        icon: const Icon(Icons.close),
      ),
    ),
  );
}
