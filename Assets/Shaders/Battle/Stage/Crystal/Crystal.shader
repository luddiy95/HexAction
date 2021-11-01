Shader "Crystal"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        // Custom Properties
        [Enum(Off, 0, On, 1)]
        _ZTest("ZTest", Float) = 4

        _TessellationFactor("Tessellation Factor", Range(1, 20)) = 2

        _BumpScale("Bump Scale", Range(0, 2.0)) = 1.0
        _BumpNoiseScale("Bump Noise Scale", Range(0, 10)) = 4
        _BumpNoiseRoughness("Bump Noise Roughness", Range(1.0, 8.0)) = 3.0
        _BumpNoisePersistance("Bump Noise Persistance", Range(0.0, 1.0)) = 0.4

        _ParallaxScale("Parallax Scale", Range(0, 2.0)) = 0.0

        _ColorNoiseScale("Color Noise Scale", Range(0, 10)) = 5
        _ColorNoiseFac("Color Noise Fac", Range(0.0, 1.0)) = 0.25
        _ColorNoiseRoughness("Color Noise Roughness", Range(1.0, 8.0)) = 3.0
        _ColorNoisePersistance("Color Noise Persistance", Range(0.0, 1.0)) = 0.4
        _ColorNoiseHue("Color Noise Hue", Range(0.0, 1.0)) = 0.0
        _ColorNoiseSaturation("Color Noise Saturation", Range(0.0, 2.0)) = 0.0

        _IOR("IOR", Range(0.0, 4.0)) = 1.0
        _TranslucentPower("Translucent Power", Range(0.0, 5.0)) = 1.0
        _TranslucentScale("Translucent Scale", Range(0.0, 100.0)) = 1.0
        _TranslucentAttenuation("Translucent Attenuation", Range(0.0, 1.0)) = 1.0
        _TranslucentAmbient("Translucent Ambient", Color) = (1, 1, 1)

        _EmissionHue("Emission Hue", Range(0.0, 1.0)) = 0.0
        _EmissionStrength("Emission Strength", Range(0.0, 5.0)) = 1.0

        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0

            // Blending state
            [HideInInspector] _Surface("__surface", Float) = 0.0
            [HideInInspector] _Blend("__blend", Float) = 0.0
            [HideInInspector] _AlphaClip("__clip", Float) = 0.0
            [HideInInspector] _SrcBlend("__src", Float) = 1.0
            [HideInInspector] _DstBlend("__dst", Float) = 0.0
            [HideInInspector] _ZWrite("__zw", Float) = 1.0
            [HideInInspector] _Cull("__cull", Float) = 2.0

            _ReceiveShadows("Receive Shadows", Float) = 1.0
            // Editmode props
            [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

            // ObsoleteProperties
            [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
            [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
            [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
            [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
            [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0

            [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

        SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel" = "4.5"}
        LOD 300

        //ZTest Always

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            ZTest[_ZTest]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma require tessellation tessHW
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local _NORMALMAP
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _EMISSION
        #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        #pragma shader_feature_local_fragment _OCCLUSIONMAP
        #pragma shader_feature_local _PARALLAXMAP
        #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
        #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
        #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
        #pragma shader_feature_local_fragment _SPECULAR_SETUP
        #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

        // -------------------------------------
        // Universal Pipeline keywords
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK

        // -------------------------------------
        // Unity defined keywords
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile_fog

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON

        #pragma vertex LitPassVertex
        #pragma fragment LitPassFragment

        #pragma hull hull
        #pragma domain domain

        #include "CrystalInput.hlsl"
        #include "Crystal.hlsl"
        ENDHLSL
    }

    Pass
    {
        Name "ShadowCaster"
        Tags{"LightMode" = "ShadowCaster"}

        ZWrite On
        ZTest LEqual
        ColorMask 0
        Cull[_Cull]

        HLSLPROGRAM
        #pragma exclude_renderers gles gles3 glcore
        #pragma target 4.5

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON

        #pragma vertex ShadowPassVertex
        #pragma fragment ShadowPassFragment

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        ENDHLSL
    }

    Pass
    {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "GBuffer"
            Tags{"LightMode" = "UniversalGBuffer"}

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local _NORMALMAP
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _EMISSION
        #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        #pragma shader_feature_local_fragment _OCCLUSIONMAP
        #pragma shader_feature_local _PARALLAXMAP
        #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

        #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
        #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
        #pragma shader_feature_local_fragment _SPECULAR_SETUP
        #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

        // -------------------------------------
        // Universal Pipeline keywords
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

        // -------------------------------------
        // Unity defined keywords
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON

        #pragma vertex LitGBufferPassVertex
        #pragma fragment LitGBufferPassFragment

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
        ENDHLSL
    }

    Pass
    {
        Name "DepthOnly"
        Tags{"LightMode" = "DepthOnly"}

        ZWrite On
        ColorMask 0
        Cull[_Cull]

        HLSLPROGRAM
        #pragma exclude_renderers gles gles3 glcore
        #pragma target 4.5

        #pragma vertex DepthOnlyVertex
        #pragma fragment DepthOnlyFragment

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
        ENDHLSL
    }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local _NORMALMAP
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
        ENDHLSL
    }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Universal2D"
            Tags{ "LightMode" = "Universal2D" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }

        SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel" = "2.0"}
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local _NORMALMAP
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _EMISSION
        #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        #pragma shader_feature_local_fragment _OCCLUSIONMAP
        #pragma shader_feature_local _PARALLAXMAP
        #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

        #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
        #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
        #pragma shader_feature_local_fragment _SPECULAR_SETUP
        #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

        // -------------------------------------
        // Universal Pipeline keywords
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

        // -------------------------------------
        // Unity defined keywords
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile_fog

        #pragma vertex LitPassVertex
        #pragma fragment LitPassFragment

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
        ENDHLSL
    }

    Pass
    {
        Name "ShadowCaster"
        Tags{"LightMode" = "ShadowCaster"}

        ZWrite On
        ZTest LEqual
        ColorMask 0
        Cull[_Cull]

        HLSLPROGRAM
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma target 2.0

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        #pragma vertex ShadowPassVertex
        #pragma fragment ShadowPassFragment

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        ENDHLSL
    }

    Pass
    {
        Name "DepthOnly"
        Tags{"LightMode" = "DepthOnly"}

        ZWrite On
        ColorMask 0
        Cull[_Cull]

        HLSLPROGRAM
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma target 2.0

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing

        #pragma vertex DepthOnlyVertex
        #pragma fragment DepthOnlyFragment

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
        ENDHLSL
    }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

        // -------------------------------------
        // Material Keywords
        #pragma shader_feature_local _NORMALMAP
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        //--------------------------------------
        // GPU Instancing
        #pragma multi_compile_instancing

        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
        ENDHLSL
    }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Universal2D"
            Tags{ "LightMode" = "Universal2D" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }

        FallBack "Hidden/Universal Render Pipeline/FallbackError"
        //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
