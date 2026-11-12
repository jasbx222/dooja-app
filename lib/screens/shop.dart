import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../common.dart';
import '../dsl.dart';
import '../repo.dart';

Widget cartButton(BuildContext c) {
  final n = repo.cartCount;
  return F(
    [
      I('store', 20, INK),
      if (n > 0)
        F(
          [Tn('$n', s: 10, w: 700, c: WH, al: 'CENTER')],
          al: 'c',
          jc: 'c',
          w: 16,
          h: 16,
          r: 8,
          bg: RD,
          ab: [22, -2],
        ),
    ],
    al: 'c',
    jc: 'c',
    w: 40,
    h: 40,
    r: 20,
    bg: WH,
    sk: LN,
    tap: () => push(c, const ShopPage(initial: 1)),
  );
}

Widget productPhoto(String? path, double w, double h, {double r = 16}) {
  final url = repo.media(path);
  return ClipRRect(
    borderRadius: BorderRadius.circular(r),
    child: SizedBox(
      width: w,
      height: h,
      child: url.isEmpty
          ? ColoredBox(color: col(PL), child: Center(child: I('store', 28, P)))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: col(PL), child: Center(child: I('image', 28, MU))),
            ),
    ),
  );
}

class ShopPage extends Scr {
  final int initial;
  const ShopPage({this.initial = 0, super.key});
  @override
  void init(ScrSt s) {
    s.set('tab', initial);
    repo.openStore();
  }

  @override
  Widget view(c, s) {
    final tab = s.get('tab', initial);
    return screen(c, [
      topbar('التسوق', back: true, right: cartButton(c)),
      tabs(const ['المتجر', 'السلة', 'طلباتي'], tab, (i) {
        s.set('tab', i);
        if (i == 2) repo.loadOrders();
        if (i == 0) repo.openStore(q: s.ctl('q').text, categoryId: s.v['cat'] as int?, sort: s.get('sort', 'latest'), discounted: s.get('sale', false));
      }),
      if (tab == 0) _store(c, s),
      if (tab == 1) _cart(c, s),
      if (tab == 2) _orders(c),
    ], nav: 'الرئيسية');
  }

  void _search(ScrSt s, {int? categoryId, String? sort, bool? discounted, int page = 1}) {
    int? money(String raw) => raw.trim().isEmpty ? null : int.tryParse(raw.trim());
    repo.openStore(
      q: s.ctl('q').text,
      categoryId: categoryId ?? s.v['cat'] as int?,
      sort: sort ?? s.get('sort', 'latest'),
      minPrice: money(s.ctl('min').text),
      maxPrice: money(s.ctl('max').text),
      discounted: discounted ?? s.get('sale', false),
      page: page,
    );
  }

  Widget _store(BuildContext c, ScrSt s) {
    if (repo.shopLoading && repo.shopProducts.isEmpty) return Tn('جاري تحميل المتجر...', s: 14, c: MU, al: 'CENTER');
    if (repo.shopError != null && repo.shopProducts.isEmpty) {
      return F([
        Tn('تعذر تحميل المتجر', s: 18, w: 800, al: 'CENTER'),
        Tn(repo.shopError!, s: 13, c: MU, al: 'CENTER'),
        btn('إعادة المحاولة', tap: () => repo.openStore()),
      ], g: 12, al: 'c', w: 'fill', p: [24, 20]);
    }
    if (!repo.shopEnabled) {
      return F([
        I('store', 42, P),
        Tn('المتجر متوقف حالياً', s: 18, w: 800, al: 'CENTER'),
        Tn('يرجع لما الإدارة تفتحه من لوحة التحكم.', s: 13, c: MU, al: 'CENTER'),
      ], g: 12, al: 'c', w: 'fill', p: [40, 24]);
    }
    final q = s.ctl('q');
    return F([
      F([
        R([
          I('search', 18, MU),
          N(field(q, 'ابحث عن منتج', 14, onChanged: (_) {}), fillW: true),
        ], g: 8, bg: G, r: 14, h: 48, w: 'fill', p: [0, 14]),
      ], w: 'fill', p: [0, 20], tap: () {}),
      R([
        F([inp('من', '0', ctl: s.ctl('min'), kb: TextInputType.number)], w: 'fill'),
        F([inp('إلى', 'أي سعر', ctl: s.ctl('max'), kb: TextInputType.number)], w: 'fill'),
      ], g: 8, w: 'fill', p: [0, 20]),
      btn('بحث', h: 44, tap: () => _search(s)),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R([
          chip('الكل', s.v['cat'] == null, null, 13, () { s.set('cat', null); _search(s); }),
          for (final cat in repo.shopCategories) chip(cat.name, s.v['cat'] == cat.id, null, 13, () { s.set('cat', cat.id); _search(s, categoryId: cat.id); }),
        ], g: 8, p: [0, 20]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: R([
          for (final (id, label) in [('latest', 'الأحدث'), ('price_asc', 'الأرخص'), ('price_desc', 'الأغلى'), ('discount', 'التخفيضات')])
            chip(label, s.get('sort', 'latest') == id, null, 13, () {
              s.set('sort', id);
              s.set('sale', id == 'discount');
              _search(s, sort: id, discounted: id == 'discount');
            }),
        ], g: 8, p: [0, 20]),
      ),
      if (repo.shopProducts.isEmpty)
        F([
          Tn('لا توجد منتجات', s: 18, w: 800, al: 'CENTER'),
          Tn('لما تنضاف منتجات من لوحة التحكم بتظهر هنا.', s: 13, c: MU, al: 'CENTER'),
        ], g: 8, al: 'c', w: 'fill', p: [30, 24])
      else
        F([
          for (final p in repo.shopProducts) _card(c, p),
          if (repo.shopProducts.length < repo.shopTotal) btn('عرض المزيد', kind: 's', tap: () => _search(s, page: repo.shopPage + 1)),
        ], g: 12, w: 'fill', p: [0, 20]),
    ], g: 12, w: 'fill');
  }

  Widget _card(BuildContext c, ShopProduct p) => F([
    productPhoto(p.image, 350, 180, r: 0),
    F([
      R([N(Tx(p.name, 16, 800, INK, maxLines: 1), fillW: true), if (p.discount != null) tag('${p.discount}%', bg: P, c: WH)], g: 8),
      Tn(p.category, s: 12, c: MU),
      R([
        price(fmt(p.price), p.compareAt == null ? null : fmt(p.compareAt!)),
        tag(p.available ? 'متوفر' : 'نفد', bg: p.available ? OKB : '#FDECEC', c: p.available ? OK : RD),
      ], jc: 'sb', w: 'fill'),
      btn('أضف للسلة', icon: 'plus', h: 44, tap: p.available ? () {
        repo.addToCart(p.id, 1).then((err) { if (c.mounted) toast(c, err ?? 'انضاف للسلة'); });
      } : null),
    ], g: 8, p: [12, 14, 14, 14], w: 'fill'),
  ], w: 'fill', r: 20, bg: WH, sk: LN, clip: true, tap: () => push(c, ProductPage(p.id)));

  Widget _cart(BuildContext c, ScrSt s) {
    if (repo.cartLines.isEmpty) {
      return F([
        Tn('السلة فارغة', s: 18, w: 800, al: 'CENTER'),
        btn('ارجع للمتجر', kind: 's', tap: () => s.set('tab', 0)),
      ], g: 12, al: 'c', w: 'fill', p: [40, 24]);
    }
    return F([
      if (repo.cartWarnings.isNotEmpty) F([for (final w in repo.cartWarnings) Tn(w, s: 12, c: WR)], g: 4, w: 'fill', p: [8, 12], r: 12, bg: WRB),
      for (final line in repo.cartLines)
        R([
          productPhoto(line.image, 72, 72, r: 14),
          F([
            Tn(line.name, s: 14, w: 700, maxLines: 1),
            price(fmt(line.unitPrice)),
            R([
              iconbtn('minus', s: 32, tap: () {
                repo.setCartQty(line.productId, line.qty - 1).then((err) { if (err != null && c.mounted) toast(c, err); });
              }),
              Tn('${line.qty}', s: 14, w: 700),
              iconbtn('plus', s: 32, tap: () {
                repo.setCartQty(line.productId, line.qty + 1).then((err) { if (err != null && c.mounted) toast(c, err); });
              }),
            ], g: 8, al: 'c'),
          ], g: 6, w: 'fill'),
          F([
            Tn('${fmt(line.lineTotal)} د.ع', s: 13, w: 700, c: P),
            F([I('trash-2', 16, RD)], tap: () => repo.setCartQty(line.productId, 0)),
          ], g: 8, al: 'e'),
        ], g: 10, al: 'c', w: 'fill', p: [10, 12], r: 16, bg: WH, sk: LN),
      R([Tn('المجموع', s: 14, c: MU), Tn('${fmt(repo.cartSubtotal)} د.ع', s: 16, w: 800, c: P)], jc: 'sb', w: 'fill'),
      if (repo.cartDiscount > 0) Tn('وفّرت ${fmt(repo.cartDiscount)} د.ع مقارنة بالسعر السابق', s: 12, c: OK),
      btn('إتمام الشراء', tap: () {
        if (!repo.authenticated) {
          toast(c, 'سجّل دخول حتى تكتمل السلة على حسابك');
          onCustomerTab(c, '__login');
          return;
        }
        push(c, const CheckoutPage());
      }),
    ], g: 12, w: 'fill', p: [0, 20]);
  }

  Widget _orders(BuildContext c) {
    if (!repo.authenticated) {
      return F([
        Tn('سجل دخول لتشوف طلباتك', s: 16, w: 700, al: 'CENTER'),
        btn('تسجيل الدخول', tap: () => onCustomerTab(c, '__login')),
      ], g: 12, al: 'c', w: 'fill', p: [30, 24]);
    }
    if (repo.shopOrders.isEmpty) return Tn('ما عندك طلبات بعد', s: 16, c: MU, al: 'CENTER');
    return F([
      for (final o in repo.shopOrders)
        F([
          R([Tn(o.number, s: 14, w: 800), tag(o.status, bg: PL, c: P)], jc: 'sb', w: 'fill'),
          Tn('${fmt(o.total)} د.ع · ${o.pay}', s: 12, c: MU),
        ], g: 6, w: 'fill', p: 14, r: 16, bg: WH, sk: LN, tap: () => push(c, OrderPage(o.id))),
    ], g: 10, w: 'fill', p: [0, 20]);
  }
}

class ProductPage extends Scr {
  final int id;
  const ProductPage(this.id, {super.key});
  @override
  void init(ScrSt s) {
    s.set('qty', 1);
    repo.openProduct(id);
  }

  @override
  Widget view(c, s) {
    final p = repo.currentProduct;
    if (p == null || p.id != id) {
      return screen(c, [
        topbar('المنتج'),
        if (repo.shopError != null) Tn(repo.shopError!, s: 14, c: RD, al: 'CENTER') else Tn('جاري التحميل...', s: 14, c: MU, al: 'CENTER'),
      ]);
    }
    final qty = s.get('qty', 1);
    final photos = p.images.where((e) => e.isNotEmpty).toList();
    return screen(c, [
      topbar(p.name, right: cartButton(c)),
      if (photos.isEmpty) productPhoto(null, 350, 220, r: 20) else SingleChildScrollView(scrollDirection: Axis.horizontal, child: R([for (final src in photos) productPhoto(src, 280, 220, r: 20)], g: 10, p: [0, 20])),
      F([
        Tn(p.category, s: 12, c: P, w: 700),
        T(p.name, 22, 800),
        R([price(fmt(p.price), p.compareAt == null ? null : fmt(p.compareAt!), 18), tag(p.available ? 'متوفر · ${p.stock}' : 'غير متوفر', bg: p.available ? OKB : '#FDECEC', c: p.available ? OK : RD)], jc: 'sb', w: 'fill'),
        if (p.description.isNotEmpty) Tn(p.description, s: 14, lh: 22),
        if (p.specs.isNotEmpty) F([Tn('المواصفات', s: 14, w: 800), Tn(p.specs, s: 13, c: MU, lh: 22)], g: 6, w: 'fill'),
        R([
          Tn('الكمية', s: 14, w: 700),
          iconbtn('minus', tap: qty > 1 ? () => s.set('qty', qty - 1) : null),
          Tn('$qty', s: 16, w: 800),
          iconbtn('plus', tap: qty < p.stock ? () => s.set('qty', qty + 1) : null),
        ], jc: 'sb', al: 'c', w: 'fill'),
        btn('أضف للسلة', tap: p.available ? () {
          repo.addToCart(p.id, qty).then((err) { if (c.mounted) toast(c, err ?? 'انضاف للسلة'); });
        } : null),
      ], g: 12, w: 'fill', p: [8, 20]),
    ]);
  }
}

class CheckoutPage extends Scr {
  const CheckoutPage({super.key});
  @override
  void init(ScrSt s) {
    s.set('key', 'shop-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}');
    s.ctl('name', repo.userName);
    s.ctl('phone', repo.phone);
    s.ctl('gov', repo.deliveryAreas.isEmpty ? repo.gov : '');
    s.ctl('area', repo.area);
    s.ctl('addr');
    s.ctl('notes');
  }

  @override
  Widget view(c, s) {
    final busy = s.get('busy', false);
    final pay = s.get('pay', repo.payMethods.isEmpty ? '' : repo.payMethods.first.$1);
    final fee = () {
      if (repo.deliveryAreas.isEmpty) return repo.shopDeliveryFee;
      final match = repo.deliveryAreas.where((a) => a.governorate == s.ctl('gov').text && a.area == s.ctl('area').text);
      return match.isEmpty ? repo.shopDeliveryFee : match.first.fee;
    }();
    final total = repo.cartSubtotal + fee;
    return screen(c, [
      topbar('إتمام الشراء'),
      F([
        inp('الاسم', 'اسم المستلم', ctl: s.ctl('name')),
        inp('الهاتف', '07xxxxxxxxx', ctl: s.ctl('phone'), kb: TextInputType.phone),
        if (repo.deliveryAreas.isEmpty) ...[
          inp('المحافظة', 'بغداد', ctl: s.ctl('gov')),
          inp('المنطقة', 'المنطقة', ctl: s.ctl('area')),
        ] else ...[
          Tn('منطقة التوصيل', s: 13, c: MU),
          for (final a in repo.deliveryAreas)
            chip('${a.governorate} · ${a.area}', s.ctl('gov').text == a.governorate && s.ctl('area').text == a.area, null, 13, () {
              s.ctl('gov').text = a.governorate;
              s.ctl('area').text = a.area;
              s.set('area', a.id);
            }),
        ],
        inp('العنوان', 'أقرب نقطة دالة', ctl: s.ctl('addr')),
        inp('ملاحظات', 'اختياري', ctl: s.ctl('notes')),
        Tn('طريقة الدفع', s: 13, c: MU),
        if (repo.payMethods.isEmpty) Tn('لا توجد طريقة دفع مفعّلة', s: 13, c: RD),
        for (final m in repo.payMethods) chip(m.$2, pay == m.$1, null, 13, () => s.set('pay', m.$1)),
        F([
          R([Tn('البضاعة', s: 13, c: MU), Tn('${fmt(repo.cartSubtotal)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          if (repo.cartDiscount > 0) R([Tn('قيمة الخصم', s: 13, c: MU), Tn('${fmt(repo.cartDiscount)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          R([Tn('التوصيل', s: 13, c: MU), Tn('${fmt(fee)} د.ع', s: 13, w: 700)], jc: 'sb', w: 'fill'),
          R([Tn('الإجمالي', s: 16, w: 800), Tn('${fmt(total)} د.ع', s: 16, w: 800, c: P)], jc: 'sb', w: 'fill'),
          Tn('الإجمالي النهائي يتأكد من الخادم وقت إنشاء الطلب.', s: 11, c: MU),
        ], g: 8, w: 'fill', p: 14, r: 16, bg: BG),
        btn('تأكيد الطلب', busy: busy, tap: busy ? null : () {
          s.set('busy', true);
          repo.checkout(name: s.ctl('name').text, phone: s.ctl('phone').text, governorate: s.ctl('gov').text, area: s.ctl('area').text, address: s.ctl('addr').text, notes: s.ctl('notes').text, payMethod: pay, idempotencyKey: s.get('key', '')).then((result) {
            final (order, err) = result;
            s.set('busy', false);
            if (!c.mounted) return;
            if (err != null || order == null) {
              toast(c, err ?? 'تعذر إكمال الطلب');
              return;
            }
            resetTo(c, OrderDone(order), anim: true);
          });
        }),
      ], g: 12, w: 'fill', p: [0, 20]),
    ]);
  }
}

class OrderDone extends Scr {
  final ShopOrder order;
  const OrderDone(this.order, {super.key});
  @override
  Widget view(c, s) => screen(c, [
    F([
      I('circle-check', 56, OK),
      Tn('تم استلام طلبك', s: 22, w: 800, al: 'CENTER'),
      Tn(order.number, s: 16, w: 700, c: P, al: 'CENTER'),
      Tn('${fmt(order.total)} د.ع · ${order.pay}', s: 14, c: MU, al: 'CENTER'),
      Tn(order.status, s: 13, al: 'CENTER'),
      btn('تفاصيل الطلب', kind: 's', tap: () => push(c, OrderPage(order.id))),
      btn('رجوع للرئيسية', tap: () => onCustomerTab(c, 'الرئيسية')),
    ], g: 12, al: 'c', w: 'fill', p: [80, 24]),
  ]);
}

class OrderPage extends Scr {
  final int id;
  const OrderPage(this.id, {super.key});
  @override
  void init(ScrSt s) => repo.loadOrders();
  @override
  Widget view(c, s) {
    final found = repo.shopOrders.where((o) => o.id == id);
    if (found.isEmpty) return screen(c, [topbar('الطلب'), Tn(repo.shopError ?? 'جاري تحميل الطلب...', s: 14, c: MU, al: 'CENTER')]);
    final o = found.first;
    final canCancel = o.status == 'بانتظار التأكيد';
    return screen(c, [
      topbar(o.number),
      F([
        tag(o.status, bg: PL, c: P),
        Tn('${o.name} · ${o.phone}', s: 14),
        Tn('${o.governorate} · ${o.area}', s: 13, c: MU),
        Tn(o.address, s: 13),
        for (final line in o.items) R([Tn('${line.name} × ${line.qty}', s: 14), Tn('${fmt(line.lineTotal)} د.ع', s: 14, w: 700)], jc: 'sb', w: 'fill'),
        R([Tn('الإجمالي', s: 16, w: 800), Tn('${fmt(o.total)} د.ع', s: 16, w: 800, c: P)], jc: 'sb', w: 'fill'),
        Tn(o.pay, s: 13, c: MU),
        Tn('سجل الحالة', s: 14, w: 800),
        for (final h in o.history) Tn('${h.$1} · ${h.$2}', s: 12, c: MU),
        if (canCancel) btn('إلغاء الطلب', kind: 'd', tap: () {
          repo.cancelOrder(o.id).then((err) {
            if (!c.mounted) return;
            toast(c, err ?? 'تم إلغاء الطلب');
            if (err == null) repo.loadOrders();
          });
        }),
      ], g: 10, w: 'fill', p: [8, 20]),
    ]);
  }
}
