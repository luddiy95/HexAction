using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Project.Scripts.Battle
{
    public class Gauge : MonoBehaviour
    {
        [SerializeField] private RectTransform gauge;
        private RectTransform gaugeStart;
        private RectTransform gaugeAmount;
        private RectTransform gaugeEnd;

        private float defaultAmountWidth;

        private float scaleX;

        protected int maxAmount;
        protected int _amount;
        public int amount
        {
            get { return _amount; }
            set
            {
                _amount = value;

                gaugeStart.gameObject.SetActive(_amount > 0);
                gaugeEnd.gameObject.SetActive(_amount >= maxAmount);

                if (_amount < 0) _amount = 0;
                if (_amount > maxAmount) _amount = maxAmount;

                gaugeAmount.sizeDelta = new Vector2(defaultAmountWidth * _amount / maxAmount, gaugeAmount.sizeDelta.y);
            }
        }

        protected virtual void Awake()
        {
            gaugeStart = gauge.transform.GetChild(0).GetComponent<RectTransform>();
            gaugeAmount = gauge.transform.GetChild(1).GetComponent<RectTransform>();
            gaugeEnd = gauge.transform.GetChild(2).GetComponent<RectTransform>();

            defaultAmountWidth = gaugeAmount.sizeDelta.x;

            scaleX = GetComponent<RectTransform>().localScale.x;
        }

        public virtual void Initialize(int maxAmount)
        {
            this.maxAmount = maxAmount;
            amount = maxAmount;
        }

        public Vector3 getCanvasGainPos(int amount)
        {
            return gaugeAmount.position;
        }
    }
}
