import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/cmc_theme.dart';

/// Fond d'écran. En Liquid Glass, deux halos donnent quelque chose à voir à
/// travers le verre ; en Simple, le fond reste uni.
class FondCmc extends StatelessWidget {
  const FondCmc({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final style = sombre
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: sombre
            ? Brightness.light
            : Brightness.dark,
      ),
      child: CustomPaint(painter: HalosCmc(context.cmc), child: child),
    );
  }
}

class HalosCmc extends CustomPainter {
  const HalosCmc(this.couleurs);

  final CmcCouleurs couleurs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(couleurs.fond, BlendMode.src);
    if (!couleurs.verre) return;
    final l = size.width;
    canvas
      ..drawCircle(
        Offset(l * 0.85, l * 0.45),
        l * 0.5,
        Paint()..color = couleurs.halo,
      )
      ..drawCircle(
        Offset(l * 0.05, size.height * 0.78),
        l * 0.42,
        Paint()..color = couleurs.halo2,
      );
  }

  @override
  bool shouldRepaint(HalosCmc oldDelegate) => oldDelegate.couleurs != couleurs;
}

/// Surface de carte. [verre] demande la transparence, accordée seulement si le
/// style Liquid Glass est actif et que le téléphone n'exige pas plus de
/// contraste.
class SurfaceCmc extends StatelessWidget {
  const SurfaceCmc({
    super.key,
    required this.child,
    this.verre = false,
    this.rayon = 20,
    this.onTap,
  });

  final Widget child;
  final bool verre;
  final double rayon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.cmc;
    final enVerre =
        verre && couleurs.verre && !MediaQuery.highContrastOf(context);
    final arrondi = BorderRadius.circular(rayon);

    final contenu = DecoratedBox(
      decoration: BoxDecoration(
        color: enVerre ? couleurs.teinteVerre : couleurs.surface,
        borderRadius: arrondi,
        border: enVerre ? Border.all(color: couleurs.bordVerre) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? child
            : InkWell(onTap: onTap, borderRadius: arrondi, child: child),
      ),
    );
    return ClipRRect(
      borderRadius: arrondi,
      child: enVerre
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: contenu,
            )
          : contenu,
    );
  }
}
