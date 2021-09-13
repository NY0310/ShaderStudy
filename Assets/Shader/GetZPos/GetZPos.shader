Shader "Depth"
{
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
                half depth : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                COMPUTE_EYEDEPTH(o.depth.x);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return half4(i.depth,0,0,1);
            }
            ENDCG
        }
    }
}
