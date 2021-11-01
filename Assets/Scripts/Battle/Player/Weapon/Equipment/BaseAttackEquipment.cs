using System.Linq;
using UnityEngine;

namespace Project.Scripts.Battle.Player.Weapon.Equipment
{
    public abstract class BaseAttackEquipment : BaseEquipment
    {
        protected int damage;

        [SerializeField] private GameObject attackTrigger;

        protected override void Start()
        {
            base.Start();
        }

        public override void Initialize()
        {
            BattleManager.AttackEquipmentData attackEquipmentData = 
                BattleManager.Instance.attackEquipmentDataMap.First(x => x.equipmentType == equipmentType);

            if (attackEquipmentData == null) return;

            startAnimationParam = attackEquipmentData.startAnimationParam;
            MPcost = attackEquipmentData.MPcost;
            damage = attackEquipmentData.damage;

            setAttackEnable(false);
        }

        public override void startEquipment(string fireButton)
        {
            base.startEquipment(fireButton);
        }

        public virtual void startAttackEnable()
        {
            setAttackEnable(true);
        }

        public virtual void finishAttackEnable()
        {
            setAttackEnable(false);
        }

        private void setAttackEnable(bool enable)
        {
            attackTrigger.SetActive(enable);
        }

        public virtual void onAttackTriggerEnter(Collider other)
        {
            BattleManager.Instance.damageToAny(other.gameObject, damage);
        }
    }
}
