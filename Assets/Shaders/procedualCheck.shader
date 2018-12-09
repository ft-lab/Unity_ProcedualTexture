Shader "Custom/Procedual/Check" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_CheckSize ("Check Size", Range(0.001, 5.0)) = 0.25
		_ProcedualColor ("Procedual Color", Color) = (0,0,0,1)

		[MaterialToggle] _Local ("Local", Float) = 1 
		[MaterialToggle] _Flip ("Flip", Float) = 0 
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Back

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _CheckSize;
		float _Local;
		float _Flip;
		float4 _ProcedualColor;

		#include "procedualCommon.cginc"

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

			float3 pos = (_Local == 0) ? IN.worldPos : worldToLocal(IN.worldPos);

			// Procedualの計算.
			float fV = procedualCheck(pos, _CheckSize, (_Flip == 1) ? true : false) * _ProcedualColor.a;

			c.rgb = lerp(c.rgb, _ProcedualColor.rgb, fV);

			o.Albedo     = c.rgb;
			o.Metallic   = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
