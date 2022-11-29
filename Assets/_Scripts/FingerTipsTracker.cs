using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Abstract:
FingerTipsTracker extends HandTracker to fetch and parse 5 finger tip joints,
    to push a target object around with fingers
*/
public class FingerTipsTracker : HandTracker
{
    [SerializeField] Transform targetTransform;
    private float handDistanceFromCamera;

    protected enum FingerTipJoint
    {
        thumbTip = 0,
        indexTip,
        middleTip,
        ringTip,
        littleTip
    }

    /*
     Start specifies wrist supporting joints and starts tracking
     */
    protected override IEnumerator Start()
    {
        jointElection = JointElection.fingerTips;
        handDistanceFromCamera = Vector3.Distance(targetTransform.position, Camera.main.transform.position);

        yield return null;
        StartCoroutine(base.Start());
    }

    /*
     Update polls the wrist supporting joints every frame,
        translates them into world space,
        and udates wristTransform's position and rotation accordingly
     */
    protected override void Update()
    {
        base.Update();

        if (!trackerIsLive) return;

        foreach (Vector2 jointResult in jointResults)
        {
            if (jointResult.x == -1)
            {
                return;
            }
        }

        //TODO: Get Fingertip joints and use them to push a rigidbody around
    }
}
