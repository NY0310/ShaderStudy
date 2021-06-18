using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental;
using UnityEngine.Experimental.Rendering;

[ExecuteInEditMode]
public class DrawObjAssetPipe : RenderPipelineAsset
{
    [SerializeField]
    private float modelRenderResolutionRate = 0.7f;
    public float ModelRenderResolutionRate => modelRenderResolutionRate;
    protected override RenderPipeline CreatePipeline()
    {
        return new DrawObjPipeInstance(this);
    }

#if UNITY_EDITOR
    [UnityEditor.MenuItem("SRP-Demo/02 - Create Basic Asset Pipeline")]
    static void CraeteDrawObjAssetPipeline()
    {
        // このクラスのインスタンスを作成
        var instance = ScriptableObject.CreateInstance<DrawObjAssetPipe>();
        // アセット化
        UnityEditor.AssetDatabase.CreateAsset(instance, "Assets/Shader/SRP/1-DrawObjAssetPipe.asset");
    }
#endif
}



public class DrawObjPipeInstance : RenderPipeline
{
    private const int MAX_CAMERA_COUNT = 4;

    private const string FORWARD_SHADER_TAG = "ToonForward";

    private CommandBuffer[] commandBuffers = new CommandBuffer[MAX_CAMERA_COUNT];

    private DrawObjAssetPipe drawObjAssetPipe;

    private CullingResults cullingResults;

    private RenderTargetIdentifier[] renderTargetIdentifiers = new RenderTargetIdentifier[(int)RenderTextureType.Count];

    private enum RenderTextureType
    {
        ModelColor,
        ModelDepth,

        Count,
    }
    public DrawObjPipeInstance(DrawObjAssetPipe asset)
    {
        drawObjAssetPipe = asset;

        // CommandBufferの事前生成
        for (int i = 0; i < commandBuffers.Length; i++)
        {
            commandBuffers[i] = new CommandBuffer();
            commandBuffers[i].name = "ToonRP";
        }
    }

    /// <summary>
    /// 描画処理
    /// </summary>
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        for (int i = 0; i < cameras.Length; i++)
        {
            var camera = cameras[i];
            var commandBuffer = commandBuffers[i];

            // カメラプロパティ設定
            context.SetupCameraProperties(camera);

            // カメラからカリングのための情報を取得
            if (!camera.TryGetCullingParameters(false, out var cullingParameters))
            {
                continue;
            }
            // ScriptableCullingParametersに基づいてカリングする
            cullingResults = context.Cull(ref cullingParameters);

            // RenderTexture作成
            CreateRenderTexture(context, camera, commandBuffer);

            // モデル描画用RTのClear
            ClearModelRenderTexture(context, camera, commandBuffer);

            // ライト情報のセットアップ
            SetupLights(context, camera, commandBuffer);

            // 不透明オブジェクト描画
            DrawOpaque(context, camera, commandBuffer);

            // Skybox描画
            if (camera.clearFlags == CameraClearFlags.Skybox)
            {
                context.DrawSkybox(camera);
            }

            // 半透明オブジェクト描画
            DrawTransparent(context, camera, commandBuffer);

            // CameraTargetに描画
            RestoreCameraTarget(context, commandBuffer);

#if UNITY_EDITOR
            // Gizmo
            if (UnityEditor.Handles.ShouldRenderGizmos())
            {
                context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            }
#endif

            // PostProcessing

#if UNITY_EDITOR
            // Gizmo
            if (UnityEditor.Handles.ShouldRenderGizmos())
            {
                context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
            }
#endif

            // RenderTexture解放
            ReleaseRenderTexture(context, commandBuffer);
        }

        context.Submit();
    }

    private void CreateRenderTexture(ScriptableRenderContext context, Camera camera, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        var width = camera.targetTexture?.width ?? Screen.width;
        var height = camera.targetTexture?.height ?? Screen.height;

        var modelWidth = (int)((float)width * drawObjAssetPipe.ModelRenderResolutionRate);
        var modelHeight = (int)((float)height * drawObjAssetPipe.ModelRenderResolutionRate);

        commandBuffer.GetTemporaryRT((int)RenderTextureType.ModelColor, modelWidth, modelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        commandBuffer.GetTemporaryRT((int)RenderTextureType.ModelDepth, modelWidth, modelHeight, 0, FilterMode.Point, RenderTextureFormat.Depth);

        context.ExecuteCommandBuffer(commandBuffer);

        for (int i = 0; i < (int)RenderTextureType.Count; i++)
        {
            renderTargetIdentifiers[i] = new RenderTargetIdentifier(i);
        }
    }


    private void ClearModelRenderTexture(ScriptableRenderContext context, Camera camera, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        // RenderTarget設定
        commandBuffer.SetRenderTarget(renderTargetIdentifiers[(int)RenderTextureType.ModelColor], renderTargetIdentifiers[(int)RenderTextureType.ModelDepth]);

        if (camera.clearFlags == CameraClearFlags.Depth || camera.clearFlags == CameraClearFlags.Skybox)
        {
            commandBuffer.ClearRenderTarget(true, false, Color.black, 1.0f);
        }
        else if (camera.clearFlags == CameraClearFlags.SolidColor)
        {
            commandBuffer.ClearRenderTarget(true, true, camera.backgroundColor, 1.0f);
        }

        context.ExecuteCommandBuffer(commandBuffer);
    }

     private void SetupLights(ScriptableRenderContext context, Camera camera, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        // DirectionalLightの探索
        int lightIndex = -1;
        for (int i = 0; i < cullingResults.visibleLights.Length; i++)
        {
            var visibleLight = cullingResults.visibleLights[i];
            var light = visibleLight.light;


            if (light == null || light.shadows == LightShadows.None || light.shadowStrength <= 0f || light.type != LightType.Directional)
            {
                continue;
            }

            lightIndex = i;
            break;
        }

        if (lightIndex < 0)
        {
            commandBuffer.DisableShaderKeyword("ENABLE_DIRECTIONAL_LIGHT");
            context.ExecuteCommandBuffer(commandBuffer);
            return;
        }

        // ライトのパラメータ設定
        {
            var visibleLight = cullingResults.visibleLights[lightIndex];
            var light = visibleLight.light;

            commandBuffer.EnableShaderKeyword("ENABLE_DIRECTIONAL_LIGHT");
            commandBuffer.SetGlobalColor("_LightColor", light.color * light.intensity);
            commandBuffer.SetGlobalVector("_LightVector", -light.transform.forward);
            context.ExecuteCommandBuffer(commandBuffer);
        }
    }

    /// <summary>
    /// 不透明オブジェクトの描画
    /// </summary>
    private void DrawOpaque(ScriptableRenderContext context, Camera camera, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        commandBuffer.SetRenderTarget(renderTargetIdentifiers[(int)RenderTextureType.ModelColor], renderTargetIdentifiers[(int)RenderTextureType.ModelDepth]);
        context.ExecuteCommandBuffer(commandBuffer);

        // 描画順 https://docs.unity3d.com/ja/current/ScriptReference/Rendering.SortingCriteria.html
        var sortingSettings = new SortingSettings(camera) { criteria = SortingCriteria.CommonOpaque };
        // ここで指定したTagを記述したシェーダーのみ描画される
        var settings = new DrawingSettings(new ShaderTagId(FORWARD_SHADER_TAG), sortingSettings);
        // https://docs.unity3d.com/ScriptReference/Rendering.FilteringSettings.html
        var filterSettings = new FilteringSettings(
            // 指定されたレンダーキューの間のオブジェクトのみ描画する(0-2500)
            new RenderQueueRange(0, (int)RenderQueue.GeometryLast),
            // カメラに指定されたレイヤーのみ描画する
            camera.cullingMask
            );

        // Rendering
        context.DrawRenderers(cullingResults, ref settings, ref filterSettings);
    }

    private void DrawTransparent(ScriptableRenderContext context, Camera camera, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        commandBuffer.SetRenderTarget(renderTargetIdentifiers[(int)RenderTextureType.ModelColor], renderTargetIdentifiers[(int)RenderTextureType.ModelDepth]);
        context.ExecuteCommandBuffer(commandBuffer);

        // Filtering, Sort
        var sortingSettings = new SortingSettings(camera) { criteria = SortingCriteria.CommonTransparent };
        var settings = new DrawingSettings(new ShaderTagId(FORWARD_SHADER_TAG), sortingSettings);
        var filterSettings = new FilteringSettings(
            // 指定されたレンダーキューの間のオブジェクトのみ描画する(2500-3000)
            new RenderQueueRange((int)RenderQueue.GeometryLast, (int)RenderQueue.Transparent),
            camera.cullingMask
            );

        // 描画
        context.DrawRenderers(cullingResults, ref settings, ref filterSettings);
    }

    private void RestoreCameraTarget(ScriptableRenderContext context, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        var cameraTarget = new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget);

        commandBuffer.SetRenderTarget(cameraTarget);
        commandBuffer.Blit(renderTargetIdentifiers[(int)RenderTextureType.ModelColor], cameraTarget);

        context.ExecuteCommandBuffer(commandBuffer);
    }

    private void ReleaseRenderTexture(ScriptableRenderContext context, CommandBuffer commandBuffer)
    {
        commandBuffer.Clear();

        for (int i = 0; i < (int)RenderTextureType.Count; i++)
        {
            commandBuffer.ReleaseTemporaryRT(i);
        }

        context.ExecuteCommandBuffer(commandBuffer);
    }
}
