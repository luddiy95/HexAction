#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _DetailAlbedoMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _Parallax;
half _OcclusionStrength;
half _ClearCoatMask;
half _ClearCoatSmoothness;
half _DetailAlbedoMapScale;
half _DetailNormalMapScale;
half _Surface;
float _BumpScale;
float _BumpNoiseScale;
float _BumpNoiseRoughness;
float _BumpNoisePersistance;
float _ParallaxScale;
float _ColorNoiseScale;
float _ColorNoiseRoughness;
float _ColorNoisePersistance;
float _ColorNoiseFac;
float _ColorNoiseHue;
float _ColorNoiseSaturation;
float _IOR;
float _Distortion;
float _TranslucentPower;
float _TranslucentScale;
float _TranslucentAttenuation;
float3 _TranslucentAmbient;
float _EmissionHue;
float _EmissionStrength;

CBUFFER_END

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED
UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _Smoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrength)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatMask)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatSmoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailAlbedoMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailNormalMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

#define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
#define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__SpecColor)
#define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__EmissionColor)
#define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Cutoff)
#define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Smoothness)
#define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Metallic)
#define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__BumpScale)
#define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Parallax)
#define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__OcclusionStrength)
#define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatMask)
#define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatSmoothness)
#define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailAlbedoMapScale)
#define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailNormalMapScale)
#define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Surface)
#endif

TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);

#ifdef _SPECULAR_SETUP
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719))
{
	//make value smaller to avoid artefacts
    float3 smallValue = sin(value);
	//get scalar value from 3d vector
    float random = dot(smallValue, dotDir);
	//make value more random by making it bigger and then taking the factional part
    random = frac(sin(random) * 143758.5453);
    return random;
}

float3 rand3dTo3d(float3 value)
{
    return float3(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
		rand3dTo1d(value, float3(73.156, 52.235, 09.151))
	);
}

float easeIn(float interpolator)
{
    return interpolator * interpolator;
}

float easeOut(float interpolator)
{
    return 1 - easeIn(1 - interpolator);
}

float easeInOut(float interpolator)
{
    float easeInValue = easeIn(interpolator);
    float easeOutValue = easeOut(interpolator);
    return lerp(easeInValue, easeOutValue, interpolator);
}

float perlinNoise(float3 pos, float scale)
{
    pos *= scale;
    float3 fraction = frac(pos);

    float interpolatorX = easeInOut(fraction.x);
    float interpolatorY = easeInOut(fraction.y);
    float interpolatorZ = easeInOut(fraction.z);

    float cellNoiseZ[2];
			[unroll]
    for (int z = 0; z <= 1; z++)
    {
        float cellNoiseY[2];
				[unroll]
        for (int y = 0; y <= 1; y++)
        {
            float cellNoiseX[2];
					[unroll]
            for (int x = 0; x <= 1; x++)
            {
                float3 cell = floor(pos) + float3(x, y, z);
                float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                float3 compareVector = fraction - float3(x, y, z);
                cellNoiseX[x] = dot(cellDirection, compareVector);
            }
            cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
        }
        cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
    }
    float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
    return noise;
}

float sampleLayeredNoise(float3 pos, float scale, float persistance, float roughness)
{
    float noise = 0;
    float frequency = 1;
    float factor = 1;

			[unroll]
    for (int i = 0; i < 4; i++)
    {
        noise = noise + perlinNoise(pos * frequency + i * 0.72354, scale) * factor;
        factor *= persistance;
        frequency *= roughness;
    }
    
    return noise;
}

 
float bumpPerlinNoise(float3 pos)
{
    return (1.0 + sampleLayeredNoise(pos, pow(2, _BumpNoiseScale), _BumpNoisePersistance, _BumpNoiseRoughness)) * 0.5;
}

half3 HSVtoRGB(half h, half s, half v)
{
    half r = v, g = v, b = v;
    if (s == 0)
    {
        return half3(r, g, b);
    }
    
    if (h > 1.0) h -= 1.0;
    h *= 6.0;
    int i = (int) h;
    float f = h - (float) i;
    
    if (i == 0)
    {
        // r = v(MAX)
        g *= 1 - s * (1 - f);
        b *= 1 - s;
    }
    else if (i == 1)
    {
        r *= 1 - s * f;
        b *= 1 - s;
    }
    else if (i == 2)
    {
        r *= 1 - s;
        b *= 1 - s * (1 - f);
    }
    else if (i == 3)
    {
        r *= 1 - s;
        g *= 1 - s * f;
    }
    else if (i == 4)
    {
        r *= 1 - s * (1 - f);
        g *= 1 - s;
    }
    else if (i == 5)
    {
        g *= 1 - s;
        b *= 1 - s * f;
    }
    
    return half3(r, g, b);
}

half3 RGBtoHSV(half r, half g, half b)
{
    half max = r > g ? r : g;
    max = max > b ? max : b;
    half min = r < g ? r : g;
    min = min < b ? min : b;
    half h = max - min;
    if (h > 0.0)
    {
        if (max == r)
        {
            h = (g - b) / h;
            if (h < 0.0)
            {
                h += 6.0;
            }
        }
        else if (max == g)
        {
            h = 2.0 + (b - r) / h;
        }
        else
        {
            h = 4.0 + (r - g) / h;
        }
    }
    h /= 6.0;
    half s = (max - min);
    if (max != 0.0)
        s /= max;
    half v = max;
    
    return half3(h, s, v);
}

half3 colorPerlinNoise(float3 pos)
{
    float noise = (1.0 + sampleLayeredNoise(pos, pow(_ColorNoiseScale, 2), _ColorNoisePersistance, _ColorNoiseRoughness)) * 0.5;

    half3 hsv = half3(noise, 0.4 + 0.2 * noise, 0.4 + 0.2 * noise);
    
    return HSVtoRGB(hsv.x + _ColorNoiseHue, hsv.y * _ColorNoiseSaturation, hsv.z);
}

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

#ifdef _METALLICSPECGLOSSMAP
    specGloss = SAMPLE_METALLICSPECULAR(uv);
#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
#else
        specGloss.a *= _Smoothness;
#endif
#else // _METALLICSPECGLOSSMAP
#if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
#else
    specGloss.rgb = _Metallic.rrr;
#endif

#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
#else
    specGloss.a = _Smoothness;
#endif
#endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
#ifdef _OCCLUSIONMAP
// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
#else
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
#endif
#else
    return 1.0;
#endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

#if defined(_CLEARCOATMAP)
    clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
#endif

    return clearCoatMaskSmoothness;
#else
    return half2(0.0, 1.0);
#endif  // _CLEARCOAT
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return 2.0h * detailAlbedo * scale - scale + 1.0h;
}

half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
#if defined(_DETAIL)
    half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

    // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
#if defined(_DETAIL_SCALED)
    detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
#else
    detailAlbedo = 2.0h * detailAlbedo;
#endif

    return albedo * LerpWhiteTo(detailAlbedo, detailMask);
#else
    return albedo;
#endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
#if defined(_DETAIL)
#if BUMP_SCALE_NOT_SUPPORTED
    half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
#else
    half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
#endif

    // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
    // For visual consistancy we going to do in all cases
    detailNormalTS = normalize(detailNormalTS);

    return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
#else
    return normalTS;
#endif
}

half2 PerlinParallaxOffsetStep(half height, half amplitude, half3 viewDirTS)
{
    height = height * amplitude - amplitude / 2.0;
    half3 v = normalize(viewDirTS);
    v.z += 0.42;
    return height * (v.xy / v.z);
}

float3 posNorm(float3 pos, float3 normalOS, float4 tangentOS, half3 viewDirTS)
{
    float sgn = tangentOS.w;
    float3 bitangentOS = sgn * cross(normalOS, tangentOS.xyz);
    
    half2 offset = PerlinParallaxOffsetStep(bumpPerlinNoise(pos), _ParallaxScale, viewDirTS);
    pos -= (offset.x * normalize(tangentOS.xyz) + offset.y * normalize(bitangentOS)) * 0.04;
    
    const float D = 100.0;
    
    float me = bumpPerlinNoise(pos);
    float n = bumpPerlinNoise(pos + bitangentOS / D);
    float s = bumpPerlinNoise(pos - bitangentOS / D);
    float e = bumpPerlinNoise(pos - tangentOS.xyz / D);
    float w = bumpPerlinNoise(pos + tangentOS.xyz / D);
 
    float3 norm = float3(0.0, 0.0, 1.0);
    float3 temp = norm;
    temp.x += 0.5;
 
    float3 perp1 = normalize(cross(norm, temp));
    float3 perp2 = normalize(cross(norm, perp1));
 
    float3 normalOffset = -1.0 * (((n - me) - (s - me)) * perp1 + ((e - me) - (w - me)) * perp2);
    
    return normalize(norm + _BumpScale * normalOffset);
}

inline void InitializeStandardLitSurfaceData(float2 uv, float3 positionOS, inout SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    half3 albedoColor = albedoAlpha.rgb * (colorPerlinNoise(positionOS) * _ColorNoiseFac + _BaseColor.rgb * (1 - _ColorNoiseFac));
    outSurfaceData.albedo = albedoColor;

#if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.occlusion = SampleOcclusion(uv);
    
    half3 albedoHSV = RGBtoHSV(albedoColor.x, albedoColor.y, albedoColor.z);
    half3 emissionColor = HSVtoRGB(albedoHSV.x + _EmissionHue, albedoHSV.y, albedoHSV.z);
    outSurfaceData.emission = emissionColor * _EmissionStrength;

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoat = SampleClearCoat(uv);
    outSurfaceData.clearCoatMask       = clearCoat.r;
    outSurfaceData.clearCoatSmoothness = clearCoat.g;
#else
    outSurfaceData.clearCoatMask = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
#endif

#if defined(_DETAIL)
    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
    float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
    outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
    outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);

#endif
}

half3 TranslucentLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    
    half3 H = normalize(refract(lightDirectionWS, normalWS, _IOR));
    half3 VdotH = pow(saturate(dot(viewDirectionWS, -H)), _TranslucentPower) * _TranslucentScale;
    half3 I = _TranslucentAttenuation * (VdotH + _TranslucentAmbient);

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch]
    if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance + lightColor * I;
}

half3 TranslucentLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return TranslucentLightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}

half4 TranslucentUniversalFragmentPBR(InputData inputData, SurfaceData surfaceData)
{
#ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif

    BRDFData brdfData;

    // NOTE: can modify alpha
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    BRDFData brdfDataClearCoat = (BRDFData) 0;
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    // base brdfData is modified here, rely on the compiler to eliminate dead computation by InitializeBRDFData()
    InitializeBRDFDataClearCoat(surfaceData.clearCoatMask, surfaceData.clearCoatSmoothness, brdfData, brdfDataClearCoat);
#endif

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

#if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 color = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                     inputData.bakedGI, surfaceData.occlusion,
                                     inputData.normalWS, inputData.viewDirectionWS);
    color += TranslucentLightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                     mainLight,
                                     inputData.normalWS, inputData.viewDirectionWS,
                                     surfaceData.clearCoatMask, specularHighlightsOff);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
#if defined(_SCREEN_SPACE_OCCLUSION)
            light.color *= aoFactor.directAmbientOcclusion;
#endif
        color += TranslucentLightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                         light,
                                         inputData.normalWS, inputData.viewDirectionWS,
                                         surfaceData.clearCoatMask, specularHighlightsOff);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
