using Dooja.Web.Data;
using Dooja.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
public class UsersController(DoojaDb db) : DashboardControllerBase
{
    public async Task<IActionResult> Index(string? q) { ViewBag.Q = q; var us = db.Users.AsNoTracking(); if (!string.IsNullOrWhiteSpace(q)) us = us.Where(x => x.Name.Contains(q) || x.Phone.Contains(q)); return View(await us.OrderBy(x => x.Name).Take(300).ToListAsync()); }
    [HttpGet] public IActionResult Create() => View("Edit", new AppUser());
    [HttpGet] public async Task<IActionResult> Edit(int id) { var u = await db.Users.FindAsync(id); return u == null ? NotFound() : View(u); }
    [HttpPost]
    public async Task<IActionResult> Save([Bind("Id,Name,Phone,Role,Governorate,Area,Birth,Points,Active")] AppUser input)
    {
        var u = await db.Users.FindAsync(input.Id);
        if (u?.Role == "Admin") { TempData["Error"] = "حساب المدير محمي من التغيير هنا"; return RedirectToAction(nameof(Index)); }
        if (input.Role is not ("Customer" or "Owner")) ModelState.AddModelError("Role", "الدور غير صحيح");
        if (await db.Users.AnyAsync(x => x.Phone == input.Phone && x.Id != input.Id)) ModelState.AddModelError("Phone", "هذا الرقم مستخدم");
        if (input.Points < 0) ModelState.AddModelError("Points", "النقاط لا تكون سالبة");
        if (!ModelState.IsValid) return View("Edit", input); if (u == null) { u = new AppUser(); db.Users.Add(u); }
        u.Name = input.Name; u.Phone = input.Phone; u.Role = input.Role; u.Governorate = input.Governorate; u.Area = input.Area; u.Birth = input.Birth; u.Points = input.Points; u.Active = input.Active; await db.SaveChangesAsync(); TempData["Success"] = "تم حفظ المستخدم"; return RedirectToAction(nameof(Index));
    }
}
