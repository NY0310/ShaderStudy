Shader "Hidden/SpotLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DistanceAttenuation ("LightAttenuation", Float) = 0.1　　// 距離減衰の係数
        _SpotFalloff ("SpotFalloff", Float) = 0.1       // 減衰係数
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
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.positionWS = Unityobje
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            half _DistanceAttenuation;
            half _SpotFalloff;

            fixed4 frag (v2f i) : SV_Target
            {
                gl_Position = vec4(vertex_pos, 1.0) * pvm_mat;
                // 焦点から頂点へのベクトル
                half3 lightDir = i.vertex - _WorldSpaceLightPos0.xyz;
                // ライトから頂点への距離
                float lightLength = length(lightDir);
                // 距離による減衰値
                float attenuation = 1.0 / (_DistanceAttenuation * lightLength * lightLength);
                // ライトベクトルを正規化
                half3 nLightDir = normalize(lightDir);
                // 光源の向き
                half3 spor_dirN = normalize(spot_dir);
                float cos_alpha = dot(lightDirN, spor_dirN);
                float cos_half_theta = cos(spot_theta / 2.0);
                float cos_half_phi = cos(spot_phi / 2.0);
                if (cos_alpha <= cos_half_phi)
                {
                    // out-range
                    // attenuation * 0.f;
                    color = ambient_color;
                    return;
                }
                else
                {
                    if (cos_alpha > cos_half_theta)
                    {
                        // inner corn
                        // attenuation * 1.f
                    }
                    else
                    {
                        // outer corn
                        attenuation *= pow((cos_alpha - cos_half_phi)/(cos_half_theta - cos_half_phi), _SpotFalloff);
                    }
                    vec3 normal = normalize((vec4(vertex_normal, 0.0) * model_mat).xyz);
                    vec3 light = -nLightDir;
                    float diffuse_power = clamp(dot(normal, light), 0.0, 1.0);
                    vec3 eye = -normalize(eye_dir);
                    vec3 half_vec = normalize(light + eye);
                    float specular = pow(clamp(dot(normal, half_vec), 0.0, 1.0), specular_shininess);
                    color = vertex_color * diffuse_color * diffuse_power * attenuation + ambient_color + specular_color * specular;
                }
            }
            ENDCG
        }
    }
}

