// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

Shader "Cyanilux/URPTemplates/PBRLitShaderExample" {
	Properties {
		// Sorry the inspector is a little messy, but I'd rather not rely on a Custom ShaderGUI
		// or the one used by the Lit/Shader, as then adding new properties won't show
		// Tried to organise it somewhat, with spacing to help separate related parts.

		[MainTexture] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}
		[MainColor]   _BaseColor("Base Color", Color) = (1, 1, 1, 1)

		[Space(20)]
		[Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Float) = 0.5

		[Space(20)]
		[Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("Workflow, Specular (if on), Metallic (if off)", Float) = 0
		[Toggle(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)] _SmoothnessSource ("Smoothness Source, Albedo Alpha (if on) vs Metallic (if off)", Float) = 0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
		[Toggle(_METALLICSPECGLOSSMAP)] _MetallicSpecGlossMapToggle ("Use Metallic/Specular Gloss Map", Float) = 0
		_MetallicSpecGlossMap("Specular or Metallic Map", 2D) = "black" {}
		// Usually this is split into _SpecGlossMap and _MetallicGlossMap, but I find
		// that a bit annoying as I'm not using a custom ShaderGUI to show/hide them.

		[Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 0
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		// Not including Height (parallax) map in this example/template

		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
		[NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "bump" {}
		_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[Space(20)]
		[Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}

		[Space(20)]
		[Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Turn Specular Highlights Off", Float) = 0
		[Toggle(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentalReflections("Turn Environmental Reflections Off", Float) = 0
		// These are inverted fom what the URP/Lit shader does which is a bit annoying.
		// They would usually be handled by the Lit ShaderGUI but I'm using Toggle instead,
		// which assumes the keyword is more of an "on" state.

		// Not including Detail maps in this template
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		float4 _EmissionColor;
		float4 _SpecColor;
		float _Metallic;
		float _Smoothness;
		float _OcclusionStrength;
		float _Cutoff;
		float _BumpScale;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "ForwardLit"
			Tags { "LightMode"="UniversalForward" }

			HLSLPROGRAM
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			// ---------------------------------------------------------------------------
			// Keywords
			// ---------------------------------------------------------------------------

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local_fragment _OCCLUSIONMAP

			//#pragma shader_feature_local _PARALLAXMAP // v10+ only
			//#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED // v10+ only
			// Note, for this template not supporting parallax/height mapping or detail maps

			//#pragma shader_feature_local _ _CLEARCOAT _CLEARCOATMAP // v10+ only, URP/ComplexLit shader

			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

			// URP Keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			// Note, v11 changes these to :
			// #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION // v10+ only (for SSAO support)
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // v10+ only, renamed from "_MIXED_LIGHTING_SUBTRACTIVE"
			#pragma multi_compile _ SHADOWS_SHADOWMASK // v10+ only

			// Unity Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile_fog

			// GPU Instancing (not supported)
			//#pragma multi_compile_instancing

			// ---------------------------------------------------------------------------
			// Structs
			// ---------------------------------------------------------------------------

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attributes {
				float4 positionOS	: POSITION;
				#ifdef _NORMALMAP
					float4 tangentOS 	: TANGENT;
				#endif
				float4 normalOS		: NORMAL;
				float2 uv		    : TEXCOORD0;
				float2 lightmapUV	: TEXCOORD1;
				float4 color		: COLOR;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings {
				float4 positionCS 					: SV_POSITION;
				float2 uv		    				: TEXCOORD0;
				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
				float3 positionWS					: TEXCOORD2;

				#ifdef _NORMALMAP
					half4 normalWS					: TEXCOORD3;    // xyz: normal, w: viewDir.x
					half4 tangentWS					: TEXCOORD4;    // xyz: tangent, w: viewDir.y
					half4 bitangentWS				: TEXCOORD5;    // xyz: bitangent, w: viewDir.z
				#else
					half3 normalWS					: TEXCOORD3;
				#endif
				
				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					half4 fogFactorAndVertexLight	: TEXCOORD6; // x: fogFactor, yzw: vertex light
				#else
					half  fogFactor					: TEXCOORD6;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord 				: TEXCOORD7;
				#endif

				float4 color						: COLOR;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
				//UNITY_VERTEX_OUTPUT_STEREO
			};

			#include "PBRSurface.hlsl"
			#include "PBRInput.hlsl"

			// ---------------------------------------------------------------------------
			// Vertex Shader
			// ---------------------------------------------------------------------------

			Varyings LitPassVertex(Attributes IN) {
				Varyings OUT;

				//UNITY_SETUP_INSTANCE_ID(IN);
				//UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				//UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				#ifdef _NORMALMAP
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
				#else
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
				#endif

				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				half3 viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
				half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
				half fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
				
				#ifdef _NORMALMAP
					OUT.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
					OUT.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
					OUT.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
				#else
					OUT.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
					//OUT.viewDirWS = viewDirWS;
				#endif

				OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUV);
				OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);

				#ifdef _ADDITIONAL_LIGHTS_VERTEX
					OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				#else
					OUT.fogFactor = fogFactor;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					OUT.shadowCoord = GetShadowCoord(positionInputs);
				#endif

				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}

			// ---------------------------------------------------------------------------
			// Fragment Shader
			// ---------------------------------------------------------------------------
			
			half4 LitPassFragment(Varyings IN) : SV_Target {
				//UNITY_SETUP_INSTANCE_ID(IN);
				//UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
				
				// Setup SurfaceData
				SurfaceData surfaceData;
				InitializeSurfaceData(IN, surfaceData);

				// Setup InputData
				InputData inputData;
				InitializeInputData(IN, surfaceData.normalTS, inputData);

				// Simple Lighting (Lambert & BlinnPhong)
				half4 color = UniversalFragmentPBR(inputData, surfaceData);
				// See Lighting.hlsl to see how this is implemented.
				// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

				// Fog
				color.rgb = MixFog(color.rgb, inputData.fogCoord);
				//color.a = OutputAlpha(color.a, _Surface);
				return color;
			}
			ENDHLSL
		}

		// UsePass "Universal Render Pipeline/Lit/ShadowCaster"
		// UsePass "Universal Render Pipeline/Lit/DepthOnly"
		// Would be nice if we could just use the passes from existing shaders,
		// However this breaks SRP Batcher compatibility. Instead, we should define them :

		// ShadowCaster, for casting shadows
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON

			// Universal Pipeline Keywords
			// (v11+) This is used during shadow map generation to differentiate between directional and punctual (point/spot) light shadows, as they use different formulas to apply Normal Bias
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

			// Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
			/*
			#pragma vertex DisplacedShadowPassVertex (instead of ShadowPassVertex above)
			
			Varyings DisplacedShadowPassVertex(Attributes input) {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				
				// Example Displacement
				input.positionOS += float4(0, _SinTime.y, 0, 0);
				
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = GetShadowPositionHClip(input);
				return output;
			}
			*/
			ENDHLSL
		}

		// DepthOnly, used for Camera Depth Texture (if cannot copy depth buffer instead, and the DepthNormals below isn't used)
		Pass {
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ColorMask 0
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

			// Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
			/*
			#pragma vertex DisplacedDepthOnlyVertex (instead of DepthOnlyVertex above)
			
			Varyings DisplacedDepthOnlyVertex(Attributes input) {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				
				// Example Displacement
				input.positionOS += float4(0, _SinTime.y, 0, 0);
				
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = TransformObjectToHClip(input.position.xyz);
				return output;
			}
			*/
			
			ENDHLSL
		}

		// DepthNormals, used for SSAO & other custom renderer features that request it
		Pass {
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

			// Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
			/*
			#pragma vertex DisplacedDepthNormalsVertex (instead of DepthNormalsVertex above)

			Varyings DisplacedDepthNormalsVertex(Attributes input) {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				
				// Example Displacement
				input.positionOS += float4(0, _SinTime.y, 0, 0);
				
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = TransformObjectToHClip(input.position.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
				output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
				return output;
			}
			*/
			
			ENDHLSL
		}
		

		// Note, while v10 versions ignore this, if you want normal mapping to affect the _CameraNormalsTexture, we could edit the DepthNormals pass
		// (or if in v12+, use the LitDepthNormalsPass.hlsl instead, which additionally includes parallax and detail normals support)
		// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl
		/*
		Pass {
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			#if defined(_NORMALMAP)
				#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
			#endif

			struct Attributes {
				float4 positionOS		: POSITION;
				float4 tangentOS		: TANGENT;
				float2 texcoord			: TEXCOORD0;
				float3 normal			: NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings {
				float4 positionCS		: SV_POSITION;
				float2 uv 				: TEXCOORD1;
				float3 normalWS			: TEXCOORD2;

				#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
					half4 tangentWS			: TEXCOORD4;    // xyz: tangent, w: sign
				#endif

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings DepthNormalsVertex(Attributes input) {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				// Example Displacement
				//input.positionOS += float4(0, _SinTime.y, 0, 0);

				output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
				output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

				#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
					float sign = input.tangentOS.w * float(GetOddNegativeScale());
					half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
					output.tangentWS = tangentWS;
				#endif

				return output;
			}

			float4 DepthNormalsFragment(Varyings input) : SV_TARGET {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);

				#if defined(_NORMALMAP)
					float sgn = input.tangentWS.w;      // should be either +1 or -1
					float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
					float3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
					
					float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
				#else
					float3 normalWS = input.normalWS;
				#endif
				
				return float4(PackNormalOctRectEncode(TransformWorldToViewDir(normalWS, true)), 0.0, 0.0);
			}
			ENDHLSL
		}
		*/

		// Meta, used for baking global illumination / lightmaps
		Pass {
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			Cull Off

			HLSLPROGRAM
			#pragma vertex UniversalVertexMeta
			#pragma fragment UniversalFragmentMeta

			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			//#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

			#pragma shader_feature_local_fragment _SPECGLOSSMAP

			struct Attributes {
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float2 uv0          : TEXCOORD0;
				float2 uv1          : TEXCOORD1;
				float2 uv2          : TEXCOORD2;
				#ifdef _TANGENT_TO_WORLD
					float4 tangentOS     : TANGENT;
				#endif
				float4 color		: COLOR;
			};

			struct Varyings {
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
				float4 color		: COLOR;
			};

			#include "PBRSurface.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

			Varyings UniversalVertexMeta(Attributes input) {
				Varyings output;
				output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2, unity_LightmapST, unity_DynamicLightmapST);
				output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
				output.color = input.color;
				return output;
			}

			half4 UniversalFragmentMeta(Varyings input) : SV_Target {
				SurfaceData surfaceData;
				InitializeSurfaceData(input, surfaceData);

				BRDFData brdfData;
				InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

				MetaInput metaInput;
				metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
				metaInput.SpecularColor = surfaceData.specular;
				metaInput.Emission = surfaceData.emission;

				return MetaFragment(metaInput);
			}

			ENDHLSL
		}

		// There is also other passes, e.g.
		// Universal2D, if you need the shader to support the 2D Renderer
		// UniversalGBuffer, for Deferred rendering support (v12 only)
		// but not supporting them here. See the URP Shaders source :
		// https://github.com/Unity-Technologies/Graphics/tree/master/com.unity.render-pipelines.universal/Shaders
	}
}