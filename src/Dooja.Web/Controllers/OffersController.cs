using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class OffersController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index() => View(await db.Offers.AsNoTracking().Include(x => x.Place).ToListAsync());
    private async Task Places() => ViewBag.Places = new SelectList(await db.Places.ToListAsync(), "Id", "Name");
    [HttpGet] public async Task<IActionResult> Create() { await Places(); return View("Edit", new Offer()); }
    [HttpGet] public async Task<IActionResult> Edit(string id) { var o = await db.Offers.FindAsync(id); if (o == null) return NotFound(); await Places(); return View(o); }
    [HttpPost]
    public async Task<IActionResult> Save([Bind("Id,PlaceId,Title,Disc,NewPrice,OldPrice,ExpiryText,ExpiresOn,Active")] Offer input)
    {
        var p = await db.Places.FindAsync(input.PlaceId); if (p == null) ModelState.AddModelError("PlaceId", "اختر مكاناً صالحاً");
        if (input.NewPrice > input.OldPrice) ModelState.AddModelError("NewPrice", "السعر الجديد يجب ألا يتجاوز السعر السابق");
        if (!ModelState.IsValid) { await Places(); return View("Edit", input); }
        var o = await db.Offers.FindAsync(input.Id); if (o == null) { o = new Offer { Id = input.Id }; db.Offers.Add(o); }
        o.PlaceId = input.PlaceId; o.Title = input.Title; o.Disc = input.Disc; o.NewPrice = input.NewPrice; o.OldPrice = input.OldPrice; o.ExpiryText = input.ExpiryText; o.ExpiresOn = input.ExpiresOn; o.Active = input.Active; o.ImageKey = p!.ImageKey; o.Area = p.Area; o.Category = p.Category; await db.SaveChangesAsync(); TempData["Success"] = "تم حفظ العرض"; return RedirectToAction(nameof(Index));
    }
    [HttpPost] public async Task<IActionResult> Toggle(string id) { var o = await db.Offers.FindAsync(id); if (o == null) return NotFound(); o.Active = !o.Active; await db.SaveChangesAsync(); return RedirectToAction(nameof(Index)); }
}
