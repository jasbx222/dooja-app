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
public class AuthController(DoojaDb db, LoginGuard guard) : Controller
{
    [HttpGet] public IActionResult Login() => View(new LoginVm());
    [HttpPost, EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginVm vm)
    {
        if (!ModelState.IsValid) return View(vm);
        var key = "admin:" + vm.Phone.Trim();
        if (guard.IsLocked(key)) { ModelState.AddModelError("", "محاولات كثيرة. حاول بعد 15 دقيقة"); return View(vm); }
        var u = await db.Users.FirstOrDefaultAsync(x => x.Phone == vm.Phone && x.Active);
        if (u?.PasswordHash == null || new PasswordHasher<AppUser>().VerifyHashedPassword(u, u.PasswordHash, vm.Password) == PasswordVerificationResult.Failed) { guard.Fail(key); ModelState.AddModelError("", "رقم الهاتف أو كلمة المرور غير صحيحة"); return View(vm); }
        // The password is right but the account is not an admin: say so instead
        // of "wrong password", so venue owners know to sign in from the app.
        if (u.Role != "Admin")
        {
            ModelState.AddModelError("", u.Role == "Owner"
                ? "هذا حساب صاحب مكان. لوحة التحكم للإدارة فقط، سجّل دخول من تطبيق ضوجة لإدارة مكانك وحجوزاتك"
                : "هذا الحساب ليس حساب إدارة. سجّل دخول من تطبيق ضوجة");
            return View(vm);
        }
        guard.Succeed(key);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(new ClaimsIdentity(TokenService.Claims(u), CookieAuthenticationDefaults.AuthenticationScheme))); return RedirectToAction("Index", "Home");
    }
    [HttpPost] public async Task<IActionResult> Logout() { await HttpContext.SignOutAsync(); return RedirectToAction(nameof(Login)); }
    public IActionResult Denied() => StatusCode(403, "غير مسموح");
}
