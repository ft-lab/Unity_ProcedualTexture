//----------------------------------------------------------.
// 共通して使用する関数など.
//----------------------------------------------------------.
#ifndef _PROCEDUAL_COMMON_
#define _PROCEDUAL_COMMON_

#pragma exclude_renderers d3d11 gles

#include "UnityCG.cginc"

#define EPSILON 1e-7
#define UNITY_PI2 (UNITY_PI * 2.0)

/**
 * ワールド座標をローカル座標変換.
 */
 float3 worldToLocal (float3 pos) {
	 return mul(unity_WorldToObject, float4(pos, 1)).xyz;
 }

/**
 * ランダムな値を返す.
 */
float rand2 (float2 co) {
	return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}

float fade (float t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float grad (int hash, float x, float y, float z) {
	int h = hash & 15;
	float u = h < 8 ? x : y,
		   v = h < 4 ? y : h == 12 || h == 14 ? x : z;
	return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float lerp2 (float t, float a, float b) {
	return a + t * (b - a); 
}

float noise (float x, float y, float z) {
	static int p[] = {
		151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
		8,99,37,240,21,10,23,190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
		35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,
		134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
		55,46,245,40,244,102,143,54, 65,25,63,161,1,216,80,73,209,76,132,187,208, 89,
		18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,
		250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,
		189,28,42,223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 
		43,172,9,129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,
		97,228,251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,
		107,49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180 };

	float ax = x;
	float ay = y;
	float az = z;

	int X = int(floor(ax)) & 255;
	int Y = int(floor(ay)) & 255;
	int Z = int(floor(az)) & 255;

	ax -= floor(ax);
	ay -= floor(ay);
	az -= floor(az);

	float u = fade(ax);
	float v = fade(ay);
	float w = fade(az);

	int A  = p[X & 255] + Y;
	int AA = p[A & 255] + Z;
	int AB = p[(A + 1) & 255] + Z;
	int B  = p[(X + 1) & 255] + Y;
	int BA = p[B & 255] + Z;
	int BB = p[(B + 1) & 255] + Z;

	float res = lerp2(w, lerp2(v, lerp2(u, grad(p[AA & 255], ax, ay, az), grad(p[BA & 255], ax-1, ay, az)), lerp2(u, grad(p[AB & 255], ax, ay-1, az), grad(p[BB & 255], ax-1, ay-1, az))), lerp2(v, lerp2(u, grad(p[(AA+1) & 255], ax, ay, az-1), grad(p[(BA+1) & 255], ax-1, ay, az-1)), lerp2(u, grad(p[(AB+1) & 255], ax, ay-1, az-1), grad(p[(BB+1) & 255], ax-1, ay-1, az-1))));
	return (res + 1.0) * 0.5;
}

/**
 * ストライプ模様.
 * @param[in] pos   位置.
 * @param[in] axis  投影軸 (0:X, 1:Y, 2:Z).
 * @param[in] size  チェックの間隔.
 * @param[in] flipF 反転させる場合はtrue.
 */
float procedualStripe (float3 pos, int axis, float size, bool flipF) {
	float fMin = 1e-4;

	float fV = (axis == 0) ? pos.x : ((axis == 1) ? pos.y : pos.z);
	float fdV = fmod(abs(fV), size) / size;

	bool chkF = true;
	if (fdV > fMin && fdV < 1.0 - fMin) {
		int iV = int(abs(fV) / size);
		chkF = ((iV & 1) == 1) ? chkF : !chkF;
		if (fV < 0.0) chkF = !chkF;
	}
	if (flipF) chkF = !chkF;

	return (chkF) ? 1.0 : 0.0;
}

/**
 * チェック模様.
 * @param[in] pos   位置.
 * @param[in] size  チェックの間隔.
 * @param[in] flipF 反転させる場合はtrue.
 */
float procedualCheck (float3 pos, float size, bool flipF) {
	// 境界部分の場合、誤差でノイズが出るため敷居値で補正.
	float fMin = 1e-4;
	float fdx = fmod(abs(pos.x), size) / size;
	float fdy = fmod(abs(pos.y), size) / size;
	float fdz = fmod(abs(pos.z), size) / size;

	bool chkF = true;
	if (fdx > fMin && fdx < 1.0 - fMin) {
		int ix = int(floor((abs(pos.x) / size)));
		chkF = ((ix & 1) == 1) ? chkF : !chkF;
		if (pos.x < 0.0) chkF = !chkF;
	}
	if (fdy > fMin && fdy < 1.0 - fMin) {
		int iy = int(floor((abs(pos.y) / size)));
		chkF = ((iy & 1) == 1) ? chkF : !chkF;
		if (pos.y < 0.0) chkF = !chkF;
	}
	if (fdz > fMin && fdz < 1.0 - fMin) {
		int iz = int(floor((abs(pos.z) / size)));
		chkF = ((iz & 1) == 1) ? chkF : !chkF;
		if (pos.z < 0.0) chkF = !chkF;
	}

	if (flipF) chkF = !chkF;

	return (chkF) ? 1.0 : 0.0;
}

/**
 * PerlinNoise.
 */
float procedualPerlinNoise (float3 pos, float scale, int octave, bool flipF) {
	float fx = pos.x * scale;
	float fy = pos.y * scale;
	float fz = pos.z * scale;

	float v = 0.0;
	for (int i = 0; i < octave; ++i) {
		v += noise(fx, fy, fz);
		fx = fx * 2.0;
		fy = fy * 2.0;
		fz = fz * 2.0;
	}
	v /= float(octave);
	v = max(min(v, 1.0), 0.0);

	if (flipF) v = 1.0 - v;

	return v;
}

#endif
