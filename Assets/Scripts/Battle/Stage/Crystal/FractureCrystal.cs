using System.Collections.Generic;
using UnityEngine;
using System.Linq;

namespace Project.Scripts.Battle.Stage.Crystal
{
    public class FractureCrystal : MonoBehaviour
    {
        // Extrusion
        [SerializeField, Range(0f, 2f)] private float extrusionFactor = 1f;
        [SerializeField, Range(1f, 20f)] private float voronoiDensity = 3f;
        [SerializeField, Range(0f, 20f)] private float voronoiOffset = 3f;

        private List<Vector3> vertexPositionsCache = new List<Vector3>();
        private List<Vector3> vertexNormalsCache = new List<Vector3>();

        // Fracture
        [SerializeField] private int chunkCount = 500;
        [SerializeField] private Material insideMaterial;
        [SerializeField] private Material outsideMaterial;

        [SerializeField] private Transform chunkPivotParent;

        private Mesh mesh = null;
        private System.Random rng = new System.Random();

        void Start()
        {
            mesh = GetComponent<MeshFilter>().mesh;
            for (int i = 0; i < mesh.vertexCount; i++)
            {
                vertexPositionsCache.Add(mesh.vertices[i]);
                vertexNormalsCache.Add(mesh.normals[i]);
            }

            extrusion();
            destruction();
        }

        private void extrusion()
        {
            Vector3 localScale = transform.localScale;
            mesh.SetVertices(
                vertexPositionsCache.Select(
                    (pos, i) =>
                        pos + MathUtil.Divide(vertexNormalsCache[i], localScale) *
                        MathUtil.Voronoi(MathUtil.Multiply(pos, localScale), voronoiDensity, voronoiOffset) * extrusionFactor
                ).ToArray()
            );
        }

        private void destruction()
        {
            var seed = rng.Next();
            Fracture.FractureGameObject(
                gameObject,
                chunkPivotParent,
                seed,
                chunkCount,
                insideMaterial,
                outsideMaterial
            );
            gameObject.SetActive(false);
        }
    }
}
