using System.Runtime.InteropServices;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Abstract:
HandTracker interacts with Cocoa Touch to request specified hand joints
*/
public class HandTracker : MonoBehaviour
{
    //JointElection indexes a subset of hand joints to fetch
    protected enum JointElection
    {
        allJoints = 0,
        wristTriangleJoints,
        fingerTips
    }

#if UNITY_IOS
    [DllImport("__Internal")]
    private static extern void _initializeHandTracker();
    [DllImport("__Internal")]
    private static extern string _getHandJoints(int jointElection);
#endif

    protected bool trackerIsLive;
    protected JointElection jointElection = JointElection.allJoints;
    protected List<Vector2> jointResults;
    protected const float xScreenScalar = 1.2f;
    private const float startDelay = 1.5f;

    protected virtual IEnumerator Start()
    {
        jointResults = new List<Vector2>();
        yield return new WaitForSeconds(startDelay);
        InitializeTracker();
    }

    protected virtual void Update()
    {
#if UNITY_IOS && !UNITY_EDITOR
        if (trackerIsLive)
        {
            GetHandJoints(jointElection);
        }
#else
        Debug.LogError("CoreML Vision hand tracking does not work in the editor!");
#endif
    }

    /*
     InitializeTracker triggers the setup and starting of the camera and tracking
     */
    protected void InitializeTracker()
    {
#if UNITY_IOS && !UNITY_EDITOR
    _initializeHandTracker();
    trackerIsLive = true;
#else
        Debug.LogError("CoreML Vision hand tracking does not work in the editor!");
#endif
    }

    /*
     GetHandJoints requests specified joints and parses the incoming string into a List of Vector2's
        @param jointElection specifies what subset of hand joints to fetch
     */
    private void GetHandJoints(JointElection jointElection = 0)
    {
        jointResults.Clear();
        string resultStr = _getHandJoints((int)jointElection);
        string[] resultJointsArr = resultStr.Split("|"[0]);
        foreach(string resultJoint in resultJointsArr)
        {
            string[] positionTuple = resultJoint.Split(","[0]);
            float x = 1 - float.Parse(positionTuple[0]);
            float y = float.Parse(positionTuple[1]);
            jointResults.Add(new Vector2(x * Screen.width, y * Screen.height));
        }
    }
}
