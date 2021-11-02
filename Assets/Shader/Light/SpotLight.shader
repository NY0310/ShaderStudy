Shader "Hidden/SpotLight"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
       // _DistanceAttenuation ("DistanceAttenuation", Float) = 0.1　　// 距離減衰の係数
        _SpotFalloff ("SpotFalloff", Float) = 0.1                // 減衰係数
        _InnerCornAngle ("SpotTheta", Float) = 20.0               // スポットライト内側の角度
        _OuterCornAngle ("OuterCornAngle", Float) = 40.0          // スポットライト外側の角度
    }
    SubShader
    {
        // No culling or depth
        //Cull Off ZWrite Off ZTest Always

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
                half3  normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                half3  viewDir    : TEXCOORD2;
                half3  normalWS   : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.positionWS = mul(unity_ObjectToWorld,v.positionOS);
                o.viewDir = UnityWorldSpaceViewDir(o.positionWS);
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            half _DistanceAttenuation;
            half _SpotFalloff;
            half _InnerCornAngle;
            half _OuterCornAngle;
            half4 _Color;

            half4 frag (v2f i) : SV_Target
            {
                half4 retColor = (0,0,0,1);
                // 焦点から頂点へのベクトル
                half3 lightDir = UnityWorldSpaceLightDir(i.positionWS);
                // ライトから頂点への距離
                float lightLength = length(lightDir);
                // 距離による減衰値
                float attenuation = 1.0 / (_DistanceAttenuation * lightLength * lightLength);
                // ライトベクトルを正規化
                half3 nLightDir = normalize(lightDir);
                // 光源の向き
                half3 nSporDir = normalize(_WorldSpaceLightPos0.xyz);
                // ライトベクトルと光源ベクトルの角度
                float cosAlpha = dot(nLightDir, nSporDir);
                float innerHalfAngle = cos(radians(_InnerCornAngle) / 2.0);
                float outerHalfAngle = cos(degrees(_OuterCornAngle) / 2.0);
                if (cosAlpha <= outerHalfAngle)
                {
                    // out-range
                    // attenuation * 0.f;
                    retColor = _Color;
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
                    //half3 normal = normalize(i.normalWS);
                    //half3 normal = normalize((vec4(vertex_normal, 0.0) * model_mat).xyz);
                    // half3 light = -nLightDir;
                    // float diffusePower = saturate(dot(normal, light));
                    // half3 eye = -normalize(i.viewDir);
                    // half3 halfVec = normalize(light + eye);
                    // float specular = pow(saturate(dot(normal, halfVec)), specular_shininess);
                    //retColor = vertex_color * diffuse_color * diffusePower * attenuation + AmbientColor + _SpecularColor * specular;
                    retColor = _Color * attenuation;
                    //retColor.a = 1;
                }

                return retColor;
            }
            ENDCG
        }
    }
}

