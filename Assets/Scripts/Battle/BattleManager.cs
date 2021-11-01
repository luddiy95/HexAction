using System;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System.Collections;
using UnityEngine.UI;
using UnityEditor;
using UnityEngine.SceneManagement;

namespace Project.Scripts.Battle
{
    public class BattleManager : SingletonMonoBehaviour<BattleManager>
    {
        // Const
        public const string BUTTON_X = "ButtonX";
        public const string BUTTON_Y = "ButtonY";

        public const string CONTINUE_COMBO = "ContinueCombo";

        public const string PLAYER = "Player";

        public const string CRYSTAL = "Crystal";
        public const string CRYSTAL_CHUNK = "CrystalChunk";
        public const string ENEMY = "Enemy";

        public const string STAGE_FLOOR_TRIGGER = "StageFloorTrigger";
        public const string GRID = "Grid";

        public const string ATTACK = "Attack";
        public const string DIE = "Die";

        // Environment
        private Camera camera;

        // UI
        [SerializeField] private Text gameClearText;
        [SerializeField] private Text gameOverText;
        [SerializeField] private Button restartButton;

        // Grid
        public enum GridStatus
        {
            PLAYER,
            ENEMY
        }
        [SerializeField] private Color _gridBaseColor;
        public Color gridBaseColor => _gridBaseColor;
        [SerializeField] private Color _gridAttackIndicatorColor;
        public Color gridAttackIndicatorColor => _gridAttackIndicatorColor;

        // Crystal
        [SerializeField] private Stage.Crystal.Crystal crystalPrefab;
        [SerializeField] private Transform crystalRoot;
        [SerializeField] private List<Transform> generateCrystalPosList = new List<Transform>();
        [SerializeField] private float crystalOffsetY = 1.5f;

        // Player
        public Player.Player player;

        ////// Equipment //////
        public enum EquipmentType
        {
            COMBO_SWORD,
            REMOTE_FIRE
        }
        [Serializable]
        public class EquipmentData
        {
            [SerializeField] private string _startAnimationParam;
            public string startAnimationParam => _startAnimationParam;
            [SerializeField] private int _MPcost;
            public int MPcost => _MPcost;
        }
        [Serializable]
        public class AttackEquipmentData : EquipmentData
        {
            [SerializeField] private EquipmentType _equipmentType;
            public EquipmentType equipmentType => _equipmentType;
            [SerializeField] private int _damage;
            public int damage => _damage;
        }

        [SerializeField] private List<AttackEquipmentData> _attackEquipmentDataMap = new List<AttackEquipmentData>();
        public List<AttackEquipmentData> attackEquipmentDataMap => _attackEquipmentDataMap;

        // Weapon
        public enum WeaponType
        {
            SIMPLE_WEAPON
        }

        [SerializeField] private List<Player.Weapon.BaseWeapon> _weaponPrefabList = new List<Player.Weapon.BaseWeapon>();
        public List<Player.Weapon.BaseWeapon> weaponPrefabList => _weaponPrefabList;

        //Enemy
        [SerializeField] private Transform enemyRoot;
        private List<Enemy.BaseEnemy> enemyList = new List<Enemy.BaseEnemy>();

        [SerializeField] private HP _enemyHPprefab;
        public HP enemyHPprefab => _enemyHPprefab;
        [SerializeField] private Transform _enemyHProot;
        public Transform enemyHProot => _enemyHProot;

        private void Start()
        {
            // Environment
            camera = Camera.main;

            // UI
            gameClearText.gameObject.SetActive(false);
            gameOverText.gameObject.SetActive(false);
            restartButton.gameObject.SetActive(false);

            // Enemy
            for(int i = 0; i < enemyRoot.childCount; i++)
            {
                Enemy.BaseEnemy enemy = enemyRoot.GetChild(i).GetComponent<Enemy.BaseEnemy>();
                if (enemy == null) continue;

                enemy.Initialize(i);
                enemyList.Add(enemy);
            }
        }

        private void Update()
        {
            if(!enemyList.Exists(x => !x.dead))
            {
                gameClearText.gameObject.SetActive(true);
                restartButton.gameObject.SetActive(true);
            }
        }

        // Environment
        public Vector3 cameraPos => camera.transform.position;
        public float cameraFOV => camera.fieldOfView;

        // UI
        public void restart()
        {
            SceneManager.LoadScene(SceneManager.GetActiveScene().name);
        }

        // Crystal
        public void onCrystalDestroy()
        {
            StartCoroutine(createCrystal());
        }

        private IEnumerator createCrystal()
        {
            yield return new WaitForSeconds(7f);
            Stage.Crystal.Crystal crystal =  Instantiate(crystalPrefab, crystalRoot);

            bool playerLandedGrid = true;
            Transform crystalGrid = null;
            while (playerLandedGrid)
            {
                crystalGrid = generateCrystalPosList[Mathf.FloorToInt(UnityEngine.Random.value * generateCrystalPosList.Count)];
                playerLandedGrid = (crystalGrid == player.landedGrid.transform);
            }
            crystal.transform.position = crystalGrid.position + crystalOffsetY * Vector3.up;
        }

        // Player
        public void playerEndDieBehaviour()
        {
            gameOverText.gameObject.SetActive(true);
            restartButton.gameObject.SetActive(true);
        }

        // Enemy
        public void enemyEndDieBehaviour(int id)
        {
            enemyList.First(x => x.enemyID == id).endDieBehaviour();
        }

        // Common
        public void damageToAny(GameObject any, int damage)
        {
            if (isCrystal(any)) any.GetComponent<Stage.Crystal.Crystal>().hp -= damage;
            if (isEnemy(any)) any.GetComponent<Enemy.BaseEnemy>().hp -= damage;
        }

        public void damageToPlayer(GameObject any, int damage)
        {
            if (isPlayer(any)) player.hp -= damage;
        }

        public Stage.Grid getLandedGrid(Vector3 landedPos)
        {
            RaycastHit[] hits = Physics.RaycastAll(landedPos + Vector3.up * 0.15f, Vector3.down, 0.3f);

            foreach (RaycastHit hit in hits)
            {
                if (isGrid(hit.transform.gameObject))
                {
                    return hit.transform.GetComponent<Stage.Grid>();
                }
            }

            return null;
        }

        // Layer
        public bool isPlayer(GameObject obj) => obj.layer == LayerMask.NameToLayer(PLAYER);

        public bool isAny(GameObject obj) => isCrystal(obj) || isEnemy(obj);

        public bool isCrystal(GameObject obj) => obj.layer == LayerMask.NameToLayer(CRYSTAL);

        public bool isCrystalChunk(GameObject obj) => obj.layer == LayerMask.NameToLayer(CRYSTAL_CHUNK);

        public bool isStageFloorTrigger(GameObject obj) => obj.layer == LayerMask.NameToLayer(STAGE_FLOOR_TRIGGER);

        public bool isGrid(GameObject obj) => obj.layer == LayerMask.NameToLayer(GRID);

        public bool isEnemy(GameObject obj) => obj.layer == LayerMask.NameToLayer(ENEMY);

        // General
        public Vector3 getFloorPosFromScreenPointRay(Vector3 screenPoint)
        {
            Ray ray = camera.ScreenPointToRay(screenPoint);
            RaycastHit[] hits = Physics.RaycastAll(ray);

            return hits.First(x => isStageFloorTrigger(x.transform.gameObject)).point;
        }

        public Vector3 getScreenPosFromWorldPos(Vector3 worldPos)
        {
            return camera.WorldToScreenPoint(worldPos);
        }
    }
}
