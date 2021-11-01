using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using System.Linq;

namespace Project.Scripts.Battle.Enemy
{
    public class CannonMachine : BaseEnemy
    {
        [SerializeField] private GameObject laser;
        [SerializeField] private float attackRangeRad = 1.5f;
        [SerializeField] private GameObject attackEffect;
        [SerializeField] private GameObject attackTrigger;

        private Vector3 attackIndicateCenterGridPos;
        private List<Stage.Grid> attackIndicateGridList = new List<Stage.Grid>();

        private Quaternion rotateCache;

        protected override void Start()
        {
            laser.SetActive(false);
            attackEffect.SetActive(false);
            attackTrigger.SetActive(false);

            rotateCache = transform.rotation;

            StartCoroutine(attackIterator());

            base.Start();
        }

        private IEnumerator attackIterator()
        {
            while (isAlive)
            {
                yield return new WaitForSeconds(7f);

                if (!isAlive) yield break;

                startAttackAnimation();
            }
        }

        private void startAttackAnimation()
        {
            animator.SetBool(BattleManager.ATTACK, true);
            attackIndicateCenterGridPos = BattleManager.Instance.player.landedGrid.transform.position;
            Vector3 relativePos = transform.position - attackIndicateCenterGridPos;
            relativePos.y = 0;
            transform.DORotateQuaternion(Quaternion.LookRotation(relativePos), 0.8f)
                .OnComplete(() =>
                {
                    if (!isAlive) return;
                    showAttackIndicator();
                    StartCoroutine(startAttack());
                });
        }

        private void showAttackIndicator()
        {
            if (!isAlive) return;

            attackIndicateGridList.Clear();

            Ray ray = new Ray(attackIndicateCenterGridPos, Vector3.down);
            RaycastHit[] hits = Physics.SphereCastAll(ray, attackRangeRad, 0f);

            foreach(RaycastHit hit in hits)
            {
                if (BattleManager.Instance.isGrid(hit.transform.gameObject))
                {
                    Stage.Grid grid = hit.transform.GetComponent<Stage.Grid>();
                    attackIndicateGridList.Add(grid);
                    grid.setAttackIndicator(true);
                }
            }

            laser.SetActive(true);
        }

        private IEnumerator startAttack()
        {
            yield return new WaitForSeconds(1f);

            if (!isAlive) yield break;

            attackEffect.transform.position = attackIndicateCenterGridPos;
            attackEffect.SetActive(true);

            StartCoroutine(enableAttackTrigger());

            StartCoroutine(endAttack());
        }

        private IEnumerator enableAttackTrigger()
        {
            yield return new WaitForSeconds(0.2f);

            if (!isAlive) yield break;

            attackTrigger.transform.position = attackIndicateCenterGridPos;
            attackTrigger.SetActive(true);
        }

        private IEnumerator endAttack()
        {
            yield return new WaitForSeconds(0.6f);

            if (!isAlive) yield break;

            attackIndicateGridList.ForEach(x => x.setAttackIndicator(false));
            attackEffect.SetActive(false);
            attackTrigger.SetActive(false);
            laser.SetActive(false);
            StartCoroutine(endAttackAnimation());
        }

        private IEnumerator endAttackAnimation()
        {
            yield return new WaitForSeconds(0.6f);

            if (!isAlive) yield break;

            transform.DORotateQuaternion(rotateCache, 0.8f)
                .OnComplete(() => {
                    if (!isAlive) return;
                    animator.SetBool(BattleManager.ATTACK, false);
                });
        }

        public void onAttackTriggerEnter(Collider other)
        {
            if (!isAlive) return;
            BattleManager.Instance.damageToPlayer(other.transform.gameObject, damage);
        }

        protected override void onDie()
        {
            laser.SetActive(false);
            attackEffect.SetActive(false);
            attackTrigger.SetActive(false);
            attackIndicateGridList.ForEach(x => x.setAttackIndicator(false));

            base.onDie();
        }
    }
}