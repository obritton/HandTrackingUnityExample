using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Abstract:
WristTracker extends HandTracker to fetch and parse wrist-defining joints,
    including the wrist, bottom index finger knuckle and bottom little finger knuckle
    to place and orient a transform on the tracked hand's wrist
*/
public class WristTracker : HandTracker
{
    [SerializeField] Transform wristTransform;
    [SerializeField] Transform midKnuckleTempTransform;
    private float wristDistanceFromCamera;
    private const float xScreenScalar = 1.2f;

    protected enum WristDefJoint
    {
        wrist = 0,
        indexKnuckle,
        littleKnuckle
    }

    /*
     Start specifies wrist supporting joints and starts tracking
     */
    protected override IEnumerator Start()
    {
        jointElection = JointElection.wristTriangleJoints;
        wristDistanceFromCamera = Vector3.Distance(wristTransform.position, Camera.main.transform.position);

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

        //TODO: add lowpass filter to condition out jitters
        Vector3 screenSpaceWristPos = new Vector3(jointResults[(int)WristDefJoint.wrist].x * xScreenScalar,
                                             jointResults[(int)WristDefJoint.wrist].y,
                                             wristDistanceFromCamera);
        wristTransform.position = Camera.main.ScreenToWorldPoint(screenSpaceWristPos);

        //TODO: correct (offset?) midknuckle marker to correct watch rotation
        //          -try averaging across all knuckles instead of only end knuckles
        Vector3 screenSpaceMidKnucklePos =
            new Vector3((jointResults[(int)WristDefJoint.indexKnuckle].x + jointResults[(int)WristDefJoint.littleKnuckle].x) / 2,
                        (jointResults[(int)WristDefJoint.indexKnuckle].y + jointResults[(int)WristDefJoint.littleKnuckle].y) / 2,
                        wristDistanceFromCamera);
        wristTransform.LookAt(Camera.main.ScreenToWorldPoint(screenSpaceMidKnucklePos));
        midKnuckleTempTransform.position = Camera.main.ScreenToWorldPoint(screenSpaceMidKnucklePos);
    }
}
