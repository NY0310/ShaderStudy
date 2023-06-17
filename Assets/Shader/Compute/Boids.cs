using System;
using System.Runtime.InteropServices;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using Random = Unity.Mathematics.Random;

public class Boids : MonoBehaviour
{
    public struct BoidState
    {
        public Vector3 Position;
        public Vector3 Forward;
    }

    [Serializable]
    public class BoidConfig
    {
        public float moveSpeed = 1f;
        // 分離
        [Range(0f, 1f)] public float separationWeight = .5f;
        // 整列
        [Range(0f, 1f)] public float alignmentWeight = .5f;
        // 結合
        [Range(0f, 1f)] public float targetWeight = .5f;

        public Transform boidTarget;
    }

    public int boidCount = 10000;

    public float3 boidExtent = new(32f, 32f, 32f);

    public ComputeShader BoidComputeShader;

    public BoidConfig boidConfig;

    GraphicsBuffer _boidBuffer;
    GraphicsBuffer _argsBuffer;
    int _kernelIndex;

    [SerializeField]
    Mesh mesh;
    [SerializeField]
    Material drawMaterial;

    void Start()
    {
        InitializeArgsBuffer();
        InitializeBoidsBuffer();
    }

    private void InitializeArgsBuffer()
    {
        var args = new uint[] { 0, 0, 0, 0, 0 };

        args[0] = mesh.GetIndexCount(0);
        args[1] = (uint)boidCount;

        _argsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, args.Length, sizeof(uint));
        _argsBuffer.SetData(args);
    }

    private void InitializeBoidsBuffer()
    {
        var random = new Random(256);
        var boidArray = new NativeArray<BoidState>(boidCount, Allocator.Temp, NativeArrayOptions.UninitializedMemory);
        for (var i = 0; i < boidArray.Length; i++)
        {
            boidArray[i] = new BoidState
            {
                // 指定した範囲でランダムに座標を決定
                Position = random.NextFloat3(-boidExtent, boidExtent),
                // 
                Forward = math.rotate(random.NextQuaternionRotation(), Vector3.forward),
            };
        }
        // GraphicsBuffer生成
        _boidBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, boidArray.Length, Marshal.SizeOf<BoidState>());
        // boidBufferに値を設定
        _boidBuffer.SetData(boidArray);
    }

    void Update()
    {
        UpdateBoids();
        RenderMesh();
    }

    void UpdateBoids()
    {
        var boidTarget = boidConfig.boidTarget != null
            ? boidConfig.boidTarget.position
            : transform.position;
        BoidComputeShader.SetFloat("deltaTime", Time.deltaTime);
        BoidComputeShader.SetFloat("separationWeight", boidConfig.separationWeight);
        BoidComputeShader.SetFloat("alignmentWeight", boidConfig.alignmentWeight);
        BoidComputeShader.SetFloat("targetWeight", boidConfig.targetWeight);
        BoidComputeShader.SetFloat("moveSpeed", boidConfig.moveSpeed);
        BoidComputeShader.SetVector("targetPosition", boidTarget);
        // ComputeShaderに生成するインスタンスの数をセット
        BoidComputeShader.SetInt("numBoids", boidCount);
        _kernelIndex = BoidComputeShader.FindKernel("CSMain");
        // ComputeShaderにboidBufferをセット
        BoidComputeShader.SetBuffer(_kernelIndex, "boidBuffer", _boidBuffer);

        BoidComputeShader.GetKernelThreadGroupSizes(_kernelIndex, out var x, out var y, out var z);
        BoidComputeShader.Dispatch(_kernelIndex, (int)(boidCount / x), 1, 1);
    }

    void RenderMesh()
    {
        if (!SystemInfo.supportsInstancing)
        {
            return;
        }
        drawMaterial.SetBuffer("_BoidDataBuffer", _boidBuffer);
        BoidState[] data = new BoidState[10];
        _boidBuffer.GetData(data);
        Debug.Log(data);
        Graphics.DrawMeshInstancedIndirect
        (
            mesh,
            0,
            drawMaterial,
            new Bounds(Vector3.zero, new Vector3(1000.0f, 1000.0f, 1000.0f)),
            _argsBuffer,
            0,
            null
        );
    }

    void OnDisable()
    {
        _boidBuffer?.Dispose();
        _argsBuffer?.Dispose();
    }
}
