#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#define _PARALLAXMAP
#define _NORMALMAP

// GLES2 has limited amount of interpolators
#if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
#endif

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

// keep this file in sync with LitGBufferPass.hlsl

float _TessellationFactor;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
};

struct ControlPoint
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
};

struct HSControlPointOutput
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
};

struct DSOutput
{
    float2 uv : TEXCOORD0;
    
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
#endif

float3 positionOS : POS;

float3 normalOS : NORMAL;
float4 tangentOS : TANGENT;

float3 normalWS : TEXCOORD3;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
float4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
#endif
float3 viewDirWS : TEXCOORD5;

half4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
float3 viewDirTS : TEXCOORD8;
#endif

float4 positionCS : SV_POSITION; // フラグメントシェーダには渡らない
};

struct TessellationFactors
{
    float outTessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
};

void InitializeInputData(DSOutput input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData) 0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

    half3 viewDirWS = SafeNormalize(input.viewDirWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w; // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings) 0;
    
    output.positionOS = input.positionOS;
    output.normalOS = input.normalOS;
    output.tangentOS = input.tangentOS;
    output.uv = input.texcoord;
    output.lightmapUV = input.lightmapUV;

    return output;
}

ControlPoint tessellationVertexProgram(Varyings input)
{
    ControlPoint output = (ControlPoint) 0;
    
    output.positionOS = input.positionOS;
    output.normalOS = input.normalOS;
    output.tangentOS = input.tangentOS;
    output.uv = input.uv;
    output.lightmapUV = input.lightmapUV;

    return output;
}

TessellationFactors patchConstantFunction(InputPatch<ControlPoint, 3> patch)
{
    TessellationFactors o = (TessellationFactors) 0;
    o.outTessFactor[0] = o.outTessFactor[1] = o.outTessFactor[2] = (int) _TessellationFactor;
    o.insideTessFactor = (int) _TessellationFactor;
    return o;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("patchConstantFunction")]
[outputcontrolpoints(3)]
HSControlPointOutput hull(InputPatch<ControlPoint, 3> input, uint id : SV_OutputControlPointID)
{
    HSControlPointOutput output = (HSControlPointOutput) 0;
    
    output.positionOS = input[id].positionOS;
    output.normalOS = input[id].normalOS;
    output.tangentOS = input[id].tangentOS;
    output.uv = input[id].uv;
    output.lightmapUV = input[id].lightmapUV;
    
    return output;
}

[domain("tri")]
DSOutput domain(TessellationFactors factors, const OutputPatch<HSControlPointOutput, 3> input, float3 bary : SV_DomainLocation)
{
    DSOutput output = (DSOutput) 0;
    
    float3 positionOS =
        bary.x * input[0].positionOS.xyz +
        bary.y * input[1].positionOS.xyz +
        bary.z * input[2].positionOS.xyz;

    float3 normalOS = normalize(
        bary.x * input[0].normalOS +
        bary.y * input[1].normalOS +
        bary.z * input[2].normalOS);

    float4 tangentOS = normalize(
        bary.x * input[0].tangentOS +
        bary.y * input[1].tangentOS +
        bary.z * input[2].tangentOS);
    
    half3x3 m = (half3x3) UNITY_MATRIX_M;
    half3 objectScale = half3(
        length(half3(m[0][0], m[1][0], m[2][0])),
        length(half3(m[0][1], m[1][1], m[2][1])),
        length(half3(m[0][2], m[1][2], m[2][2]))
    );
    output.positionOS = positionOS * objectScale;
    
    output.uv =
        bary.x * input[0].uv +
        bary.y * input[1].uv +
        bary.z * input[2].uv;
    
    output.normalOS = normalOS;
    output.tangentOS = tangentOS;
    
    float2 lightmapUV =
        bary.x * input[0].lightmapUV +
        bary.y * input[1].lightmapUV +
        bary.z * input[2].lightmapUV;
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);
    
    VertexNormalInputs normalInput = GetVertexNormalInputs(normalOS, tangentOS);
    
    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    
    output.normalWS = normalInput.normalWS;
    output.viewDirWS = viewDirWS;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = tangentOS.w * GetOddNegativeScale(); // 接線の向き
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif
    
    OUTPUT_LIGHTMAP_UV(lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(DSOutput input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    half3 viewDirTS = input.viewDirTS;
#if defined(_PARALLAXMAP)
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    viewDirTS = input.viewDirTS;
#else
    viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
#endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
#endif

    SurfaceData surfaceData;
    surfaceData.normalTS = posNorm(input.positionOS, input.normalOS, input.tangentOS, viewDirTS);
    InitializeStandardLitSurfaceData(input.uv, input.positionOS, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = TranslucentUniversalFragmentPBR(inputData, surfaceData);

    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = OutputAlpha(color.a, _Surface);

    return color;
}

#endif
