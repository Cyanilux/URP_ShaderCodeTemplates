// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

Shader "Cyanilux/URPTemplates/TransparentUnlitShaderExample" {
	Properties {
		_BaseMap ("Example Texture", 2D) = "white" {}
		_BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 0.5)
		//_ExampleVector ("Example Vector", Vector) = (0, 1, 0, 0)
		//_ExampleFloat ("Example Float (Vector1)", Float) = 0.5
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		//float4 _ExampleVector;
		//float _ExampleFloat;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "Unlit"
			//Tags { "LightMode"="SRPDefaultUnlit" } // (is default anyway)

			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment

			// Structs
			struct Attributes {
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
			};

			struct Varyings {
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float4 color		: COLOR;
			};

			// Textures, Samplers & Global Properties
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			// Vertex Shader
			Varyings UnlitPassVertex(Attributes IN) {
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				// Or :
				//OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}

			// Fragment Shader
			half4 UnlitPassFragment(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

				return baseMap * _BaseColor * IN.color;
			}
			ENDHLSL
		}
	}
}