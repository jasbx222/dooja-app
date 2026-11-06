using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
namespace Dooja.Web.Models;
public class AppUser
{
    public int Id { get; set; }
    [Required, RegularExpression(@"07\d{9}")] public string Phone { get; set; } = "";
    [Required, StringLength(100)] public string Name { get; set; } = "";
    public string Role { get; set; } = "Customer";
    public string Governorate { get; set; } = "بغداد"; public string Area { get; set; } = "";
    public string Birth { get; set; } = ""; public int Points { get; set; }
    [JsonIgnore] public string? PasswordHash { get; set; }
    public bool Active { get; set; } = true;
}
public class Place
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    [Required, StringLength(150)] public string Name { get; set; } = "";
    public string ImageKey { get; set; } = "padel";
    [Required] public string Type { get; set; } = "";
    [Required] public string Area { get; set; } = "";
    public string Dist { get; set; } = ""; public double Rating { get; set; }
    public int ReviewCount { get; set; }
    [Range(0, 100000000)] public int Price { get; set; }
    public string Unit { get; set; } = "ساعة";
    [RegularExpression("open|slots|full")] public string Kind { get; set; } = "open";
    [Required] public string Category { get; set; } = "";
    public string Phone { get; set; } = ""; public bool Featured { get; set; }
    public int Followers { get; set; }
    public int OwnerUserId { get; set; }
    public AppUser? OwnerUser { get; set; }
    public bool Active { get; set; } = true;
}
public class Booking
{
    public string? OfferId { get; set; }
    public Offer? Offer { get; set; }
    public int Id { get; set; }
    public string Code { get; set; } = "DJ-" + Guid.NewGuid().ToString("N")[..10].ToUpperInvariant();
    public string PlaceId { get; set; } = ""; public Place? Place { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public DateOnly Day { get; set; }
    public string Time { get; set; } = "";
    public string Duration { get; set; } = "ساعة"; public int Hours { get; set; } = 1;
    public int People { get; set; }
    public int Total { get; set; }
    public string PayMethod { get; set; } = "كاش بالمكان";
    public string Status { get; set; } = "بانتظار القبول"; public bool Rated { get; set; }
    public bool Arrived { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
public class Offer
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    [Required] public string PlaceId { get; set; } = ""; public Place? Place { get; set; }
    public string ImageKey { get; set; } = "padel";
    [Required, StringLength(160)] public string Title { get; set; } = ""; public string Disc { get; set; } = "";
    [Range(0, 100000000)] public int NewPrice { get; set; }
    [Range(0, 100000000)] public int OldPrice { get; set; }
    public string ExpiryText { get; set; } = ""; public DateOnly? ExpiresOn { get; set; }
    public string Category { get; set; } = ""; public string Area { get; set; } = "";
    public int Views { get; set; }
    public int Clicks { get; set; }
    public int Books { get; set; }
    public bool Active { get; set; } = true;
}
public class Review
{
    public int Id { get; set; }
    public string PlaceId { get; set; } = ""; public Place? Place { get; set; }
    public int? UserId { get; set; }
    public AppUser? User { get; set; }
    public int? BookingId { get; set; }
    public Booking? Booking { get; set; }
    public string Name { get; set; } = ""; public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string Ago { get; set; } = "الآن";
    [Range(1, 5)] public int Stars { get; set; }
    [Required, StringLength(2000)] public string Text { get; set; } = "";
    public bool HasPhotos { get; set; }
    public string? Reply { get; set; }
}
public class Reel
{
    public int Id { get; set; }
    public string ImageKey { get; set; } = "";
    public string PlaceId { get; set; } = ""; public Place? Place { get; set; }
    public string Caption { get; set; } = ""; public string OfferText { get; set; } = ""; public int Likes { get; set; }
}
public class ReelComment
{
    public int Id { get; set; }
    public int ReelId { get; set; }
    public Reel? Reel { get; set; }
    public int? UserId { get; set; }
    public AppUser? User { get; set; }
    public string Name { get; set; } = ""; public string Text { get; set; } = ""; public int Likes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
public class Favorite { public int UserId { get; set; } public AppUser? User { get; set; } public string PlaceId { get; set; } = ""; public Place? Place { get; set; } }
public class Follow { public int UserId { get; set; } public AppUser? User { get; set; } public string PlaceId { get; set; } = ""; public Place? Place { get; set; } }
public class ReelLike { public int UserId { get; set; } public AppUser? User { get; set; } public int ReelId { get; set; } public Reel? Reel { get; set; } }
public class Notification
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public string Icon { get; set; } = "calendar-check"; public string Title { get; set; } = ""; public string Body { get; set; } = "";
    public bool Fresh { get; set; } = true; public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
public class OwnerService { public int Id { get; set; } public string PlaceId { get; set; } = ""; public Place? Place { get; set; } [Required] public string Name { get; set; } = ""; [Range(0, 100000000)] public int Price { get; set; } public string Unit { get; set; } = "ساعة"; }
public class ClosedSlot { public int Id { get; set; } public string PlaceId { get; set; } = ""; public Place? Place { get; set; } public DateOnly Day { get; set; } public string Time { get; set; } = ""; }
public static class BookingStates
{
    public static readonly string[] All = ["بانتظار القبول", "بالانتظار", "مؤكد", "مكتمل", "ملغي"];
    public static bool CanChange(string from, string to) => from == to || from switch { "بانتظار القبول" => to is "مؤكد" or "ملغي" or "بالانتظار", "بالانتظار" => to is "مؤكد" or "ملغي", "مؤكد" => to is "مكتمل" or "ملغي", _ => false };
}
