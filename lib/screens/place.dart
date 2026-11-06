import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'flow.dart';

// Duration estimates use the same unit pricing as the API; no invented discounts.
List<(String, String, int)> packagesOf(Place p) => [
  for (var hours = 1; hours <= 3; hours++)
    (
      hours == 1
          ? 'ساعة'
          : hours == 2
          ? 'ساعتين'
          : '3 ساعات',
      p.unit == 'ساعة' ? 'حسب سعر الساعة' : 'السعر للفرد',
      p.price * (p.unit == 'ساعة' ? hours : 1),
    ),
];
N reviewTile(Review r, {bool full = false}) => F(
  [
    R(
      [
        R([
          avatar(r.name),
          F([T(r.name, 14, 700), T(r.ago, 11, 400, MU)], g: 2),
        ], g: 10),
        stars(r.stars),
      ],
      jc: 'sb',
      w: 'fill',
    ),
    Tn(r.text, s: 13, w2: 'fill', lh: 21),
    if (r.reply != null)
      F(
        [T('رد صاحب المكان', 12, 700, P), Tn(r.reply!, s: 13)],
        g: 4,
        p: 12,
        r: 12,
        bg: BG,
        w: 'fill',
      ),
    if (full && r.photos) T('صور التقييم غير متاحة من الخادم', 12, 400, MU),
  ],
  g: 10,
  w: 'fill',
);
Future<void> reportSheet(BuildContext c) => openSheet(
  c,
  title: 'بلاغ',
  body: (sc, set) => [
    Tn(
      'إرسال البلاغات غير مربوط في API الحالي. لم يتم إرسال أي بلاغ.',
      s: 14,
      c: MU,
    ),
    btn('إغلاق', tap: () => Navigator.pop(sc)),
  ],
);

class Details extends Scr {
  final String id;
  const Details(this.id, {super.key});
  @override
  void init(ScrSt s) {
    repo.loadPlace(id);
  }

  @override
  Widget view(c, s) {
    if (!repo.hasPlace(id)) return unavailable(c, 'المكان غير متاح');
    final p = repo.place(id), pks = packagesOf(repo.place(id));
    final pk = s.get('pk', 0),
        revs = repo.reviewsOf(id),
        services = repo.publicServices[id] ?? [];
    return screen(
      c,
      [
        img(p.img, 390, 260, 0, [
          F(
            [iconbtn('arrow-right', tap: () => Navigator.pop(c))],
            w: 'fill',
            p: 20,
          ),
        ]),
        F(
          [
            R(
              [
                F([
                  T(p.name, 22, 800),
                  meta('map-pin', '${p.type} · ${p.area}'),
                ], g: 4),
                rating(p.rating),
              ],
              jc: 'sb',
              w: 'fill',
            ),
            R(
              [
                btn(
                  repo.favs.contains(id) ? 'محفوظ' : 'حفظ',
                  kind: 'g',
                  tap: () => repo.toggleFav(id),
                ),
                btn(
                  repo.follows.contains(id) ? 'متابَع' : 'متابعة',
                  kind: 's',
                  tap: () => repo.toggleFollow(id),
                ),
              ],
              g: 10,
              w: 'fill',
            ),
            T('${kfmt(p.followers)} متابع · ${p.nRev} تقييم', 13, 500, MU),
            T('الأسعار', 17, 800),
            R(
              [
                for (var i = 0; i < pks.length; i++)
                  F(
                    [
                      Tn(pks[i].$1, s: 14, w: 700, al: 'CENTER'),
                      Tn(
                        '${fmt(pks[i].$3)} د.ع',
                        s: 16,
                        w: 800,
                        c: P,
                        al: 'CENTER',
                      ),
                    ],
                    g: 6,
                    al: 'c',
                    w: 104,
                    p: 12,
                    r: 16,
                    bg: i == pk ? PL : G,
                    tap: () => s.set('pk', i),
                  ),
              ],
              g: 10,
              w: 'fill',
            ),
            T('الخدمات', 17, 800),
            if (services.isEmpty) T('ماكو خدمات إضافية مسجلة', 13, 400, MU),
            for (final service in services)
              card(
                [
                  T(service.$1, 14, 700),
                  T('${fmt(service.$2)} د.ع / ${service.$3}', 13, 500, P),
                ],
                p: 12,
                g: 6,
              ),
            Tn(
              'الخدمات الإضافية للعرض فقط؛ الحجز الحالي يحسب سعر المكان ولا يضيف خدمات غير مدعومة.',
              s: 12,
              c: MU,
            ),
            T('التواصل والموقع', 17, 800),
            T(p.phone, 14, 600),
            T(p.area, 14, 500, MU),
            Tn(
              'ساعات الدوام والمرافق والإحداثيات غير متوفرة في API الحالي.',
              s: 13,
              c: MU,
            ),
            R(
              [
                T('التقييمات', 17, 800),
                F([T('عرض الكل', 13, 700, P)], tap: () => push(c, Reviews(id))),
              ],
              jc: 'sb',
              w: 'fill',
            ),
            if (revs.isEmpty) T('ماكو تقييمات لعرضها', 14, 400, MU),
            for (final r in revs.take(2)) card([reviewTile(r)], p: 14),
          ],
          g: 16,
          w: 'fill',
          p: 20,
        ),
      ],
      bottomBar: bottom([
        R(
          [
            T('${p.priceS} د.ع / ${p.unit}', 16, 800, P),
            btn('احجز هسه', w: 180, tap: () => push(c, BookSlot(id, dur: pk))),
          ],
          jc: 'sb',
          w: 'fill',
        ),
      ]),
    );
  }
}

class Reviews extends Scr {
  final String id;
  const Reviews(this.id, {super.key});
  @override
  void init(ScrSt s) {
    repo.loadPlace(id);
  }

  @override
  Widget view(c, s) {
    if (!repo.hasPlace(id)) return unavailable(c, 'المكان غير متاح');
    final p = repo.place(id),
        all = repo.reviewsOf(id),
        ch = s.get('ch', 'الكل');
    final list = all
        .where(
          (r) => ch == '5 نجوم'
              ? r.stars == 5
              : ch == 'مع صور'
              ? r.photos
              : true,
        )
        .toList();
    return screen(c, [
      topbar('التقييمات', sub: p.name),
      F(
        [
          R([rating(p.rating), T('${p.nRev} تقييم', 14, 500, MU)], g: 10),
          R([
            for (final label in ['الكل', '5 نجوم', 'مع صور'])
              chip(label, ch == label, null, 13, () => s.set('ch', label)),
          ], g: 8),
          if (list.isEmpty) T('ماكو تقييمات هنا', 14, 500, MU),
          for (final r in list) card([reviewTile(r, full: true)], p: 14),
        ],
        g: 14,
        w: 'fill',
        p: 20,
      ),
    ]);
  }
}
