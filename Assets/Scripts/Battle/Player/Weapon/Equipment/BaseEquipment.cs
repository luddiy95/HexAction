using UnityEngine;

namespace Project.Scripts.Battle.Player.Weapon.Equipment
{
    public abstract class BaseEquipment : MonoBehaviour
    {
        public abstract BattleManager.EquipmentType equipmentType
        {
            get;
        }

        public int MPcost { get; protected set; }
        protected string startAnimationParam;

        protected string fireButton;

        protected virtual void Start()
        {

        }

        public abstract void Initialize();

        public bool canExecute(MP playerMP)
        {
            return (playerMP.amount >= MPcost);
        }

        //! state=IDLE/RUN‚Ì‚Æ‚«(‘•”õ‚µ‚Ä‚¢‚é‚Æ‚«)‚ÉŒÄ‚Î‚ê‚é
        public abstract void equipUpdate();

        public virtual void fireInputUpdate(string input)
        {

        }

        //! state=FIRE‚Ì‚Æ‚«‚ÉŒÄ‚Î‚ê‚é
        public abstract void fireUpdate();

        public virtual void startEquipment(string fireButton)
        {
            this.fireButton = fireButton;
            BattleManager.Instance.player.setAnimationBoolean(startAnimationParam);
        }

        public abstract void controlPlayerRootMotion();

        // Behaviour
        public virtual void enterFirstEquipmentBehaviour()
        {
            BattleManager.Instance.player.resetAnimationBoolean(startAnimationParam);
        }
        public virtual void exitLastEquipmentBehaviour()
        {
            BattleManager.Instance.player.finishEquipment();
        }
    }
}
