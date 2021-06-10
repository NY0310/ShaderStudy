using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

public class BasicAssetPipe : RenderPipelineAsset
{
    public Color ClearColor = Color.green;

#if UNITY_EDITOR
    [UnityEditor.MenuItem("SRP-Demo/01 - Create Basic Asset Pipeline")]
    static void CraeteBasicAssetPipeline()
    {
        var instance = ScriptableObject.CreateInstance<BasicAssetPipe>();
        UnityEditor.AssetDatabase.CreateAsset(instance, "Assets/SRP-Demo/1-BasicAssetPipe.asset");
    }
#endif

    protected override IRenderPipeline InternalCreatePipeline()
    {
        return new BasicPipeInstance(ClearColor);
    }
}

public class BasicPipeInstance : RenderPipeline
{
    private Color _clearColor = Color.black;

    public BasicPipeInstance(Color clearColor)
    {
        _clearColor = clearColor;
    }

    public override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        // does not so much yet.
        base.Render(context, cameras);

        // Clear buffer to the configured color.
        var cmd = new CommandBuffer();
        cmd.ClearRenderTarget(true, true, _clearColor);
        context.ExecuteCommandBuffer(cmd);
        cmd.Release();
        context.Submit();
    }
}
