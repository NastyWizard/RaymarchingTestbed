#ifndef _SDF_INCLUDES_
#define _SDF_INCLUDES_

// Signed distance fields includes, for raymarching

// operations

vec3 opRep(vec3 p, vec3 r)
{
	return mod(abs(p), r) - .5 * r;
}

vec3 opRepXZ(vec3 p, vec3 r)
{
	vec3 res = mod(abs(p), r) - .5 * r;
	res.y = p.y;
	return res;
}

// union
vec2 OpU2(vec2 d, vec2 d2)
{
	return d.x < d2.x ? d : d2;
}

// intersection
float OpI(float d, float d2)
{
	return max(d, d2);
}

// subtraction 
vec2 OpS2(vec2 d, vec2 d2)
{
	return -d.x > d2.x ? d : d2;
}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

// primitives
float sdSphere(vec3 p, float r)
{
	return length(p) - (r);
}

float sdDisk(vec3 p, vec2 h)
{
	vec2 d = abs(vec2(length(p.xz), p.y)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdGear(vec3 p, vec3 s)
{
	vec3 ps = p * s;
	return OpI(sdDisk(ps, vec2(1., .25)), sdSphere(ps, .5));
}

float sdPlane(vec3 p, vec3 n)
{
	n = normalize(n);
	return dot(p, n.xyz) + 1.;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return length(max(d, 0.));
}

float sdCylinder(vec3 p, vec3 c)
{
	return length(p.xz - c.xy) - c.z;
}

float sdCross(vec3 p)
{
	float r = sdBox(p.xyz, vec3(FLT_MAX, 1.0, 1.0));
	float r1 = sdBox(p.yzx, vec3(1.0, FLT_MAX, 1.0));
	float r2 = sdBox(p.zxy, vec3(1.0, 1.0, FLT_MAX));

	float d1 = maxcomp2(abs(p.xy));
	float d2 = maxcomp2(abs(p.yz));
	float d3 = maxcomp2(abs(p.zx));

	return min(d1, min(d2, d3)) - 1.0;
}


uniform int FractalIterations;

float sdFractalCross(vec3 p)
{
	float d = sdBox(p, vec3(1.0));

	float s = 1.0;
	for (int m = 0; m < FractalIterations; m++)
	{
		vec3 a = mod(p*s, 2.0) - 1.0;
		s *= 3.0;
		vec3 r = 1.0 - 3.0*abs(a);

		float c = sdCross(r) / s;
		d = max(d, -c);
	}
	return d;
}

float sdMengerSponge(vec3 p, vec3 p2)
{
	float d = sdBox(p, vec3(1.0));
	float s = 1.0;
	for (int m = 0; m < FractalIterations; m++)
	{
		vec3 a = mod(p2*s, 2.0) - 1.0;
		s *= 3.0;
		vec3 r = 1.0 - 3.0*abs(a);

		float c = sdCross(r) / s;
		d = max(d, c);
	}
	return d;
}

#endif 