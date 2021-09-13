


grad_pos = ComputeGrabScreenPos(o.vertex);
scr_pos = ComputeScreenPos(o.vertex);
geo_pos = world_pos;

float DepthFoam(float4 grab_pos, float4 scr_pos, float3 geo_pos, out float3 foam_normal){
	float4 dist_uv = grab_pos;
	float surf_depth = UNITY_Z_0_FAR_FROM_CLIPSPACE(scr_pos.z);
	float ref_fix = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(grab_pos))));
	float depth_diff = (ref_fix - surf_depth);
	
	float2 fuv = geo_pos.xz * _DepthFoamSize;
	float scroll = _Time.x * _FlowSpeed;
	float c_a = tex2D(_DepthFoamTex, fuv - float2(scroll, cos(fuv.x))).r;
	float c_b = tex2D(_DepthFoamTex, fuv * 0.5 + float2(sin(fuv.y), scroll)).b;
	float mask = (c_a + c_b) * 0.95;
	mask = saturate(mask * mask);
	
	float fa = 0;
	if(depth_diff < _EdgeWidth * _EdgeFalloff){
		fa = depth_diff / (_EdgeWidth * _EdgeFalloff);
		mask *= fa;
	}
	float falloff = 1.0 - saturate(depth_diff / _EdgeWidth);

	float depth_foam = saturate(falloff - mask);
	depth_foam *= tex2D(_DetailDepthFoamTex, geo_pos.xz * _DetailDepthFoamSize);

	float3 tangent_space_geo_normal = float3(0.0, 0.0, 1.0);
	foam_normal = UnpackNormal(tex2D(_DetailDepthFoamNormalTex, geo_pos.xz * _DetailDepthFoamSize));
	foam_normal = lerp(tangent_space_geo_normal, foam_normal, depth_foam * _FoamNormalStrength);
	foam_normal = normalize(foam_normal);

	return depth_foam;
}