import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../modeles/apparence.dart';
import '../theme/cmc_theme.dart';
import '../widgets/apercu.dart';
import '../widgets/surfaces.dart';

/// Le choix reste un brouillon visible dans l'aperçu jusqu'à « Appliquer ».
class ReglageApparence extends StatefulWidget {
  const ReglageApparence({super.key, required this.session});

  final Session session;

  @override
  State<ReglageApparence> createState() => _ReglageApparenceState();
}

class _ReglageApparenceState extends State<ReglageApparence> {
  late Apparence _brouillon = widget.session.apparence;
  bool _enCours = false;

  Future<void> _appliquer() async {
    final messager = ScaffoldMessenger.of(context);
    final nom = widget.session.actif!.nom;
    setState(() => _enCours = true);
    final enregistre = await widget.session.appliquer(_brouillon);
    if (!mounted) return;
    setState(() => _enCours = false);
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            enregistre
                ? 'Apparence appliquée au compte $nom.'
                : 'L’apparence n’a pas pu être enregistrée. Réessayez.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final texte = Theme.of(context).textTheme;
      final doux = context.cmc.texteDoux;
      final modifie = _brouillon != widget.session.apparence;
      return FondCmc(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Apparence')),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: modifie && !_enCours ? _appliquer : null,
              child: const Text('Appliquer'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text('Aperçu', style: texte.titleMedium),
              const SizedBox(height: 8),
              ApercuApparence(
                apparence: _brouillon,
                seance: widget.session.prochaine ?? exempleApercu,
              ),
              const SizedBox(height: 20),
              Text('Style', style: texte.titleMedium),
              const SizedBox(height: 8),
              SurfaceCmc(
                child: RadioGroup<StyleApp>(
                  groupValue: _brouillon.style,
                  onChanged: (style) => setState(
                    () => _brouillon = _brouillon.copie(style: style),
                  ),
                  child: Column(
                    children: [
                      for (final style in StyleApp.values)
                        RadioListTile<StyleApp>(
                          value: style,
                          title: Text(style.libelle),
                          subtitle: Text(style.description),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Luminosité', style: texte.titleMedium),
              const SizedBox(height: 8),
              SurfaceCmc(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final choix in Luminosite.values)
                        ChoiceChip(
                          label: Text(choix.libelle),
                          selected: _brouillon.luminosite == choix,
                          onSelected: (_) => setState(
                            () => _brouillon = _brouillon.copie(
                              luminosite: choix,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Système suit le réglage du téléphone.',
                style: texte.bodyMedium?.copyWith(color: doux),
              ),
            ],
          ),
        ),
      );
    },
  );
}
