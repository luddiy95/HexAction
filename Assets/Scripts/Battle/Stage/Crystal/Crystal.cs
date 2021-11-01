using UnityEngine;
using DG.Tweening;
using System.Collections;

namespace Project.Scripts.Battle.Stage.Crystal
{
    public class Crystal : MonoBehaviour
    {
        private int _hp;
        public int hp
        {
            get { return _hp; }
            set
            {
                if (_hp <= 0) return;
                _hp = value;

                if (_hp <= 0) startVanishing();
            }
        }
        [SerializeField] private int maxHP;
        [SerializeField] private int gainMP;

        // Rotating
        private bool rotating = true;
        [SerializeField] private Transform crystalChunkPivotRoot;
        [SerializeField] private float crystalRotateSpeed;

        // Vanishing
        [SerializeField] private Transform fractureCrystal;

        [SerializeField] private Transform vanishingTrigger;
        [SerializeField, Range(1f, 10f)] private float vanishingDuration = 0.1f;

        [SerializeField, Range(0.1f, 1f)] private float chunkScaleDuration = 0.721f;
        [SerializeField] private float chunkMoveDistance = 2f;
        [SerializeField] private float chunkMoveDuration = 3f;

        [SerializeField, Range(0f, 1f)] private float vanishingChunkRatio;

        private float triggerInitialY;
        private float triggerGoalDistanceY;

        // Gaining
        private bool alreadyGain = false;
        [SerializeField] private float startGainMPdisenableRatio = 0.8f;
        [SerializeField, Range(0f, 1f)] private float gainChunkShrinkRatio;
        [SerializeField] private float gainSpeed;

        private void Start()
        {
            _hp = maxHP;
        }

        private void Update()
        {
            if (rotating)
            {
                crystalChunkPivotRoot.rotation *= Quaternion.AngleAxis(crystalRotateSpeed * Time.deltaTime, Vector3.up);
            }
            else
            {
                // gaining‚ªŽn‚Ü‚Á‚Ä‚¢‚é
                int chunkCount = crystalChunkPivotRoot.childCount;
                int disenableCount = 0;
                for(int i = 0; i < chunkCount; i++)
                {
                    if (!crystalChunkPivotRoot.GetChild(i).gameObject.activeSelf) ++disenableCount;
                }
                if ((float)disenableCount / chunkCount > startGainMPdisenableRatio && !alreadyGain)
                {
                    alreadyGain = true;
                    BattleManager.Instance.player.mp += gainMP;
                }
                if (disenableCount == chunkCount)
                {
                    BattleManager.Instance.onCrystalDestroy();
                    Destroy(gameObject);
                }
            }
        }

        public void startVanishing()
        {
            triggerInitialY = vanishingTrigger.localPosition.y;
            float triggerGoalY = -fractureCrystal.localScale.y / 2f;
            triggerGoalDistanceY = triggerInitialY - triggerGoalY;
            vanishingTrigger
                .DOLocalMoveY(triggerGoalY, vanishingDuration)
                .OnComplete(() => vanishingTrigger.gameObject.SetActive(false));
        }

        public void onChunkEnterTrigger(Collider other)
        {
            if (!BattleManager.Instance.isCrystalChunk(other.gameObject)) return;

            Destroy(other.GetComponent<MeshCollider>());

            float triggerMoveRatio = (triggerInitialY - vanishingTrigger.localPosition.y) / triggerGoalDistanceY;

            if (triggerMoveRatio < vanishingChunkRatio) startVanishingChunk(other.transform.parent);
            else StartCoroutine(startGaining(other.transform.parent));
        }

        private void startVanishingChunk(Transform pivot)
        {
            pivot.localRotation = Quaternion.Euler(new Vector3(MathUtil.RandomEuler, MathUtil.RandomEuler, MathUtil.RandomEuler));
            pivot.DOLocalMoveY(chunkMoveDistance, chunkMoveDuration);

            pivot.DOScale(Vector3.zero, chunkScaleDuration)
                .OnComplete(() => pivot.gameObject.SetActive(false));
        }

        private IEnumerator startGaining(Transform pivot)
        {
            rotating = false;

            Tweener scaleTweener = pivot.DOScale(Vector3.zero, chunkScaleDuration);
            pivot.localRotation = Quaternion.Euler(new Vector3(MathUtil.RandomEuler, MathUtil.RandomEuler, MathUtil.RandomEuler));
            Tweener moveTweener = pivot.DOLocalMoveY(chunkMoveDistance, chunkMoveDuration);

            yield return new WaitForSeconds(chunkScaleDuration * gainChunkShrinkRatio);

            scaleTweener.Kill();
            moveTweener.Kill();

            CrystalChunkPivot crystalChunkPivot = pivot.GetComponent<CrystalChunkPivot>();
            if (crystalChunkPivot != null) crystalChunkPivot.startGainAnimation(gainMP, gainSpeed);
        }
    }
}
