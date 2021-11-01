using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Project.Scripts.Battle.Stage.Crystal
{
    public class Fracture : MonoBehaviour
    {
        public static void FractureGameObject(
            GameObject gameObject, Transform parentPivot, int seed, int totalChunks, Material insideMaterial, Material outsideMaterial)
        {
            Mesh mesh = GetWorldMesh(gameObject); // GameObject����Mesh�����Mesh��

            NvBlastExtUnity.setSeed(seed);

            // mesh��NvMesh�Ƃ��Ĉ�����悤�ɂ���
            NvMesh nvMesh = new NvMesh(
                mesh.vertices,
                mesh.normals,
                mesh.uv,
                mesh.vertexCount,
                mesh.GetIndices(0),
                (int)mesh.GetIndexCount(0)
            );

            List<Mesh> meshes = FractureMeshesInNvblast(totalChunks, nvMesh);

            BuildChunks(parentPivot, insideMaterial, outsideMaterial, meshes);
        }

        private static void BuildChunks(Transform parentPivot, Material insideMaterial, Material outsideMaterial, List<Mesh> meshes)
        {
            meshes.Select((chunkMesh, i) =>
            {
                GameObject chunk = BuildChunk(parentPivot, insideMaterial, outsideMaterial, chunkMesh);
                chunk.name += $" [{i}]";
                return chunk;
            }).ToList();
        }

        private static List<Mesh> FractureMeshesInNvblast(int totalChunks, NvMesh nvMesh)
        {
            NvFractureTool fractureTool = new NvFractureTool();
            fractureTool.setRemoveIslands(false);
            fractureTool.setSourceMesh(nvMesh);
            NvVoronoiSitesGenerator sites = new NvVoronoiSitesGenerator(nvMesh);
            sites.uniformlyGenerateSitesInMesh(totalChunks);
            fractureTool.voronoiFracturing(0, sites);
            fractureTool.finalizeFracturing();

            // Extract meshes
            int meshCount = fractureTool.getChunkCount();
            List<Mesh> meshes = new List<Mesh>(meshCount);
            for (int i = 1; i < meshCount; i++)
            {
                meshes.Add(ExtractChunkMesh(fractureTool, i));
            }

            return meshes;
        }

        private static Mesh ExtractChunkMesh(NvFractureTool fractureTool, int index)
        {
            NvMesh outside = fractureTool.getChunkMesh(index, false);
            NvMesh inside = fractureTool.getChunkMesh(index, true);
            Mesh chunkMesh = outside.toUnityMesh();
            chunkMesh.subMeshCount = 2;
            chunkMesh.SetIndices(inside.getIndexes(), MeshTopology.Triangles, 1);
            return chunkMesh;
        }

        // GameObject���̕�����Mesh�����Mesh�ɂ���(���b�V���ɕ����̃��b�V����g�ݍ��킹��)
        private static Mesh GetWorldMesh(GameObject gameObject)
        {
            var combineInstances = gameObject
                .GetComponentsInChildren<MeshFilter>()
                .Where(mf => ValidateMesh(mf.mesh)) // MeshFilter�Ŏ擾����Mesh�����̒��ŗL����Mesh�̂�
                .Select(mf => new CombineInstance()
            {
                    mesh = mf.mesh,
                    transform = mf.transform.localToWorldMatrix
                }).ToArray();

            var totalMesh = new Mesh();
            totalMesh.CombineMeshes(combineInstances, true);
            return totalMesh;
        }

        private static bool ValidateMesh(Mesh mesh)
        {
            // readable��false����CPU��������Mesh�f�[�^��upload����Ȃ�(true����upload����A�X��keep�����<-�������̎g�������ɒ���)
            // �܂��Afalse����GPU��������upload����CPU�����������菜�����
            // ������Mesh��Combine����Ƃ���isReadable == true�łȂ���΂Ȃ�Ȃ�
            if (mesh.isReadable == false)
            {
                Debug.LogError($"Mesh [{mesh}] has to be readable.");
                return false;
            }

            if (mesh.vertices == null || mesh.vertices.Length == 0)
            {
                Debug.LogError($"Mesh [{mesh}] does not have any vertices.");
                return false;
            }

            if (mesh.uv == null || mesh.uv.Length == 0)
            {
                Debug.LogError($"Mesh [{mesh}] does not have any uvs.");
                return false;
            }

            return true;
        }

        private static GameObject BuildChunk(Transform parentPivot, Material insideMaterial, Material outsideMaterial, Mesh mesh)
        {
            GameObject crystalChunkPivot = new GameObject($"CrystalChunkPivot");
            GameObject crystalChunk = new GameObject($"CrystalChunk");

            MeshRenderer renderer = crystalChunk.AddComponent<MeshRenderer>();
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;

            renderer.sharedMaterials = new[]
            {
                insideMaterial,
                outsideMaterial
            };

            MeshFilter meshFilter = crystalChunk.AddComponent<MeshFilter>();
            meshFilter.sharedMesh = mesh;

            MeshCollider mc = crystalChunk.AddComponent<MeshCollider>();
            mc.convex = true;
            mc.isTrigger = true;

            crystalChunk.layer = LayerMask.NameToLayer(BattleManager.CRYSTAL_CHUNK);

            crystalChunkPivot.AddComponent<CrystalChunkPivot>();
            crystalChunkPivot.transform.position = renderer.bounds.center;
            crystalChunk.transform.parent = crystalChunkPivot.transform;
            crystalChunkPivot.transform.parent = parentPivot;

            return crystalChunkPivot;
        }
    }
}
