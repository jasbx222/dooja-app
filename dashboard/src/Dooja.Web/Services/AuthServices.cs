using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Dooja.Web.Models;
using Microsoft.IdentityModel.Tokens;
namespace Dooja.Web.Services;
public class TokenService(string key)
{
    public string Create(AppUser user) => new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken("Dooja", "Dooja.App", Claims(user), expires: DateTime.UtcNow.AddDays(7), signingCredentials: new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256)));
    public static Claim[] Claims(AppUser u) => [new(ClaimTypes.NameIdentifier, u.Id.ToString()), new(ClaimTypes.Name, u.Name), new(ClaimTypes.Role, u.Role)];
}
public class OtpStore
{
    private readonly ConcurrentDictionary<string, (DateTime Expires, int Attempts)> entries = new();
    public void Request(string phone) { foreach (var e in entries.Where(x => x.Value.Expires < DateTime.UtcNow)) entries.TryRemove(e.Key, out _); entries[phone] = (DateTime.UtcNow.AddMinutes(5), 0); }
    public bool Verify(string phone, string code) { lock (entries) { if (!entries.TryGetValue(phone, out var e) || e.Expires < DateTime.UtcNow || e.Attempts >= 5) return false; if (code != "1234") { entries[phone] = (e.Expires, e.Attempts + 1); return false; } entries.TryRemove(phone, out _); return true; } }
}
