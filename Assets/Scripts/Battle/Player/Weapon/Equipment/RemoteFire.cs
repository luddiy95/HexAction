using UnityEngine;

namespace Project.Scripts.Battle.Player.Weapon.Equipment
{
    public class RemoteFire : BaseAttackEquipment
    {
        public override BattleManager.EquipmentType equipmentType => BattleManager.EquipmentType.REMOTE_FIRE;

        [SerializeField] private GameObject attackEffect;

        protected override void Start()
        {
            attackEffect.SetActive(false);
            base.Start();
        }

        public override void startAttackEnable()
        {
            attackEffect.SetActive(true);
            base.startAttackEnable();
        }

        public override void exitLastEquipmentBehaviour()
        {
            attackEffect.SetActive(false);
            base.exitLastEquipmentBehaviour();
        }

        public override void controlPlayerRootMotion()
        {

        }

        public override void equipUpdate()
        {

        }

        public override void fireUpdate()
        {

        }
    }
}
