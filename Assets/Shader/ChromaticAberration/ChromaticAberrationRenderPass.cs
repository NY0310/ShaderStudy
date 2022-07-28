using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public sealed class ChromaticAberrationRenderPass : ScriptableRenderPass
{
    private const string RenderPassName = nameof(ChromaticAberrationRenderPass);
    private readonly Material _material;

    public ChromaticAberrationRenderPass(Shader shader)
    {
        if (shader == null)
            return;

        _material = new Material(shader);
        // このレンダーパスをポストプロセスのタイミングで実行
        renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData data)
    {
        if (_material == null)
            return;

        var cmd = CommandBufferPool.Get(RenderPassName);

        // 一回Blitするだけでカラーバッファにマテリアルが適用される
        Blit(cmd, ref data, _material);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
