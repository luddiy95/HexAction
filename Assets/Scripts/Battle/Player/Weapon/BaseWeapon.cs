using UnityEngine;

namespace Project.Scripts.Battle.Player.Weapon
{
    public class BaseWeapon : MonoBehaviour
    {
        [SerializeField] private BattleManager.WeaponType _weaponType;
        public BattleManager.WeaponType weaponType => _weaponType;

        [SerializeField] private Equipment.BaseEquipment equipmentXprefab;
        [SerializeField] private Equipment.BaseEquipment equipmentYprefab;

        public Equipment.BaseEquipment equipmentX { get; private set; }
        public Equipment.BaseEquipment equipmentY { get; private set; }

        public void Initialize(Transform equipmentXroot, Transform equipmentYroot)
        {
            equipmentX = Instantiate(equipmentXprefab, equipmentXroot);
            equipmentX.Initialize();
            equipmentY = Instantiate(equipmentYprefab, equipmentYroot);
            equipmentY.Initialize();
        }
    }
}
