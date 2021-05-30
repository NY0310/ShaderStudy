using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommandBufferDrawMesh : MonoBehaviour
{
    private void Awake () {
        Initialize();
    }

    private void Initialize()
    {
        var camera = GetComponent<Camera>();
        if (camera.allowMSAA) {
            // MSAAがONになっていると正常に動作しない
            return;
        }

        // シェーダー名からシェーダーを取得してマテリアル作成
        var material = new Material(Shader.Find("InversionColor"));
        var commandBuffer = new CommandBuffer();
        
        // テクスチャのIDを取得するにはShader.PropertyToIDを使う
        int tempTextureIdentifier = Shader.PropertyToID("_PostEffectTempTexture");
        // 一時テクスチャを取得する,サイズは画面と同じ大きさ
        commandBuffer.GetTemporaryRT(tempTextureIdentifier, -1, -1);

        // 現在のレンダーターゲットを一時テクスチャにコピー
        commandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, tempTextureIdentifier);
        // 一時テクスチャからレンダーターゲットにポストエフェクトを掛けつつ描画
        commandBuffer.Blit(tempTextureIdentifier, BuiltinRenderTextureType.CurrentActive, material);

        // 一時テクスチャを解放
        commandBuffer.ReleaseTemporaryRT(tempTextureIdentifier);

        camera.AddCommandBuffer(CameraEvent.AfterEverything, commandBuffer);
    }
}
