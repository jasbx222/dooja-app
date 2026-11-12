using System.ComponentModel.DataAnnotations;
using Dooja.Web.Data;
using Dooja.Web.Models;
using Dooja.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Controllers.Api;
[Route("api/auth")]
public class AuthController(DoojaDb db, OtpStore otp, TokenService tokens, ISmsSender sms, IWebHostEnvironment env) : ApiBase(db)
{
    public record PhoneRequest([Required, RegularExpression(@"07\d{9}")] string Phone);
    public record VerifyRequest([Required, RegularExpression(@"07\d{9}")] string Phone, [Required] string Code);
    static bool IsDemoPhone(string phone) => phone is "07700000000" or "07700000001" or "07700000002" or "07700000003" or "07700000004" or "07700000005" or "07700000006";
    static string ToE164(string phone) => "+964" + phone[1..];
    [HttpPost("request-otp"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> RequestOtp(PhoneRequest input, CancellationToken cancellationToken)
    {
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
        if (!env.IsDevelopment() && IsDemoPhone(input.Phone)) return StatusCode(403, new { error = "هذا الرقم مخصص للتطوير" });
        if (!sms.IsConfigured && !env.IsDevelopment()) return StatusCode(503, new { error = "إنشاء الحساب وتسجيل الدخول بالرمز متوقف مؤقتاً" });
        if (!otp.Verify(input.Phone, input.Code)) return BadRequest(new { error = "الرمز غير صحيح أو منتهي" });
        var u = await Db.Users.FirstOrDefaultAsync(x => x.Phone == input.Phone);
        if (u == null) { u = new AppUser { Phone = input.Phone, Name = "مستخدم جديد" }; Db.Users.Add(u); await Db.SaveChangesAsync(); }
        if (!u.Active || u.Role == "Admin") return Unauthorized(); return Ok(new { token = tokens.Create(u), role = u.Role, user = u });
    }
    [HttpGet("me")] public async Task<IActionResult> Me() => Ok(await Db.Users.FindAsync(UserId));
    public record Profile([Required, StringLength(100)] string Name, [StringLength(100)] string Governorate, [StringLength(100)] string Area, [StringLength(40)] string Birth);
    [HttpPut("me")] public async Task<IActionResult> Update(Profile input) { var u = (await Db.Users.FindAsync(UserId))!; u.Name = input.Name; u.Governorate = input.Governorate; u.Area = input.Area; u.Birth = input.Birth; await Db.SaveChangesAsync(); return Ok(u); }
}
