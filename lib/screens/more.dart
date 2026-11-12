import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'auth.dart';
import 'flow.dart';
import 'home.dart';
import 'place.dart';
import 'owner.dart';

(String, String) stColor(String st) => switch (st) {
  'مؤكد' => ('#E8F7EE', OK),
  'بالانتظار' => (PL, P),
  'بانتظار القبول' => (WRB, WR),
  'ملغي' => ('#FDECEC', RD),
  _ => (G, MU),
};

class Bookings extends Scr {
  const Bookings({super.key});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final up = repo.bookings
        .where(
          (b) => ['مؤكد', 'بالانتظار', 'بانتظار القبول'].contains(b.status),
        )
        .toList();
    final past = repo.bookings.where((b) => !up.contains(b)).toList();
    Widget bk(Booking b) {
      final p = repo.place(b.placeId);
      final stc = stColor(b.status);
      final acts = <Widget>[
        if (b.status == 'مؤكد') ...[
          btn(
            'رمز الدخول',
            icon: 'qr-code',
            h: 40,
            tap: () => push(c, BookingDetail(b)),
          ),
          btn('إلغاء', kind: 'g', h: 40, w: 90, tap: () => cancelDialog(c, b)),
        ],
        if (b.status == 'بالانتظار' || b.status == 'بانتظار القبول')
          btn('تفاصيل', kind: 'g', h: 40, tap: () => push(c, BookingDetail(b))),
        if (b.status == 'مكتمل' && !b.rated)
          btn(
            'قيّم تجربتك',
            icon: 'star',
            kind: 's',
            h: 40,
            tap: () => push(c, Rate(b)),
          ),
        if (b.status == 'مكتمل')
          btn(
            'احجز مرة ثانية',
            kind: 'g',
            h: 40,
            tap: () => push(c, BookSlot(b.placeId)),
          ),
      ];
      return card(
        [
          R(
            [
              img(p.img, 72, 72, 14),
              F(
                [
                  R(
                    [T(p.name, 15, 800), tag(b.status, bg: stc.$1, c: stc.$2)],
                    jc: 'sb',
                    w: 'fill',
                  ),
                  meta('calendar', '${b.day} · ${b.time}'),
                  meta('users', '${b.people} أشخاص · ${fmt(b.total)} د.ع'),
                ],
                g: 5,
                w: 'fill',
              ),
            ],
            g: 12,
            al: 's',
            w: 'fill',
            tap: () => push(c, BookingDetail(b)),
          ),
          if (acts.isNotEmpty) R(acts, g: 8, w: 'fill'),
        ],
        p: 12,
        g: 12,
      );
    }

    final list = t == 0 ? up : past;
    return screen(c, [
      topbar('حجوزاتي', back: false),
      F(
        [
          tabs(['القادمة', 'السابقة'], t, (i) => s.set('t', i)),
        ],
        w: 'fill',
        p: [4, 20],
      ),
      if (list.isEmpty)
        F(
          [
            BOX(h: 80, w: 1),
            F(
              [I('calendar-check', 44, P)],
              al: 'c',
              jc: 'c',
              w: 110,
              h: 110,
              r: 32,
              bg: PL,
            ),
            Tn('ماكو حجوزات هنا', s: 20, w: 800, al: 'CENTER'),
            btn(
              'اكتشف أماكن',
              icon: 'compass',
              w: 220,
              tap: () => onCustomerTab(c, 'الرئيسية'),
            ),
          ],
          g: 16,
          al: 'c',
          w: 'fill',
        )
      else
        F([for (final b in list) bk(b)], g: 12, w: 'fill', p: [8, 20]),
    ], nav: 'حجوزاتي');
  }
}

Future<void> cancelDialog(BuildContext c, Booking b) => openSheet(
  c,
  title: 'تلغي الحجز؟',
  top: 560,
  body: (sc, set) => [
    Tn(
      '${repo.place(b.placeId).name} · ${b.day} ${b.time}',
      s: 14,
      c: MU,
      w2: 'fill',
      lh: 22,
    ),
    R(
      [
        btn('لا، خليه', kind: 'g', tap: () => Navigator.pop(sc)),
        btn(
          'إلغاء الحجز',
          kind: 'd',
          tap: () async {
            if (await apiAction(c, repo.cancel(b), 'انلغى الحجز ${b.code}') &&
                sc.mounted)
              Navigator.pop(sc);
          },
        ),
      ],
      g: 10,
      w: 'fill',
    ),
  ],
);

class BookingDetail extends Scr {
  final Booking b;
  const BookingDetail(this.b, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(b.placeId);
    return screen(c, [
      topbar('حجزك', sub: b.code),
      F(
        [
          card([
            F(
              [
                I('ticket', 72, P),
                Tn(
                  b.status == 'مؤكد'
                      ? 'اعرض الرمز عند الوصول'
                      : 'حالة الحجز: ${b.status}',
                  s: 14,
                  w: 700,
                  al: 'CENTER',
                ),
                Tn(b.code, s: 14, w: 700, c: P, al: 'CENTER'),
              ],
              g: 8,
              al: 'c',
              w: 'fill',
            ),
          ], p: 20),
          card([
            R(
              [T(p.name, 14, 700), T('المكان', 13, 400, MU)],
              jc: 'sb',
              w: 'fill',
            ),
            R(
              [
                T('${b.day.split(' ').take(2).join(' ')} · ${b.time}', 14, 700),
                T('الموعد', 13, 400, MU),
              ],
              jc: 'sb',
              w: 'fill',
            ),
            R(
              [T('${b.people} أشخاص', 14, 700), T('الأشخاص', 13, 400, MU)],
              jc: 'sb',
              w: 'fill',
            ),
            R(
              [
                T('${fmt(b.total)} د.ع · ${b.pay}', 14, 700),
                T('الدفع', 13, 400, MU),
              ],
              jc: 'sb',
              w: 'fill',
            ),
          ], g: 12),
          R(
            [
              btn(
                'الاتجاهات',
                icon: 'navigation',
                kind: 's',
                h: 46,
                tap: () => toast(c, 'يفتح الخريطة على ${p.area}'),
              ),
              btn(
                'اتصال',
                icon: 'phone',
                kind: 'g',
                h: 46,
                tap: () => toast(c, 'يتصل بـ ${p.phone}'),
              ),
            ],
            g: 10,
            w: 'fill',
          ),
          if (b.status != 'ملغي' && b.status != 'مكتمل')
            F(
              [
                Tn(
                  'الإلغاء مجاني لحد 4 ساعات قبل الموعد',
                  s: 12,
                  c: MU,
                  al: 'CENTER',
                ),
                F([
                  Tn('إلغاء الحجز', s: 14, w: 800, c: RD, al: 'CENTER'),
                ], tap: () => cancelDialog(c, b)),
              ],
              g: 6,
              al: 'c',
              w: 'fill',
            ),
        ],
        g: 14,
        w: 'fill',
        p: [4, 20],
      ),
    ]);
  }
}

class Rate extends Scr {
  final Booking b;
  const Rate(this.b, {super.key});
  @override
  Widget view(c, s) {
    final p = repo.place(b.placeId);
    final st = s.get('st', 4);
    final tags = s.get('tags', <String>{'نظيف', 'سعر مناسب', 'إضاءة قوية'});
    final ctl = s.ctl('t');
    final busy = s.get('busy', false);
    const words = ['سيئة', 'مقبولة', 'زينة', 'حلوة', 'رهيبة'];
    return screen(
      c,
      [
        topbar('قيّم تجربتك'),
        F(
          [
            R(
              [
                img(p.img, 56, 56, 14),
                F([T(p.name, 15, 800), T('زرته ${b.day}', 12, 400, MU)], g: 2),
              ],
              g: 12,
              al: 'c',
            ),
            F(
              [
                Tn('شلون كانت تجربتك؟', s: 17, w: 800, al: 'CENTER'),
                R(
                  [
                    for (var i = 0; i < 5; i++)
                      F([
                        I(
                          'star',
                          38,
                          i < st ? STAR : '#D9D6E3',
                          i < st ? STAR : '#D9D6E3',
                        ),
                      ], tap: () => s.set('st', i + 1)),
                  ],
                  g: 10,
                  ltr: true,
                ),
                Tn(words[st - 1], s: 14, w: 700, c: P, al: 'CENTER'),
              ],
              g: 10,
              al: 'c',
              w: 'fill',
              p: [10, 0],
            ),
            R(
              [
                for (final l in [
                  'نظيف',
                  'سعر مناسب',
                  'خدمة ممتازة',
                  'إضاءة قوية',
                ])
                  chip(l, tags.contains(l), null, 13, () {
                    tags.contains(l) ? tags.remove(l) : tags.add(l);
                    s.set('x', l);
                  }),
              ],
              g: 8,
              wrap: true,
              w: 'fill',
            ),
            F(
              [
                N(
                  TextField(
                    controller: ctl,
                    maxLines: 4,
                    style: ts(14, 400, INK, lh: 22),
                    cursorColor: col(P),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  ),
                  fillW: true,
                ),
              ],
              w: 'fill',
              h: 110,
              p: 14,
              r: 16,
              bg: G,
            ),
            Tn('رفع صور التقييم غير مربوط حالياً', s: 12, c: MU),
          ],
          g: 16,
          w: 'fill',
          p: [4, 20],
        ),
      ],
      bottomBar: bottom([
        btn(
          'أرسل التقييم · +20 نقطة',
          busy: busy,
          tap: () async {
            s.set('busy', true);
            final ok = await apiAction(
              c,
              repo.addReview(b.placeId, st, ctl.text, b.id),
            );
            s.set('busy', false);
            if (!ok) return;
            if (!c.mounted) return;
            Navigator.pop(c);
            toast(c, 'شكراً! انضافت 20 نقطة لحسابك');
          },
        ),
      ]),
    );
  }
}

class Offers extends Scr {
  const Offers({super.key});
  @override
  Widget view(c, s) {
    final ch = s.get('ch', 'الكل');
    final list = repo.offers
        .where(
          (o) =>
              ch == 'الكل' ||
              (ch == 'ينتهي قريب' && o.exp.contains('بعد')) ||
              o.cat == ch,
        )
        .toList();
    Widget oc(Offer o) => card(
      [
        img(
          o.img,
          318,
          120,
          14,
          [tag(o.disc, bg: P, c: WH, s: 13)],
          'h',
          10,
          's',
        ),
        R(
          [
            F([T(o.place, 15, 800), meta('clock', o.exp)], g: 4),
            F(
              [
                T('${fmt(o.newP)} د.ع', 16, 800, P),
                Tn(fmt(o.oldP), s: 12, c: MU, st: true),
              ],
              g: 2,
              al: 'e',
            ),
          ],
          jc: 'sb',
          w: 'fill',
        ),
      ],
      p: 12,
      tap: () => push(c, OfferDetail(o)),
    );
    return screen(c, [
      topbar('عروض وخصومات', back: Navigator.of(c).canPop()),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R(
          [
            for (final (l, i) in [
              ('الكل', null),
              ('ينتهي قريب', 'clock'),
              ('ملاعب', null),
              ('مطاعم', null),
              ('ألعاب', null),
            ])
              chip(l, ch == l, i, 13, () => s.set('ch', l)),
          ],
          g: 8,
          p: [4, 20],
        ),
      ),
      F([for (final o in list) oc(o)], g: 12, w: 'fill', p: [8, 20]),
    ], nav: 'الرئيسية');
  }
}

class OfferDetail extends Scr {
  final Offer o;
  const OfferDetail(this.o, {super.key});
  @override
  void init(ScrSt s) {
    repo.viewOffer(o);
  }

  @override
  Widget view(c, s) => screen(
    c,
    [
      img(o.img, 390, 230, 0, [
        status(true),
        F(
          [iconbtn('arrow-right', tap: () => Navigator.pop(c))],
          w: 'fill',
          p: [4, 20],
        ),
      ]),
      F(
        [
          R(
            [
              F([
                T(o.place, 20, 800),
                meta('map-pin', '${o.cat} · ${o.area}'),
              ], g: 4),
              tag(o.disc, bg: P, c: WH, s: 14),
            ],
            jc: 'sb',
            al: 's',
            w: 'fill',
          ),
          R(
            [
              T('${fmt(o.newP)} د.ع', 24, 800, P),
              Tn('${fmt(o.oldP)} د.ع', s: 14, c: MU, st: true),
              T('لل${repo.place(o.placeId).unit}', 13, 400, MU),
            ],
            g: 8,
            al: 'c',
          ),
          R(
            [
              R([I('clock', 18, WR), T(o.exp, 14, 700, WR)], g: 8),
            ],
            jc: 's',
            w: 'fill',
            p: 12,
            r: 14,
            bg: WRB,
          ),
          F(
            [
              T('الشروط', 16, 800),
              for (final t in ['التفاصيل حسب العرض المسجل لدى المكان'])
                R([I('check', 16, P), Tn(t, s: 14, w2: 300)], g: 8, al: 's'),
            ],
            g: 10,
            w: 'fill',
          ),
          F(
            [
              T('شلون تستفاد', 16, 800),
              for (final (i, t) in [
                (1, 'اضغط "احجز بالعرض"'),
                (2, 'اختار موعد ضمن أوقات العرض'),
                (3, 'الخصم يتطبق تلقائي بالفاتورة'),
              ])
                R(
                  [
                    F(
                      [Tn('$i', s: 12, w: 800, c: P, al: 'CENTER')],
                      al: 'c',
                      jc: 'c',
                      w: 24,
                      h: 24,
                      r: 12,
                      bg: PL,
                    ),
                    Tn(t, s: 14, w2: 290),
                  ],
                  g: 10,
                  al: 'c',
                ),
            ],
            g: 10,
            w: 'fill',
          ),
        ],
        g: 16,
        w: 'fill',
        p: [16, 20],
      ),
    ],
    bottomBar: bottom([
      R(
        [
          iconbtn('share-2', s: 52, tap: () => toast(c, 'نسخنا رابط العرض')),
          btn(
            'احجز بالعرض',
            icon: 'ticket-percent',
            tap: () async {
              if (await apiAction(c, repo.clickOffer(o)) && c.mounted)
                push(c, BookSlot(o.placeId, dur: 0, offer: o));
            },
          ),
        ],
        g: 10,
        w: 'fill',
      ),
    ]),
  );
}

class Reels extends Scr {
  const Reels({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('ريلز ضوجة'),
    F(
      [
        BOX(h: 48, w: 1),
        F([I('video', 44, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL),
        Tn('الريلز قريباً', s: 22, w: 800, al: 'CENTER'),
        Tn(
          'رح تقدر تشوف فيديوهات الأماكن، تتابعهن، وتحجز مباشرة من الريل. الميزة تجهز حالياً وما تعرض محتوى تجريبي.',
          s: 14,
          c: MU,
          al: 'CENTER',
          w2: 300,
          lh: 22,
        ),
      ],
      g: 16,
      al: 'c',
      w: 'fill',
    ),
  ], nav: 'الرئيسية');
}

class Favs extends Scr {
  final bool empty;
  const Favs({super.key, this.empty = false});
  @override
  Widget view(c, s) {
    final t = s.get('t', 0);
    final places = this.empty
        ? <Place>[]
        : repo.places.where((p) => repo.favs.contains(p.id)).toList();
    final follows = repo.places
        .where((p) => repo.follows.contains(p.id))
        .toList();
    Widget follow(Place p, String? nw) => R(
      [
        R(
          [
            img(p.img, 52, 52, 26),
            F([
              T(p.name, 14, 800),
              T('${p.type} · ${p.area}', 12, 400, MU),
            ], g: 2),
          ],
          g: 10,
          al: 'c',
          tap: () => push(c, Details(p.id)),
        ),
        nw != null
            ? tag(nw, icon: 'bell')
            : F([T('متابَع', 12, 700, MU)], tap: () => repo.toggleFollow(p.id)),
      ],
      jc: 'sb',
      w: 'fill',
      al: 'c',
    );
    Widget empty(String icon, String title, String sub) => F([
      BOX(w: 10, h: 120),
      F(
        [
          F([I(icon, 44, P)], al: 'c', jc: 'c', w: 110, h: 110, r: 32, bg: PL),
          Tn(title, s: 20, w: 800, al: 'CENTER'),
          Tn(sub, s: 14, c: MU, al: 'CENTER', w2: 290, lh: 22),
          btn(
            'اكتشف أماكن',
            icon: 'compass',
            w: 220,
            tap: () => onCustomerTab(c, 'الرئيسية'),
          ),
        ],
        g: 16,
        al: 'c',
        w: 'fill',
      ),
    ], w: 'fill');
    final followsW = [
      T('المشاريع اللي تتابعها', 16, 800),
      card([
        for (var i = 0; i < follows.length; i++) ...[
          if (i > 0) divider(),
          follow(follows[i], null),
        ],
      ], g: 12),
    ];
    return screen(c, [
      topbar('المفضلة', back: false),
      F(
        [
          tabs(
            ['الأماكن', 'المشاريع المتابَعة', 'الريلز'],
            t,
            (i) => s.set('t', i),
          ),
        ],
        w: 'fill',
        p: [4, 20],
      ),
      if (t == 0)
        places.isEmpty
            ? empty(
                'heart',
                'بعدك ما حفظت أي مكان',
                'اضغط على القلب بأي مكان يعجبك حتى تلگاه هنا بسرعة',
              )
            : F(
                [
                  for (final p in places) rowcard(c, p),
                  if (follows.isNotEmpty && !this.empty) ...followsW,
                ],
                g: 12,
                w: 'fill',
                p: [8, 20],
              ),
      if (t == 1)
        follows.isEmpty
            ? empty(
                'store',
                'ما تتابع أي مشروع',
                'تابع الأماكن حتى توصلك عروضهم وريلزهم',
              )
            : F(followsW, g: 12, w: 'fill', p: [8, 20]),
      if (t == 2)
        empty(
          'video',
          'الريلز قريباً',
          'حفظ الريلز ومشاهدتها يجهز للزبائن. ماكو محتوى تجريبي بهالقسم.',
        ),
    ], nav: 'المفضلة');
  }
}

class Rewards extends Scr {
  const Rewards({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('المكافآت'),
    F(
      [
        T('نقاطك', 16, 700),
        T(fmt(repo.points), 36, 800, P),
        Tn(
          'النقاط من حسابك في الخادم. الاستبدال والتحديات والدعوات غير مدعومة حالياً.',
          s: 14,
          c: MU,
        ),
      ],
      g: 16,
      p: 24,
      w: 'fill',
    ),
  ], nav: 'حسابي');
}

class Notifs extends Scr {
  final bool owner;
  const Notifs({super.key, this.owner = false});
  @override
  Widget view(c, s) {
    final list = owner ? repo.ownerNotifs : repo.notifs;
    Widget nt(Notif n) => R(
      [
        F([I(n.icon, 20, P)], al: 'c', jc: 'c', w: 42, h: 42, r: 14, bg: PL),
        F([
          T(n.title, 14, 800),
          Tn(n.body, s: 13, c: MU, w2: 250, lh: 20),
          T(n.ago, 11, 400, MU),
        ], g: 3),
        if (n.fresh && !owner) BOX(w: 8, h: 8, r: 4, bg: P),
      ],
      g: 12,
      al: 's',
      w: 'fill',
      p: [14, 20],
      bg: n.fresh ? BG : WH,
      tap: () {
        repo.readNotif(n);
        if (owner) {
          if (n.icon == 'calendar-check') onOwnerTab(c, 'الحجوزات');
          if (n.icon == 'star') push(c, const OReviews());
          if (n.icon == 'trending-up' || n.icon == 'hourglass')
            push(c, const OOffPerf());
        } else {
          if (n.icon == 'calendar-check' || n.icon == 'hourglass')
            onCustomerTab(c, 'حجوزاتي');
          if (n.icon == 'badge-percent') push(c, const Offers());
          if (n.icon == 'trophy') push(c, const Rewards());
        }
      },
    );
    final fresh = list
        .where((n) => n.ago.contains('قبل') || n.ago == 'الآن')
        .toList();
    final older = list.where((n) => !fresh.contains(n)).toList();
    return screen(c, [
      topbar(
        'الإشعارات',
        right: owner
            ? null
            : F([T('قراءة الكل', 12, 700, P)], tap: () => repo.readAll()),
      ),
      if (!owner) F([T('اليوم', 13, 700, MU)], w: 'fill', p: [8, 20]),
      for (final n in (owner ? list : fresh)) nt(n),
      if (!owner) F([T('هذا الأسبوع', 13, 700, MU)], w: 'fill', p: [8, 20]),
      if (!owner)
        for (final n in older) nt(n),
    ]);
  }
}

class Group extends Scr {
  final Booking? b;
  const Group([this.b]);
  @override
  Widget view(c, s) => screen(c, [
    topbar('طلعة جماعية'),
    F(
      [
        if (b != null) T('الحجز ${b!.code}', 16, 700),
        Tn(
          'الدعوات وتقسيم الدفعات والمجموعات غير مدعومة في API الحالي. ماكو أعضاء أو دفعات وهمية.',
          s: 14,
          c: MU,
        ),
      ],
      g: 14,
      p: 24,
      w: 'fill',
    ),
  ]);
}

class Profile extends Scr {
  const Profile({super.key});
  @override
  Widget view(c, s) {
    Widget it(String i, String t, [String? v, VoidCallback? tap]) => R(
      [
        R([I(i, 20, INK), T(t, 15, 500)], g: 12),
        R([if (v != null) T(v, 13, 400, MU), I('chevron-left', 18, MU)], g: 6),
      ],
      jc: 'sb',
      w: 'fill',
      p: [14, 0],
      tap: tap ?? () => toast(c, 'قريباً'),
    );
    final upcoming = repo.bookings.where((b) => b.status == 'مؤكد').length;
    return screen(c, [
      topbar(
        'حسابي',
        back: false,
        right: iconbtn('settings', tap: () => push(c, const Settings())),
      ),
      F(
        [
          R(
            [
              R(
                [
                  avatar(repo.userName, 64, 24),
                  F([
                    T(repo.userName, 18, 800),
                    T('${phoneFmt(repo.phone)} · ${repo.gov}', 13, 400, MU),
                  ], g: 4),
                ],
                g: 14,
                al: 'c',
              ),
              F([T('تعديل', 13, 800, P)], tap: () => push(c, const Edit())),
            ],
            jc: 'sb',
            al: 'c',
            w: 'fill',
          ),
          R(
            [
              for (final (a, b, tp) in [
                (
                  '${repo.bookings.length}',
                  'حجز',
                  () => onCustomerTab(c, 'حجوزاتي'),
                ),
                (fmt(repo.points), 'نقطة', () => push(c, const Rewards())),
                (
                  '${repo.follows.length}',
                  'متابَع',
                  () => onCustomerTab(c, 'المفضلة'),
                ),
              ])
                F(
                  [
                    Tn(a, s: 18, w: 800, al: 'CENTER'),
                    Tn(b, s: 12, c: MU, al: 'CENTER'),
                  ],
                  g: 2,
                  al: 'c',
                  w: 'fill',
                  tap: tp,
                ),
            ],
            w: 'fill',
            p: 14,
            r: 18,
            bg: G,
          ),
          F([
            it(
              'calendar-check',
              'حجوزاتي',
              '$upcoming قادم',
              () => onCustomerTab(c, 'حجوزاتي'),
            ),
            divider(),
            it('users', 'طلعاتي الجماعية', null, () => push(c, const Group())),
            divider(),
            it('star', 'تقييماتي', null, () => push(c, const MyReviews())),
            divider(),
            it(
              'user-plus',
              'ادعُ أصحابك',
              'غير مربوط',
              () => push(c, const Rewards()),
            ),
            divider(),
            it(
              'store',
              'سجّل مشروعك على ضوجة',
              null,
              () => push(c, const OIntro()),
            ),
          ], w: 'fill'),
          F([
            it(
              'globe',
              'اللغة',
              'العربية',
              () => toast(c, 'الإنكليزي والكردي قريباً'),
            ),
            divider(),
            it(
              'map-pin',
              'المحافظة',
              repo.gov,
              () => push(c, const Gov(fromSettings: true)),
            ),
            divider(),
            it(
              'circle-help',
              'المساعدة والدعم',
              null,
              () => toast(c, 'قناة الدعم غير مهيأة حالياً'),
            ),
          ], w: 'fill'),
        ],
        g: 16,
        w: 'fill',
        p: [4, 20],
      ),
    ], nav: 'حسابي');
  }
}

class Edit extends Scr {
  const Edit({super.key});
  @override
  Widget view(c, s) {
    final n = s.ctl('n', repo.userName),
        b = s.ctl('b', repo.birth),
        a = s.ctl('a', repo.area),
        g = s.ctl('g', repo.gov);
    final busy = s.get('busy', false);
    return screen(
      c,
      [
        topbar('تعديل الحساب'),
        F(
          [
            F(
              [
                F(
                  [
                    F(
                      [
                        Tn(
                          repo.userName.isEmpty
                              ? '؟'
                              : repo.userName.characters.first,
                          s: 32,
                          w: 800,
                          c: P,
                          al: 'CENTER',
                        ),
                      ],
                      al: 'c',
                      jc: 'c',
                      w: 96,
                      h: 96,
                      r: 48,
                      bg: PL,
                    ),
                    F(
                      [I('camera', 16, WH)],
                      al: 'c',
                      jc: 'c',
                      w: 32,
                      h: 32,
                      r: 16,
                      bg: P,
                      ab: [64, 64],
                      tap: () => toast(c, 'رفع صورة الحساب غير مربوط'),
                    ),
                  ],
                  w: 96,
                  h: 96,
                ),
              ],
              w: 'fill',
              al: 'c',
            ),
            inp('الاسم', '', ctl: n),
            inp(
              'رقم الموبايل',
              phoneFmt(repo.phone),
              lead: F([
                T('تغيير', 13, 700, P),
              ], tap: () => toast(c, 'تغيير رقم الموبايل غير مدعوم حالياً')),
            ),
            inp('تاريخ الميلاد', '', icon: 'calendar', ctl: b),
            inp('المحافظة', '', ctl: g),
            inp('المنطقة', '', icon: 'map-pin', ctl: a),
          ],
          g: 18,
          w: 'fill',
          p: [8, 20],
        ),
      ],
      bottomBar: bottom([
        btn(
          'احفظ',
          busy: busy,
          tap: () async {
            s.set('busy', true);
            final ok = await apiAction(
              c,
              repo.saveProfile(
                name: n.text.trim(),
                governorate: g.text.trim(),
                location: a.text.trim(),
                birthday: b.text,
              ),
            );
            s.set('busy', false);
            if (!ok) return;
            if (!c.mounted) return;
            Navigator.pop(c);
            toast(c, 'انحفظت التغييرات');
          },
        ),
      ]),
    );
  }
}

class Settings extends Scr {
  const Settings({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('الإعدادات'),
    F(
      [
        Tn(
          'تفضيلات الإشعارات والموقع والوضع الداكن وحذف الحساب غير مدعومة في API الحالي. الإشعارات داخل التطبيق تُقرأ من الخادم؛ لا توجد خدمة Push مفعلة.',
          s: 14,
          c: MU,
        ),
        if (repo.isOwner)
          btn('لوحة المالك', kind: 'g', tap: () => onOwnerTab(c, 'الرئيسية')),
        btn(
          'تسجيل الخروج',
          kind: 'g',
          tap: () async {
            await repo.logout();
            if (c.mounted) resetTo(c, const Login(), anim: true);
          },
        ),
      ],
      g: 20,
      p: 24,
      w: 'fill',
    ),
  ]);
}

class Offline extends Scr {
  const Offline({super.key});
  @override
  Widget view(c, s) {
    final busy = s.get('busy', false);
    return screen(c, [
      BOX(w: 10, h: 180),
      F(
        [
          F(
            [I('wifi-off', 44, P)],
            al: 'c',
            jc: 'c',
            w: 110,
            h: 110,
            r: 32,
            bg: PL,
          ),
          Tn('ماكو اتصال بالإنترنت', s: 20, w: 800, al: 'CENTER'),
          Tn(
            repo.error ??
                'تعذر الاتصال بالخادم. ما نعرض بيانات وهمية أو محفوظة قديمة.',
            s: 14,
            c: MU,
            al: 'CENTER',
            w2: 300,
            lh: 22,
          ),
          btn(
            'حاول مرة ثانية',
            icon: 'refresh-cw',
            w: 220,
            busy: busy,
            tap: () async {
              s.set('busy', true);
              await repo.refresh();
              s.set('busy', false);
              if (c.mounted) onCustomerTab(c, 'الرئيسية');
            },
          ),
          F([
            Tn('افتح حجوزاتي', s: 14, w: 700, c: P, al: 'CENTER'),
          ], tap: () => onCustomerTab(c, 'حجوزاتي')),
        ],
        g: 16,
        al: 'c',
        w: 'fill',
      ),
    ], nav: 'الرئيسية');
  }
}

class MyReviews extends Scr {
  const MyReviews({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('تقييماتي'),
    F(
      [
        if (!repo.bookings.any((b) => b.rated))
          T('ما عندك حجوزات مقيّمة', 14, 500, MU),
        for (final b in repo.bookings.where((b) => b.rated))
          btn(
            '${repo.place(b.placeId).name} · ${b.code}',
            kind: 'g',
            tap: () => push(c, Reviews(b.placeId)),
          ),
      ],
      g: 12,
      p: 20,
      w: 'fill',
    ),
  ]);
}
