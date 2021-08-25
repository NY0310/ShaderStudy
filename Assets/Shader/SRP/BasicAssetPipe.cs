using UnityEngine;
using UnityEngine.Rendering;

// スクリプトを Edit モードで実行
[ExecuteInEditMode]
public class BasicAssetPipe : RenderPipelineAsset
{
    public Color clearColor = Color.green;
    protected override RenderPipeline CreatePipeline()
    {
       return new BasicPipeInstance(clearColor);
    }

    #if UNITY_EDITOR
    [UnityEditor.MenuItem("SRP-Demo/01 - Create Basic Asset Pipeline")]
    static void CraeteBasicAssetPipeline()
    {
        // このクラスのインスタンスを作成
        var instance = ScriptableObject.CreateInstance<BasicAssetPipe>();
        // アセット化
        UnityEditor.AssetDatabase.CreateAsset(instance, "Assets/Shader/SRP/1-BasicAssetPipe.asset");
    }
#endif
}

public class BasicPipeInstance : RenderPipeline
{
    private Color m_ClearColor = Color.black;

    public BasicPipeInstance(Color clearColor)
    {
        m_ClearColor = clearColor;
    }

    /// <summary>
    /// 描画処理
    /// </summary>
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        var cmd = new CommandBuffer();
        // レンダーターゲットを設定した色で塗りつぶす
        cmd.ClearRenderTarget(true, true, m_ClearColor);
        // コマンドバッファを即時実行
        context.ExecuteCommandBuffer(cmd);
        cmd.Release();
        // スケジュールされたすべてのコマンドをレンダリングループに送信して実行します。
        context.Submit();
    }
}
