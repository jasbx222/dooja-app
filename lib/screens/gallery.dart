import 'package:flutter/material.dart';
import '../dsl.dart';
import '../common.dart';
import '../app.dart';
import '../repo.dart';
import 'auth.dart';
import 'home.dart';
import 'place.dart';
import 'flow.dart';
import 'more.dart';
import 'owner.dart';

class Gallery extends Scr {
  const Gallery({super.key});
  @override
  Widget view(c, s) {
    final items = galleryItems();
    return screen(c, [
      topbar('كل الشاشات', sub: '${items.length} شاشة'),
      F([R([for (final it in items) F([Tn(it.$1, s: 13, w: 700, al: 'CENTER')], al: 'c', jc: 'c', w: 168, h: 52, r: 14, bg: G, tap: () => push(c, it.$2()))], g: 14, wrap: true, w: 'fill')], w: 'fill', p: [4, 20]),
    ]);
  }
}

List<(String, Widget Function())> galleryItems() {
    final b = repo.bookings.first;
    return <(String, Widget Function())>[
      ('سبلاش', () => const Splash()), ('التعريف', () => const Onboard()), ('تسجيل الدخول', () => const Login()), ('رمز التحقق', () => Otp(Repo.demoCustomer)),
      ('المحافظة', () => const Gov()), ('الاهتمامات', () => const Interests()), ('الرئيسية', () => const Home()), ('البحث', () => const Search(q: 'ملعب بادل')), ('الخريطة', () => MapView()),
      ('قسم', () => const Category('بادل')), ('تفاصيل مكان', () => const Details('p1')), ('التقييمات', () => const Reviews('p1')),
      ('اختارلي', () => const PickQ()), ('نتائج اختارلي', () => const PickRes()), ('اختارلي فارغ', () => const PickEmpty()),
      ('اختيار موعد', () => const BookSlot('p1')), ('الفلاتر', () => AutoOpen(const Search(q: 'ملعب بادل'), (c) => filtersSheet(c, Filt()..type = 'بادل'..minBudget = 13750..maxBudget = 32250..dist = '5 كم'..avail = 'تتوفر مواعيد الآن'..minRate = 4.5, () {}))),
      ('الدفع', () => BookPay(Draft('p1'))), ('تم الحجز', () => BookDone(b, 'كاش', Draft('p1'))), ('التعليقات', () => AutoOpen(const Reels(), (c) => commentsSheet(c, repo.reels.first))),
      ('الإبلاغ', () => AutoOpen(const Reels(), (c) => reportSheet(c))), ('حالة: تحميل', () => const LoadingDemo()), ('المفضلة فارغة', () => const Favs(empty: true)),
      ('مالك: رفض بسبب', () => AutoOpen(const OBookings(), (c) => rejectSheet(c, repo.ownerReqs.first))), ('مالك: قائمة النشر', () => AutoOpen(const OwnerHome(), (c) => postSheet(c))), ('قائمة الانتظار', () => const Waitlist('p5')), ('خطأ دفع', () => const ErrorBook()),
      ('حجوزاتي', () => const Bookings()), ('تفاصيل حجز', () => BookingDetail(b)), ('تقييم', () => Rate(b)), ('العروض', () => const Offers()), ('تفاصيل عرض', () => OfferDetail(repo.offers.first)),
      ('ريلز', () => const Reels()), ('المفضلة', () => const Favs()), ('المكافآت', () => const Rewards()), ('الإشعارات', () => const Notifs()), ('طلعة جماعية', () => Group(b)),
      ('حسابي', () => const Profile()), ('تعديل الحساب', () => const Edit()), ('الإعدادات', () => const Settings()), ('بدون إنترنت', () => const Offline()),
      ('مالك: تعريف', () => const OIntro()), ('مالك: معلومات', () => const OInfo()), ('مالك: موقع', () => const OLoc()), ('مالك: دوام', () => const OHours()), ('مالك: صور', () => const OMedia()),
      ('مالك: خدمات', () => const OServices()), ('مالك: مراجعة', () => const OPending()), ('مالك: الرئيسية', () => const OwnerHome()), ('مالك: إحصائيات', () => const OInsights()),
      ('مالك: أداء العروض', () => const OOffPerf()), ('مالك: إشعارات', () => const Notifs(owner: true)), ('مالك: حجوزات', () => const OBookings()), ('مالك: مسح QR', () => const OScan()),
      ('مالك: المواعيد', () => const OCal()), ('مالك: عرض جديد', () => const OOffer()), ('مالك: ريل', () => const OReel()), ('مالك: مشروعي', () => const OProject()),
      ('مالك: تعديل خدمة', () => const OEdit(0)), ('مالك: التقييمات', () => const OReviews()), ('مالك: الموظفين', () => const OStaff()),
    ];
}

class AutoOpen extends StatefulWidget {
  final Widget base;
  final void Function(BuildContext) open;
  const AutoOpen(this.base, this.open, {super.key});
  @override
  State<AutoOpen> createState() => _AutoOpenSt();
}

class _AutoOpenSt extends State<AutoOpen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) widget.open(context); });
  }
  @override
  Widget build(BuildContext context) => widget.base;
}

class LoadingDemo extends StatelessWidget {
  const LoadingDemo({super.key});
  @override
  Widget build(BuildContext context) => loadingView(context);
}
