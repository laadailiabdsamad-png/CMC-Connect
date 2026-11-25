import 'package:material_ui/material_ui.dart';

import '../etat/session.dart';
import '../theme/cmc_theme.dart';
import '../widgets/surfaces.dart';
import 'accueil.dart';
import 'planning.dart';
import 'profil.dart';

/// Les trois onglets du stagiaire.
class Coquille extends StatefulWidget {
  const Coquille({super.key, required this.session});

  final Session session;

  @override
  State<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends State<Coquille> {
  int _onglet = 0;

  void _ouvrir(int onglet) => setState(() => _onglet = onglet);

  @override
  Widget build(BuildContext context) => FondCmc(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      // Le contenu ne passe derrière la barre que si elle est en verre.
      extendBody: context.cmc.verre,
      body: IndexedStack(
        index: _onglet,
        children: [
          Accueil(session: widget.session, ouvrirPlanning: () => _ouvrir(1)),
          Planning(session: widget.session),
          Profil(session: widget.session),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SurfaceCmc(
          verre: true,
          rayon: 26,
          child: NavigationBar(
            height: 72,
            selectedIndex: _onglet,
            onDestinationSelected: _ouvrir,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Planning',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
