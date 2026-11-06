using Dooja.Web.Models;
using Microsoft.EntityFrameworkCore;
namespace Dooja.Web.Data;
public class DoojaDb(DbContextOptions<DoojaDb> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>(); public DbSet<Place> Places => Set<Place>();
    public DbSet<Booking> Bookings => Set<Booking>(); public DbSet<Offer> Offers => Set<Offer>();
    public DbSet<Review> Reviews => Set<Review>(); public DbSet<Reel> Reels => Set<Reel>();
    public DbSet<ReelComment> ReelComments => Set<ReelComment>(); public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Follow> Follows => Set<Follow>(); public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<OwnerService> OwnerServices => Set<OwnerService>(); public DbSet<ClosedSlot> ClosedSlots => Set<ClosedSlot>();
    public DbSet<ReelLike> ReelLikes => Set<ReelLike>();
    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<AppUser>().HasIndex(x => x.Phone).IsUnique(); b.Entity<Booking>().HasIndex(x => x.Code).IsUnique();
        b.Entity<Review>().HasIndex(x => x.BookingId).IsUnique();
        b.Entity<Favorite>().HasKey(x => new { x.UserId, x.PlaceId }); b.Entity<Follow>().HasKey(x => new { x.UserId, x.PlaceId });
        b.Entity<ReelLike>().HasKey(x => new { x.UserId, x.ReelId });
        b.Entity<ClosedSlot>().HasIndex(x => new { x.PlaceId, x.Day, x.Time }).IsUnique();
        b.Entity<Booking>().HasIndex(x => new { x.PlaceId, x.Day, x.Time });
        foreach (var rel in b.Model.GetEntityTypes().SelectMany(x => x.GetForeignKeys())) rel.DeleteBehavior = DeleteBehavior.Restrict;
    }
}
