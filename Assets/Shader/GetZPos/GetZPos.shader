Shader "Zpos"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD1;
            };

            // デプステクスチャの宣言
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //  深度バッファの値を取得するためにスクリーンスペースでの位置を求める
                o.projPos = ComputeScreenPos(o.vertex);

                // ビュー座標系での深度値を求める
                COMPUTE_EYEDEPTH(o.projPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 描画するピクセルの深度バッファの値
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,i.projPos));
                 // 描画するピクセルの深度値
                float partZ = i.projPos.z;

                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}