// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Grass"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Wind noise Texture", 2D) = "white" {}

		//Texture that denotes how much the leaf can sway
		_SwayTex("Sway Texture", 2D) = "white"{}
		_SwayDir("Sway Direction", Range(-2, 2)) = 1
		_SwayStrength("Sway Strength", Range(0, 100)) = 10
		_SwaySpeed("Sway Speed", Range(0, 50)) = 10

		//Parameters for player/grass interactions
		_PlayerPosition("Player's Position", Vector) = (0,0,0,0)
		_PlayerRadius("Player Radius", Range(0, 3)) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _NoiseTex;
			sampler2D _MainTex;
			sampler2D _SwayTex;
			float4 _MainTex_ST;
			float _Amount = 0.5;
			float _SwayDir;
			float _SwayStrength;
			float _SwaySpeed;

			//Checking PlayerPos
			float4 _PlayerPosition;
			float _PlayerRadius;

			v2f vert (appdata v)
			{
				//Position of this origin in the world
				float4 worldPosition = mul(unity_ObjectToWorld, float4(0,0,0,1));
				
				//Distance from origin to the Player
				float dist = length(worldPosition - _PlayerPosition);

				//sampling textures
				float4 swayAmount = tex2Dlod(_SwayTex, float4(v.vertex.x, v.vertex.y, 0,0));
				float4 noiseAmount = tex2Dlod(_NoiseTex, float4(worldPosition.x, worldPosition.y, 0,0));

				//Set amount with perlin and sway values, set X
				_Amount = (sin(_Time.y*swayAmount.r*noiseAmount.r*_SwaySpeed) + _SwayDir) * (_SwayStrength/100) * noiseAmount.r;
				v.vertex.x += v.uv.y * _Amount;

				_PlayerPosition.y = 0;

				//Setting direction
				float3 direction = worldPosition - _PlayerPosition.xyz;
				direction.y = 0;
				direction = normalize(direction);

				//Calculating how much the model should sway when it's being stepped on
				float movement = max(0, _PlayerRadius - dist)*direction;
				movement *= swayAmount.r;

				//Add on to the X and Z
				v.vertex.xz += v.uv.y * movement * 2;

				//Default
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
