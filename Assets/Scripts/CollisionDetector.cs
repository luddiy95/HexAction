using UnityEngine;
using UnityEngine.Events;
using System;

namespace Project.Scripts
{
    [RequireComponent(typeof(Collider))]
    public class CollisionDetector : MonoBehaviour
    {
        [SerializeField] private TriggerEvent onTriggerEnter = new TriggerEvent();
        [SerializeField] private TriggerEvent onTriggerStay = new TriggerEvent();
        [SerializeField] private TriggerEvent onTriggerExit = new TriggerEvent();

        [SerializeField] private CollisionEvent onCollisionEnter = new CollisionEvent();
        [SerializeField] private CollisionEvent onCollisionStay = new CollisionEvent();
        [SerializeField] private CollisionEvent onCollisionExit = new CollisionEvent();

        private void OnTriggerEnter(Collider other)
        {
            onTriggerEnter.Invoke(other);
        }

        private void OnTriggerStay(Collider other)
        {
            onTriggerStay.Invoke(other);
        }

        private void OnTriggerExit(Collider other)
        {
            onTriggerExit.Invoke(other);
        }

        private void OnCollisionEnter(Collision collision)
        {
            onCollisionEnter.Invoke(collision);
        }

        private void OnCollisionStay(Collision collision)
        {
            onCollisionStay.Invoke(collision);
        }

        private void OnCollisionExit(Collision collision)
        {
            onCollisionExit.Invoke(collision);
        }


        [Serializable]
        public class TriggerEvent : UnityEvent<Collider>
        {

        }

        [Serializable]
        public class CollisionEvent : UnityEvent<Collision>
        {

        }
    }
}