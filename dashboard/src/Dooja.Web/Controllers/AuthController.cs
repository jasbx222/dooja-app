using Dooja.Web.Data;
using Dooja.Web.Models;
using Dooja.Web.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers;
[AutoValidateAntiforgeryToken]
public class AuthController(DoojaDb db) : Controller
{
    [HttpGet] public IActionResult Login() => View(new LoginVm());
    [HttpPost, EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginVm vm)
    {
        if (!ModelState.IsValid) return View(vm);
        var u = await db.Users.FirstOrDefaultAsync(x => x.Phone == vm.Phone && x.Role == "Admin" && x.Active);
        if (u?.PasswordHash == null || new PasswordHasher<AppUser>().VerifyHashedPassword(u, u.PasswordHash, vm.Password) == PasswordVerificationResult.Failed) { ModelState.AddModelError("", "رقم الهاتف أو كلمة المرور غير صحيحة"); return View(vm); }
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(new ClaimsIdentity(TokenService.Claims(u), CookieAuthenticationDefaults.AuthenticationScheme))); return RedirectToAction("Index", "Home");
    }
    [HttpPost] public async Task<IActionResult> Logout() { await HttpContext.SignOutAsync(); return RedirectToAction(nameof(Login)); }
    public IActionResult Denied() => StatusCode(403, "غير مسموح");
}
