using UnityEngine;

namespace Project.Scripts.Battle.Stage
{
    public class Grid : MonoBehaviour
    {
        [SerializeField] private BattleManager.GridStatus gridStatus;

        private Renderer renderer;

        public bool isPlayer => gridStatus == BattleManager.GridStatus.PLAYER;

        private void Start()
        {
            renderer = GetComponent<Renderer>();
        }

        public void setAttackIndicator(bool indicate)
        {
            Material[] materials = renderer.materials;
            if (indicate) materials[1].color = BattleManager.Instance.gridAttackIndicatorColor;
            else materials[1].color = BattleManager.Instance.gridBaseColor;
        }
    }
}
