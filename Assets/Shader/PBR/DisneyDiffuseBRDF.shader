Shader "DisneyDiffuseBRDF"
{
    Properties
    {
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

            inline half3 F_Schlick(half3 f0, half3 f90, half cos)
            {
                return f0 + (f90 - f0) * pow(1 - cos, 5);
            }

            inline half Fd_Burley(half ndotv, half ndotl, half ldoth, half roughness)
            {
                half fd90 = 0.5 + 2 * ldoth * ldoth * roughness;
                half lightScatter = F_Schlick(1,fd90,ndotl);
                half viewScatter = F_Schlick(1,fd90,ndotv);
                half diffuse = lightScatter * viewScatter / UNITY_PI;
                return diffuse;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal = normalize(i.worldNormal);
                half3 viewDir = normalize(i.viewDir);
                half ndotv = abs(dot(normal, viewDir));
                float ndotl = max(0, dot(normal, _WorldSpaceLightPos0.xyz));
                float3 halfDir = normalize(_WorldSpaceLightPos0.xyz + viewDir);
                half ldoth = max(0, dot(_WorldSpaceLightPos0.xyz, halfDir));
                
                
                half diffuse = Fd_Burley(ndotv,ndotl,ldoth,_Roughness);
                return fixed4(diffuse * _LightColor0.rgb,1);
            }
            ENDCG
        }
    }
}
