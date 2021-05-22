using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeRenderTarget : MonoBehaviour
{
    RenderTexture rt;
    [SerializeField]
    private Material mat;
    void Start()
    {
        var format = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf) ? RenderTextureFormat.Default : RenderTextureFormat.ARGBHalf;
        // 画面サイズのレンダーテクスチャを作成
        rt = new RenderTexture(Screen.width, Screen.height, 24, format);
        rt.Create();

        // RenderTextureのバッファーをカメラに設定
        GetComponent<Camera>().SetTargetBuffers(rt.colorBuffer, rt.depthBuffer);
    }

    /// <summary>
    /// ここまでにRenderTextureにカメラの描画結果が入っている
    /// </summary>
    void OnPostRender()
	{
		// 色を反転させるマテリアルを設定してRenderTextureの結果を画面に描画する
		Graphics.Blit(rt, null ,mat);
	}
}
