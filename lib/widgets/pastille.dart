import 'package:material_ui/material_ui.dart';

/// Libellé court sur fond coloré : état d'un TP, d'un rendu…
class Pastille extends StatelessWidget {
  const Pastille({
    super.key,
    required this.texte,
    required this.fond,
    required this.encre,
    this.bord,
  });

  final String texte;
  final Color fond;
  final Color encre;
  final Color? bord;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
        border: bord == null ? null : Border.all(color: bord!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          texte,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: encre, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
