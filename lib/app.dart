import 'package:material_ui/material_ui.dart';

import 'ecrans/choix_profil.dart';
import 'ecrans/coquille.dart';
import 'etat/session.dart';
import 'theme/cmc_theme.dart';

class CmcConnect extends StatefulWidget {
  const CmcConnect({super.key, required this.session});

  final Session session;

  @override
  State<CmcConnect> createState() => _CmcConnectState();
}

class _CmcConnectState extends State<CmcConnect> {
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    // Au retour dans l'application, l'heure a pu dépasser la prochaine séance.
    _cycle = AppLifecycleListener(onResume: widget.session.rafraichir);
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final apparence = session.apparence;
      final actif = session.actif;
      return MaterialApp(
        title: 'CMC Connect',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: themeCmc(apparence.style, Brightness.light),
        darkTheme: themeCmc(apparence.style, Brightness.dark),
        themeMode: modeDe(apparence.luminosite),
        home: actif == null
            ? ChoixProfil(session: session)
            : Coquille(key: ValueKey(actif.id), session: session),
      );
    },
  );
}
