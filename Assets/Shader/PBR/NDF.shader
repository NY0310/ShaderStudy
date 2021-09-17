Shader "NDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness("Roughness", Range(0.0, 1.0)) = 0.5
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
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD2;
                half3 viewDir : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = UnityWorldSpaceViewDir(worldPos);
                return o;
            }

            sampler2D _MainTex;
            float _Roughness;
            float3 _LightColor0;

            // 法線分布関数（D項）ハーフベクトル方向を向いているマイクロファセットの多さ
            inline half D_GGX(half perceptualRoughness, half ndoth, half3 normal, half3 halfDir) {
                half3 ncrossh = cross(normal, halfDir);
                half a = ndoth * perceptualRoughness;
                half k = perceptualRoughness / (dot(ncrossh, ncrossh) + a * a);
                half d = k * k * UNITY_INV_PI;
                return min(d, 65504.0h);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal = normalize(i.worldNormal);
                half3 viewDir = normalize(i.viewDir);
                half ndotv = abs(dot(normal, viewDir));
                float ndotl = max(0, dot(normal, _WorldSpaceLightPos0.xyz));
                float3 halfDir = normalize(_WorldSpaceLightPos0.xyz + viewDir);
                
                half D = D_GGX(_Roughness,ndotv,normal,halfDir);
                return fixed4(D * _LightColor0.rgb,1);
            }
            ENDCG
        }
    }
}
