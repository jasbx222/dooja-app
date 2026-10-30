import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dsl.dart';
import 'app.dart';
import 'repo.dart';
import 'screens/auth.dart';
import 'screens/home.dart';
import 'screens/flow.dart';
import 'screens/more.dart';
import 'screens/owner.dart';
import 'screens/gallery.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadIcons();
  for (final f in ['tab_center_infinity_white', 'lockup_color', 'lockup_white', 'mark_purple', 'mark_white']) {
    final l = SvgAssetLoader('assets/logo/$f.svg');
    await svg.cache.putIfAbsent(l.cacheKey(null), () => l.loadBytes(null));
  }
  onCustomerTab = (c, t) {
    switch (t) {
      case 'الرئيسية': resetTo(c, const Home());
      case 'حجوزاتي': resetTo(c, const Bookings());
      case 'اختارلي': push(c, const PickQ());
      case 'المفضلة': resetTo(c, const Favs());
      case 'حسابي': resetTo(c, const Profile());
      case '__login': resetTo(c, const Login(), anim: true);
    }
  };
  onOwnerTab = (c, t) {
    switch (t) {
      case 'الرئيسية': resetTo(c, const OwnerHome());
      case 'الحجوزات': resetTo(c, const OBookings());
      case '+': postSheet(c);
      case 'الإحصائيات': resetTo(c, const OInsights());
      case 'مشروعي': resetTo(c, const OProject());
    }
  };
  repo.role;
  runApp(const DoojaApp());
}

class DoojaApp extends StatelessWidget {
  const DoojaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navKey,
        title: 'ضوجة',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'IQ'),
        supportedLocales: const [Locale('ar', 'IQ')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        theme: ThemeData(fontFamily: 'Plex', scaffoldBackgroundColor: col(WH), colorScheme: ColorScheme.fromSeed(seedColor: col(P)), splashFactory: NoSplash.splashFactory),
        builder: (c, child) { for (final k in const ['padel', 'billiard', 'gaming', 'cafe', 'football', 'pool', 'friends', 'food', 'reel']) { precacheImage(AssetImage('assets/img/$k.jpg'), c); } precacheImage(const AssetImage('assets/img/dice.png'), c); return DesignCanvas(child!); },
        home: () { final q = int.tryParse(Uri.base.queryParameters['s'] ?? ''); final g = galleryItems(); return q != null && q < g.length ? g[q].$2() : const Splash(); }(),
      );
}
