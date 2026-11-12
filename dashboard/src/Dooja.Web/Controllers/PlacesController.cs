using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class PlacesController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index(string? q, int? page, int? size)
    {
        if (Paging.Reject(page, size) is { } bad) return bad;
        var (p, s) = Paging.Normalize(page, size);
        ViewData["Q"] = q;
        var ps = db.Places.AsNoTracking().Include(x => x.OwnerUser).AsQueryable();
        if (!string.IsNullOrWhiteSpace(q)) ps = ps.Where(x => x.Name.Contains(q) || x.Area.Contains(q) || x.Category.Contains(q));
        var total = await ps.CountAsync();
        var bar = PageBar.Create(p, s, total);
        var items = await ps.OrderBy(x => x.Name).ThenBy(x => x.Id).Skip((bar.Page - 1) * s).Take(s).ToListAsync();
        return View(new PagedList<Place> { Items = items, Page = bar });
    }
    private async Task Owners() => ViewBag.Owners = new SelectList(await db.Users.Where(x => x.Role == "Owner" && x.Active).ToListAsync(), "Id", "Name");
    [HttpGet] public async Task<IActionResult> Create() { await Owners(); return View("Edit", new Place()); }
    [HttpGet] public async Task<IActionResult> Edit(string id) { var p = await db.Places.FindAsync(id); if (p == null) return NotFound(); await Owners(); return View(p); }
    [HttpPost]
    public async Task<IActionResult> Save([Bind("Id,Name,ImageKey,Type,Area,Dist,Price,Unit,Kind,Category,Phone,Featured,OwnerUserId,Active")] Place input)
    {
        if (!await db.Users.AnyAsync(x => x.Id == input.OwnerUserId && x.Role == "Owner")) ModelState.AddModelError("OwnerUserId", "اختر مالكاً صالحاً");
        if (!ModelState.IsValid) { await Owners(); return View("Edit", input); }
        var p = await db.Places.FindAsync(input.Id); if (p == null) { p = new Place { Id = input.Id }; db.Places.Add(p); }
        p.Name = input.Name; p.ImageKey = input.ImageKey; p.Type = input.Type; p.Area = input.Area; p.Dist = input.Dist; p.Price = input.Price; p.Unit = input.Unit; p.Kind = input.Kind; p.Category = input.Category; p.Phone = input.Phone; p.Featured = input.Featured; p.OwnerUserId = input.OwnerUserId; p.Active = input.Active; await db.SaveChangesAsync(); TempData["Success"] = "تم حفظ المكان"; return RedirectToAction(nameof(Index));
    }
}
