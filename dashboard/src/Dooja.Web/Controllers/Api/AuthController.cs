using System.ComponentModel.DataAnnotations;
using Dooja.Web.Data;
using Dooja.Web.Models;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/auth")]
public class AuthController(DoojaDb db, OtpStore otp, TokenService tokens, ISmsSender sms, IWebHostEnvironment env, IConfiguration config, LoginGuard guard) : ApiBase(db)
{
    static readonly PasswordHasher<AppUser> Passwords = new();
    public record PhoneRequest([Required, RegularExpression(@"07\d{9}")] string Phone);
    public record VerifyRequest([Required, RegularExpression(@"07\d{9}")] string Phone, [Required] string Code);
    public record RegisterRequest([Required, StringLength(100, MinimumLength = 2)] string Name, [Required, RegularExpression(@"07\d{9}")] string Phone, [Required, StringLength(100, MinimumLength = 6)] string Password);
    public record PasswordLoginRequest([Required, RegularExpression(@"07\d{9}")] string Phone, [Required] string Password);
    static bool IsDemoPhone(string phone) => phone is "07700000000" or "07700000001" or "07700000002" or "07700000003" or "07700000004" or "07700000005" or "07700000006";
    static string ToE164(string phone) => "+964" + phone[1..];
    bool SmsEnabled => config.GetValue("Auth:EnableSms", false);
    IActionResult AuthResult(AppUser u) => Ok(new { token = tokens.Create(u), role = u.Role, user = u });
    static bool PasswordOk(AppUser u, string password) =>
        u.PasswordHash != null && Passwords.VerifyHashedPassword(u, u.PasswordHash, password) != PasswordVerificationResult.Failed;

    [HttpPost("register"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Register(RegisterRequest input)
    {
        var name = input.Name.Trim();
        if (name.Length < 2) return BadRequest(new { error = "اكتب اسمك" });
        if (input.Password.Length < 6) return BadRequest(new { error = "كلمة السر لازم تكون 6 حروف أو أكثر" });
        var u = await Db.Users.FirstOrDefaultAsync(x => x.Phone == input.Phone);
        // Never let a stranger claim an existing account by registering its
        // number, even one that has no password yet (e.g. created by an admin).
        if (u != null) return Conflict(new { error = u.PasswordHash != null
            ? "هذا الرقم مسجل مسبقاً. سجّل دخول بكلمة السر"
            : "هذا الرقم مسجل مسبقاً. تواصل مع إدارة ضوجة حتى تعيّن كلمة السر" });
        u = new AppUser { Phone = input.Phone, Name = name, Role = "Customer" };
        u.PasswordHash = Passwords.HashPassword(u, input.Password);
        Db.Users.Add(u);
        await Db.SaveChangesAsync();
        return AuthResult(u);
    }

    [HttpPost("login"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(PasswordLoginRequest input)
    {
        var key = "app:" + input.Phone;
        if (guard.IsLocked(key)) return StatusCode(429, new { error = "محاولات كثيرة. حاول بعد 15 دقيقة" });
        var u = await Db.Users.FirstOrDefaultAsync(x => x.Phone == input.Phone);
        if (u == null || !u.Active || u.Role == "Admin" || !PasswordOk(u, input.Password))
        {
            guard.Fail(key);
            return Unauthorized(new { error = u is { PasswordHash: null, Active: true } && u.Role != "Admin"
                ? "هذا الحساب ما عنده كلمة سر بعد. تواصل مع إدارة ضوجة"
                : "رقم الهاتف أو كلمة السر غير صحيحة" });
        }
        guard.Succeed(key);
        return AuthResult(u);
    }

    [HttpPost("request-otp"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> RequestOtp(PhoneRequest input, CancellationToken cancellationToken)
    {
        if (!SmsEnabled) return StatusCode(503, new { error = "الدخول بالرمز متوقف حالياً. استخدم رقم الهاتف وكلمة السر" });
        if (!env.IsDevelopment() && IsDemoPhone(input.Phone)) return StatusCode(403, new { error = "هذا الرقم مخصص للتطوير" });
        if (!sms.IsConfigured && !env.IsDevelopment()) return StatusCode(503, new { error = "إنشاء الحساب وتسجيل الدخول بالرمز متوقف مؤقتاً" });
        var code = sms.IsConfigured ? System.Security.Cryptography.RandomNumberGenerator.GetInt32(0, 1000000).ToString("D6") : "1234";
        if (!otp.TryIssue(input.Phone, code, TimeSpan.FromMinutes(5), TimeSpan.FromSeconds(60))) return StatusCode(429, new { error = "انتظر دقيقة قبل طلب رمز جديد" });
        if (!sms.IsConfigured) return Ok(new { message = "رمز التطوير 1234", expiresIn = 300 });
        try { await sms.SendAsync(ToE164(input.Phone), "رمز دخول ضوجة: " + code, cancellationToken); }
        catch (Exception ex) when (ex is HttpRequestException or InvalidOperationException or TaskCanceledException) { otp.Cancel(input.Phone); return StatusCode(503, new { error = "تعذر إرسال الرسالة. حاول بعد قليل" }); }
        return Ok(new { message = "تم إرسال الرمز", expiresIn = 300 });
    }
    [HttpPost("verify"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Verify(VerifyRequest input)
    {
        if (!SmsEnabled) return StatusCode(503, new { error = "الدخول بالرمز متوقف حالياً. استخدم رقم الهاتف وكلمة السر" });
        if (!env.IsDevelopment() && IsDemoPhone(input.Phone)) return StatusCode(403, new { error = "هذا الرقم مخصص للتطوير" });
        if (!sms.IsConfigured && !env.IsDevelopment()) return StatusCode(503, new { error = "إنشاء الحساب وتسجيل الدخول بالرمز متوقف مؤقتاً" });
        if (!otp.Verify(input.Phone, input.Code)) return BadRequest(new { error = "الرمز غير صحيح أو منتهي" });
        var u = await Db.Users.FirstOrDefaultAsync(x => x.Phone == input.Phone);
        if (u == null) { u = new AppUser { Phone = input.Phone, Name = "مستخدم جديد" }; Db.Users.Add(u); await Db.SaveChangesAsync(); }
        if (!u.Active || u.Role == "Admin") return Unauthorized(); return AuthResult(u);
    }
    [HttpGet("me")] public async Task<IActionResult> Me() => Ok(await Db.Users.FindAsync(UserId));

    /// Deletes the caller's account (required by the app stores). Personal data
    /// and the password are wiped and the account is closed; bookings and
    /// orders stay as anonymous history for the venues and the store.
    [HttpDelete("me")]
    public async Task<IActionResult> DeleteMe()
    {
        var u = await Db.Users.FindAsync(UserId);
        if (u == null) return NotFound();
        if (u.Role == "Admin") return Forbid();
        await using var tx = await Db.Database.BeginTransactionAsync();
        var today = BookingService.Today;
        var upcoming = await Db.Bookings.Include(x => x.Place)
            .Where(x => x.UserId == u.Id && x.Day >= today && (x.Status == "بانتظار القبول" || x.Status == "بالانتظار" || x.Status == "مؤكد"))
            .ToListAsync();
        foreach (var b in upcoming)
        {
            b.Status = "ملغي";
            if (b.Place != null) Db.Notifications.Add(new Notification { UserId = b.Place.OwnerUserId, Title = "انلغى حجز " + b.Code, Body = "صاحب الحجز حذف حسابه" });
        }
        if (u.Role == "Owner")
            await Db.Places.Where(x => x.OwnerUserId == u.Id).ExecuteUpdateAsync(s => s.SetProperty(x => x.Active, false));
        foreach (var f in await Db.Follows.Where(x => x.UserId == u.Id).Include(x => x.Place).ToListAsync())
            if (f.Place != null) f.Place.Followers = Math.Max(0, f.Place.Followers - 1);
        await Db.Follows.Where(x => x.UserId == u.Id).ExecuteDeleteAsync();
        await Db.Favorites.Where(x => x.UserId == u.Id).ExecuteDeleteAsync();
        await Db.Notifications.Where(x => x.UserId == u.Id).ExecuteDeleteAsync();
        await Db.CartItems.Where(x => x.Cart!.UserId == u.Id).ExecuteDeleteAsync();
        await Db.Carts.Where(x => x.UserId == u.Id).ExecuteDeleteAsync();
        u.Active = false;
        u.PasswordHash = null;
        u.Name = "حساب محذوف";
        u.Phone = "deleted-" + u.Id;
        u.Governorate = ""; u.Area = ""; u.Birth = ""; u.Points = 0;
        await Db.SaveChangesAsync();
        await tx.CommitAsync();
        return NoContent();
    }
    public record Profile([Required, StringLength(100)] string Name, [StringLength(100)] string Governorate, [StringLength(100)] string Area, [StringLength(40)] string Birth);
    [HttpPut("me")] public async Task<IActionResult> Update(Profile input) { var u = (await Db.Users.FindAsync(UserId))!; u.Name = input.Name; u.Governorate = input.Governorate; u.Area = input.Area; u.Birth = input.Birth; await Db.SaveChangesAsync(); return Ok(u); }
}
