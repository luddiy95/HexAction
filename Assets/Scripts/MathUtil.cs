using UnityEngine;

namespace Project.Scripts
{
    public class MathUtil : MonoBehaviour
    {
        private static Vector3 Hash(Vector3 pos, float voronoiOffset)
        {
            Vector3 dot = new Vector3(
                Vector3.Dot(pos, new Vector3(127.1f, 311.7f, 74.7f)),
                Vector3.Dot(pos, new Vector3(269.5f, 183.3f, 246.1f)),
                Vector3.Dot(pos, new Vector3(113.5f, 271.9f, 124.6f))
            );
            dot = Frac(new Vector3(Mathf.Sin(dot.x), Mathf.Sin(dot.y), Mathf.Sin(dot.z)) * 43758.5453123f);
            return Frac(new Vector3(
                Mathf.Sin(dot.y * voronoiOffset) * 0.5f + 0.5f,
                Mathf.Cos(dot.x * voronoiOffset) * 0.5f + 0.5f,
                Mathf.Sin(dot.z * voronoiOffset) * 0.5f + 0.5f
            ));
        }

        public static float Voronoi(Vector3 pos, float voronoiDensity, float voronoiOffset)
        {
            Vector3 p = Floor(pos * voronoiDensity);
            Vector3 f = Frac(pos * voronoiDensity);

            Vector2 res = new Vector2(100f, 0f);
            for (int k = -1; k <= 1; k++)
                for (int j = -1; j <= 1; j++)
                    for (int i = -1; i <= 1; i++)
                    {
                        Vector3 b = new Vector3(i, j, k);
                        Vector3 r = b - f + Hash(p + b, voronoiOffset);
                        float d = Vector3.Dot(r, r);

                        if (d < res.x) res = new Vector2(d, res.x);
                        else if (d < res.y) res.y = d;
                    }

            return Mathf.Sqrt(res.x);
        }

        public static Vector3 Floor(Vector3 vec)
        {
            return new Vector3(Mathf.Floor(vec.x), Mathf.Floor(vec.y), Mathf.Floor(vec.z));
        }

        public static float Frac(float value)
        {
            return value - Mathf.FloorToInt(value);
        }

        public static Vector3 Frac(Vector3 vec)
        {
            return new Vector3(Frac(vec.x), Frac(vec.y), Frac(vec.z));
        }

        public static Vector3 Multiply(Vector3 x, Vector3 y)
        {
            return new Vector3(x.x * y.x, x.y * y.y, x.z * y.z);
        }

        public static Vector3 Divide(Vector3 x, Vector3 y)
        {
            return new Vector3(x.x / y.x, x.y / y.y, x.z / y.z);
        }

        public static float RandomEuler => Random.Range(-180f, 180f);
    }
}
