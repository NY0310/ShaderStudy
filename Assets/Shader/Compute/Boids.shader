Shader "Boids"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _ObjectScale ("Scale", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Opaque" }
            LOD 200
            
            HLSLPROGRAM
            //#pragma surface surf Standard vertex:vert addshadow
            #pragma instancing_options procedural:setup
            #pragma multi_compile_instancing
            #pragma target 4.5

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionCS               : SV_POSITION;
                half3 data : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // Boidの構造体
            struct BoidState
            {
                float3 position; // 位置
                float3 forward; // 速度
            };

           // #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                // Boidデータの構造体バッファ
                StructuredBuffer<BoidState> _BoidDataBuffer;
         //   #endif

            sampler2D _MainTex; // テクスチャ

            half3 _Color;      // カラー
            float3 _ObjectScale; // Boidオブジェクトのスケール

            // オイラー角（ラジアン）を回転行列に変換
            float4x4 eulerAnglesToRotationMatrix(float3 angles)
            {
                float ch = cos(angles.y); float sh = sin(angles.y); // heading
                float ca = cos(angles.z); float sa = sin(angles.z); // attitude
                float cb = cos(angles.x); float sb = sin(angles.x); // bank

                // Ry-Rx-Rz (Yaw Pitch Roll)
                return float4x4(
                ch * ca + sh * sb * sa, -ch * sa + sh * sb * ca, sh * cb, 0,
                cb * sa, cb * ca, -sb, 0,
                -sh * ca + ch * sb * sa, sh * sa + ch * sb * ca, ch * cb, 0,
                0, 0, 0, 1
                );
            }

            // 頂点シェーダ
            Varyings vert(Attributes input, uint instanceID : SV_InstanceID)
            {
                Varyings output = (Varyings)0;

                // インスタンスIDからBoidのデータを取得
                BoidState boidData = _BoidDataBuffer[instanceID]; 

                float3 pos = boidData.position.xyz; // Boidの位置を取得
                float3 scl = _ObjectScale;          // Boidのスケールを取得

                // オブジェクト座標からワールド座標に変換する行列を定義
                float4x4 object2world = (float4x4)0; 
                // スケール値を代入
                object2world._11_22_33_44 = float4(scl.xyz, 1.0);

                // 速度からY軸についての回転を算出
                float rotY = atan2(boidData.forward.x, boidData.forward.z);
                // 速度からX軸についての回転を算出
                float rotX = -asin(boidData.forward.y / (length(boidData.forward.xyz) + 1e-8));
                // オイラー角（ラジアン）から回転行列を求める
                float4x4 rotMatrix = eulerAnglesToRotationMatrix(float3(rotX, rotY, 0));
                // 行列に回転を適用
                object2world = mul(rotMatrix, object2world);
                // 行列に位置（平行移動）を適用
                object2world._14_24_34 += pos.xyz;

                // 頂点を座標変換
                float4 positionWS = mul(object2world, input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);

                return output;

                //#endif
            }
            
            void setup()
            {
            }

            half4 frag(Varyings input) : SV_Target
            {
                return half4(_Color,1);
            }
            ENDHLSL
        }
    }
}