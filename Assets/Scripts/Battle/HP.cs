
namespace Project.Scripts.Battle
{
    public class HP : Gauge
    {
        public static HP operator +(HP hp, int amount)
        {
            hp.amount += amount;
            return hp;
        }

        public static HP operator -(HP hp, int amount)
        {
            hp.amount -= amount;
            return hp;
        }
    }
}
