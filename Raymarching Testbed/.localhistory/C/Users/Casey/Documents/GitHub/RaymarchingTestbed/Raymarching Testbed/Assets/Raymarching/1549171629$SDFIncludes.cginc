#ifndef SDFINCLUDES
#define SDFINCLUDES

// PRIMITIVES 

// shapes defined by 
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdPlane(float3 p, float4 n)
{
	n = normalize(n);
	return dot(p, n.xyz) + n.w;
}

float sdTorus(float3 p, float2 t)
{
	float2 q = float2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return length(max(d, 0.0))
		+ min(max(d.x, max(d.y, d.z)), 0.0);
}

// CUSTOM PRIMITIVES

float sdHeightMap(float3 p, float4 img) 
{
	
}

// PRIMITIVES END

// OPERATIONS

float3 opRep(float3 p, float3 c)
{
	return abs(p) % c - 0.5*c;
}

float3 opHRep(float3 p, float x, float z) 
{
	return float3(abs(p.x) % x - .5 * x, p.y, abs(p.z) % z - .5 * z);
}

// union
float opUnion(float d1, float d2)
{
	return min(d1, d2);
}

// subtraction
float opSub(float d1, float d2)
{
	return max(-d1, d2);
}

// intersection
float opIntersect(float d1, float d2)
{
	return max(d1, d2);
}

// smooth versions

float opSmoothUnion(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5*(d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) - k * h*(1.0 - h);
}

float opSmoothSub(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 + d1) / k, 0.0, 1.0);
	return lerp(d2, -d1, h) + k * h*(1.0 - h);
}

float opSmoothIntersect(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) + k * h*(1.0 - h);
}

// OPERATIONS END

// RENDERING

// requires a float named shadow
// Adapted from http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
#define SHADE(ro, rd,MAP, MINT, MAXT) {shadow = 1.0;for(float t = MINT; t < MAXT;){float h = MAP(ro + rd * t);if (h < .001){shadow = 0.0;break;}t += h;}}
#define SHADESOFT(ro, rd,MAP, MINT, MAXT, K){shadow = 1.0;float ph = 1e20;for(float t = MINT; t < MAXT;){float h = MAP(ro + rd * t);if (h < .001){	shadow = 0.0;	break;}float y = h * h / (2.0*ph);float d = sqrt(h*h - y * y);shadow = min(shadow, K*d / max(0, t - y));ph = h;t += h;}}

// RENDERING END

// requires a float named norm
#define CALCNORMAL(POS, MAP){ float2 e = float2(1.0, -1.0)*0.5773*0.0005; norm = normalize(e.xyy*map(POS + e.xyy) + e.yyx*map(POS + e.yyx) +e.yxy*map(POS + e.yxy) +e.xxx*map(POS + e.xxx)); }


/// old normal function
//float3 calcNormal(float3 pos)
//{
//	float2 e = float2(1.0, -1.0)*0.5773*0.0005;
//	return normalize(e.xyy*map(pos + e.xyy) +
//		e.yyx*map(pos + e.yyx) +
//		e.yxy*map(pos + e.yxy) +
//		e.xxx*map(pos + e.xxx));
//}


// NOISE


float hash(float3 p)  // replace this by something better
{
	p = 50.0*frac(p*0.3183099 + float3(0.71, 0.113, 0.419));
	return -1.0 + 2.0*frac(p.x*p.y*p.z*(p.x + p.y + p.z));
}


// return value noise (in x) and its derivatives (in yzw)
float4 Noise(in float3 x)
{
	float3 p = floor(x);
	float3 w = frac(x);

#if 1
	// quintic interpolation
	float3 u = w * w*w*(w*(w*6.0 - 15.0) + 10.0);
	float3 du = 30.0*w*w*(w*(w - 2.0) + 1.0);
#else
	// cubic interpolation
	float3 u = w * w*(3.0 - 2.0*w);
	float3 du = 6.0*w*(1.0 - w);
#endif    


	float a = hash(p + float3(0.0, 0.0, 0.0));
	float b = hash(p + float3(1.0, 0.0, 0.0));
	float c = hash(p + float3(0.0, 1.0, 0.0));
	float d = hash(p + float3(1.0, 1.0, 0.0));
	float e = hash(p + float3(0.0, 0.0, 1.0));
	float f = hash(p + float3(1.0, 0.0, 1.0));
	float g = hash(p + float3(0.0, 1.0, 1.0));
	float h = hash(p + float3(1.0, 1.0, 1.0));

	float k0 = a;
	float k1 = b - a;
	float k2 = c - a;
	float k3 = e - a;
	float k4 = a - b - c + d;
	float k5 = a - c - e + g;
	float k6 = a - b - e + f;
	float k7 = -a + b + c - d + e - f - g + h;

	return float4(k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x*u.y + k5 * u.y*u.z + k6 * u.z*u.x + k7 * u.x*u.y*u.z,
		du * float3(k1 + k4 * u.y + k6 * u.z + k7 * u.y*u.z,
			k2 + k5 * u.z + k4 * u.x + k7 * u.z*u.x, k3 + k6 * u.x + k5 * u.y + k7 * u.x*u.y));
}

float FBMNoise(float3 pos, float amp, float freq, int o) 
{
	float a = 1.0;
	float p = pos;

	float v = a * Noise(p);

	for (int i = 0; i < o; i++) 
	{
		v += a * Noise(p);
		a *= amp;
		p *= freq;
	}
	return clamp(v, 0, 1);

}

// NOISE END
#endif