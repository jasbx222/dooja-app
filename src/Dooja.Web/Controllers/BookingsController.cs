using Dooja.Web.Data;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class BookingsController(DoojaDb db, BookingService service) : DashboardControllerBase
{
    public async Task<IActionResult> Index(string? status, string? q) { ViewBag.Status = status; ViewBag.Q = q; var bs = db.Bookings.AsNoTracking().Include(x => x.Place).Include(x => x.User).AsQueryable(); if (!string.IsNullOrEmpty(status)) bs = bs.Where(x => x.Status == status); if (!string.IsNullOrEmpty(q)) bs = bs.Where(x => x.Code.Contains(q) || x.User!.Name.Contains(q) || x.Place!.Name.Contains(q)); return View(await bs.OrderByDescending(x => x.Id).Take(300).ToListAsync()); }
    [HttpPost] public async Task<IActionResult> Status(int id, string status) { var b = await db.Bookings.FindAsync(id); if (b == null) return NotFound(); var error = await service.SetStatus(b, status); TempData[error == null ? "Success" : "Error"] = error ?? "تم تحديث الحجز"; return RedirectToAction(nameof(Index)); }
    [HttpPost] public async Task<IActionResult> Arrive(int id) { var b = await db.Bookings.FindAsync(id); if (b == null) return NotFound(); if (b.Status == "مؤكد") { b.Arrived = true; await db.SaveChangesAsync(); TempData["Success"] = "تم تسجيل الوصول"; } else TempData["Error"] = "يجب تأكيد الحجز أولاً"; return RedirectToAction(nameof(Index)); }
}
