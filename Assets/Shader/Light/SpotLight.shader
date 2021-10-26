Shader "Hidden/SpotLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DistanceAttenuation ("LightAttenuation", Float) = 0.1　　// 距離減衰の係数
        _SpotFalloff ("SpotFalloff", Float) = 0.1                // 減衰係数
        _InnerCornAngle ("SpotTheta", Float) = 20               // スポットライト内側の角度
        _OuterCornAngle ("OuterCornAngle", Float) = 40          // スポットライト外側の角度
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
                o.positionWS = mul(unity_objecttoworld,v.positionOS);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            half _DistanceAttenuation;
            half _SpotFalloff;
            half _InnerCornAngle;
            half _OuterCornAngle;

            half4 frag (v2f i) : SV_Target
            {
                half4 retColor = (0,0,0,1);
                gl_Position = vec4(vertex_pos, 1.0) * pvm_mat;
                // 焦点から頂点へのベクトル
                half3 lightDir = UnityWorldSpaceLightDir(i.positionWS);
                // ライトから頂点への距離
                float lightLength = length(lightDir);
                // 距離による減衰値
                float attenuation = 1.0 / (_DistanceAttenuation * lightLength * lightLength);
                // ライトベクトルを正規化
                half3 nLightDir = normalize(lightDir);
                // 光源の向き
                half3 nSporDir = normalize();
                // ライトベクトルと光源ベクトルの角度
                float cosAlpha = dot(nLightDir, nSporDir);
                float innerHalfAngle = cos(_InnerCornAngle / 2.0);
                float outerHalfAngle = cos(_OuterCornAngle / 2.0);
                if (cosAlpha <= outerHalfAngle)
                {
                    // out-range
                    // attenuation * 0.f;
                    retColor = ambient_color;
                }
                else
                {
                    if (cosAlpha > innerHalfAngle)
                    {
                        // inner corn
                        // attenuation * 1.f
                    }
                    else
                    {
                        // outer corn
                        attenuation *= pow((cosAlpha - outerHalfAngle)/(innerHalfAngle - outerHalfAngle), _SpotFalloff);
                    }
                    half3 normal = normalize((vec4(vertex_normal, 0.0) * model_mat).xyz);
                    half3 light = -nLightDir;
                    float diffuse_power = clamp(dot(normal, light), 0.0, 1.0);
                    half3 eye = -normalize(eye_dir);
                    half3 half_vec = normalize(light + eye);
                    float specular = pow(clamp(dot(normal, half_vec), 0.0, 1.0), specular_shininess);
                    retColor = vertex_color * diffuse_color * diffuse_power * attenuation + ambient_color + specular_color * specular;
                }

                return retColor;
            }
            ENDCG
        }
    }
}

