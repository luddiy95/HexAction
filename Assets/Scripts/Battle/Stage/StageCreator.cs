using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Project.Scripts.Battle.Stage
{
    public class StageCreator : MonoBehaviour
    {
        [SerializeField] private Grid gridPrefab;
        [SerializeField] private int radius;

        private readonly float diffX = Mathf.Sqrt(3) / 2f;
        private readonly float diffZ = 3f / 2f;

        private void Start()
        {
            createStage();
        }

        private void createStage()
        {
            List<Vector2> vertexList = new List<Vector2>();
            Vector3 towerPos = Vector3.zero;

            for (int rad = 0; rad <= radius; rad++)
            {
                vertexList.Clear();

                vertexList.Add(new Vector2(-1 * diffX * rad, diffZ * rad));
                vertexList.Add(new Vector2(-1 * diffX * rad * 2, 0));
                vertexList.Add(new Vector2(-1 * diffX * rad, -1 * diffZ * rad));
                vertexList.Add(new Vector2(diffX * rad, -1 * diffZ * rad));
                vertexList.Add(new Vector2(diffX * rad * 2, 0));
                vertexList.Add(new Vector2(diffX * rad, diffZ * rad));

                foreach (Vector2 pos2 in vertexList)
                {
                    towerPos = new Vector3(pos2.x, 0, pos2.y);
                    Grid grid = Instantiate(gridPrefab, transform);
                    grid.transform.position = towerPos;
                }
                Vector2 diffVec = Vector2.zero;
                List<Vector2> btwHexList = new List<Vector2>();
                for (int vt = 0; vt < 6; vt++)
                {
                    diffVec = (vertexList[(vt + 1) % 6] - vertexList[vt]) / rad;
                    for (int i = 1; i <= rad - 1; i++)
                    {
                        btwHexList.Add(vertexList[vt] + diffVec * i);
                    }
                }

                foreach (Vector2 pos2 in btwHexList)
                {
                    towerPos = new Vector3(pos2.x, 0, pos2.y);
                    Grid grid = Instantiate(gridPrefab, transform);
                    grid.transform.position = towerPos;
                }
            }
        }
    }
}