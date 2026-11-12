import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'place.dart';
import 'flow.dart';
import 'more.dart';

N heartBtn(Place p, {double s = 30, double is_ = 16, List<double>? ab}) {
  final on = repo.favs.contains(p.id);
  return F(
    [I('heart', is_, on ? P : INK, on ? P : null)],
    al: 'c',
    jc: 'c',
    w: s,
    h: s,
    r: s / 2,
    bg: WH,
    ab: ab,
    tap: () => repo.toggleFav(p.id),
  );
}

N nowcard(BuildContext c, Place p, {double w = 172}) => F(
  [
    img(
      p.img,
      w,
      118,
      0,
      [
        availBadge(p.kind),
        heartBtn(p, ab: [w - 40, 10]),
      ],
      'h',
      [10, 10],
      's',
      's',
    ),
    F(
      [
        T(p.name, 15, 800),
        meta('map-pin', '${p.type} · ${p.area}'),
        R(
          [rating(p.rating), T('${p.priceS} د.ع / ${p.unit}', 13, 800, P)],
          jc: 'sb',
          w: 'fill',
        ),
      ],
      g: 6,
      p: [12, 12, 14, 12],
      w: 'fill',
    ),
  ],
  w: w,
  r: 20,
  bg: WH,
  sk: LN,
  clip: true,
  tap: () => push(c, Details(p.id)),
);

N rowcard(BuildContext c, Place p, {String? reason}) {
  final fav = repo.favs.contains(p.id);
  return card(
    [
      R(
        [
          img(p.img, 104, 104, 16),
          F(
            [
              R(
                [
                  N(Tx(p.name, 15, 800, INK, maxLines: 1), fillW: true),
                  F([
                    I('heart', 18, fav ? P : MU, fav ? P : null),
                  ], tap: () => repo.toggleFav(p.id)),
                ],
                jc: 'sb',
                w: 'fill',
              ),
              meta('map-pin', '${p.type} · ${p.area} · ${p.dist}'),
              R([rating(p.rating, p.nRev), availBadge(p.kind)], g: 8),
              R([
                T('${p.priceS} د.ع', 15, 800, P),
                T('/ ${p.unit}', 12, 400, MU),
              ], g: 4),
              if (reason != null) tag(reason, icon: 'sparkle'),
            ],
            g: 6,
            w: 'fill',
          ),
        ],
        g: 12,
        al: 's',
        w: 'fill',
      ),
    ],
    p: 10,
    tap: () => push(c, Details(p.id)),
  );
}

class Home extends Scr {
  const Home({super.key});
  @override
  void init(ScrSt s) {
    if (!repo.homeLoaded) repo.refresh();
  }

  @override
  Widget view(c, s) {
    if (repo.offline) return const Offline();
    if (!repo.homeLoaded) return loadingView(c);
    final pl = repo.places;
    final cat = s.get('cat', 0);
    Widget feat(Place p, String badge) => F(
      [
        img(
          p.img,
          268,
          150,
          0,
          [
            tag(
              badge,
              bg: badge == 'مميز' ? P : INK,
              c: WH,
              icon: badge == 'مميز' ? 'crown' : 'badge-percent',
            ),
            heartBtn(p, s: 32, ab: [224, 12]),
          ],
          'h',
          [12, 12],
          's',
        ),
        F(
          [
            R([T(p.name, 16, 800), rating(p.rating)], jc: 'sb', w: 'fill'),
            meta('map-pin', 'بغداد · ${p.area}'),
            R([
              T('يبدأ من', 12, 400, MU),
              T('${p.priceS} د.ع', 14, 800, P),
            ], g: 4),
          ],
          g: 6,
          p: [12, 14, 14, 14],
          w: 'fill',
        ),
      ],
      w: 268,
      r: 20,
      bg: WH,
      sk: LN,
      clip: true,
      tap: () => push(c, Details(p.id)),
    );
    Widget offer(Offer o, String cond, String how) => card(
      [
        R(
          [
            img(o.img, 96, 124, 16),
            F(
              [
                R(
                  [T(o.place, 15, 800), tag(o.disc, bg: P, c: WH, s: 12)],
                  jc: 'sb',
                  w: 'fill',
                ),
                price(fmt(o.newP), fmt(o.oldP)),
                meta('clock', o.exp),
                meta('info', cond),
                meta('ticket', how, P),
              ],
              g: 6,
              w: 'fill',
            ),
          ],
          g: 12,
          al: 's',
          w: 'fill',
        ),
      ],
      p: 12,
      tap: () => push(c, OfferDetail(o)),
    );
    final hz = (List<Widget> k, double g) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: R(k, g: g, al: 's', p: [0, 20]),
    );
    return screen(
      c,
      [
        R(
          [
            R(
              [
                T(repo.gov, 14, 700),
                I('map-pin', 18, P),
                I('chevron-down', 16, MU),
              ],
              g: 6,
              p: [8, 12],
              r: 22,
              bg: WH,
              sk: LN,
              tap: () => push(c, MapView()),
            ),
            WORD(22),
            iconbtn(
              'bell',
              dot: repo.notifs.any((n) => n.fresh),
              tap: () => push(c, const Notifs()),
            ),
          ],
          jc: 'sb',
          al: 'c',
          w: 'fill',
          p: [6, 20],
        ),
        F(
          [
            F(
              [
                R(
                  [
                    F([
                      Tn(
                        'ضايج وما تعرف شنو تسوي؟',
                        s: 21,
                        w: 800,
                        w2: 200,
                        lh: 30,
                      ),
                      T('خلّي ضوجة تختارلك الأفضل اليوم', 14, 500, MU),
                    ], g: 8),
                    F(const [], d: null, bg: 'img:dice:FIT', w: 104, h: 104),
                  ],
                  jc: 'sb',
                  al: 'c',
                  w: 'fill',
                ),
                btn(
                  'اختارلي',
                  icon: 'sparkle',
                  h: 56,
                  tap: () => push(c, const PickQ()),
                ),
              ],
              g: 18,
              p: 20,
              r: 26,
              bg: WH,
              sk: LN,
              w: 'fill',
            ),
          ],
          w: 'fill',
          p: [0, 20],
        ),
        hz([
          for (var i = 0; i < CATS.length; i++)
            cattile(CATS[i].$1, CATS[i].$2, i == cat, () {
              s.set('cat', i);
              if (i > 0)
                push(c, Category(CATS[i].$2));
              else
                push(c, const Search());
            }),
        ], 6),
        sechead(
          'متوفر هسه',
          'zap',
          'عرض الكل',
          () => push(c, const Search(avail: true)),
        ),
        hz([
          for (final p in pl.where((p) => p.kind != 'full').take(8))
            nowcard(c, p),
        ], 12),
        sechead(
          'أماكن مميزة',
          'crown',
          'عرض الكل',
          () => push(c, const Search()),
        ),
        hz([for (final p in pl.where((p) => p.featured)) feat(p, 'مميز')], 12),
        sechead(
          'عروض وخصومات',
          'badge-percent',
          'عرض الكل',
          () => push(c, const Offers()),
        ),
        F(
          [
            for (final o in repo.offers.take(2))
              offer(o, o.exp, 'احجز من التطبيق'),
          ],
          g: 10,
          w: 'fill',
          p: [0, 20],
        ),
        sechead('ريلز ضوجة', 'video', 'قريباً', () => push(c, const Reels())),
        F(
          [
            card([
              F(
                [
                  F(
                    [I('video', 28, P)],
                    al: 'c',
                    jc: 'c',
                    w: 64,
                    h: 64,
                    r: 20,
                    bg: PL,
                  ),
                  Tn('الريلز قريباً', s: 16, w: 800, al: 'CENTER'),
                  Tn(
                    'رح تشوف فيديوهات الأماكن وتحجز منها مباشرة. الميزة تجهز للزبائن، وما نعرض محتوى تجريبي.',
                    s: 13,
                    c: MU,
                    al: 'CENTER',
                    w2: 280,
                    lh: 20,
                  ),
                ],
                g: 10,
                al: 'c',
                w: 'fill',
              ),
            ], p: 16, tap: () => push(c, const Reels())),
          ],
          w: 'fill',
          p: [0, 20],
        ),
        sechead(
          'ضوجة تقترحلك',
          'sparkle',
          'ليش هاي؟',
          () => toast(c, 'نقترح حسب اهتماماتك وحجوزاتك السابقة وموقعك'),
        ),
        F(
          [
            card([
              R(
                [
                  img('friends', 140, 170, 16),
                  F(
                    [
                      Tn(
                        'اختار من الأماكن المتوفرة',
                        s: 16,
                        w: 800,
                        w2: 'fill',
                        lh: 22,
                      ),
                      R(
                        [
                          tag('ضمن ميزانيتك', icon: 'wallet'),
                          tag('قريب منك', icon: 'navigation'),
                        ],
                        g: 6,
                        wrap: true,
                        w: 'fill',
                      ),
                      tag('يناسب 4 أشخاص', icon: 'users'),
                      R([
                        T('بادل', 12, 500, MU),
                        T('·', 12, 400, MU),
                        T('بليارد', 12, 500, MU),
                        T('·', 12, 400, MU),
                        T('ألعاب', 12, 500, MU),
                      ], g: 4),
                      R(
                        [
                          T('شوف الاقتراحات', 14, 700, WH),
                          I('chevron-left', 18, WH),
                        ],
                        g: 6,
                        jc: 'c',
                        bg: P,
                        r: 20,
                        h: 40,
                        w: 'fill',
                        tap: () => push(c, const PickRes()),
                      ),
                    ],
                    g: 8,
                    w: 'fill',
                  ),
                ],
                g: 12,
                al: 's',
                w: 'fill',
              ),
            ], p: 12),
          ],
          w: 'fill',
          p: [0, 20],
        ),
      ],
      g: 18,
      nav: 'الرئيسية',
    );
  }
}

Widget loadingView(BuildContext c) => screen(
  c,
  [
    R(
      [sk(110, 38, 20), sk(90, 40), sk(40, 40, 20)],
      jc: 'sb',
      w: 'fill',
      p: [6, 20],
    ),
    F([sk(350, 190, 26)], w: 'fill', p: [8, 20]),
    R(
      [
        for (var i = 0; i < 5; i++)
          F([sk(62, 62, 20), sk(50, 10, 5)], g: 8, al: 'c'),
      ],
      g: 10,
      p: [8, 20],
    ),
    F([sk(120, 16)], w: 'fill', p: [8, 20]),
    R(
      [
        for (var i = 0; i < 2; i++)
          F(
            [
              sk(172, 118, 0),
              F([sk(120, 12), sk(90, 10), sk(140, 12)], g: 8, p: 12),
            ],
            r: 20,
            bg: WH,
            sk: LN,
            clip: true,
          ),
      ],
      g: 12,
      p: [0, 20],
    ),
  ],
  nav: 'الرئيسية',
  scroll: false,
);

Widget searchbar(
  BuildContext c, {
  TextEditingController? ctl,
  String txt = 'ملعب بادل',
  VoidCallback? onFilter,
  ValueChanged<String>? onChanged,
  VoidCallback? onTapBar,
}) => R(
  [
    R(
      [
        I('search', 20, MU),
        ctl != null
            ? N(
                field(ctl, 'دوّر على مكان أو نشاط', 15, onChanged: onChanged),
                fillW: true,
              )
            : Tn(txt, s: 15, w2: 'fill'),
        if (ctl != null && ctl.text.isNotEmpty)
          F(
            [I('x', 18, MU)],
            tap: () {
              ctl.clear();
              onChanged?.call('');
            },
          ),
      ],
      g: 10,
      bg: G,
      r: 16,
      h: 50,
      w: 'fill',
      p: [0, 14],
      tap: onTapBar,
    ),
    F(
      [I('sliders-horizontal', 20, WH)],
      al: 'c',
      jc: 'c',
      w: 50,
      h: 50,
      r: 16,
      bg: P,
      tap: onFilter,
    ),
  ],
  g: 10,
  w: 'fill',
  p: [4, 20],
);

class Filt {
  String type = 'الكل';
  int maxBudget = 40000, minBudget = 5000;
  String dist = 'كل بغداد';
  String avail = '';
  double minRate = 0;
  Filt copy() => Filt()
    ..type = type
    ..maxBudget = maxBudget
    ..minBudget = minBudget
    ..dist = dist
    ..avail = avail
    ..minRate = minRate;
}

double km(Place p) =>
    double.tryParse(p.dist.split(' ').first) ?? double.infinity;
List<Place> applyF(Filt f, String q, String chip) => repo.places.where((p) {
  if (q.isNotEmpty &&
      !q
          .split(' ')
          .where((w) => w.isNotEmpty)
          .any(
            (q) =>
                p.name.contains(q) ||
                p.type.contains(q) ||
                p.area.contains(q) ||
                p.cat.contains(q),
          ))
    return false;
  if (f.type != 'الكل' && !(p.type.contains(f.type) || p.cat.contains(f.type)))
    return false;
  if (p.price > f.maxBudget && f.maxBudget < 40000) return false;
  if (p.price < f.minBudget && f.minBudget > 5000) return false;
  final d = {'أقل من 2 كم': 2.0, '5 كم': 5.0, '10 كم': 10.0}[f.dist];
  if (d != null && km(p) > d) return false;
  if (f.avail == 'مفتوح الآن' && p.kind == 'full') return false;
  if (f.avail == 'تتوفر مواعيد الآن' && p.kind != 'slots') return false;
  if (double.parse(p.rating) < f.minRate) return false;
  if (chip == 'قريب مني' && km(p) > 3) return false;
  if (chip == 'متوفر هسه' && p.kind != 'slots') return false;
  if (chip == 'عروض' && !repo.offers.any((o) => o.placeId == p.id))
    return false;
  return true;
}).toList();

Future<void> filtersSheet(BuildContext c, Filt f, VoidCallback onApply) {
  final t = f.copy();
  Widget sect(String title, List<Widget> k) =>
      F([T(title, 15, 800), ...k], g: 12, w: 'fill');
  return openSheet(
    c,
    title: 'الفلاتر',
    top: 230,
    body: (sc, set) {
      final n = applyF(t, '', '').length;
      Widget ch(String l, bool on, VoidCallback tp, [String? icon]) =>
          chip(l, on, icon, 13, () => set(tp));
      final lo = 5000, hi = 40000;
      return [
        Expanded(
          child: SingleChildScrollView(
            child: F(
              [
                sect('النوع', [
                  R(
                    [
                      for (final l in [
                        'بادل',
                        'ملاعب',
                        'بليارد',
                        'كافيهات',
                        'ألعاب',
                      ])
                        ch(
                          l,
                          t.type == l,
                          () => t.type = t.type == l ? 'الكل' : l,
                        ),
                    ],
                    g: 8,
                    wrap: true,
                    w: 'fill',
                  ),
                ]),
                sect('الميزانية للشخص', [
                  R(
                    [T('5,000 د.ع', 13, 700), T('40,000 د.ع', 13, 700)],
                    jc: 'sb',
                    w: 'fill',
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: col(P),
                      inactiveTrackColor: col(G),
                      thumbColor: col(WH),
                      overlayShape: SliderComponentShape.noOverlay,
                      rangeThumbShape: const _RThumb(),
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        (t.minBudget - lo) / (hi - lo),
                        (t.maxBudget - lo) / (hi - lo),
                      ),
                      onChanged: (v) => set(() {
                        t.minBudget =
                            ((lo + v.start * (hi - lo)) / 250).round() * 250;
                        t.maxBudget =
                            ((lo + v.end * (hi - lo)) / 250).round() * 250;
                      }),
                    ),
                  ),
                ]),
                sect('المسافة', [
                  R(
                    [
                      for (final l in [
                        'أقل من 2 كم',
                        '5 كم',
                        '10 كم',
                        'كل بغداد',
                      ])
                        ch(l, t.dist == l, () => t.dist = l),
                    ],
                    g: 8,
                    wrap: true,
                    w: 'fill',
                  ),
                ]),
                sect('التوفر', [
                  R([
                    for (final l in ['مفتوح الآن', 'تتوفر مواعيد الآن'])
                      ch(
                        l,
                        t.avail == l,
                        () => t.avail = t.avail == l ? '' : l,
                      ),
                  ], g: 8),
                ]),
                sect('التقييم', [
                  R([
                    ch(
                      '4.5 وأكثر',
                      t.minRate == 4.5,
                      () => t.minRate = t.minRate == 4.5 ? 0 : 4.5,
                      'star',
                    ),
                    ch(
                      '4 وأكثر',
                      t.minRate == 4,
                      () => t.minRate = t.minRate == 4 ? 0 : 4,
                    ),
                  ], g: 8),
                ]),
              ],
              g: 16,
              w: 'fill',
            ),
          ),
        ),
        R(
          [
            btn(
              'مسح',
              kind: 'g',
              w: 110,
              tap: () => set(() {
                final z = Filt();
                t
                  ..type = z.type
                  ..maxBudget = z.maxBudget
                  ..minBudget = z.minBudget
                  ..dist = z.dist
                  ..avail = z.avail
                  ..minRate = z.minRate;
              }),
            ),
            btn(
              'اعرض $n نتيجة',
              tap: () {
                f
                  ..type = t.type
                  ..maxBudget = t.maxBudget
                  ..minBudget = t.minBudget
                  ..dist = t.dist
                  ..avail = t.avail
                  ..minRate = t.minRate;
                onApply();
                Navigator.pop(sc);
              },
            ),
          ],
          g: 12,
          w: 'fill',
        ),
      ];
    },
  );
}

class Search extends Scr {
  final bool avail;
  final String q;
  const Search({super.key, this.avail = false, this.q = ''});
  @override
  Widget view(c, s) {
    final ctl = s.ctl('q', q);
    final f = s.get('f', Filt());
    final chipSel = s.get('chip', avail ? 'متوفر هسه' : 'الكل');
    final busy = s.get('busy', false);
    final res = applyF(f, ctl.text.trim(), chipSel);
    void reload() async {
      s.set('busy', true);
      await repo.refresh();
      s.set('busy', false);
    }

    return screen(c, [
      topbar('البحث'),
      searchbar(
        c,
        ctl: ctl,
        onChanged: (_) => reload(),
        onFilter: () => filtersSheet(c, f, reload),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R(
          [
            for (final (l, i) in [
              ('الكل', null),
              ('قريب مني', 'navigation'),
              ('متوفر هسه', 'zap'),
              ('عروض', 'badge-percent'),
            ])
              chip(l, chipSel == l, i, 13, () {
                s.set('chip', l);
                reload();
              }),
          ],
          g: 8,
          p: [4, 20],
        ),
      ),
      R(
        [
          T('${res.length} نتيجة بـ ${repo.gov}', 14, 700),
          R([
            R(
              [T('قائمة', 13, 700, P), I('list', 16, P)],
              g: 4,
              bg: PL,
              r: 10,
              p: [6, 10],
            ),
            R(
              [T('خريطة', 13, 500, MU), I('map', 16, MU)],
              g: 4,
              r: 10,
              p: [6, 10],
              tap: () => push(c, MapView()),
            ),
          ]),
        ],
        jc: 'sb',
        w: 'fill',
        p: [8, 20],
      ),
      if (busy)
        F(
          [
            for (var i = 0; i < 3; i++) F([sk(350, 124, 20)]),
          ],
          g: 10,
          w: 'fill',
          p: [4, 20],
        )
      else if (res.isEmpty)
        F(
          [
            BOX(h: 40, w: 1),
            F(
              [I('search-x', 44, P)],
              al: 'c',
              jc: 'c',
              w: 110,
              h: 110,
              r: 32,
              bg: PL,
            ),
            Tn('ما لگينا نتائج', s: 19, w: 800, al: 'CENTER'),
            Tn('جرّب كلمة ثانية أو امسح الفلاتر', s: 14, c: MU, al: 'CENTER'),
          ],
          g: 14,
          al: 'c',
          w: 'fill',
        )
      else
        F([for (final p in res) rowcard(c, p)], g: 10, w: 'fill', p: [4, 20]),
    ], nav: 'الرئيسية');
  }
}

const MAPSVG = '''<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844"><rect width="390" height="844" fill="#EEF0F5"/>
<path d="M250 -10 C210 120 300 220 240 330 C180 440 260 540 200 650 C160 730 190 800 170 860" stroke="#CFE3F7" stroke-width="34" fill="none"/>
<g stroke="#FFFFFF" stroke-width="12" fill="none"><path d="M-10 180 L400 240"/><path d="M-10 470 L400 420"/><path d="M90 -10 L130 860"/><path d="M-10 690 L400 720"/><path d="M330 -10 L300 860"/></g>
<g stroke="#FFFFFF" stroke-width="5" fill="none"><path d="M-10 90 L400 120"/><path d="M-10 330 L400 350"/><path d="M200 -10 L180 860"/><path d="M-10 590 L400 560"/><path d="M40 -10 L60 860"/></g>
<rect x="140" y="250" width="40" height="60" rx="6" fill="#DCEFD8"/><rect x="20" y="500" width="60" height="40" rx="6" fill="#DCEFD8"/><rect x="310" y="610" width="50" height="50" rx="6" fill="#DCEFD8"/></svg>''';

class MapView extends Scr {
  const MapView({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('الأماكن'),
    Tn('الخريطة الحية غير مربوطة. العناوين أدناه من الخادم.', s: 14, c: MU),
    for (final p in repo.places) rowcard(c, p),
  ]);
}

class SvgFill extends StatelessWidget {
  final String svg;
  const SvgFill(this.svg, {super.key});
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, bc) => S(svg, bc.maxWidth, bc.maxHeight));
}

class Category extends Scr {
  final String cat;
  const Category(this.cat, {super.key});
  @override
  Widget view(c, s) {
    final ch = s.get('ch', 'الكل');
    var list = repo.places
        .where((p) => p.cat == cat || p.type == cat || cat.contains(p.type))
        .toList();
    if (ch == 'متوفر هسه') list = list.where((p) => p.kind == 'slots').toList();
    if (ch == 'الأعلى تقييم') list.sort((a, b) => b.rating.compareTo(a.rating));
    if (ch == 'الأرخص') list.sort((a, b) => a.price.compareTo(b.price));
    final big = list.isNotEmpty ? list.first : null;
    return screen(c, [
      topbar(
        cat,
        sub: '${list.length} مكان بـ ${repo.gov}',
        right: iconbtn('map', tap: () => push(c, MapView())),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R(
          [
            for (final (l, i) in [
              ('الكل', null),
              ('متوفر هسه', 'zap'),
              ('الأعلى تقييم', 'star'),
              ('الأرخص', null),
            ])
              chip(l, ch == l, i, 13, () => s.set('ch', l)),
          ],
          g: 8,
          p: [4, 20],
        ),
      ),
      if (big != null)
        F(
          [
            img(
              big.img,
              350,
              170,
              22,
              [tag('مميز', bg: P, c: WH, icon: 'crown')],
              'h',
              12,
              's',
            ),
            R(
              [
                F([
                  T(big.name, 17, 800),
                  meta('map-pin', '${big.area} · ${big.dist}'),
                ], g: 4),
                F(
                  [price(big.priceS), T('لل${big.unit}', 11, 400, MU)],
                  g: 2,
                  al: 'e',
                ),
              ],
              jc: 'sb',
              w: 'fill',
            ),
          ],
          g: 12,
          w: 'fill',
          p: [8, 20],
          tap: () => push(c, Details(big.id)),
        ),
      if (list.length > 1)
        F(
          [for (final p in list.skip(1)) rowcard(c, p)],
          g: 10,
          w: 'fill',
          p: [0, 20],
        ),
      if (list.isEmpty)
        F(
          [
            BOX(h: 60, w: 1),
            F(
              [I('search-x', 44, P)],
              al: 'c',
              jc: 'c',
              w: 110,
              h: 110,
              r: 32,
              bg: PL,
            ),
            Tn('قريباً بهالقسم', s: 19, w: 800, al: 'CENTER'),
            Tn('دا نضيف أماكن جديدة كل أسبوع', s: 14, c: MU, al: 'CENTER'),
          ],
          g: 14,
          al: 'c',
          w: 'fill',
        ),
    ], nav: 'الرئيسية');
  }
}

class _RThumb extends RangeSliderThumbShape {
  const _RThumb();
  @override
  Size getPreferredSize(bool e, bool d) => const Size(22, 22);
  @override
  void paint(
    PaintingContext ctx,
    Offset o, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    ctx.canvas.drawCircle(o, 11, Paint()..color = col(WH));
    ctx.canvas.drawCircle(
      o,
      9.5,
      Paint()
        ..color = col(P)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
