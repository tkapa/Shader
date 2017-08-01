Shader "Toon/Dissolver" {
	Properties {
		_Color ("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Ramp ("Toon Ramp (RGB)", 2D) = "gray" {} 
		_NoiseTex("Dissolve", 2D) = "white"{}
		_DisLineWidth("Dissolve Width", Range(0,2)) = 0
		_DisLineColor("Dissolve Colour", Color) = (1,1,1,1)
		_DisAmount("Dissolve Amount", Range(0,1)) = 0.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		
CGPROGRAM
#pragma surface surf ToonRamp keepalpha

sampler2D _Ramp;

// custom lighting function that uses a texture ramp based
// on angle between light direction and normal
#pragma lighting ToonRamp exclude_path:prepass
inline half4 LightingToonRamp (SurfaceOutput s, half3 lightDir, half atten)
{
	#ifndef USING_DIRECTIONAL_LIGHT
	lightDir = normalize(lightDir);
	#endif
	
	half d = dot (s.Normal, lightDir)*0.5 + 0.5;
	half3 ramp = tex2D (_Ramp, float2(d,d)).rgb;
	
	half4 c;

	c.rgb = s.Albedo * _LightColor0.rgb * ramp * (atten * 2);
	c.a = s.Alpha;
	return c;
}

sampler2D _NoiseTex;
float _DisLineWidth;
float4 _DisLineColor;
float _DisAmount;

sampler2D _MainTex;
float4 _Color;

struct Input {
	float2 uv_MainTex : TEXCOORD0;
	float3 worldPos;
};

void surf (Input IN, inout SurfaceOutput o) {
	half4 n = tex2D(_NoiseTex, IN.worldPos.xy);
	half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

	if(n.r-_DisLineWidth < _DisAmount){
		c = _DisLineColor;
	}
	if(n.r<_DisAmount){
		c.a = 0.0;
	}

	o.Albedo = c.rgb;
	o.Alpha = c.a;
}
ENDCG

	} 

	Fallback "Diffuse"
}
