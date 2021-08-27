Shader "Hidden/LinearWorkflow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Intensity("Intensity", Range(0,1)) = 0
        [Toggle] _USE_FAST("Is Liner", Float) = 0
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

            #define FLT_EPSILON     1.192092896e-07 // Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
            
            
            float3 PositivePow(float3 base, float3 power)
            {
                return pow(max(abs(base), float3(FLT_EPSILON, FLT_EPSILON, FLT_EPSILON)), power);
            }


            half3 sRGBToLinear(half3 c)
            {
                half3 linearRGBLo = c / 12.92;
                half3 linearRGBHi = PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
                half3 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
                return linearRGB;
            }

            
            half4 sRGBToLinear(half4 c)
            {
                return half4(sRGBToLinear(c.rgb), c.a);
            }


            half3 LinearTosRGB(half3 c)
            {
                half3 sRGBLo = c * 12.92;
                half3 sRGBHi = (PositivePow(c, half3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
                half3 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
                return sRGB;
            }

            half4 LinearTosRGB(half4 c)
            {
                return half4(LinearTosRGB(c.rgb), c.a);
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                half lambert = max(0,dot(i.normal,WorldSpaceLightDir(i.vertex))) * _Intensity;
                #if UNITY_COLORSPACE_GAMMA
                    //albedo = pow(albedo,2.2);
                    albedo = sRGBToLinear(albedo);
                #endif
                fixed4 retColor = albedo * lambert;
                #if UNITY_COLORSPACE_GAMMA
                    //retColor = pow(retColor, 1 / 2.2);
                    retColor = LinearTosRGB(retColor);
                #endif            
                return retColor;
            }
            ENDCG
        }
    }
}
