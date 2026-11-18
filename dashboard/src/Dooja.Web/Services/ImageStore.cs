using Dooja.Web.Data;
using Dooja.Web.Models;

namespace Dooja.Web.Services;

/// Uploaded images live in the database, not on disk: the Render container's
/// disk is wiped on every deploy and restart, which made uploads vanish.
/// They are served from /media/{id}.{ext} by MediaController.
public static class ImageStore
{
    public const long MaxBytes = 4 * 1024 * 1024;

    public static async Task<(string? RelativePath, string? Error)> Save(DoojaDb db, IFormFile file)
    {
        if (file.Length <= 0 || file.Length > MaxBytes) return (null, "حجم الصورة يجب أن يكون أقل من 4 ميغابايت");
        await using var stream = file.OpenReadStream();
        using var buffer = new MemoryStream();
        await stream.CopyToAsync(buffer);
        var data = buffer.ToArray();
        var type = Sniff(data);
        if (type == null) return (null, "الصورة يجب أن تكون JPEG أو PNG أو WEBP");
        var row = new StoredFile { ContentType = type.Value.Mime, Data = data };
        db.StoredFiles.Add(row);
        return ($"/media/{row.Id:N}{type.Value.Ext}", null);
    }

    /// Removes a stored image. Paths that are not ours (seed images under
    /// /img, or old /uploads files that are already gone) are left alone.
    public static async Task Delete(DoojaDb db, string? relative)
    {
        if (TryId(relative) is not { } id) return;
        var row = await db.StoredFiles.FindAsync(id);
        if (row != null) db.StoredFiles.Remove(row);
    }

    public static Guid? TryId(string? relative)
    {
        if (string.IsNullOrWhiteSpace(relative) || !relative.StartsWith("/media/", StringComparison.Ordinal)) return null;
        var name = relative["/media/".Length..];
        var dot = name.IndexOf('.');
        return Guid.TryParseExact(dot < 0 ? name : name[..dot], "N", out var id) ? id : null;
    }

    static (string Ext, string Mime)? Sniff(ReadOnlySpan<byte> h)
    {
        if (h.Length >= 3 && h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF) return (".jpg", "image/jpeg");
        if (h.Length >= 8 && h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47) return (".png", "image/png");
        if (h.Length >= 12 && h[0] == (byte)'R' && h[1] == (byte)'I' && h[2] == (byte)'F' && h[3] == (byte)'F' && h[8] == (byte)'W' && h[9] == (byte)'E' && h[10] == (byte)'B' && h[11] == (byte)'P') return (".webp", "image/webp");
        return null;
    }
}
