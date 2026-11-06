namespace Dooja.Web.Models;
public record DashboardVm(int TodayBookings, long TodayIncome, int Places, int Users, int Pending, List<Booking> Recent, List<Place> Popular, List<DailyCount> Week);
public record DailyCount(string Label, int Count);
public class LoginVm
{
    [System.ComponentModel.DataAnnotations.Required] public string Phone { get; set; } = "";
    [System.ComponentModel.DataAnnotations.Required, System.ComponentModel.DataAnnotations.DataType(System.ComponentModel.DataAnnotations.DataType.Password)] public string Password { get; set; } = "";
}
