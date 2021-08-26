Shader "Hidden/LinearWorkflow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Intensity("Intensity", Range(0,1)) = 0
       // [Toggle] _IsLiner("Is Liner", Float) = 0
    }
    
    SubShader
    {
        // No culling or depth
       // Cull Off ZWrite Off ZTest Always

        

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma shader_feature _ISLINER_ON

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 normal : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            sampler2D _MainTex;
            half _Intensity;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                half lambert = max(0,dot(i.normal,WorldSpaceLightDir(i.vertex))) * _Intensity;
#if !UNITY_COLORSPACE_GAMMA
                albedo = pow(albedo,2.2);
#endif
                fixed4 retColor = albedo * lambert;
#if !UNITY_COLORSPACE_GAMMA
                retColor = pow(retColor, 1 / 2.2);
#endif            
                return retColor;
            }
            ENDCG
        }
    }
}