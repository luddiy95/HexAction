using System.Collections.Generic;
using Cinemachine;
using UnityEngine;
using System;
using System.Linq;
using UnityEngine.UI;

namespace Project.Scripts.Battle.Player
{
    public class Player : MonoBehaviour
    {
        // Const
        protected const string HORIZONTAL1 = "Horizontal1";
        protected const string VERTICAL1 = "Vertical1";
        protected const string HORIZONTAL2 = "Horizontal2";
        protected const string VERTICAL2 = "Vertical2";
        protected const string SPEED = "Speed";
        private const string SPEED_HORIZONTAL = "SpeedHorizontal";
        private const string SPEED_VERTICAL = "SpeedVertical";
        private const string DIE = "Die";

        // Component
        private Rigidbody rigidbody;
        private Animator animator;

        // UI
        [SerializeField] private Image keyA;
        [SerializeField] private Image keyS;
        [SerializeField] private Image keyZ;
        [SerializeField] private Image keyW;
        [SerializeField] private Color keyHightLightColor;

        [SerializeField] private Image mouse;
        [SerializeField] private Sprite mouseDefault;
        [SerializeField] private Sprite mouseLeftClick;
        [SerializeField] private Sprite mouseRightClick;

        // Camera
        [SerializeField] private CinemachineVirtualCamera v_camera;
        protected CinemachineOrbitalTransposer transposer;

        // Status
        public HP hp;
        [SerializeField] private int maxHP;
        public MP mp;
        [SerializeField] private int maxMP;

        // Locomotion
        public enum State
        {
            IDLE,
            RUN,

            FIRE,

            DIE
        }
        private State _state = State.IDLE;
        private State state
        {
            get { return _state; }
            set
            {
                _state = value;
            }
        }

        private List<Vector3> prevInputForceCache = new List<Vector3>();
        [SerializeField] private int prevInputCount = 3;

        // Run Property
        [SerializeField] private float runSpeed = 8f;
        protected Vector3 curInputForce = Vector3.zero;
        protected Vector3 prevInputForce = Vector3.zero;

        [SerializeField] private float firstRunAcceleration = 5f;
        private float firstRunSpeed = 0f;
        private Vector3 runVelocity = Vector3.zero;
        private Vector3 runForce = Vector3.zero;

        // Weapon
        [Serializable]
        public class WeaponData
        {
            [SerializeField] private BattleManager.WeaponType _weaponType;
            public BattleManager.WeaponType weaponType => _weaponType;
            [SerializeField] private Transform _weaponRoot;
            public Transform weaponRoot => _weaponRoot;
            [SerializeField] private Transform _equipmentXroot;
            public Transform equipmentXroot => _equipmentXroot;
            [SerializeField] private Transform _equipmentYroot;
            public Transform equipmentYroot => _equipmentYroot;
        }
        [SerializeField] private List<WeaponData> _weaponDataMap = new List<WeaponData>();
        public List<WeaponData> weaponDataMap => _weaponDataMap;

        [SerializeField] private BattleManager.WeaponType equipWeaponType;
        private Weapon.BaseWeapon equipWeapon;

        public Weapon.Equipment.BaseEquipment curFireEquipment { get; private set; }

        private void Start()
        {
            // Component
            rigidbody = GetComponent<Rigidbody>();
            animator = GetComponent<Animator>();

            // Camera
            transposer = v_camera.GetCinemachineComponent<CinemachineOrbitalTransposer>();

            // Status
            hp.Initialize(maxHP);
            mp.Initialize(maxMP);

            // Locomotion
            for (int i = 0; i < prevInputCount; i++) prevInputForceCache.Add(Vector3.zero);

            // Weapon
            Weapon.BaseWeapon equipWeaponPrefab = BattleManager.Instance.weaponPrefabList.First(x => x.weaponType == equipWeaponType);
            WeaponData weaponData = weaponDataMap.First(x => x.weaponType == equipWeaponType);
            Transform weaponRoot = weaponData.weaponRoot;
            equipWeapon = Instantiate(equipWeaponPrefab, weaponRoot);
            equipWeapon.Initialize(weaponData.equipmentXroot, weaponData.equipmentYroot);
        }

        private void Update()
        {
            if (state != State.DIE && hp.amount <= 0)
            {
                state = State.DIE;
                animator.SetTrigger(DIE);
            }

            updateUI();

            updateEquipment();

            updateFire();
        }

        private void FixedUpdate()
        {
            fixedUpdateLocomotion();
        }

        // Landed
        public Stage.Grid landedGrid
        {
            get
            {
                return BattleManager.Instance.getLandedGrid(transform.position);
            }
        }

        // UI
        private void updateUI()
        {
            float horizontal2 = Input.GetAxisRaw(HORIZONTAL2);
            float vertical2 = Input.GetAxisRaw(VERTICAL2);
            if (horizontal2 > 0) keyS.color = keyHightLightColor;
            else keyS.color = Color.white;
            if (horizontal2 < 0) keyA.color = keyHightLightColor;
            else keyA.color = Color.white;
            if (vertical2 > 0) keyW.color = keyHightLightColor;
            else keyW.color = Color.white;
            if (vertical2 < 0) keyZ.color = keyHightLightColor;
            else keyZ.color = Color.white;

            if (Input.GetMouseButton(0)) mouse.sprite = mouseLeftClick;
            else if (Input.GetMouseButton(1)) mouse.sprite = mouseRightClick;
            else mouse.sprite = mouseDefault;
        }

        // Status
        public Vector3 getMPgainingPos(int amount)
        {
            Vector3 canvasGainPos = mp.getCanvasGainPos(amount);
            return BattleManager.Instance.getFloorPosFromScreenPointRay(canvasGainPos);
        }

        // Locomotion
        private void fixedUpdateLocomotion()
        {
            Vector3 tmpCurInputForce = Vector3.zero;
            tmpCurInputForce.x = Input.GetAxisRaw(HORIZONTAL1);
            tmpCurInputForce.z = Input.GetAxisRaw(VERTICAL1);

            tmpCurInputForce.x = Input.GetAxisRaw(HORIZONTAL2);
            tmpCurInputForce.z = Input.GetAxisRaw(VERTICAL2);

            // 2F連続で同じ入力だったら入力を更新する
            bool canInputChange = true;
            for (int i = 0; i < prevInputCount; i++)
            {
                Vector3 vectorDiff = prevInputForceCache[i] - tmpCurInputForce;
                if (vectorDiff.magnitude > 0.1)
                {
                    canInputChange = false;
                    break;
                }
            }

            if (canInputChange) curInputForce = tmpCurInputForce;
            else curInputForce = prevInputForce;

            // cacheを更新
            for (int i = 0; i < prevInputCount - 1; i++) prevInputForceCache[i] = prevInputForceCache[i + 1];
            prevInputForceCache[prevInputCount - 1] = tmpCurInputForce;

            // Camera
            //TODO:

            // その場で回転
            //TODO:

            // Run
            switch (state)
            {
                case State.IDLE:
                case State.RUN:

                    // Run
                    runVelocity = Vector3.zero;

                    if (curInputForce.magnitude >= 0.1)
                    {
                        state = State.RUN;

                        // 方向転換
                        if ((curInputForce - prevInputForce).magnitude < 0.1)
                        {
                            float euler = (Quaternion.AngleAxis(transposer.m_Heading.m_Bias, Vector3.up) * Quaternion.LookRotation(curInputForce)).eulerAngles.y;
                            runForce = Quaternion.AngleAxis(euler, Vector3.up) * Vector3.forward;
                        }

                        firstRunSpeed += firstRunAcceleration * Time.deltaTime;
                        if (firstRunSpeed > 1f) firstRunSpeed = 1f;

                        runVelocity += runForce.normalized * firstRunSpeed * runSpeed;
                    }
                    else
                    {
                        state = State.IDLE;
                        firstRunSpeed = 0f;
                    }

                    prevInputForce = curInputForce;

                    if (canRun) rigidbody.velocity = runVelocity;
                    else stopVelocity();

                    animator.SetFloat(SPEED, curInputForce.magnitude);
                    animator.SetFloat(SPEED_HORIZONTAL, curInputForce.x);
                    animator.SetFloat(SPEED_VERTICAL, curInputForce.z);

                    break;
            }
        }

        private bool canRun
        {
            get
            {
                Stage.Grid destinationGrid = BattleManager.Instance.getLandedGrid(transform.position + runVelocity * Time.deltaTime);

                if (destinationGrid != null && destinationGrid.isPlayer) return true;
                return false;
            }
        }

        private void stopVelocity()
        {
            rigidbody.velocity = Vector3.zero;
            animator.SetFloat(SPEED, 0);
            animator.SetFloat(SPEED_HORIZONTAL, 0);
            animator.SetFloat(SPEED_VERTICAL, 0);
        }

        // Equipment
        private void updateEquipment()
        {
            switch (state)
            {
                case State.IDLE:
                case State.RUN:

                    equipWeapon.equipmentX.equipUpdate();
                    equipWeapon.equipmentY.equipUpdate();

                    if (Input.GetButton(BattleManager.BUTTON_X) || Input.GetMouseButtonDown(1))
                    {
                        if (!equipWeapon.equipmentX.canExecute(mp)) return;

                        curFireEquipment = equipWeapon.equipmentX;
                        curFireEquipment.startEquipment(BattleManager.BUTTON_X);
                        mp -= curFireEquipment.MPcost;
                        startFire();
                    }

                    if (Input.GetButton(BattleManager.BUTTON_Y) || Input.GetMouseButtonDown(0))
                    {
                        if (!equipWeapon.equipmentY.canExecute(mp)) return;

                        curFireEquipment = equipWeapon.equipmentY;
                        curFireEquipment.startEquipment(BattleManager.BUTTON_Y);
                        mp -= curFireEquipment.MPcost;
                        startFire();
                    }

                    break;
            }
        }

        public void finishEquipment()
        {
            state = State.IDLE;
        }

        public void enterFirstEquipmentBehaviour()
        {
            curFireEquipment.enterFirstEquipmentBehaviour();
        }

        public void exitLastEquipmentBehaviour()
        {
            curFireEquipment.exitLastEquipmentBehaviour();
        }

        public void acceptCombInput()
        {
            if (curFireEquipment is Weapon.Equipment.BaseComboAttackEquipment)
            {
                curFireEquipment.GetComponent<Weapon.Equipment.BaseComboAttackEquipment>().acceptCombInput();
            }
        }

        public void finishAcceptCombInput()
        {
            if (curFireEquipment is Weapon.Equipment.BaseComboAttackEquipment)
            {
                curFireEquipment.GetComponent<Weapon.Equipment.BaseComboAttackEquipment>().finishAcceptCombInput();
            }
        }

        public void startEquipmentAttackEnable()
        {
            if (curFireEquipment is Weapon.Equipment.BaseAttackEquipment) 
                curFireEquipment.GetComponent<Weapon.Equipment.BaseAttackEquipment>().startAttackEnable();
        }

        public void finishEquipmentAttackEnable()
        {
            if (curFireEquipment is Weapon.Equipment.BaseAttackEquipment)
                curFireEquipment.GetComponent<Weapon.Equipment.BaseAttackEquipment>().finishAttackEnable();
        }

        // Fire
        private void startFire()
        {
            stopVelocity();
            state = State.FIRE;
        }

        private void updateFire()
        {
            switch (state)
            {
                case State.FIRE:
                    if (Input.GetButtonDown(BattleManager.BUTTON_X) || Input.GetMouseButtonDown(1)) 
                        curFireEquipment.fireInputUpdate(BattleManager.BUTTON_X);
                    if (Input.GetButtonDown(BattleManager.BUTTON_Y) || Input.GetMouseButtonDown(0)) 
                        curFireEquipment.fireInputUpdate(BattleManager.BUTTON_Y);

                    curFireEquipment.fireUpdate();

                    break;
            }
        }

        // Animation Method
        public void setAnimationBoolean(string param)
        {
            animator.SetBool(param, true);
        }

        public void resetAnimationBoolean(string param)
        {
            animator.SetBool(param, false);
        }

        public void setAnimationTrigger(string param)
        {
            animator.SetTrigger(param);
        }

        public void controlRootMotion(bool apply)
        {
            animator.applyRootMotion = apply;
        }
    }
}
