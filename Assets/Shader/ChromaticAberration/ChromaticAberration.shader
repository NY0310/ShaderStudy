Shader "Hidden/ChromaticAberration"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Intensity ("Intensity", Range(0.0, 1.0)) = 0.1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            half _Intensity;

            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                // uvを-0.5〜0.5にする
                half2 uvBase = i.uv - 0.5h;
                // R値を拡大する
                half2 uvR = uvBase * (1.0h - _Intensity * 2.0h) + 0.5h;
                col.r = tex2D(_MainTex, uvR).r;
                // G値を拡大する
                half2 uvG = uvBase * (1.0h - _Intensity) + 0.5h;
                col.g = tex2D(_MainTex, uvG).g;

                return col;
            }
            ENDCG
        }
    }
}
