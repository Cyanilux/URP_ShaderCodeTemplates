
// ---------------------------------------------------------------------------
// Includes
// ---------------------------------------------------------------------------

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

// ---------------------------------------------------------------------------
// Textures, Samplers & Global Properties
// ---------------------------------------------------------------------------
// (note, BaseMap, BumpMap and EmissionMap is being defined by the SurfaceInput.hlsl include)
TEXTURE2D(_MetallicSpecGlossMap); 	SAMPLER(sampler_MetallicSpecGlossMap);
TEXTURE2D(_OcclusionMap); 			SAMPLER(sampler_OcclusionMap);

// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha) {
	half4 specGloss;
	#ifdef _METALLICSPECGLOSSMAP
		specGloss = SAMPLE_TEXTURE2D(_MetallicSpecGlossMap, sampler_MetallicSpecGlossMap, uv);
		#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			specGloss.a = albedoAlpha * _Smoothness;
		#else
			specGloss.a *= _Smoothness;
		#endif
	#else // _METALLICSPECGLOSSMAP
		#if _SPECULAR_SETUP
			specGloss.rgb = _SpecColor.rgb;
		#else
			specGloss.rgb = _Metallic.rrr;
		#endif

		#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			specGloss.a = albedoAlpha * _Smoothness;
		#else
			specGloss.a = _Smoothness;
		#endif
	#endif
	return specGloss;
}

half SampleOcclusion(float2 uv) {
	#ifdef _OCCLUSIONMAP
	#if defined(SHADER_API_GLES)
		return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
	#else
		half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
		return LerpWhiteTo(occ, _OcclusionStrength);
	#endif
	#else
		return 1.0;
	#endif
}

// ---------------------------------------------------------------------------
// SurfaceData
// ---------------------------------------------------------------------------

void InitializeSurfaceData(Varyings IN, out SurfaceData surfaceData){
	surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

	half4 albedoAlpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
	surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
	surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * IN.color.rgb;

	surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
	surfaceData.emission = SampleEmission(IN.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
	surfaceData.occlusion = SampleOcclusion(IN.uv);
	
	half4 specGloss = SampleMetallicSpecGloss(IN.uv, albedoAlpha.a);
	#if _SPECULAR_SETUP
		surfaceData.metallic = 1.0h;
		surfaceData.specular = specGloss.rgb;
	#else
		surfaceData.metallic = specGloss.r;
		surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
	#endif
	surfaceData.smoothness = specGloss.a;
}