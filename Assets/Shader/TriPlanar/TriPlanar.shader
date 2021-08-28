Shader "Hidden/TriPlanar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TillingScale("Tilling Scale",Float) =  0
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 vertexWS : TEXCOORD2;
            };

            float3 tex3D(sampler2D tex,float3 p, float3 n)
            {

                float4 xaxis = tex2D(tex, p.yz);
                float4 yaxis = tex2D(tex, p.xz);
                float4 zaxis = tex2D(tex, p.xy);


                float3 blending = abs(n);
                blending = normalize(max(blending, 0.00001));

                // normalized total value to 1.0
                float b = (blending.x + blending.y + blending.z);
                blending /= b;

                // blend the results of the 3 planar projections.
                return (xaxis * blending.x + yaxis * blending.y + zaxis * blending.z).rgb;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertexWS= mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(tex3D(_MainTex,i.vertexWS,i.normal),1);
            }
            ENDCG
        }
    }
}
