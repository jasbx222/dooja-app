using Dooja.Web.Data;
using Dooja.Web.Models;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Dooja.Web.Controllers;

public class HomeController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index()
    {
        var today = BookingService.Today;
        var start = today.AddDays(-6);
        var statusRows = await db.Bookings.AsNoTracking()
            .GroupBy(x => x.Status)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToListAsync();
        int Of(string status) => statusRows.FirstOrDefault(x => x.Key == status)?.Count ?? 0;

        var weekRows = await db.Bookings.AsNoTracking()
            .Where(x => x.Day >= start && x.Day <= today)
            .Select(x => new { x.Day, x.Status, x.Total, x.Arrived })
            .ToListAsync();

        var week = new List<DailyCount>();
        var revenue = new List<RevenueDay>();
        for (var i = 6; i >= 0; i--)
        {
            var day = today.AddDays(-i);
            var rows = weekRows.Where(x => x.Day == day).ToList();
            week.Add(new DailyCount(day.ToString("MM-dd"), rows.Count(x => x.Status != "ملغي")));
            revenue.Add(new RevenueDay(day.ToString("MM-dd"), rows.Where(x => x.Arrived || x.Status == "مكتمل").Sum(x => (long)x.Total)));
        }

        var statuses = BookingStates.All
            .Select(s => new StatusCount(s, Of(s), Tone(s)))
            .ToList();
        foreach (var extra in statusRows.Where(x => !BookingStates.All.Contains(x.Key)))
            statuses.Add(new StatusCount(extra.Key, extra.Count, "muted"));

        var recent = await db.Bookings.AsNoTracking()
            .Include(x => x.Place)
            .Include(x => x.User)
            .OrderByDescending(x => x.Id)
            .Take(8)
            .ToListAsync();
        var reviews = await db.Reviews.AsNoTracking()
            .Include(x => x.Place)
            .OrderByDescending(x => x.Id)
            .Take(5)
            .ToListAsync();
        var activity = recent.Select(b => new ActivityRow(
                When(b.CreatedAt),
                "calendar-check",
                "حجز " + b.Code,
                $"{b.Place?.Name} · {b.User?.Name} · {b.Status}",
                "/Bookings?q=" + Uri.EscapeDataString(b.Code)))
            .Concat(reviews.Select(r => new ActivityRow(
                When(r.CreatedAt),
                "star",
                "تقييم " + r.Name,
                $"{r.Place?.Name} · {r.Stars} من 5",
                "/Reviews")))
            .OrderByDescending(x => x.When)
            .Take(6)
            .ToList();

        var todayBookings = week[^1].Count;
        var yesterdayBookings = week[^2].Count;
        var todayIncome = revenue[^1].Amount;
        var yesterdayIncome = revenue[^2].Amount;

        return View(new DashboardVm(
            await db.Bookings.CountAsync(),
            todayBookings,
            todayBookings - yesterdayBookings,
            Of("بانتظار القبول"),
            Of("مؤكد"),
            Of("مكتمل"),
            Of("ملغي"),
            await db.Places.CountAsync(),
            await db.Places.CountAsync(x => x.Active),
            await db.Offers.CountAsync(x => x.Active),
            await db.Offers.CountAsync(),
            await db.Users.CountAsync(x => x.Role == "Customer"),
            await db.Users.CountAsync(),
            todayIncome,
            todayIncome - yesterdayIncome,
            recent,
            await db.Places.AsNoTracking().OrderByDescending(x => x.Followers).ThenBy(x => x.Name).Take(5).ToListAsync(),
            week,
            revenue,
            statuses,
            activity));
    }

    private static string Tone(string status) => status switch
    {
        "مؤكد" => "ok",
        "مكتمل" => "info",
        "ملغي" => "bad",
        "بالانتظار" => "muted",
        _ => "warn"
    };

    private static string When(DateTime value)
    {
        var utc = value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };
        var local = TimeZoneInfo.ConvertTimeFromUtc(utc, TimeZoneInfo.FindSystemTimeZoneById("Asia/Baghdad"));
        return local.ToString("yyyy-MM-dd HH:mm");
    }
}
