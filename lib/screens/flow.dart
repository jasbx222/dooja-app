import 'package:flutter/material.dart';

import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'home.dart';
import 'more.dart';
import 'place.dart';

class PickPrefs {
  String people = '4', budget = '10 - 25 ألف', mood = 'حماسي';
}

final pickPrefs = PickPrefs();

List<(Place, List<(String, String)>)> pickResults(int shuffle) {
  final pp = pickPrefs;
  final n = int.tryParse(pp.people.replaceAll('+', '')) ?? 5;
  final out = <(Place, List<(String, String)>)>[];
  for (final p in repo.places) {
    final per = p.unit == 'ساعة' ? (p.price * 2 / n).round() : p.price;
    final okB = pp.budget == 'أقل من 10 آلاف'
        ? per < 10000
        : pp.budget == '10 - 25 ألف'
        ? per <= 25000
        : true;
    final calm = ['كافيه', 'مطاعم', 'منتجعات', 'مسابح'].contains(p.type);
    final okM =
        pp.mood == 'أي شي' ||
        (pp.mood == 'حماسي' && !calm && p.type != 'أنشطة عائلية') ||
        (pp.mood == 'هادئ' &&
            calm &&
            per < 10000 &&
            pp.budget != 'أقل من 10 آلاف') ||
        (pp.mood == 'عائلي' &&
            (p.type == 'أنشطة عائلية' ||
                p.type == 'منتجعات' ||
                p.type == 'مطاعم'));
    if (okB && okM && p.kind != 'full') {
      out.add((
        p,
        [
          ('wallet', 'ضمن ميزانيتك'),
          if (km(p) < 3) ('navigation', 'قريب منك ${p.dist}'),
          if (p.kind == 'slots')
            ('calendar-check', 'تحقق من الموعد عند الحجز')
          else
            ('users', 'يناسب ${pp.people} أشخاص'),
        ],
      ));
    }
  }
  if (out.length > 2) {
    final r = shuffle % out.length;
    return [...out.skip(r), ...out.take(r)];
  }
  return out;
}

class PickQ extends Scr {
  const PickQ({super.key});
  @override
  Widget view(c, s) {
    final pp = pickPrefs;
    final busy = s.get('busy', false);
    Widget q(String icon, String lab, String val) => R(
      [
        R([I(icon, 20, P), T(lab, 15, 700)], g: 10),
        R([T(val, 14, 500, MU), I('chevron-left', 18, MU)], g: 6),
      ],
      jc: 'sb',
      w: 'fill',
      p: [16, 16],
      r: 16,
      bg: WH,
      sk: LN,
      tap: () => toast(c, 'تكدر تغيّر $lab من هنا'),
    );
    Widget grp(String t, List<Widget> k) =>
        F([T(t, 14, 800), R(k, g: 8)], g: 10, w: 'fill');
    return screen(
      c,
      [
        topbar('اختارلي'),
        F(
          [
            R(
              [
                F([
                  Tn('خل ضوجة تختارلك الأفضل', s: 22, w: 800, w2: 230, lh: 30),
                  T('جاوب على كم سؤال ونختارلك الأنسب', 14, 400, MU),
                ], g: 6),
                F(const [], d: null, bg: 'img:dice:FIT', w: 84, h: 84),
              ],
              jc: 'sb',
              al: 'c',
              w: 'fill',
            ),
          ],
          w: 'fill',
          p: [4, 20],
        ),
        F(
          [
            grp('كم شخص؟', [
              for (final x in ['1', '2', '3', '4', '5+'])
                chip(x, x == pp.people, null, 13, () {
                  pp.people = x;
                  s.set('x', x);
                }),
            ]),
            grp('الميزانية للشخص', [
              for (final x in ['أقل من 10 آلاف', '10 - 25 ألف', 'أكثر'])
                chip(x, x == pp.budget, null, 13, () {
                  pp.budget = x;
                  s.set('x', x);
                }),
            ]),
            grp('نوع الجو', [
              for (final (x, i) in [
                ('حماسي', 'flame'),
                ('هادئ', null),
                ('عائلي', null),
                ('أي شي', null),
              ])
                chip(
                  x,
                  x == pp.mood,
                  x == pp.mood ? i : (x == 'حماسي' ? i : null),
                  13,
                  () {
                    pp.mood = x;
                    s.set('x', x);
                  },
                ),
            ]),
          ],
          g: 18,
          w: 'fill',
          p: [8, 20],
        ),
        F(
          [
            q('map-pin', 'الموقع', '${repo.area} · لحد 5 كم'),
            q('clock', 'الوقت', 'اليوم · 8 بالليل'),
            q('hourglass', 'المدة', 'ساعتين'),
            q('layout-grid', 'النشاط', 'بادل، بليارد، ألعاب'),
          ],
          g: 10,
          w: 'fill',
          p: [8, 20],
        ),
      ],
      bottomBar: bottom([
        btn(
          'اختارلي هسه',
          icon: 'sparkle',
          busy: busy,
          tap: () async {
            s.set('busy', true);
            await repo.refresh();
            s.set('busy', false);
            if (!c.mounted) return;
            push(
              c,
              pickResults(0).isEmpty ? const PickEmpty() : const PickRes(),
            );
          },
        ),
      ]),
    );
  }
}

class PickRes extends Scr {
  const PickRes({super.key});
  @override
  Widget view(c, s) {
    final sh = s.get('sh', 0);
    final res = pickResults(sh).take(3).toList();
    final pp = pickPrefs;
    Widget resw(Place p, List<(String, String)> rs, bool top) {
      final n = int.tryParse(pp.people.replaceAll('+', '')) ?? 5;
      final per = p.unit == 'ساعة' ? (p.price * 2 / n).round() : p.price;
      return card(
        [
          img(
            p.img,
            318,
            130,
            16,
            [if (top) tag('الأنسب إلكم', bg: P, c: WH, icon: 'sparkle')],
            'h',
            10,
            's',
          ),
          R(
            [
              F([
                T(p.name, 16, 800),
                meta('map-pin', '${p.type} · ${p.area}'),
              ], g: 4),
              F(
                [T('${fmt(per)} د.ع', 15, 800, P), T('للشخص', 11, 400, MU)],
                al: 'e',
                g: 2,
              ),
            ],
            jc: 'sb',
            w: 'fill',
          ),
          R(
            [for (final (i, r) in rs) tag(r, icon: i)],
            g: 6,
            wrap: true,
            w: 'fill',
          ),
          R(
            [
              btn(
                'احجز',
                icon: 'calendar-check',
                h: 40,
                tap: () => push(c, BookSlot(p.id)),
              ),
              btn(
                'التفاصيل',
                kind: 'g',
                h: 40,
                w: 110,
                tap: () => push(c, Details(p.id)),
              ),
            ],
            g: 8,
            w: 'fill',
          ),
        ],
        p: 12,
        g: 10,
      );
    }

    return screen(
      c,
      [
        topbar(
          'اخترنالك',
          sub: '${pp.people} أشخاص · ${pp.budget} · ${pp.mood}',
        ),
        if (res.isEmpty)
          F(
            [BOX(h: 60, w: 1), Tn('ماكو نتائج', s: 18, w: 800, al: 'CENTER')],
            al: 'c',
            w: 'fill',
          ),
        F(
          [
            for (var i = 0; i < res.length; i++)
              resw(res[i].$1, res[i].$2, i == 0),
          ],
          g: 12,
          w: 'fill',
          p: [4, 20],
        ),
      ],
      bottomBar: bottom([
        R(
          [
            btn(
              'اختارلي غيرهن',
              icon: 'shuffle',
              kind: 's',
              tap: () => s.set('sh', sh + 1),
            ),
            btn(
              'عدّل',
              icon: 'sliders-horizontal',
              kind: 'g',
              w: 110,
              tap: () => Navigator.pop(c),
            ),
          ],
          g: 10,
          w: 'fill',
        ),
      ]),
    );
  }
}

class PickEmpty extends Scr {
  const PickEmpty({super.key});
  @override
  Widget view(c, s) => screen(
    c,
    [
      topbar('اخترنالك'),
      F(
        [
          BOX(w: 10, h: 80),
          F(
            [I('search-x', 44, P)],
            al: 'c',
            jc: 'c',
            w: 110,
            h: 110,
            r: 32,
            bg: PL,
          ),
          Tn('ما لگينا مكان يطابق كل اختياراتك', s: 19, w: 800, al: 'CENTER'),
          Tn(
            'جرّب توسّع المسافة أو تغيّر الميزانية، أو خلّينا نقترح أقرب شي',
            s: 14,
            c: MU,
            al: 'CENTER',
            w2: 300,
            lh: 22,
          ),
          F(
            [
              R(
                [T('وسّع المسافة لـ 10 كم', 14, 700), I('navigation', 18, P)],
                g: 8,
                jc: 'sb',
                w: 'fill',
                tap: () {
                  pickPrefs.mood = 'أي شي';
                  replace(c, const PickRes());
                },
              ),
              R(
                [T('ارفع الميزانية لـ 30 ألف', 14, 700), I('wallet', 18, P)],
                g: 8,
                jc: 'sb',
                w: 'fill',
                tap: () {
                  pickPrefs.budget = 'أكثر';
                  replace(c, const PickRes());
                },
              ),
            ],
            g: 14,
            w: 'fill',
            p: 16,
            r: 18,
            bg: G,
          ),
        ],
        g: 16,
        al: 'c',
        w: 'fill',
        p: [0, 24],
      ),
    ],
    bottomBar: bottom([
      btn(
        'عدّل الاختيارات',
        icon: 'sliders-horizontal',
        tap: () => Navigator.pop(c),
      ),
    ]),
  );
}

N slot(String t, {String st = 'free', bool on = false, VoidCallback? tap}) {
  final bg = st == 'full' ? G : WH;
  final c = st == 'full' ? MU : (on ? WH : INK);
  return F(
    [Tn(t, s: 14, w: 700, c: c, al: 'CENTER', st: st == 'full')],
    al: 'c',
    jc: 'c',
    w: 100,
    h: 46,
    r: 14,
    bg: on ? P : bg,
    sk: on || st == 'full' ? null : LN,
    tap: tap,
  );
}

List<(String, String, String)> get DAYS => [
  for (var i = 0; i < 5; i++)
    (
      _weekday(DateTime.now().add(Duration(days: i)).weekday),
      DateTime.now().add(Duration(days: i)).day.toString(),
      isoDay(i),
    ),
];
String _weekday(int day) =>
    ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'][day - 1];
const SLOTS = ['6:00 م', '7:00 م', '8:00 م', '9:00 م', '10:00 م', '11:00 م'];
const DURS = ['ساعة', 'ساعتين', '3 ساعات'];

class Draft {
  final String placeId;
  int day = 0, slot = 2, dur = 1, people = 4;
  String pay = 'cash';
  Offer? offer;
  Draft(this.placeId);
  Place get p => repo.place(placeId);
  int get base => p.price * (p.unit == 'ساعة' ? dur + 1 : people);
  int get disc => offer == null
      ? 0
      : base - offer!.newP * (p.unit == 'ساعة' ? dur + 1 : people);
  int get total => base - disc;
  String get end {
    final h = 18 + slot + dur + 1;
    return '${(h % 24).toString().padLeft(2, '0')}:00';
  }

  String get dayShort => DAYS[day].$3.split(' ').take(2).join(' ');
}

Set<int> fullSlots(String placeId, int day) => {
  for (var i = 0; i < SLOTS.length; i++)
    if (repo.occupied(placeId, isoDay(day)).contains(18 + i)) i,
};

class BookSlot extends Scr {
  final String id;
  final int dur;
  final Offer? offer;
  const BookSlot(this.id, {super.key, this.dur = 1, this.offer});
  @override
  void init(ScrSt s) {
    repo.loadAvailability(id, isoDay());
  }

  @override
  Widget view(c, s) {
    final d = s.get(
      'd',
      Draft(id)
        ..dur = dur
        ..offer = offer,
    );
    final occupied = repo.occupied(id, isoDay(d.day));
    final full = {
      for (var i = 0; i < SLOTS.length; i++)
        if (18 + i + d.dur + 1 > 24 ||
            List.generate(d.dur + 1, (j) => 18 + i + j).any(occupied.contains))
          i,
    };
    final p = d.p;
    void up(VoidCallback f) {
      f();
      s.set('t', DateTime.now());
    }

    return screen(
      c,
      [
        topbar('اختار الموعد', sub: p.name),
        F(
          [
            T(isoDay(d.day), 15, 800),
            R([
              for (var i = 0; i < DAYS.length; i++)
                F(
                  [
                    Tn(
                      DAYS[i].$1,
                      s: 12,
                      w: 500,
                      c: i == d.day ? WH : MU,
                      al: 'CENTER',
                    ),
                    Tn(
                      DAYS[i].$2,
                      s: 18,
                      w: 800,
                      c: i == d.day ? WH : INK,
                      al: 'CENTER',
                    ),
                  ],
                  g: 4,
                  al: 'c',
                  w: 60,
                  p: [10, 0],
                  r: 16,
                  bg: i == d.day ? P : G,
                  tap: () => up(() {
                    d.day = i;
                    repo.loadAvailability(id, isoDay(i));
                  }),
                ),
            ], g: 10),
          ],
          g: 12,
          w: 'fill',
          p: [4, 20],
        ),
        F(
          [
            R(
              [
                T('الأوقات المتوفرة', 15, 800),
                R([
                  BOX(w: 10, h: 10, r: 3, bg: G),
                  T('محجوز', 12, 400, MU),
                ], g: 4),
              ],
              jc: 'sb',
              w: 'fill',
            ),
            R(
              [
                for (var i = 0; i < SLOTS.length; i++)
                  slot(
                    SLOTS[i],
                    st: full.contains(i) ? 'full' : 'free',
                    on: i == d.slot,
                    tap: full.contains(i) ? null : () => up(() => d.slot = i),
                  ),
              ],
              g: 11,
              wrap: true,
              w: 'fill',
            ),
          ],
          g: 12,
          w: 'fill',
          p: [8, 20],
        ),
        F(
          [
            T('المدة', 15, 800),
            R([
              for (var i = 0; i < 3; i++)
                chip(DURS[i], i == d.dur, null, 13, () => up(() => d.dur = i)),
            ], g: 8),
          ],
          g: 12,
          w: 'fill',
          p: [8, 20],
        ),
        F(
          [
            R(
              [
                T('عدد الأشخاص', 15, 800),
                R(
                  [
                    F(
                      [I('minus', 18)],
                      al: 'c',
                      jc: 'c',
                      w: 36,
                      h: 36,
                      r: 18,
                      bg: G,
                      tap: () =>
                          up(() => d.people = (d.people - 1).clamp(1, 20)),
                    ),
                    T('${d.people}', 18, 800),
                    F(
                      [I('plus', 18, WH)],
                      al: 'c',
                      jc: 'c',
                      w: 36,
                      h: 36,
                      r: 18,
                      bg: P,
                      tap: () =>
                          up(() => d.people = (d.people + 1).clamp(1, 20)),
                    ),
                  ],
                  g: 14,
                  al: 'c',
                  ltr: true,
                ),
              ],
              jc: 'sb',
              w: 'fill',
            ),
          ],
          g: 12,
          w: 'fill',
          p: [8, 20],
        ),
      ],
      bottomBar: bottom([
        R(
          [
            F([
              T('${DURS[d.dur]} · ${d.people} أشخاص', 12, 400, MU),
              T('${fmt(d.base)} د.ع', 18, 800, P),
            ], g: 2),
            btn(
              'كمّل',
              icon: 'chevron-left',
              w: 170,
              tap: () {
                if (full.contains(d.slot)) {
                  toast(c, 'اختار موعداً متاحاً بعد تحميل المواعيد');
                  return;
                }
                push(c, BookPay(d));
              },
            ),
          ],
          jc: 'sb',
          w: 'fill',
        ),
      ]),
    );
  }
}

class BookPay extends Scr {
  final Draft d;
  const BookPay(this.d, {super.key});
  @override
  Widget view(c, s) {
    final d = this.d;
    final busy = s.get('busy', false);
    Widget pm(String key, String icon, String t, String sub) {
      final on = d.pay == key;
      return R(
        [
          R([
            F([I(icon, 20, P)], al: 'c', jc: 'c', w: 40, h: 40, r: 12, bg: PL),
            F([T(t, 15, 700), T(sub, 12, 400, MU)], g: 2),
          ], g: 12),
          radio(on),
        ],
        jc: 'sb',
        w: 'fill',
        p: 14,
        r: 16,
        bg: WH,
        sk: on ? P : LN,
        skw: on ? 2 : 1,
        tap: () {
          d.pay = key;
          s.set('x', key);
        },
      );
    }

    final payName = {'cash': 'كاش', 'zain': 'زين كاش', 'card': 'بطاقة'}[d.pay]!;
    return screen(
      c,
      [
        topbar('تأكيد الحجز'),
        F(
          [
            card([
              R(
                [
                  img(d.p.img, 64, 64, 14),
                  F([
                    T(d.p.name, 15, 800),
                    meta(
                      'calendar',
                      '${DAYS[d.day].$3} · ${SLOTS[d.slot].replaceAll(' م', '')} - ${d.end}',
                    ),
                    meta('users', '${d.people} أشخاص'),
                  ], g: 4),
                ],
                g: 12,
                al: 'c',
                w: 'fill',
              ),
            ], p: 12),
            if (d.offer != null && d.disc > 0)
              R(
                [
                  R([
                    I('ticket-percent', 20, P),
                    T('عرض: ${d.offer!.disc}', 14, 700, P),
                  ], g: 8),
                  T('مطبّق', 13, 800, P),
                ],
                jc: 'sb',
                w: 'fill',
                p: 14,
                r: 16,
                bg: PL,
              ),
            T('طريقة الدفع', 15, 800),
            pm('cash', 'banknote', 'كاش بالمكان', 'ادفع لما توصل'),
            Tn(
              'الدفع الإلكتروني غير مربوط؛ المتاح كاش بالمكان فقط.',
              s: 13,
              c: MU,
            ),
            card([
              R(
                [
                  T('الحجز (${DURS[d.dur]})', 14, 400, MU),
                  T('${fmt(d.base)} د.ع', 14, 700),
                ],
                jc: 'sb',
                w: 'fill',
              ),
              if (d.disc > 0)
                R(
                  [
                    T('خصم العرض', 14, 400, MU),
                    T('- ${fmt(d.disc)} د.ع', 14, 700, OK),
                  ],
                  jc: 'sb',
                  w: 'fill',
                ),
              divider(),
              R(
                [T('المجموع', 15, 800), T('${fmt(d.total)} د.ع', 17, 800, P)],
                jc: 'sb',
                w: 'fill',
              ),
              R(
                [
                  T('حصتك لو قسمتوها على ${d.people}', 12, 400, MU),
                  T('${fmt((d.total / d.people).round())} د.ع', 12, 700),
                ],
                jc: 'sb',
                w: 'fill',
              ),
            ], g: 10),
          ],
          g: 12,
          w: 'fill',
          p: [4, 20],
        ),
      ],
      bottomBar: bottom([
        btn(
          'أكّد الحجز',
          icon: 'check',
          busy: busy,
          tap: () async {
            s.set('busy', true);
            Booking b;
            try {
              b = await repo.book(
                placeId: d.placeId,
                day: isoDay(d.day),
                time: SLOTS[d.slot],
                dur: DURS[d.dur],
                people: d.people,
                total: d.total,
                pay: 'كاش بالمكان',
                offerId: d.offer?.id,
              );
            } catch (e) {
              s.set('busy', false);
              if (c.mounted) toast(c, e.toString());
              return;
            }
            s.set('busy', false);
            if (c.mounted) push(c, BookDone(b, payName, d));
          },
        ),
      ]),
      bottomH: 100,
    );
  }
}

class BookDone extends Scr {
  final Booking b;
  final String pay;
  final Draft d;
  const BookDone(this.b, this.pay, this.d, {super.key});
  @override
  Widget view(c, s) => screen(
    c,
    [
      BOX(w: 10, h: 30),
      F(
        [
          F(
            [I('check', 40, WH, null, 3)],
            al: 'c',
            jc: 'c',
            w: 88,
            h: 88,
            r: 44,
            bg: P,
          ),
          Tn('تم إرسال طلب الحجز', s: 26, w: 800, al: 'CENTER'),
          Tn(b.status, s: 14, c: MU, al: 'CENTER'),
        ],
        g: 12,
        al: 'c',
        w: 'fill',
      ),
      F(
        [
          card(
            [
              F(
                [
                  I('ticket', 72, P),
                  Tn('رمز الحجز ${b.code}', s: 14, w: 800, al: 'CENTER'),
                  Tn('اعرضه بالمكان لتسجيل الوصول', s: 12, c: MU, al: 'CENTER'),
                ],
                g: 8,
                al: 'c',
                w: 'fill',
              ),
              divider(),
              R(
                [T(d.p.name, 14, 700), T('المكان', 13, 400, MU)],
                jc: 'sb',
                w: 'fill',
              ),
              R(
                [
                  T(
                    '${d.dayShort} · ${SLOTS[d.slot].replaceAll(' م', '')} - ${d.end}',
                    14,
                    700,
                  ),
                  T('الموعد', 13, 400, MU),
                ],
                jc: 'sb',
                w: 'fill',
              ),
              R(
                [
                  T('${fmt(b.total)} د.ع · $pay', 14, 700),
                  T('الدفع', 13, 400, MU),
                ],
                jc: 'sb',
                w: 'fill',
              ),
              R(
                [T('${repo.points}', 14, 800, P), T('نقاطك', 13, 400, MU)],
                jc: 'sb',
                w: 'fill',
              ),
            ],
            g: 12,
            p: 20,
          ),
        ],
        w: 'fill',
        p: [24, 20],
      ),
    ],
    bottomBar: bottom([
      R(
        [
          btn(
            'أضف للتقويم',
            icon: 'calendar',
            kind: 'g',
            tap: () => toast(c, 'التقويم غير مربوط حالياً'),
          ),
          btn(
            'ادعُ أصحابك',
            icon: 'user-plus',
            kind: 's',
            tap: () => push(c, Group(b)),
          ),
        ],
        g: 10,
        w: 'fill',
      ),
      btn('رجوع للرئيسية', kind: 'o', tap: () => onCustomerTab(c, 'الرئيسية')),
    ]),
    bottomH: 160,
  );
}

class Waitlist extends Scr {
  final String id, time, day;
  const Waitlist(this.id, {super.key, this.time = '21:00', this.day = ''});
  @override
  Widget view(c, s) => screen(
    c,
    [
      topbar('قائمة الانتظار'),
      F(
        [
          Tn(
            'إرسال طلب انتظار للموعد المحدد. ترتيب القائمة والتنبيهات التلقائية غير مدعومة حالياً.',
            s: 14,
            c: MU,
          ),
          T(day.isEmpty ? isoDay() : day, 14, 700),
          T(time, 14, 700),
        ],
        g: 14,
        p: 20,
        w: 'fill',
      ),
    ],
    bottomBar: bottom([
      btn(
        'سجّلني بالانتظار',
        tap: () async {
          try {
            await repo.book(
              placeId: id,
              day: day.isEmpty ? isoDay() : day,
              time: time,
              dur: 'ساعة',
              people: 1,
              total: 0,
              pay: 'كاش بالمكان',
              wait: true,
            );
            if (c.mounted) onCustomerTab(c, 'حجوزاتي');
          } catch (e) {
            if (c.mounted) toast(c, e.toString());
          }
        },
      ),
    ]),
  );
}

class ErrorBook extends Scr {
  const ErrorBook({super.key});
  @override
  Widget view(c, s) => screen(c, [
    topbar('الدفع'),
    F(
      [
        Tn(
          'الدفع الإلكتروني غير مربوط حالياً. لم يتم حجز موعد أو خصم مبلغ.',
          s: 16,
          c: MU,
        ),
      ],
      p: 24,
      w: 'fill',
    ),
  ]);
}
