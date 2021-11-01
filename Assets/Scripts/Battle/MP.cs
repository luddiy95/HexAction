
namespace Project.Scripts.Battle
{
    public class MP : Gauge
    {
        public static MP operator +(MP mp, int amount)
        {
            mp.amount += amount;
            return mp;
        }

        public static MP operator -(MP mp, int amount)
        {
            mp.amount -= amount;
            return mp;
        }
    }
}
