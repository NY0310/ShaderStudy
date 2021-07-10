using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class CameraFilter : MonoBehaviour
{
    [SerializeField] private Shader shader;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        var mat = new Material(shader);
        Graphics.Blit(src,dest,mat);
    }
}