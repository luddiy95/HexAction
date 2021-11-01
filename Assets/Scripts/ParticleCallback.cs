using UnityEngine.Events;
using UnityEngine;

public class ParticleCallback : MonoBehaviour
{
    [SerializeField] private UnityEvent stopCallback;

    private void OnParticleSystemStopped()
    {
        stopCallback.Invoke();
    }
}
