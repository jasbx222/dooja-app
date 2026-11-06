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
public class AuthController(DoojaDb db, OtpStore otp, TokenService tokens, IWebHostEnvironment env) : ApiBase(db)
{
    public record PhoneRequest([Required, RegularExpression(@"07\d{9}")] string Phone);
    public record VerifyRequest([Required, RegularExpression(@"07\d{9}")] string Phone, [Required] string Code);
    [HttpPost("request-otp"), AllowAnonymous, EnableRateLimiting("auth")]
    public IActionResult RequestOtp(PhoneRequest input) { if (!env.IsDevelopment()) return StatusCode(503, new { error = "SMS provider is not configured. Development OTP is disabled." }); otp.Request(input.Phone); return Ok(new { message = "رمز التطوير 1234", expiresIn = 300 }); }
    [HttpPost("verify"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Verify(VerifyRequest input)
    {
        if (!env.IsDevelopment()) return StatusCode(503, new { error = "SMS provider is not configured" });
        if (!otp.Verify(input.Phone, input.Code)) return BadRequest(new { error = "الرمز غير صحيح أو منتهي" });
        var u = await Db.Users.FirstOrDefaultAsync(x => x.Phone == input.Phone);
        if (u == null) { u = new AppUser { Phone = input.Phone, Name = "مستخدم جديد" }; Db.Users.Add(u); await Db.SaveChangesAsync(); }
        if (!u.Active || u.Role == "Admin") return Unauthorized(); return Ok(new { token = tokens.Create(u), role = u.Role, user = u });
    }
    [HttpGet("me")] public async Task<IActionResult> Me() => Ok(await Db.Users.FindAsync(UserId));
    public record Profile([Required, StringLength(100)] string Name, [StringLength(100)] string Governorate, [StringLength(100)] string Area, [StringLength(40)] string Birth);
    [HttpPut("me")] public async Task<IActionResult> Update(Profile input) { var u = (await Db.Users.FindAsync(UserId))!; u.Name = input.Name; u.Governorate = input.Governorate; u.Area = input.Area; u.Birth = input.Birth; await Db.SaveChangesAsync(); return Ok(u); }
}
