import 'package:flutter/material.dart';
import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'flow.dart';

const MAPSVG_SMALL = '<svg xmlns="http://www.w3.org/2000/svg" width="318" height="120"><rect width="318" height="120" rx="14" fill="#EEF0F5"/><path d="M200 -5 C170 40 230 80 190 125" stroke="#CFE3F7" stroke-width="18" fill="none"/><g stroke="#fff" stroke-width="8"><path d="M0 40 L318 55"/><path d="M90 0 L110 120"/></g><circle cx="140" cy="62" r="14" fill="#7C3AED"/><circle cx="140" cy="62" r="5" fill="#fff"/></svg>';

List<(String, String, int)> packagesOf(Place p) => [('ساعة', p.unit == 'ساعة' ? '4 لاعبين' : 'للشخص', p.price), ('ساعتين', 'وفّر ${fmt((p.price * 0.25).round())}', (p.price * 1.75).round()), ('3 ساعات', p.type == 'بادل' ? 'مع مضارب' : 'أفضل قيمة', (p.price * 2.5).round())];

N reviewTile(Review r, {bool full = false}) => F([
      R([R([avatar(r.name), F([T(r.name, 14, 700), T(r.ago, 11, 400, MU)], g: 2)], g: 10), stars(r.stars)], jc: 'sb', w: 'fill'),
      Tn(r.text, s: 13, w2: 'fill', lh: 21),
      if (full && r.photos) R([img('padel', 64, 64, 10), img('football', 64, 64, 10)], g: 8),
    ], g: 10, w: 'fill');

Future<void> reportSheet(BuildContext c) {
  var sel = 1;
  const opts = ['محتوى غير لائق', 'معلومات أو أسعار غلط', 'احتيال أو إعلان مضلل', 'إساءة أو تنمر', 'شي ثاني'];
  return openSheet(c, title: 'بلاغ', top: 330, body: (sc, set) => [
        T('ليش تبلّغ عن هذا المحتوى؟', 14, 400, MU),
        for (var i = 0; i < opts.length; i++) R([T(opts[i], 15, 500), radio(sel == i)], jc: 'sb', w: 'fill', al: 'c', p: [12, 0], tap: () => set(() => sel = i)),
        btn('أرسل البلاغ', tap: () async {
          Navigator.pop(sc);
          await repo.lag(400);
          if (c.mounted) toast(c, 'وصلنا بلاغك، فريق ضوجة يراجعه خلال 24 ساعة');
        }),
      ]);
}

class Details extends Scr {
  final String id;
  const Details(this.id, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(id);
    final follow = repo.follows.contains(id);
    final pk = s.get('pk', 1);
    final pks = packagesOf(p);
    final revs = repo.reviewsOf(id);
    Widget pkw(int i) {
      final (t, d, pr) = pks[i];
      final on = i == pk;
      return F([Tn(t, s: 14, w: 700, c: on ? P : INK, al: 'CENTER'), Tn('${fmt(pr)} د.ع', s: 17, w: 800, al: 'CENTER'), Tn(d, s: 11, c: MU, al: 'CENTER')], g: 4, al: 'c', w: 106, p: [14, 6], r: 18, bg: on ? PL : WH, sk: on ? P : LN, skw: on ? 2 : 1, tap: () => s.set('pk', i));
    }

    const am = [('car', 'موقف سيارات'), ('snowflake', 'تكييف'), ('wifi', 'واي فاي'), ('coffee', 'كافتيريا'), ('armchair', 'استراحة'), ('lock', 'خزائن')];
    final hero = img(p.img, 390, 300, 0, [
      status(true),
      F([R([iconbtn('arrow-right', tap: () => Navigator.pop(c)), R([iconbtn('share-2', tap: () => toast(c, 'نسخنا الرابط: dooja.app/p/${p.id}')), iconbtn('heart', c: INK, f: null, tap: () => repo.toggleFav(id))], g: 8)], jc: 'sb', w: 'fill')], w: 'fill', p: [4, 20]),
      R([T('1 / 12', 12, 700, WH), I('image', 14, WH)], g: 4, bg: '#11111199', r: 10, p: [4, 8], ab: [20, 250]),
    ]);
    final r = revs.first;
    final body = F([
      hero,
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([
        img(p.img, 72, 56, 12),
        img('reel', 72, 56, 12, [F([I('play', 16, WH, WH)], al: 'c', jc: 'c', w: 72, h: 56)]),
        img('football', 72, 56, 12),
        img('gaming', 72, 56, 12),
        F([T('+8', 14, 800, P)], al: 'c', jc: 'c', w: 72, h: 56, r: 12, bg: PL),
      ], g: 8, p: [0, 20])),
      F([
        R([
          F([T(p.name, 22, 800), R([T(p.type, 13, 700, P), T('·', 13, 400, MU), T('${p.area}، بغداد', 13, 400, MU)], g: 4)], g: 4),
          F([R([T(p.rating, 18, 800), I('star', 18, STAR, STAR)], g: 4), T('${p.nRev} تقييم', 11, 400, MU)], al: 'e', g: 2, tap: () => push(c, Reviews(id))),
        ], jc: 'sb', al: 's', w: 'fill'),
        R([availBadge(p.kind), tag('مفتوح لحد 2 بالليل', bg: G, c: INK, icon: 'clock')], g: 8),
        R([btn(follow ? 'متابَع' : 'متابعة', icon: follow ? 'check' : 'user-plus', kind: 's', w: null, h: 40, tap: () => repo.toggleFollow(id)), T('${kfmt(p.followers + (follow ? 1 : 0))} متابع', 13, 400, MU)], g: 12, al: 'c'),
      ], g: 12, w: 'fill', p: [4, 20]),
      divider(),
      F([
        T('الأسعار والباقات', 17, 800),
        R([pkw(0), pkw(1), pkw(2)], g: 10, w: 'fill'),
        R([I('info', 14, MU), T(p.type == 'بادل' ? 'تأجير مضارب 3,000 د.ع للمضرب · الكرات مجانية' : 'الأسعار تشمل الضريبة والخدمة', 12, 400, MU)], g: 6),
      ], g: 12, w: 'fill', p: [0, 20]),
      F([T('المرافق', 17, 800), R([for (final (i, l) in am) F([I(i, 22, INK), Tn(l, s: 11, w: 500, c: MU, al: 'CENTER')], g: 6, al: 'c', w: 96, p: [12, 0], r: 16, bg: G)], g: 10, wrap: true, w: 'fill')], g: 12, w: 'fill', p: [0, 20]),
      F([
        card([
          R([T('أوقات الدوام', 16, 800), tag('مفتوح الآن', bg: '#E8F7EE', c: OK)], jc: 'sb', w: 'fill'),
          R([T('السبت - الخميس', 14, 500), T('4:00 م - 2:00 ص', 14, 700)], jc: 'sb', w: 'fill'),
          R([T('الجمعة', 14, 500), T('2:00 م - 3:00 ص', 14, 700)], jc: 'sb', w: 'fill'),
        ]),
        card([
          T('التواصل والموقع', 16, 800),
          S(MAPSVG_SMALL, 318, 120),
          R([meta('map-pin', '${p.area}، شارع 14 رمضان، قرب مطعم الساعة', INK, 13)], w: 'fill'),
          R([
            btn('اتصال', icon: 'phone', kind: 'g', h: 44, tap: () => toast(c, 'يتصل بـ ${p.phone}')),
            btn('واتساب', icon: 'message-circle', kind: 'g', h: 44, tap: () => toast(c, 'يفتح واتساب ${p.phone}')),
            btn('انستغرام', icon: 'instagram', kind: 'g', h: 44, tap: () => toast(c, 'يفتح @dooja.${p.id}')),
          ], g: 8, w: 'fill'),
          btn('الاتجاهات', icon: 'navigation', kind: 's', h: 44, tap: () => toast(c, 'يفتح الخريطة على ${p.area}')),
        ]),
      ], w: 'fill', p: [0, 20], g: 14),
      F([
        R([T('التقييمات', 17, 800), F([T('عرض الكل (${p.nRev})', 13, 700, P)], tap: () => push(c, Reviews(id)))], jc: 'sb', w: 'fill'),
        card([
          reviewTile(r),
          if (r.reply != null) divider(),
          if (r.reply != null) F([R([T('رد صاحب المكان', 12, 700, P), I('reply', 14, P)], g: 4), T(r.reply!, 13, 400, INK)], g: 4, w: 'fill', p: 12, r: 12, bg: BG),
        ]),
      ], g: 12, w: 'fill', p: [0, 20]),
      R([I('flag', 16, MU), T('بلّغ عن هذا المكان', 13, 500, MU)], g: 6, p: [0, 20], tap: () => reportSheet(c)),
    ], g: 20, w: 'fill', p: [0, 0, 120, 0]);
    final pr = pks[pk];
    return Scaffold(
        backgroundColor: col(WH),
        body: Stack(children: [
          Positioned.fill(child: SingleChildScrollView(child: body)),
          Positioned(left: 0, right: 0, bottom: 0, child: bottom([
            R([
              F([T(pk == 0 ? 'يبدأ من' : pr.$1, 12, 400, MU), T('${fmt(pr.$3)} د.ع', 18, 800, P)], g: 2),
              btn('احجز هسه', icon: 'calendar-check', w: 200, tap: () => push(c, p.kind == 'full' ? Waitlist(id) : BookSlot(id, dur: pk))),
            ], jc: 'sb', w: 'fill'),
          ])),
        ]));
  }
}

class Reviews extends Scr {
  final String id;
  const Reviews(this.id, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(id);
    final ch = s.get('ch', 'الكل');
    var revs = repo.reviewsOf(id).toList();
    if (ch == 'مع صور') revs = revs.where((r) => r.photos).toList();
    if (ch == '5 نجوم') revs = revs.where((r) => r.stars == 5).toList();
    Widget bar(int n, double w) => R([T('$n', 12, 700), F([BOX(w: w, h: 6, r: 3, bg: P)], d: 'h', w: 200, h: 6, r: 3, bg: G)], g: 8, al: 'c');
    return screen(c, [
      topbar('التقييمات', sub: p.name),
      F([
        card([
          R([
            F([Tn(p.rating, s: 40, w: 800, al: 'CENTER'), stars(5, 14), T('${p.nRev} تقييم', 12, 400, MU)], al: 'c', g: 4),
            F([bar(5, 170), bar(4, 40), bar(3, 12), bar(2, 4), bar(1, 2)], g: 6),
          ], jc: 'sb', al: 'c', w: 'fill'),
        ]),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([for (final (l, i) in [('الكل', null), ('مع صور', 'image'), ('5 نجوم', null), ('الأحدث', null)]) chip(l, ch == l, i, 13, () => s.set('ch', l))], g: 8)),
        for (final r in revs) card([reviewTile(r, full: true), if (r.reply != null) F([T('رد صاحب المكان', 12, 700, P), T(r.reply!, 13, 400, INK)], g: 4, w: 'fill', p: 12, r: 12, bg: BG)]),
      ], g: 14, w: 'fill', p: [4, 20]),
    ]);
  }
}
