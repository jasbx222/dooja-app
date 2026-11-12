using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Dooja.Web.Models;
using Microsoft.IdentityModel.Tokens;
namespace Dooja.Web.Services;
public class TokenService(string key)
{
    public string Create(AppUser user) => new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken("Dooja", "Dooja.App", Claims(user), expires: DateTime.UtcNow.AddDays(7), signingCredentials: new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256)));
    public static Claim[] Claims(AppUser u) => [new(ClaimTypes.NameIdentifier, u.Id.ToString()), new(ClaimTypes.Name, u.Name), new(ClaimTypes.Role, u.Role)];
}
public sealed class OtpStore
{
    private readonly record struct Entry(string CodeHash, DateTime Expires, DateTime ResendAfter, int Attempts);
    private readonly ConcurrentDictionary<string, Entry> entries = new();
    public bool TryIssue(string phone, string code, TimeSpan lifetime, TimeSpan cooldown)
    {
        lock (entries)
        {
            var now = DateTime.UtcNow;
            foreach (var key in entries.Where(x => x.Value.Expires <= now).Select(x => x.Key).ToArray()) entries.TryRemove(key, out _);
            if (entries.TryGetValue(phone, out var current) && current.ResendAfter > now) return false;
            entries[phone] = new Entry(Hash(phone, code), now.Add(lifetime), now.Add(cooldown), 0);
            return true;
        }
    }
    public void Cancel(string phone) { lock (entries) entries.TryRemove(phone, out _); }
    public bool Verify(string phone, string code)
    {
        lock (entries)
        {
            if (!entries.TryGetValue(phone, out var entry) || entry.Expires < DateTime.UtcNow || entry.Attempts >= 5) return false;
            var actual = Convert.FromHexString(entry.CodeHash);
            var given = Convert.FromHexString(Hash(phone, code));
            if (!CryptographicOperations.FixedTimeEquals(actual, given)) { entries[phone] = entry with { Attempts = entry.Attempts + 1 }; return false; }
            entries.TryRemove(phone, out _);
            return true;
        }
    }
    static string Hash(string phone, string code) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{phone}:{code}")));
}
