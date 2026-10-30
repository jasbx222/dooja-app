import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'dsl.dart';

const INF_PATH = 'M60 40 C70 25 78 15 92 15 C106 15 116 26 116 40 C116 54 106 65 92 65 C78 65 70 55 60 40 C50 25 42 15 28 15 C14 15 4 26 4 40 C4 54 14 65 28 65 C42 65 50 55 60 40 Z';
String star4(double cx, double cy, double r) {
  final q = r * 0.18;
  return 'M$cx ${cy - r} Q${cx + q} ${cy - q} ${cx + r} $cy Q${cx + q} ${cy + q} $cx ${cy + r} Q${cx - q} ${cy + q} ${cx - r} $cy Q${cx - q} ${cy - q} $cx ${cy - r} Z';
}

String markSvg([String c = P, String? starc, double sw = 11]) {
  starc ??= c;
  return '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="80" viewBox="0 0 120 80"><path d="$INF_PATH" fill="none" stroke="$c" stroke-width="$sw" stroke-linejoin="round"/><path d="${star4(28, 40, 9)}" fill="$starc"/><path d="${star4(92, 40, 9)}" fill="$starc"/></svg>';
}

N MARK([double w = 60, String c = P, String? starc]) => N(SvgPicture.asset(c == WH ? 'assets/logo/mark_white.svg' : 'assets/logo/mark_purple.svg', width: w, height: (w * 281.75 / 562.25).roundToDouble()));
N WORD([double h = 26, String c = INK, String acc = P, bool sub = true]) {
  final s = h / 26;
  return F([
    R([T('D', (30 * s).roundToDouble(), 800, c), MARK((44 * s).roundToDouble(), acc), T('JA', (30 * s).roundToDouble(), 800, c)], g: (1 * s).roundToDouble(), ltr: true),
    if (sub) Tn('ضوجة؟', s: (15 * s).roundToDouble(), w: 700, c: acc, al: 'CENTER'),
  ], al: 'c');
}

Widget status([bool dark = false]) => Builder(builder: (ctx) {
      if (!isWebPreview) return SizedBox(height: MediaQuery.of(ctx).padding.top + 8);
      final c = dark ? WH : INK;
      return R([T('9:41', 15, 700, c), R([I('signal', 16, c), I('wifi', 16, c), I('battery-full', 22, c)], g: 5, ltr: true)], jc: 'sb', ltr: true, w: 'fill', p: [14, 26, 6, 26]);
    });

N btn(String label, {String? icon, String kind = 'p', dynamic w = 'fill', double h = 52, VoidCallback? tap, bool busy = false}) {
  final bgc = {'p': P, 's': PL, 'g': G, 'w': WH, 'o': null, 'd': '#FDECEC'}[kind];
  final fc = {'p': WH, 's': P, 'g': INK, 'w': INK, 'o': P, 'd': RD}[kind]!;
  return R([
    if (busy) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: col(fc))) else T(label, 16, 700, fc),
    if (icon != null && !busy) I(icon, 20, fc),
  ], g: 8, jc: 'c', bg: bgc, r: (h ~/ 2).toDouble(), h: h, w: w, p: [0, 22], sk: kind == 'o' ? P : null, tap: busy ? null : tap);
}

N chip(String label, [bool on = false, String? icon, double s = 13, VoidCallback? tap]) => R([
      if (icon != null) I(icon, 16, on ? WH : INK),
      T(label, s, on ? 700 : 500, on ? WH : INK),
    ], g: 6, bg: on ? P : G, r: 20, p: [8, 14], tap: tap);

N tag(String label, {String bg = PL, String c = P, double s = 11, String? icon}) => R([if (icon != null) I(icon, 12, c), T(label, s, 700, c)], g: 4, bg: bg, r: 8, p: [4, 8]);

N iconbtn(String n, {String bg = WH, String c = INK, double s = 40, String? sk = LN, bool dot = false, VoidCallback? tap, String? f}) => F([
      I(n, 20, c, f),
      if (dot) BOX(w: 9, h: 9, r: 5, bg: '#E5484D', ab: [s - 14, 8]),
    ], al: 'c', jc: 'c', w: s, h: s, r: s / 2, bg: bg, sk: sk, tap: tap);

Widget topbar(String title, {bool back = true, Widget? right, String? sub}) => Builder(
    builder: (ctx) => R([
          back ? iconbtn('arrow-right', tap: () => Navigator.of(ctx).maybePop()) : BOX(w: 40, h: 40),
          F([Tn(title, s: 18, w: 700, al: 'CENTER'), if (sub != null) Tn(sub, s: 12, c: MU, al: 'CENTER')], al: 'c', g: 2),
          right ?? BOX(w: 40, h: 40),
        ], jc: 'sb', w: 'fill', p: [8, 20]));

N sechead(String title, [String? icon, String? more = 'عرض الكل', VoidCallback? tap]) => R([
      R([if (icon != null) I(icon, 18, P), T(title, 18, 800)], g: 6),
      if (more != null) F([T(more, 13, 700, P)], tap: tap),
    ], jc: 'sb', w: 'fill', p: [0, 20]);

N inp(String label, String val, {String? icon, bool ph = false, dynamic w = 'fill', Widget? lead, TextEditingController? ctl, TextInputType? kb}) => F([
      T(label, 13, 500, MU),
      R([
        if (icon != null) I(icon, 20, MU),
        ctl != null ? N(field(ctl, val, 15, kb: kb), fillW: true) : Tn(val, s: 15, c: ph ? MU : INK, w2: 'fill'),
        lead,
      ], g: 10, bg: G, r: 14, h: 52, w: 'fill', p: [0, 16]),
    ], g: 8, w: w);

Widget field(TextEditingController c, String hint, double s, {TextInputType? kb, TextAlign al = TextAlign.right, int w = 400, ValueChanged<String>? onChanged, TextDirection? dir, FocusNode? focus, int? maxLength}) => TextField(
    controller: c,
    focusNode: focus,
    keyboardType: kb,
    textAlign: al,
    maxLength: maxLength,
    textDirection: dir,
    onChanged: onChanged,
    cursorColor: col(P),
    style: ts(s, w, INK),
    decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: hint, counterText: '', hintStyle: ts(s, 400, MU)));

N card(List<Widget?> k, {double p = 16, double g = 10, double r = 20, dynamic w = 'fill', String bg = WH, String? sk = LN, VoidCallback? tap}) => F(k, p: p, g: g, r: r, w: w, bg: bg, sk: sk, tap: tap);
N divider() => BOX(w: 'fill', h: 1, bg: LN);
N price(String v, [String? old, double s = 15]) => R([T('$v د.ع', s, 800, P), if (old != null) Tn(old, s: 12, c: MU, st: true)], g: 6);
N rating(String v, [String? n, String c = INK]) => R([I('star', 14, STAR, STAR), T(v, 13, 700, c), if (n != null) T('($n)', 12, 400, MU)], g: 4);
N meta(String icon, String txt, [String c = MU, double s = 12]) => R([I(icon, 14, c), T(txt, s, 400, c)], g: 4);

const BARSVG = '<svg xmlns="http://www.w3.org/2000/svg" width="390" height="92" viewBox="0 0 390 92"><path d="M0 24 Q0 0 24 0 H140 C152 0 156 4 160 14 C168 38 182 46 195 46 C208 46 222 38 230 14 C234 4 238 0 250 0 H366 Q390 0 390 24 V92 H0 Z" fill="#FFFFFF" stroke="#ECE9F5" stroke-width="1"/></svg>';

typedef TabItem = (String?, String);
const NAV = <TabItem>[('house', 'الرئيسية'), ('calendar-check', 'حجوزاتي'), (null, 'اختارلي'), ('heart', 'المفضلة'), ('user', 'حسابي')];
const ONAV = <TabItem>[('house', 'الرئيسية'), ('calendar-check', 'الحجوزات'), (null, 'نشر'), ('chart-column', 'الإحصائيات'), ('store', 'مشروعي')];

Widget tabbar(List<TabItem> items, String? active, Widget center, void Function(String) onTab) {
  final kids = <Widget>[];
  for (final (ic, l) in items) {
    if (ic == null) {
      kids.add(BOX(w: 72, h: 10));
    } else {
      final on = l == active;
      kids.add(F([I(ic, 24, on ? P : INK, on && ['house', 'heart', 'user'].contains(ic) ? P : null), Tn(l, s: 12, w: on ? 700 : 500, c: on ? P : INK, al: 'CENTER')], g: 5, al: 'c', w: 64, tap: () => onTab(l)));
    }
  }
  final centerLabel = items[2].$2;
  return SizedBox(
      width: 390,
      height: 120,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, top: 28, child: S(BARSVG, 390, 92)),
        Positioned(left: 0, top: 40, child: R(kids, jc: 'sb', al: 'c', w: 390, h: 72, p: [0, 16])),
        Positioned(left: 170, top: 22, child: F([SvgPicture.asset('assets/logo/tab_center_infinity_white.svg', width: 30, height: 30)], al: 'c', jc: 'c', w: 50, h: 50, r: 25, bg: P, tap: () => onTab(centerLabel))),
      ]));
}

// ---- cards
const CATS = <(String, String)>[('layout-grid', 'كل الأقسام'), ('dribbble', 'ملاعب'), ('padel', 'بادل'), ('billiard', 'بليارد'), ('gamepad-2', 'ألعاب إلكترونية'), ('coffee', 'كافيهات'), ('utensils', 'مطاعم'), ('tree-palm', 'منتزهات ومنتجعات'), ('waves', 'مسابح'), ('party-popper', 'فعاليات'), ('baby', 'أنشطة عائلية'), ('ellipsis', 'أخرى')];
const PADEL = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><ellipse cx="10" cy="9" rx="6" ry="7"/><path d="M13 14.5 L19 20.5"/><circle cx="8" cy="7" r=".6"/><circle cx="11" cy="7" r=".6"/><circle cx="9.5" cy="10" r=".6"/><circle cx="12.5" cy="10" r=".6"/><circle cx="19.5" cy="5" r="1.6"/></svg>';
const BILL = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4.5"/><path d="M12 9.6a1.2 1.2 0 1 0 0 .01M12 12.4a1.4 1.4 0 1 0 0 .01"/></svg>';
N cicon(String n, [double s = 24, String c = INK]) {
  if (n == 'padel') return S(PADEL.replaceAll('currentColor', c).replaceFirst('stroke-width="2"', 'stroke-width="${2 * 24 / s}"'), s, s);
  if (n == 'billiard') return S(BILL.replaceAll('currentColor', c).replaceFirst('stroke-width="2"', 'stroke-width="${2 * 24 / s}"'), s, s);
  return I(n, s, c);
}

N cattile(String n, String l, [bool on = false, VoidCallback? tap]) => F([
      F([cicon(n, 26, on ? WH : INK)], al: 'c', jc: 'c', w: 62, h: 62, r: 20, bg: on ? P : G),
      Tn(l, s: 12, w: on ? 700 : 500, c: on ? P : INK, al: 'CENTER', w2: 72),
    ], g: 8, al: 'c', w: 72, tap: tap);

N availBadge(String kind) {
  if (kind == 'open') return tag('مفتوح الآن', bg: WH, c: OK, icon: 'circle-check');
  if (kind == 'slots') return tag('تتوفر مواعيد الآن', bg: P, c: WH, icon: 'calendar-check');
  return tag('مفتوح · الحجز ممتلئ', bg: WH, c: MU, icon: 'hourglass');
}

N tabs(List<String> l, int on, [void Function(int)? tap]) => R([
      for (var i = 0; i < l.length; i++)
        F([Tn(l[i], s: 14, w: i == on ? 800 : 500, c: i == on ? P : MU, al: 'CENTER')], al: 'c', jc: 'c', w: 'fill', h: 40, r: 12, bg: i == on ? WH : null, tap: tap == null ? null : () => tap(i)),
    ], g: 4, w: 'fill', p: 4, r: 16, bg: G);

N toggle(bool on, [VoidCallback? tap]) => R([BOX(w: 22, h: 22, r: 11, bg: WH)], w: 46, h: 28, r: 14, p: [3, 3], bg: on ? P : '#D9D6E3', jc: on ? 'e' : 's', tap: tap);

N radio(bool on) => F([if (on) BOX(w: 10, h: 10, r: 5, bg: P)], al: 'c', jc: 'c', w: 22, h: 22, r: 11, sk: on ? P : LN, skw: 2);

N avatar(String name, [double s = 36, double fs = 14]) => F([Tn(name.characters.first, s: fs, w: 800, c: P, al: 'CENTER')], al: 'c', jc: 'c', w: s, h: s, r: s / 2, bg: PL);

N stars(int n, [double s = 13]) => R([for (var i = 0; i < n; i++) I('star', s, STAR, STAR)], g: 2);

N ibox(String i, {String c = P, String bg = PL, double s = 44}) => F([I(i, (s ~/ 2).toDouble(), c)], al: 'c', jc: 'c', w: s, h: s, r: (s ~/ 3).toDouble(), bg: bg);

N sk(double w, double h, [double r = 10]) => BOX(w: w, h: h, r: r, bg: G);
