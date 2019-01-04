Shader "Hidden/RayTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise",2D) = "black"{}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "SDFIncludes.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			//
			uniform float4x4 _Frustrum;
			uniform float4x4 _InverseViewMatrix;
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler2D _NoiseTex;
			uniform float4 _MainTex_TexelSize;
			uniform float3 _CameraPos;
			//
			//float hash(float n)
			//{
			//	return frac(sin(n)*43758.5453);
			//}
			//
			//float noise(float3 x)
			//{
			//
			//	// noise from texture
			//
			//	float3 p = floor(x);
			//	float3 f = frac(x);
			//	f = f * f * (3.0 - 2.0*f);
			//	float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
			//	float2 rg = tex2D(_NoiseTex, (uv + 0.5) / 256.0).yx;
			//
			//	return -1.0 + 2.0*lerp(rg.x, rg.y, f.z);
			//}

			float map(float3 p)
			{
				// move position over time
				//float3 q = p - float3(0.0, 0.1, 1.0)*_Time;
				//
				//// calculate noise
				//float f;
				//f = 0.50000* (noise(q));
				//q = q * 2.02;
				//f += 0.25000*(noise(q));
				//
				//return 1 - clamp(2.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);

				float3 s = float3(3, 10, 3);

				// bunch of morphing spheres
				//float3 q = (sin(p + _Time)) + opRep(p, s);
				//float3 q2 = (cos(p + _Time)) + opRep(p + float3(0, 0.25, 1), s);
				//float3 q3 = opRep(p + float3(0, -.55, 0.5), s);
				//float m = opSmoothSub(opSmoothUnion(sdTorus(q, float2(1, .2)), sdTorus(q2, float2(1, .2)), .8), sdSphere(q3, 1),0.1);
				//float plane = sdPlane(p + float3(0, -10, 0), float4(0, -1, 0, 0));
				//float plane2 = sdPlane(p + float3(0, 10, 0), float4(0, 1, 0, 0));

				// sphere lighting showcase
				float3 planePos = p + float3(0, 0, 0);
				float plane = sdPlane(planePos, float4(0, 1, 0, 0));
				//
				float3 spherePos = p + float3(0,0, 0);
				float sphere = sdSphere(spherePos, 1);
				return opUnion(sphere, plane);

				//return opSub(FBMNoise(p, 5, 0.5, 3), plane);

				//return opUnion(opSub(plane2, opSub(plane,m)),sdPlane(p + float3(0,5.5,0),float4(0,1,0,0)));
			}

			float4 Lighting(float3 p, float3 norm, float3 lightDir, float3 color = float3(1,1,1))
			{
				float NDotL = dot(norm, lightDir);

				NDotL = max(NDotL, 0);

				float shadow;
				SHADESOFT(p, lightDir, map, 0.01, 10,16);

				NDotL *= shadow;

				float a = .25;
				float4 ret = max(fixed4(NDotL, NDotL, NDotL, 1), a);

				ret.rgb *= color;

				return ret;
			}

			float4 GetFog(float4 col, float4 fog, float t) { return lerp(col, fog, 1 - clamp(1 - pow(t, .4) + 10, 0, 1)); }


			void March( float3 ro, float3 rd, float depth, const float steps, in float t, out float4 ret)
			{
				fixed3 lightDir = fixed3(1, .5, 0);
				lightDir = normalize(lightDir);

				float4 fog = float4(0.65, 0.85, 0.95, 1);

				const float maxDrawDist = 200;
#ifdef DOFOG
				ret = fog;
#endif
				for (int i = 0; i < steps; i++)
				{
					if (t >= depth) 
					{
						ret = float4(0,0,0,0); 
#ifdef DOFOG
						ret = GetFog(ret, fog, t);
#endif
						break;
					}

					float3 p = ro + rd * t;

					float den = map(p);

					if (t > maxDrawDist)
					{
#ifdef DOFOG
						ret = fog;
#endif
						break;
					}
					if (den < 0.001 )
					{

						float3 norm;
						CALCNORMAL(p, map);

						float VDotN = dot(-rd, norm);

						float fi = .5; 
						float fs = 2;
						float f = 1 - pow(VDotN, fi) * fs;
						f = max(f, 0);

						ret =( Lighting(p, norm, lightDir)+ float2(f,0).rrrg) * float4(1,1,1,1);

#ifdef DOFOG
						ret = GetFog(ret, fog, t);
#endif

						//ret = fixed4(norm,1); // normal render
						//ret = float2((float)i / steps,0).grrr;
						break;
					}

					t += den;

				}
			}

			float4 raymarch(float3 ro, float3 rd, float depth)
			{
				fixed4 ret = fixed4(0, 0, 0, 0);

				float t = 0;

				March(ro, rd, depth, 512, t, ret);

				//r.rgb *= r.a;

				return clamp(ret,0.0,1.0);
			}

			//

			v2f vert(appdata v)
			{
				v2f o;

				half index = v.vertex.z;
				v.vertex.z = 0.1;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				// flip uvs if needed
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						o.uv.y = 1 - o.uv.y;
				#endif

				// get worldspace ray

				o.ray = _Frustrum[(int)index].xyz;
				o.ray /= abs(o.ray.z);

				o.ray = mul(_InverseViewMatrix, o.ray);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				float3 rd = normalize(i.ray.xyz);
				float3 ro = _CameraPos;

				float2 uv_Depth = i.uv;

				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						uv_Depth = 1 - uv_Depth;
				#endif

				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, uv_Depth).r);
				depth *= length(i.ray.xyz);

				fixed4 add = raymarch(ro, rd, depth);

				return fixed4(col*(1.0-add.w) + add.xyz,1.0);
			}

            ENDCG
        }
    }
}
