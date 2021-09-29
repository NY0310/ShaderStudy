using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdateTrans : MonoBehaviour
{
    [SerializeField]
    private Vector3 rotateSpeed = new Vector3(30,30,0);
    // Start is called before the first frame update
    private Vector3 rotate = Vector3.zero;
    // Update is called once per frame
    void Update()
    {
        rotate += rotateSpeed * Time.deltaTime;
        transform.localRotation =   Quaternion.Euler(rotate);
    }
}
