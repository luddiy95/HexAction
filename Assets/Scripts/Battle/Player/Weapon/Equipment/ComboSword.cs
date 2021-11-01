using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace Project.Scripts.Battle.Player.Weapon.Equipment
{
    public class ComboSword : BaseComboAttackEquipment
    {
        public override BattleManager.EquipmentType equipmentType => BattleManager.EquipmentType.COMBO_SWORD;

        [SerializeField] private Transform slashingEffectRoot;
        private List<GameObject> slashingEffectList = new List<GameObject>();

        protected override void Start()
        {
            for(int i = 0; i < slashingEffectRoot.childCount; i++)
            {
                GameObject slashingEffect = slashingEffectRoot.GetChild(i).gameObject;
                slashingEffectList.Add(slashingEffect);
            }
            base.Start();
        }

        public override void Initialize()
        {
            base.Initialize();
        }

        public override void equipUpdate()
        {

        }

        public override void fireInputUpdate(string input)
        {
            if (input == fireButton)
            {
                if (isAcceptCombInput)
                {
                    isCombInput = true;
                }
            }
        }

        public override void fireUpdate()
        {

        }

        public override void onAttackTriggerEnter(Collider other)
        {
            if (BattleManager.Instance.isAny(other.gameObject))
            {
                slashingEffectList[comboIndex].SetActive(true);
            }

            base.onAttackTriggerEnter(other);
        }

        // Comb
        public override void acceptCombInput()
        {
            base.acceptCombInput();
        }

        public override void controlPlayerRootMotion()
        {
            BattleManager.Instance.player.controlRootMotion(false);
        }

        // Effect
        public void stopSlashing0Effect()
        {
            slashingEffectList.ForEach(x => x.SetActive(false));
        }
    }
}
