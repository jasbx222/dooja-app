import 'package:flutter/material.dart';
import 'dsl.dart';
import 'common.dart';
import 'repo.dart';

abstract class Scr extends StatefulWidget {
  const Scr({super.key});
  Widget view(BuildContext c, ScrSt s);
  void init(ScrSt s) {}
  @override
  State<Scr> createState() => ScrSt();
}

class ScrSt extends State<Scr> {
  final v = <String, dynamic>{};
  final ctls = <String, TextEditingController>{};
  T get<T>(String k, T d) => v.putIfAbsent(k, () => d) as T;
  void set(String k, dynamic x) => mounted ? setState(() => v[k] = x) : null;
  TextEditingController ctl(String k, [String t = '']) => ctls.putIfAbsent(k, () => TextEditingController(text: t));
  void _l() => mounted ? setState(() {}) : null;
  @override
  void initState() {
    super.initState();
    repo.addListener(_l);
    widget.init(this);
  }
  @override
  void dispose() {
    repo.removeListener(_l);
    for (final c in ctls.values) { c.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.view(context, this);
}

Future<T?> push<T>(BuildContext c, Widget w) => Navigator.of(c).push<T>(MaterialPageRoute(builder: (_) => w));
void replace(BuildContext c, Widget w) => Navigator.of(c).pushReplacement(MaterialPageRoute(builder: (_) => w));
void resetTo(BuildContext c, Widget w, {bool anim = false}) => Navigator.of(c).pushAndRemoveUntil(
    anim ? MaterialPageRoute(builder: (_) => w) : PageRouteBuilder(pageBuilder: (_, __, ___) => w, transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero), (_) => false);

// Tab routing is registered by main.dart to avoid import cycles.
late void Function(BuildContext, String) onCustomerTab;
late void Function(BuildContext, String) onOwnerTab;

Widget navbar(BuildContext c, String active) => tabbar(NAV, active, MARK(46, WH, WH), (l) => onCustomerTab(c, l));
Widget onav(BuildContext c, String? active) => tabbar(ONAV, active, I('plus', 32, WH), (l) => onOwnerTab(c, l));

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m, textAlign: TextAlign.center, style: ts(14, 700, WH)), backgroundColor: col(INK), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));

/// Standard 390-wide screen: status bar, scrollable content, optional tab bar / bottom bar.
Widget screen(BuildContext c, List<Widget?> k, {String bg = WH, String? nav, String? onavTab, bool dark = false, double g = 0, Widget? bottomBar, double bottomH = 100, List<Widget> extra = const [], Widget? background, bool scroll = true}) {
  final pb = nav != null || onavTab != null ? 120.0 : (bottomBar != null ? bottomH + 20 : 24.0);
  final content = F(k, g: g, w: 'fill', p: [0, 0, pb, 0]);
  return Scaffold(
    backgroundColor: col(bg),
    resizeToAvoidBottomInset: false,
    body: Stack(children: [
      if (background != null) Positioned.fill(child: background),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        status(dark),
        Expanded(child: scroll ? SingleChildScrollView(child: content) : content),
      ]),
      if (bottomBar != null) Positioned(left: 0, right: 0, bottom: MediaQuery.of(c).viewInsets.bottom, child: bottomBar),
      if (nav != null) Positioned(left: 0, bottom: 0, child: navbar(c, nav)),
      if (onavTab != null) Positioned(left: 0, bottom: 0, child: onav(c, onavTab)),
      ...extra,
    ]),
  );
}

Widget bottom(List<Widget?> k, {double g = 10, String d = 'v'}) => F(k, d: d, g: g, w: 390, p: [12, 24, 30, 24], bg: WH, sk: LN);

Future<X?> openSheet<X>(BuildContext c, {String? title, double top = 360, required List<Widget?> Function(BuildContext sc, void Function(VoidCallback) set) body}) {
  return showModalBottomSheet<X>(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: col('#11111180'),
      elevation: 0,
      builder: (sc) => StatefulBuilder(
          builder: (sc, set) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(sc).viewInsets.bottom),
                child: F([
                  F([BOX(w: 40, h: 5, r: 3, bg: '#D9D6E3')], w: 'fill', al: 'c'),
                  if (title != null) T(title, 18, 800),
                  ...body(sc, set),
                ], g: 16, w: 390, h: 844 - top, p: [12, 24, 30, 24], bg: WH, rr: [28, 28, 0, 0]),
              )));
}

/// Scales the 390pt design canvas to the device; on wide screens shows a phone frame.
class DesignCanvas extends StatelessWidget {
  final Widget child;
  const DesignCanvas(this.child, {super.key});
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LayoutBuilder(builder: (ctx, bc) {
      final wide = bc.maxWidth >= 600;
      final scale = wide ? (bc.maxHeight / 844).clamp(0.5, 1.0) : bc.maxWidth / 390;
      final vh = wide ? 844.0 : bc.maxHeight / scale;
      final inner = MediaQuery(
          data: mq.copyWith(size: Size(390, vh), padding: wide ? EdgeInsets.zero : mq.padding / scale, viewPadding: wide ? EdgeInsets.zero : mq.viewPadding / scale, viewInsets: mq.viewInsets / scale, textScaler: TextScaler.noScaling),
          child: SizedBox(width: 390, height: vh, child: child));
      final scaled = SizedBox(width: 390 * scale, height: vh * scale, child: FittedBox(fit: BoxFit.fill, child: inner));
      if (!wide) return scaled;
      return ColoredBox(color: const Color(0xFFE9E6F2), child: Center(child: Container(decoration: BoxDecoration(boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40)], borderRadius: BorderRadius.circular(28 * scale)), clipBehavior: Clip.antiAlias, child: scaled)));
    });
  }
}
