using System.Collections;
using UnityEngine;

namespace Project.Scripts.Battle.Enemy
{
    public abstract class BaseEnemy : MonoBehaviour
    {
        public int enemyID { get; private set; }

        protected bool isAlive = true;
        public bool dead { get; private set; }

        [SerializeField] protected int damage;

        [SerializeField] private int maxHP;
        [System.NonSerialized] public HP hp;
        [SerializeField] private Transform showHPpos;

        protected Animator animator;

        protected virtual void Start()
        {
            animator = GetComponent<Animator>();
            dead = false;
        }

        protected virtual void Update()
        {
            hp.transform.position = BattleManager.Instance.getScreenPosFromWorldPos(showHPpos.position);
            if (isAlive && hp.amount <= 0) onDie();
        }

        public virtual void Initialize(int id)
        {
            hp = Instantiate(BattleManager.Instance.enemyHPprefab, BattleManager.Instance.enemyHProot);
            hp.Initialize(maxHP);
            enemyID = id;
        }

        protected virtual void onDie()
        {
            isAlive = false;
            animator.SetTrigger(BattleManager.DIE);
            hp.gameObject.SetActive(false);
        }

        public virtual void endDieBehaviour()
        {
            StartCoroutine(endDie());
        }

        protected virtual IEnumerator endDie()
        {
            yield return new WaitForSeconds(1f);
            dead = true;
        }
    }
}
