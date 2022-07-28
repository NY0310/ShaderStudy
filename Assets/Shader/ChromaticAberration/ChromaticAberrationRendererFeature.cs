using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class ChromaticAberrationRendererFeature : ScriptableRendererFeature
{
    [SerializeField] private Shader _shader;

    private ChromaticAberrationRenderPass _postProcessPass;

    public override void Create()
    {
        _postProcessPass = new ChromaticAberrationRenderPass(_shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_postProcessPass);
    }
}