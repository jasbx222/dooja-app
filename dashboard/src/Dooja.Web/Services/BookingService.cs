using Dooja.Web.Models;
using Dooja.Web.Data;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Services;
public class BookingService(DoojaDb db)
{
    public static DateOnly Today => DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "Asia/Baghdad"));
    public async Task<(Booking? Booking, string? Error)> Create(int userId, string placeId, DateOnly day, string time, int hours, int people, string pay, bool wait, string? offerId = null)
    {
        if (day < Today || day > Today.AddYears(1) || hours < 1 || hours > 12 || people < 1 || people > 100 || !TimeOnly.TryParseExact(time, "HH:mm", out var start) || start.Hour + hours > 24) return (null, "تفاصيل الحجز غير صحيحة، الوقت بصيغة HH:mm والتاريخ YYYY-MM-DD");
        if (pay is not ("كاش بالمكان" or "زين كاش" or "بطاقة")) return (null, "طريقة الدفع غير مدعومة");
        await using var tx = await db.Database.BeginTransactionAsync();
        var p = await db.Places.FirstOrDefaultAsync(x => x.Id == placeId && x.Active);
        if (p == null) return (null, "المكان غير موجود");
        var closed = await db.ClosedSlots.Where(x => x.PlaceId == placeId && x.Day == day).ToListAsync();
        bool overlap(string t, int h) => TimeOnly.TryParseExact(t, "HH:mm", out var s) && s.ToTimeSpan().TotalHours < start.ToTimeSpan().TotalHours + hours && start.ToTimeSpan().TotalHours < s.ToTimeSpan().TotalHours + h;
        if (closed.Any(x => overlap(x.Time, 1))) return (null, "هذا الوقت مغلق");
        var existing = await db.Bookings.Where(x => x.PlaceId == placeId && x.Day == day && (x.Status == "مؤكد" || x.Status == "بانتظار القبول")).ToListAsync();
        if ((p.Kind == "full" || existing.Any(x => overlap(x.Time, x.Hours))) && !wait) return (null, "الوقت محجوز، يمكنك الدخول بقائمة الانتظار");
        // Price and ownership always come from the server, never from a client-provided total.
        Offer? offer = null;
        if (offerId != null) { offer = await db.Offers.FirstOrDefaultAsync(x => x.Id == offerId && x.PlaceId == placeId && x.Active && (!x.ExpiresOn.HasValue || x.ExpiresOn >= Today)); if (offer == null) return (null, "العرض غير متاح لهذا المكان"); }
        var price = offer?.NewPrice ?? p.Price;
        var b = new Booking { OfferId = offerId, UserId = userId, PlaceId = p.Id, Day = day, Time = time, Hours = hours, Duration = hours + " ساعة", People = people, Total = checked(price * (p.Unit == "ساعة" ? hours : people)), PayMethod = pay, Status = wait ? "بالانتظار" : "بانتظار القبول" };
        if (offer != null) offer.Books++;
        db.Bookings.Add(b); db.Notifications.Add(new Notification { UserId = userId, Title = wait ? "سجّلناك بالانتظار" : "تم إرسال طلب الحجز", Body = p.Name + " · " + day + " " + time });
        db.Notifications.Add(new Notification { UserId = p.OwnerUserId, Title = "طلب حجز جديد", Body = p.Name + " · " + day + " " + time });
        await db.SaveChangesAsync(); await tx.CommitAsync(); return (b, null);
    }
    public async Task<string?> SetStatus(Booking b, string status)
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        if (!BookingStates.All.Contains(status) || !BookingStates.CanChange(b.Status, status)) return "لا يمكن تغيير حالة هذا الحجز";
        if (b.Status == status) return null;
        if (status == "مؤكد")
        {
            var others = await db.Bookings.Where(x => x.Id != b.Id && x.PlaceId == b.PlaceId && x.Day == b.Day && x.Status == "مؤكد").ToListAsync();
            if (TimeOnly.TryParseExact(b.Time, "HH:mm", out var t) && others.Any(x => TimeOnly.TryParseExact(x.Time, "HH:mm", out var s) && s.ToTimeSpan().TotalHours < t.ToTimeSpan().TotalHours + b.Hours && t.ToTimeSpan().TotalHours < s.ToTimeSpan().TotalHours + x.Hours)) return "يوجد حجز مؤكد بنفس الوقت";
        }
        b.Status = status; db.Notifications.Add(new Notification { UserId = b.UserId, Title = "تحديث حجزك " + b.Code, Body = status }); await db.SaveChangesAsync(); await tx.CommitAsync(); return null;
    }
}
