Shader "NewImageEffectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                float3 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
                float uv3 : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            fixed4 color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
             //   float4 s = v.uv2;
             //   float uv3 =  v.uv3;
             color = fixed4(1,0,0,1);
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
              //  fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return color;
            }
            ENDCG
        }
    }
}
