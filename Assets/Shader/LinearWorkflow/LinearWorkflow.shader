Shader "Hidden/LinearWorkflow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Intensity("Intensity", Range(0,1)) = 0
        [KeywordEnum(NONE, ON, FAST)] _Linear_Mode("Linear Mode", Float) = 0
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma shader_feature _LINEAR_MODE_NONE _LINEAR_MODE_ON _LINEAR_MODE_FAST

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

            fixed4 sRGBToLinear(fixed4 sRGB)
            {
                #if _LINEAR_MODE_NONE
                    return sRGB;
                #elif _LINEAR_MODE_ON
                    if ( sRGB <= 0.04045 ) 
                    {
                        return sRGB / 12.92;
                    }
                    else 
                    {
                        return pow((sRGB + 0.055) / 1.055, 2.4);
                    }
                #elif _LINEAR_MODE_FAST
                    return fixed4(pow(sRGB.rgb,2.2),1);
                #endif
            }

            fixed4 LinearTosRGB(fixed4 Linear)
            {
                #if _LINEAR_MODE_NONE
                    return Linear
                #elif _LINEAR_MODE_ON
                    if ( Linear <= 0.0031308) 
                    {
                        return Linear * 12.92;
                    }
                    else {
                        return 1.055 * pow(Linear, 1.0 / 2.4) - 0.055;
                    }
                #elif _LINEAR_MODE_FAST
                    return pow(Linear,1.0/2.2);
                #endif
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                half lambert = max(0,dot(i.normal,WorldSpaceLightDir(i.vertex))) * _Intensity;
                fixed4 lAlbedo = sRGBToLinear(albedo);
                fixed4 retLColor = lAlbedo * lambert;
                fixed4 sRgbColor = LinearTosRGB(retLColor);
                return sRgbColor;
            }
            ENDCG
        }
    }
}
