Shader "Custom/Emission" 
{
    Properties 
    {
        _MainColor("Color", Color) = (1,1,1,1)       
        _EmissionTex ("Emission Texture", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)    
    }
    SubShader 
    {
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _MainColor;
            float4 _EmissionColor;      
            sampler2D _EmissionTex;  

            fixed4 frag(v2f_img i) : SV_Target 
            {
                // albedoにEmissionの色を足している
                return _MainColor + tex2D(_EmissionTex,i.uv) * _EmissionColor;  
            }
            ENDCG
        }
    }
}