using UnityEngine;

namespace Project.Scripts.Battle.Stage.Crystal
{
    public class CrystalChunkPivot : MonoBehaviour
    {
        private bool gaining = false;

        private int gainMP;
        private float gainSpeed;

        private Vector3 initialScale;
        private float initialDistanceFromCamera;

        public void startGainAnimation(int gainMP, float gainSpeed)
        {
            gaining = true;
            this.gainMP = gainMP;
            this.gainSpeed = gainSpeed;

            initialScale = transform.localScale;
            initialDistanceFromCamera = Vector3.Distance(transform.position, BattleManager.Instance.cameraPos);

            for(int i = 0; i < transform.childCount; i++)
            {
                GameObject chunk = transform.GetChild(i).gameObject;
                if (BattleManager.Instance.isCrystalChunk(chunk))
                {
                    chunk.GetComponent<Renderer>().material.SetFloat("_ZTest", (float)UnityEngine.Rendering.CompareFunction.Always);
                }
            }
        }

        private void Update()
        {
            if (!gaining) return;

            Vector3 goalPos = BattleManager.Instance.player.getMPgainingPos(gainMP);
            Vector3 velocity = (goalPos - transform.position).normalized;
            transform.position += velocity * gainSpeed * Time.deltaTime;

            if(Vector3.Distance(transform.position, goalPos) < gainSpeed * Time.deltaTime)
            {
                gameObject.SetActive(false);
            }

            // ƒJƒƒ‰‚É‹ß‚Ã‚­‚É‚Â‚ê‚ÄChunk‚ð¬‚³‚­‚·‚é
            float FOV = BattleManager.Instance.cameraFOV;
            transform.localScale = initialScale * 
                (Vector3.Distance(transform.position, BattleManager.Instance.cameraPos) / initialDistanceFromCamera) / Mathf.Tan(FOV / 2f);
        }
    }
}
