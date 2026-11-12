namespace Dooja.Web.Models;

public record DashboardVm(
    int TotalBookings,
    int TodayBookings,
    int TodayBookingDelta,
    int Pending,
    int Confirmed,
    int Completed,
    int Cancelled,
    int Places,
    int ActivePlaces,
    int ActiveOffers,
    int Offers,
    int Customers,
    int Users,
    long TodayIncome,
    long IncomeDelta,
    List<Booking> Recent,
    List<Place> Popular,
    List<DailyCount> Week,
    List<RevenueDay> Revenue,
    List<StatusCount> Statuses,
    List<ActivityRow> Activity);

public record DailyCount(string Label, int Count);
public record RevenueDay(string Label, long Amount);
public record StatusCount(string Status, int Count, string Tone);
public record ActivityRow(string When, string Icon, string Title, string Detail, string Href);
public record OpsAlertsVm(int Count, List<Booking> Items);

public sealed class PageBar
{
    public int Page { get; init; }
    public int Size { get; init; }
    public int Total { get; init; }
    public int Pages { get; init; }
    public int From { get; init; }
    public int To { get; init; }

    public static PageBar Create(int page, int size, int total)
    {
        var pages = Math.Max(1, (int)Math.Ceiling(total / (double)size));
        var current = total == 0 ? 1 : Math.Min(page, pages);
        var from = total == 0 ? 0 : (current - 1) * size + 1;
        var to = Math.Min(current * size, total);
        return new PageBar { Page = current, Size = size, Total = total, Pages = total == 0 ? 1 : pages, From = from, To = to };
    }
}

public sealed class PagedList<T>
{
    public required List<T> Items { get; init; }
    public required PageBar Page { get; init; }
}

public class LoginVm
{
    [System.ComponentModel.DataAnnotations.Required] public string Phone { get; set; } = "";
    [System.ComponentModel.DataAnnotations.Required, System.ComponentModel.DataAnnotations.DataType(System.ComponentModel.DataAnnotations.DataType.Password)] public string Password { get; set; } = "";
}
