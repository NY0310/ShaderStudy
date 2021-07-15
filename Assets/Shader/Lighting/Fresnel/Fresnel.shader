Shader "Hidden/Fresnel"
{
    Properties
    {
        [PowerSlider(0.1)] _F0 ("F0", Range(0.0, 1.0)) = 0.02
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            half _Metalness;

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half vdotn      : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half3 viewDir   = normalize(ObjSpaceViewDir(v.vertex));
                o.vdotn         = dot(viewDir, v.normal.xyz);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 金属性に応じてF0を変える
                half f0         = _Metalness;
                half fresnel    = f0 + (1.0h - f0) * pow(1.0h - i.vdotn, 5);
                return fresnel;
            }
            ENDCG
        }
    }
}
