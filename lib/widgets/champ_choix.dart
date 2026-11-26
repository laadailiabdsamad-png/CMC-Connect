import 'package:material_ui/material_ui.dart';

/// Champ qui ouvre un sélecteur (date, heure, fichier) au lieu du clavier.
class ChampChoix extends StatelessWidget {
  const ChampChoix({
    super.key,
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
