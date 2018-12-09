Shader "Custom/Procedual/PerlinNoise" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Bumpmap", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		
		_ProcedualColor ("Procedual Color", Color) = (0,0,0,1)
		_Scale ("Scale", Range(0.001, 10.0)) = 1.0
		_Octave ("Octave", Range(1,10)) = 5
		_Power ("Power", Range(0.0, 5.0)) = 1.0

		_BumpStrength ("Bump Strength", Range(0.0, 2.0)) = 1.0
		_BumpScale ("Bump Scale", Range(0.001, 10.0)) = 1.0
		_BumpOctave ("Bump Octave", Range(1,10)) = 5

		[MaterialToggle] _Local ("Local", Float) = 1 
		[MaterialToggle] _Flip ("Flip", Float) = 0 
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Back

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _BumpMap;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float3 worldNormal;
			float4 tangent;
			float3 normal;
			INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _CheckSize;
		float _Local;
		float _Flip;
		float4 _ProcedualColor;
		float _Scale;
		int _Octave;
		float _Power;

		float _BumpStrength;
		float _BumpScale;
		int _BumpOctave;

		#include "procedualCommon.cginc"

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.normal  = v.normal;
			o.tangent = v.tangent;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

			float3 pos = (_Local == 0) ? IN.worldPos : worldToLocal(IN.worldPos);

			// Procedualの計算.
			bool flipF = (_Flip == 1) ? true : false;
			float fV = pow(procedualPerlinNoise(pos, _Scale, _Octave, flipF), _Power) * _ProcedualColor.a;
			c.rgb = lerp(c.rgb, _ProcedualColor.rgb, fV);

			if (_BumpStrength > 0.0) {
				float d = 0.005;
				float3 n, v1, v2;
				for (int i = 0; i < 3; ++i) {
					v1 = float3(pos.x + d, pos.y, pos.z);
					v2 = float3(pos.x - d, pos.y, pos.z);
					n.x = procedualPerlinNoise(v1, _BumpScale, _BumpOctave, flipF) - procedualPerlinNoise(v2, _BumpScale, _BumpOctave, flipF);

					v1 = float3(pos.x, pos.y + d, pos.z);
					v2 = float3(pos.x, pos.y - d, pos.z);
					n.y = procedualPerlinNoise(v1, _BumpScale, _BumpOctave, flipF) - procedualPerlinNoise(v2, _BumpScale, _BumpOctave, flipF);

					v1 = float3(pos.x, pos.y, pos.z + d);
					v2 = float3(pos.x, pos.y, pos.z - d);
					n.z = procedualPerlinNoise(v1, _BumpScale, _BumpOctave, flipF) - procedualPerlinNoise(v2, _BumpScale, _BumpOctave, flipF);

					if (n.x != 0.0 || n.y != 0.0 || n.z != 0.0) break;
					d *= 0.5;
				}
				n = normalize(n);

				// ローカル座標に変換.
				//if (_Local != 0) {
					n = mul(unity_WorldToObject, float4(n, 0)).xyz;
				//}

				// (0, 0, 1)の方向を向くように変換.
				// tangent spaceは TANGENT_SPACE_ROTATION マクロを参照.
				float3 binormal = cross(IN.normal, IN.tangent.xyz) * IN.tangent.w;
				float3x3 rotationInv = float3x3(
											float3(IN.tangent.x, binormal.x, IN.normal.x),
											float3(IN.tangent.y, binormal.y, IN.normal.y),
											float3(IN.tangent.z, binormal.z, IN.normal.z));

				n = mul(rotationInv, n).xyz;
				n = normalize(n);

				n.xy *= _BumpStrength * 0.1;
				n.z = 1.0;

				o.Normal = normalize(n);

			} else {
				o.Normal = float3(0, 0, 1);
			}
			//float3 n = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));

			o.Albedo     = c.rgb;
			o.Metallic   = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
