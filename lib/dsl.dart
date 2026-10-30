// Layout primitives mirroring the design spec (auto-layout frames, RTL).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const P = '#7C3AED', PL = '#EDE9FE', BG = '#F5F3FF', G = '#F1F1F6', INK = '#111111', WH = '#FFFFFF', MU = '#6B6B7B', LN = '#ECE9F5', PD = '#5B21B6';
const OK = '#15803D', OKB = '#E7F6EC', WR = '#B45309', WRB = '#FFF4E5', RD = '#C62828', STAR = '#F5A524';

final Map<String, Color> _cc = {};
Color col(String s) => _cc.putIfAbsent(s, () {
      var h = s.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      return Color(int.parse(h.substring(6, 8) + h.substring(0, 6), radix: 16));
    });

final Map<String, String> ICONS = {};
const iconNames = <String>[];
Future<void> loadIcons() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  for (final a in manifest.listAssets().where((a) => a.startsWith('assets/icons/'))) {
    final n = a.split('/').last.replaceAll('.svg', '');
    ICONS[n] = (await rootBundle.loadString(a)).replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Node: a widget carrying layout hints for its parent frame.
class N extends StatelessWidget {
  final Widget child;
  final bool fillW, fillH, hasFill;
  final List<double>? ab;
  const N(this.child, {this.fillW = false, this.fillH = false, this.hasFill = false, this.ab, super.key});
  @override
  Widget build(BuildContext context) => child;
}

List<double> pad(dynamic p) {
  if (p is num) return List.filled(4, p.toDouble());
  final l = (p as List).map((e) => (e as num).toDouble()).toList();
  if (l.length == 2) return [l[0], l[1], l[0], l[1]];
  return l;
}

EdgeInsets ins(List<double> p) => EdgeInsets.fromLTRB(p[3], p[0], p[1], p[2]);

FontWeight fw(int w) => switch (w) { 300 => FontWeight.w300, 500 => FontWeight.w500, 600 => FontWeight.w600, 700 => FontWeight.w700, 800 => FontWeight.w700, 900 => FontWeight.w700, _ => FontWeight.w400 };

MainAxisAlignment _jc(String? j) => switch (j) { 'c' => MainAxisAlignment.center, 'e' => MainAxisAlignment.end, 'sb' => MainAxisAlignment.spaceBetween, _ => MainAxisAlignment.start };

class DashPainter extends CustomPainter {
  final Color c; final double r, w;
  DashPainter(this.c, this.r, this.w);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = w;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w), Radius.circular(r)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) { canvas.drawPath(m.extractPath(d, d + 6), p); d += 11; }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

DecorationImage? _img(String? bg) {
  if (bg == null || !bg.startsWith('img:')) return null;
  final parts = bg.split(':');
  final k = parts[1];
  return DecorationImage(image: AssetImage(k == 'dice' ? 'assets/img/dice.png' : 'assets/img/$k.jpg'), fit: parts.length > 2 && parts[2] == 'FIT' ? BoxFit.contain : BoxFit.cover);
}

/// Frame. d: 'v' column, 'h' row, null absolute box.
N F(List<Widget?> kids, {String? d = 'v', double g = 0, dynamic p = 0, String? bg, double r = 0, dynamic w, dynamic h, String? al, String? jc, String? sk, double? skw, bool clip = false, List<double>? ab, double? op, bool ltr = false, List<double>? rr, bool dash = false, bool wrap = false, VoidCallback? tap, Key? key}) {
  final ks = kids.whereType<Widget>().toList();
  final abs = ks.where((k) => k is N && k.ab != null).cast<N>().toList();
  final flow = ks.where((k) => !(k is N && k.ab != null)).toList();
  final pp = pad(p);
  bool isFillW(Widget k) => k is N && k.fillW;
  bool isFillH(Widget k) => k is N && k.fillH;
  bool hasFill = flow.any((k) => isFillW(k) || (k is N && k.hasFill));
  Widget? inner;
  if (d != null && flow.isNotEmpty) {
    if (wrap) {
      inner = Wrap(spacing: g, runSpacing: g, textDirection: ltr ? TextDirection.ltr : null, alignment: jc == 'c' ? WrapAlignment.center : WrapAlignment.start, crossAxisAlignment: WrapCrossAlignment.center, verticalDirection: VerticalDirection.up, children: flow);
    } else if (d == 'h') {
      final ch = <Widget>[];
      for (var i = 0; i < flow.length; i++) {
        if (i > 0 && g > 0) ch.add(SizedBox(width: g));
        final k = flow[i];
        ch.add(isFillW(k) ? Expanded(child: k) : (k is N && k.hasFill) ? Flexible(child: k) : k);
      }
      inner = Row(
          mainAxisSize: w == null && !flow.any(isFillW) ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: _jc(jc),
          crossAxisAlignment: switch (al ?? 'c') { 's' => CrossAxisAlignment.start, 'e' => CrossAxisAlignment.end, _ => CrossAxisAlignment.center },
          textDirection: ltr ? TextDirection.ltr : null,
          children: ch);
    } else {
      final anyFill = flow.any(isFillW);
      final a = al ?? 's';
      final ch = <Widget>[];
      for (var i = 0; i < flow.length; i++) {
        if (i > 0 && g > 0) ch.add(SizedBox(height: g));
        var k = flow[i];
        if (anyFill && !isFillW(k) && k is! Flexible) k = Align(alignment: a == 'c' ? Alignment.center : a == 'e' ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: k);
        ch.add(isFillH(k) ? Expanded(child: k) : k);
      }
      inner = Column(
          mainAxisSize: h == null && !flow.any(isFillH) ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: _jc(jc),
          crossAxisAlignment: anyFill ? CrossAxisAlignment.stretch : switch (a) { 'c' => CrossAxisAlignment.center, 'e' => CrossAxisAlignment.end, _ => CrossAxisAlignment.start },
          children: ch);
      if (anyFill && w == null) inner = IntrinsicWidth(child: inner);
    }
  }
  Widget body;
  if (abs.isNotEmpty || d == null) {
    body = Stack(clipBehavior: clip ? Clip.hardEdge : Clip.none, children: [
      if (inner != null) Padding(padding: ins(pp), child: inner) else if (w is num && h is num) const SizedBox.expand(),
      for (final a in abs) Positioned(left: a.ab![0], top: a.ab![1], child: a),
    ]);
  } else {
    body = Padding(padding: ins(pp), child: inner ?? const SizedBox.shrink());
  }
  BorderRadius? br = rr != null ? BorderRadius.only(topLeft: Radius.circular(rr[0]), topRight: Radius.circular(rr[1]), bottomRight: Radius.circular(rr[2]), bottomLeft: Radius.circular(rr[3])) : (r > 0 ? BorderRadius.circular(r) : null);
  Gradient? grad;
  if (bg != null && bg.startsWith('lg:')) {
    final ps = bg.split(':');
    grad = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col(ps[1]), col(ps[2])]);
  }
  final deco = BoxDecoration(
      color: bg != null && !bg.startsWith('img:') && !bg.startsWith('lg:') ? col(bg) : null,
      image: _img(bg),
      gradient: grad,
      borderRadius: br,
      border: sk != null && !dash ? Border.all(color: col(sk), width: skw ?? 1) : null);
  Widget out = Container(
      width: w is num ? w.toDouble() : null,
      height: h is num ? h.toDouble() : null,
      decoration: deco,
      clipBehavior: clip && br != null ? Clip.antiAlias : (clip ? Clip.hardEdge : Clip.none),
      foregroundDecoration: null,
      child: body);
  if (dash && sk != null) out = CustomPaint(foregroundPainter: DashPainter(col(sk), r, skw ?? 1), child: out);
  if (op != null) out = Opacity(opacity: op, child: out);
  if (tap != null) out = GestureDetector(behavior: HitTestBehavior.opaque, onTap: tap, child: out);
  return N(out, fillW: w == 'fill', fillH: h == 'fill', hasFill: hasFill && w == null, ab: ab, key: key);
}

N R(List<Widget?> kids, {double g = 0, dynamic p = 0, String? bg, double r = 0, dynamic w, dynamic h, String? al, String? jc, String? sk, double? skw, bool clip = false, List<double>? ab, double? op, bool ltr = false, bool dash = false, bool wrap = false, VoidCallback? tap, Key? key}) =>
    F(kids, d: 'h', g: g, p: p, bg: bg, r: r, w: w, h: h, al: al, jc: jc, sk: sk, skw: skw, clip: clip, ab: ab, op: op, ltr: ltr, dash: dash, wrap: wrap, tap: tap, key: key);

N BOX({dynamic w, dynamic h, double r = 0, String? bg, String? sk, double? skw, List<double>? ab, List<double>? rr}) => F(const [], d: null, w: w, h: h, r: r, bg: bg, sk: sk, skw: skw, ab: ab, rr: rr);

TextStyle ts(double s, int w, String c, {double? lh, bool st = false}) => TextStyle(fontFamily: 'Plex', fontSize: s, fontWeight: fw(w), color: col(c), height: lh != null ? lh / s : null, decoration: st ? TextDecoration.lineThrough : null, decorationColor: col(c));

N T(String v, [double s = 14, int w = 400, String c = INK]) => Tx(v, s, w, c);
N Tx(String v, double s, int w, String c, {String? al, dynamic w2, double? lh, bool st = false, List<double>? ab, double? op, int? maxLines}) {
  Widget t = Text(v,
      textAlign: al == 'CENTER' ? TextAlign.center : al == 'LEFT' ? TextAlign.left : TextAlign.right,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: ts(s, w, c, lh: lh, st: st));
  if (w2 is num) t = SizedBox(width: w2.toDouble(), child: t);
  if (op != null) t = Opacity(opacity: op, child: t);
  return N(t, fillW: w2 == 'fill', ab: ab);
}

/// Text with named options.
N Tn(String v, {double s = 14, int w = 400, String c = INK, String? al, dynamic w2, double? lh, bool st = false, List<double>? ab, int? maxLines}) => Tx(v, s, w, c, al: al, w2: w2, lh: lh, st: st, ab: ab, maxLines: maxLines);

N I(String n, [double s = 20, String c = INK, String? f, double? sw, List<double>? ab]) {
  var sv = ICONS[n] ?? ICONS['circle']!;
  sv = sv.replaceAll('currentColor', c);
  if (f != null) sv = sv.replaceFirst('fill="none"', 'fill="$f"');
  sv = sv.replaceFirst('stroke-width="2"', 'stroke-width="${(sw ?? 2) * 24 / s * strokeScale(s)}"');
  return N(SvgPicture.string(sv, width: s, height: s), ab: ab);
}

// Figma keeps stroke weight constant (~2px) when icons are resized.
double strokeScale(double s) => s / 24 + (1 - s / 24) * 0.0 + (kStrokeFixed ? (1 - s / 24) : 0);
const kStrokeFixed = true;

N S(String v, double w, double h, {List<double>? ab}) => N(SvgPicture.string(v, width: w, height: h, fit: BoxFit.fill), ab: ab);

N img(String k, double w, double h, [double r = 0, List<Widget?> kids = const [], String? d = 'v', dynamic p = 0, String? al, String? jc, double g = 0, List<double>? ab, VoidCallback? tap]) =>
    F(kids, bg: 'img:$k', w: w, h: h, r: r, clip: true, d: d, p: p, al: al, jc: jc, g: g, ab: ab, tap: tap);

bool get isWebPreview => kIsWeb;
