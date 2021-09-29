Shader "SmithGGXCorrelated"
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

            // 幾何減衰項(V項) マイクロファセットの凹凸に遮れた反射光
            inline float V_SmithGGXCorrelated(float ndotl, float ndotv, float alpha)
            {
                float lambdaV = ndotl * (ndotv * (1 - alpha) + alpha);
                float lambdaL = ndotv * (ndotl * (1 - alpha) + alpha);

                return 0.5f / (lambdaV + lambdaL + 0.0001);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal = normalize(i.worldNormal);
                half3 viewDir = normalize(i.viewDir);
                half ndotv = abs(dot(normal, viewDir));
                float ndotl = max(0, dot(normal, _WorldSpaceLightPos0.xyz));
                
                float alpha = _Roughness * _Roughness;
                half V = V_SmithGGXCorrelated(_Roughness,ndotv,alpha);
                return fixed4(V * _LightColor0.rgb,1);
            }
            ENDCG
        }
    }
}
