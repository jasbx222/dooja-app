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
        var today = BookingService.Today; var week = new List<DailyCount>(); for (int i = 6; i >= 0; i--) { var d = today.AddDays(-i); week.Add(new(d.ToString("MM-dd"), await db.Bookings.CountAsync(x => x.Day == d && x.Status != "ملغي"))); }
        return View(new DashboardVm(await db.Bookings.CountAsync(x => x.Day == today && x.Status != "ملغي"), await db.Bookings.Where(x => x.Day == today && (x.Arrived || x.Status == "مكتمل")).SumAsync(x => (long)x.Total), await db.Places.CountAsync(), await db.Users.CountAsync(), await db.Bookings.CountAsync(x => x.Status == "بانتظار القبول"), await db.Bookings.AsNoTracking().Include(x => x.Place).Include(x => x.User).OrderByDescending(x => x.Id).Take(6).ToListAsync(), await db.Places.AsNoTracking().OrderByDescending(x => x.Followers).Take(4).ToListAsync(), week));
    }
}
