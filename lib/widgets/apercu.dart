import 'package:material_ui/material_ui.dart';

import '../modeles/apparence.dart';
import '../modeles/seance.dart';
import '../theme/cmc_theme.dart';
import 'carte_seance.dart';
import 'surfaces.dart';

/// Montre l'apparence choisie sans toucher au thème de l'application.
class ApercuApparence extends StatelessWidget {
  const ApercuApparence({
    super.key,
    required this.apparence,
    required this.seance,
  });

  final Apparence apparence;
  final Seance? seance;

  @override
  Widget build(BuildContext context) {
    final luminosite = luminositeResolue(
      apparence.luminosite,
      MediaQuery.platformBrightnessOf(context),
    );
    return Theme(
      data: themeCmc(apparence.style, luminosite),
      child: Builder(
        builder: (context) => ClipRRect(
          borderRadius: BorderRadius.circular(24),
          // Les halos seuls : l'aperçu ne change pas la barre d'état.
          child: CustomPaint(
            painter: HalosCmc(context.cmc),
            foregroundPainter: const _Contour(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (seance case final seance?) ...[
                    CarteSeance(
                      seance: seance,
                      titre: 'PROCHAINE SÉANCE',
                      verre: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Barre décorative : les vrais onglets restent ailleurs.
                  const ExcludeSemantics(child: _BarreMiniature()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarreMiniature extends StatelessWidget {
  const _BarreMiniature();

  @override
  Widget build(BuildContext context) => SurfaceCmc(
    verre: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (index, icone) in const [
            Icons.home_outlined,
            Icons.calendar_month_outlined,
            Icons.person_outline,
          ].indexed)
            Icon(
              icone,
              color: index == 0
                  ? Theme.of(context).colorScheme.primary
                  : context.cmc.texteDoux,
            ),
        ],
      ),
    ),
  );
}

/// Délimite l'aperçu quand son fond est celui de la page.
class _Contour extends CustomPainter {
  const _Contour();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(24),
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF6E8F8A),
  );

  @override
  bool shouldRepaint(_Contour oldDelegate) => false;
}
