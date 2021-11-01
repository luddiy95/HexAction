using UnityEngine;

namespace Project.Scripts.Battle.Player.Weapon.Equipment
{
    public abstract class BaseComboAttackEquipment : BaseAttackEquipment
    {
        protected bool isAcceptCombInput = false;
        protected bool isCombInput = false;
        protected bool continueComb = false;

        protected int comboIndex = 0;

        protected override void Start()
        {
            base.Start();

            isAcceptCombInput = false;
            isCombInput = false;
            continueComb = false;

            comboIndex = 0;
        }

        public override void Initialize()
        {
            base.Initialize();
        }

        public override void startEquipment(string fireButton)
        {
            comboIndex = 0;
            base.startEquipment(fireButton);
        }

        public override void finishAttackEnable()
        {
            ++comboIndex;
            base.finishAttackEnable();
        }

        // Comb
        public virtual void acceptCombInput()
        {
            isAcceptCombInput = true;
        }

        public virtual void finishAcceptCombInput()
        {
            isAcceptCombInput = false;
            if (isCombInput)
            {
                BattleManager.Instance.player.setAnimationTrigger(BattleManager.CONTINUE_COMBO);
            }
            isCombInput = false;
        }
    }
}
