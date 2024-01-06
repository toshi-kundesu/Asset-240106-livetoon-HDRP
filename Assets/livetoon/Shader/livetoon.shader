Shader "livetoon"
{
    Properties
    {
        [Header(BaseParam)]
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        _BaseLightColor ("Base Light Color", Color) = (1, 1, 1, 1)
        _BaseLightColorIntensity ("Base Light Color Intensity", Range(0, 1)) = 0
        [Toggle(TRANSPARENTMODE)] _TRANSPARENTMODE ("Transparent Mode", Float ) = 0.0

        _TransparentValue ("TransparentValue", Range(0, 1)) = 1


        [Header(ReflectionModel)]
        _LambertIntensity ("Lambert Intensity", Range(0, 1)) = 1
        _SpecPower ("Specular Power", Range(1.0, 10.0)) = 10.0
        _SpecularIntensity ("Specular Intensity", Range(0, 1)) = 1
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0, 10)) = 5
        _RimIntensity ("Rim Intensity", Range(0, 1)) = 1


        // [Header(OutLine)]
        _OutLineColor ("OutLineColor", Color) = (0, 0, 0, 1)
        _OutLineThickness ("OutLineThickness", Range(0, 0.01)) = 0.005



        // [Header(LightIntensity)]
        _LightIntensityMultiplier ("Light Intensity Multiplier", Range(0, 1)) = 1
        _DirectionalLightIntensity ("Directional Light Intensity", Range(0, 0.0001)) = 0.0001
        _PunctualLightIntensity ("Punctual Light Intensity", Range(0, 0.005)) = 0.005
        [Header(ForScreenSpaceGlobalIllumination)]
        _EnvironmentalLightingIntensity ("Environmental Lighting Intensity", Range(0, 1)) = 1



        // [Header(Shadow)]
        [Toggle(_PUNCTUALSHADOWATTENUATION)] _PUNCTUALSHADOWATTENUATION ("Punctual Shadow Attenuation Mode", Float ) = 1.0
        [Toggle(_DIRECTIONALSHADOWATTENUATION)] _DIRECTIONALSHADOWATTENUATION ("Directional Shadow Attenuation Mode", Float ) = 1.0
        // [Header(Toon)]
        [HideInInspector]
        _ToonLightColor ("Toon Light Color", Color) = (1, 1, 1, 1)
        [HideInInspector]
        _ToonDarkColor ("Toon Dark Color", Color) = (0, 0, 0, 1)

        [Enum(UnityEngine.Rendering.CullMode)] _Culling ("Culling", int) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _BleModSour("Blend - Source", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BleModDest("Blend - Destination", int) = 0
        [HideInInspector] _ZTeForLiOpa("ZTeForLiOpa", int) = 3
        [Enum(On,1,Off,0)] _ZWrite("ZWrite", int) = 1



    }
    HLSLINCLUDE

    #pragma target 4.5



    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

    // Default properties    
    CBUFFER_START(UnityPerMaterial)
    float3 _EmissiveColor;
    float _EmissiveExposureWeight;
    float _AlbedoAffectEmissive;
    float4 _BaseColor;
    float4 _BaseColorMap_ST;
    float _Metallic;
    float _Smoothness;
    float _NormalScale;
    float4 _DetailMap_ST;
    float _Anisotropy;
    float _DiffusionProfileHash;
    float _SubsurfaceMask;
    float _Thickness;
    float4 _SpecularColor;
    float _TexWorldScale;
    float4 _UVMappingMask;
    float4 _UVDetailsMappingMask;
    float4 _UVMappingMaskEmissive;
    float _LinkDetailsWithBase;
    float _AlphaRemapMin;
    float _AlphaRemapMax;
    float _ObjectSpaceUVMapping;
    float _TransmissionMask;
    CBUFFER_END

    TEXTURE2D(_BaseColorMap);
    SAMPLER(sampler_BaseColorMap);

    TEXTURE2D(_HeightMap);
    SAMPLER(sampler_HeightMap);

	ENDHLSL

    SubShader
    {
        Tags{"RenderType" = "HDLitShader" "Queue" = "Geometry+225"}

        LOD 100

        Pass
        {
            Name "Outline"

            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            float _OutLineThickness;
            half4 _OutLineColor;

            struct a2v
            {
                float4 positionOS : POSITION;
                float4 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };


            v2f vert(a2v v)
            {
                v2f o;

                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                float3 normalCS = mul((float3x3)UNITY_MATRIX_V, normalWS);

                o.positionCS = TransformWorldToHClip(positionWS + normalCS * _OutLineThickness);

                return o;
            }

            half4 frag(v2f i): SV_Target
            {
                float4 col = _OutLineColor;
                return col;
            }
            ENDHLSL
        }


        Pass
        {

            Name"GeometryBuffer"
            Tags{"LightMode"="GBuffer"}

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_GBUFFER

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/VertMesh.hlsl"

            PackedVaryingsType vert(AttributesMesh input)
            {
                VaryingsType varyingsType;
                varyingsType.vmesh = VertMesh(input); // メッシュの頂点を変換
                return PackVaryingsType(varyingsType); // 変換した頂点データをパックして返す
            }

            void frag(PackedVaryingsToPS packedIn, out GBufferType0 gBufferType0 : SV_Target0, out GBufferType1 gBufferType1 : SV_Target1, out GBufferType2 gBufferType2 : SV_Target2, out GBufferType3 gBufferType3 : SV_Target3)
            {
                ZERO_INITIALIZE(GBufferType0,gBufferType0); 
                ZERO_INITIALIZE(GBufferType1,gBufferType1);
                ZERO_INITIALIZE(GBufferType2,gBufferType2);
                ZERO_INITIALIZE(GBufferType3,gBufferType3);
                
                SurfaceData surfaceData;
                BuiltinData builtinData; 
                float3 v = float3(1.0, 1.0, 1.0);
                FragInputs input = UnpackVaryingsMeshToFragInputs(packedIn); // パックされた頂点データを解凍
                PositionInputs posIn = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS); // ポジション入力を取得
                GetSurfaceAndBuiltinData(input, v, posIn, surfaceData, builtinData); // サーフェスデータとビルトインデータを取得
          
                gBufferType0 = float4(1.0,1.0,1.0,0.0); 
                EncodeIntoNormalBuffer(ConvertSurfaceDataToNormalData(surfaceData), posIn.positionSS, gBufferType1); // サーフェスデータをノーマルデータに変換し、GBT1にエンコード
                gBufferType2 = float4(0.0,0.0,0.0,0.0); 
                gBufferType3 = float4(1.0,1.0,1.0,0.0); 
            }

            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata i)
            {
                v2f o;
                o.pos = TransformObjectToHClip(i.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return 0;
            }
            
            ENDHLSL
        }


        Pass
        {
            Name "Lit"
			Tags{"LightMode" = "ForwardOnly"}
            Blend[_BleModSour][_BleModDest]

            Cull [_Culling]
            ZTest [_ZTeForLiOpa]   
			ZWrite [_ZWrite]


            HLSLPROGRAM
			#pragma target 4.5

            #pragma vertex VSMain
            #pragma fragment PSMain
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            
            TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float _LightIntensityMultiplier;
                float _EnvironmentalLightingIntensity;
                float _DirectionalLightIntensity;
				half _SpecPower;
                half4 _BaseLightColor;
                half4 _RimColor;
                half _RimPower;
                half4 _ToonLightColor;
                half4 _ToonDarkColor;
                half _SpecularIntensity;
                half _LambertIntensity;
                half _RimIntensity;
                half _BaseLightColorIntensity;
                half _PunctualLightIntensity;
                half _TransparentValue;
                half _PUNCTUALSHADOWATTENUATION;
                half _DIRECTIONALSHADOWATTENUATION;
			CBUFFER_END

            struct SVSIn
			{
				float4 pos       : POSITION;
				float3 normal         : NORMAL;
				float2 uv               : TEXCOORD0;
			};

			struct SPSIn
			{
                float4 pos : SV_POSITION;
                float3 normalWS   : NORMAL;
				float2 uv         : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

				float3 viewDirWS  : TEXCOORD3;
				float  fogCoord   : TEXCOORD4;

				UNITY_VERTEX_OUTPUT_STEREO
			};

            

            SPSIn VSMain(SVSIn vsIn)
			{
				SPSIn psin;

				psin.pos = TransformObjectToHClip(vsIn.pos.xyz);
				psin.worldPos = TransformObjectToWorld(vsIn.pos);
				psin.uv = vsIn.uv;

				psin.viewDirWS = GetWorldSpaceViewDir(psin.worldPos);
				psin.normalWS = TransformObjectToWorldNormal(vsIn.normal);

				return psin;
			}

			float4 PSMain(SPSIn psIn) : SV_Target
			{
                uint2 tileIndex = uint2(psIn.pos.xy) / GetTileSize();

                PositionInputs posInput = GetPositionInput(psIn.pos.xy, _ScreenSize.zw, psIn.pos.z, psIn.pos.w, psIn.worldPos, tileIndex);

                float4 indirectDiffuseTex = LOAD_TEXTURE2D_X(_IndirectDiffuseTexture, posInput.positionSS);
                float4 environmentColor = float4(indirectDiffuseTex.xyz * _EnvironmentalLightingIntensity * _LightIntensityMultiplier,1);

                uint h=0;
                float3 finalDirectionalLightColor = float3(0.0,0.0,0.0);
                for (h = 0; h < _DirectionalLightCount; ++h)
                {

                    DirectionalLightData directionalLightData = _DirectionalLightDatas[h];

                    LightLoopContext context;
                    context.shadowContext  = InitShadowContext();
                    context.shadowValue = 1;			
                    context.sampleReflection = 0;
                    context.splineVisibility = -1;

                    context.contactShadowFade = 0.0;
                    context.contactShadow = 0;

                    uint2 tileIndex = uint2(psIn.pos.xy) / GetTileSize();

                    PositionInputs posInput = GetPositionInput(psIn.pos.xy, _ScreenSize.zw, psIn.pos.z, psIn.pos.w, psIn.worldPos, tileIndex);
                    
                    float DirectionalShadow = 1.0;


                    if ((directionalLightData.shadowDimmer > 0)) //(Plight.shadowIndex >= 0) && 
                    {
                         DirectionalShadow = GetDirectionalShadowAttenuation(context.shadowContext, posInput.positionSS, posInput.positionWS, (float3)0.0 , directionalLightData.shadowIndex, -directionalLightData.forward);
                    }



                    float DirectionalShadowAttenuation = smoothstep(0.0f, 1.0f,DirectionalShadow);

                    float t_d_Lambert = dot(psIn.normalWS, directionalLightData.forward);
                    t_d_Lambert *= -1.0f;

                    // saturate
                    if (t_d_Lambert < 0.0f)
                    {
                        t_d_Lambert = 0.0f;
                    }

                    float3 diffuse_d_Lig = directionalLightData.color * t_d_Lambert;

                    float3 diffuse_d_Toon = lerp(directionalLightData.color * _ToonLightColor.xyz, _ToonDarkColor.xyz, step(t_d_Lambert, 0.1f));

                    float3 refVec_d = reflect(directionalLightData.forward, psIn.normalWS);

                    float3 toEye = psIn.viewDirWS - psIn.worldPos;

                    toEye = normalize(toEye);

                    float t_Specular = dot(refVec_d, toEye);

                    if (t_Specular < 0.0f)
                    {
                        t_Specular = 0.0f;
                    }

                    t_Specular = pow(t_Specular, _SpecPower);

                    float3 specularToon = lerp(directionalLightData.color * _ToonLightColor.xyz, _ToonDarkColor.xyz, step(t_Specular, 0.1f));

                    float3 specularLig = specularToon;


                    finalDirectionalLightColor += diffuse_d_Toon * _LambertIntensity + specularLig * _SpecularIntensity;
                    finalDirectionalLightColor *= _DirectionalLightIntensity * _LightIntensityMultiplier;
                    if (_DIRECTIONALSHADOWATTENUATION > 0.5)
                    {
                        finalDirectionalLightColor *= DirectionalShadowAttenuation;
                    }

                }

                float3 finalLightColor = float3(0.0,0.0,0.0);
                uint j=0;
                for (j = 0; j < _PunctualLightCount; ++j)
                {
                    LightData lightData;
                    lightData = FetchLight(j);

                    float4 distance;
                    float3 punctualLightDir = float3(0.0,0.0,0.0);
                    float3 lightToSample = psIn.worldPos - lightData.positionRWS;
                    distance.w = dot(lightToSample, lightData.forward);

                    float3 pixelToLightVec = -lightToSample;
                    float  distanceSquared = dot(pixelToLightVec, pixelToLightVec);
                    float  reciprocalDistance = rsqrt(distanceSquared);
                    float  actualDistance = distanceSquared * reciprocalDistance;
                    punctualLightDir = pixelToLightVec * reciprocalDistance;
                    distance.xyz = float3(actualDistance, distanceSquared, reciprocalDistance);

                    float punctunalLightAttenuation = PunctualLightAttenuation(
                        distance, 
                        lightData.rangeAttenuationScale, 
                        lightData.rangeAttenuationBias, 
                        lightData.angleScale, 
                        lightData.angleOffset);

                    LightLoopContext context;
                    context.shadowContext  = InitShadowContext();
                    context.shadowValue = 1;			
                    context.sampleReflection = 0;
                    context.splineVisibility = -1;
                    context.contactShadowFade = 0.0;
                    context.contactShadow = 0;

                    float punctualShadowAttenuationValue = 1.0f;


                    if ((lightData.shadowDimmer > 0))
                    {
                        punctualShadowAttenuationValue = GetPunctualShadowAttenuation(context.shadowContext, posInput.positionSS, posInput.positionWS, 0 , lightData.shadowIndex,punctualLightDir, distance.x, lightData.lightType == GPULIGHTTYPE_POINT, lightData.lightType != GPULIGHTTYPE_PROJECTOR_BOX);
                    }

                    float punctualShadowAttenuation = smoothstep(0.0f, 1.0f,punctualShadowAttenuationValue);

                    float3 NomalizedLightToSample = normalize(lightToSample);

                    float t_Lambert = dot(psIn.normalWS, NomalizedLightToSample);
                    t_Lambert *= -1.0f;

                    if (t_Lambert < 0.0f)
                    {
                        t_Lambert = 0.0f;
                    }

                    float3 diffuseToon = lerp(lightData.color * _ToonLightColor.xyz, _ToonDarkColor.xyz, step(t_Lambert, 0.1f));

                    float3 diffuseLig = diffuseToon;

                    float3 refVec = reflect(NomalizedLightToSample, psIn.normalWS);

                    float3 toEye = psIn.viewDirWS - psIn.worldPos;

                    toEye = normalize(toEye);

                    float t_Specular = dot(refVec, toEye);

                    if (t_Specular < 0.0f)
                    {
                        t_Specular = 0.0f;
                    }

                    t_Specular = pow(t_Specular, _SpecPower);

                    float3 specularToon = lerp(lightData.color * _ToonLightColor.xyz, _ToonDarkColor.xyz, step(t_Specular, 0.1f));

                    float3 specularLig = specularToon;

                    float3 lig = diffuseLig * _LambertIntensity + specularLig * _SpecularIntensity;

                    lig *= _PunctualLightIntensity * _LightIntensityMultiplier;
                    lig *= punctunalLightAttenuation;
                    if (_PUNCTUALSHADOWATTENUATION > 0.5)
                    {
                        lig *= punctualShadowAttenuation;
                    }

                    finalLightColor += lig;
                    
                }
                float NdotV = saturate(dot(psIn.normalWS, psIn.viewDirWS));
                float3 rim = _RimColor.xyz * pow(1.0 - NdotV, 10.001 - _RimPower);
                finalLightColor += rim * _RimIntensity + _BaseLightColor.xyz * _BaseLightColorIntensity;

                float4 finalColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, psIn.uv);
                finalColor.xyz *= finalLightColor + finalDirectionalLightColor + environmentColor.xyz;

				return float4(finalColor.xyz, 1 - _TransparentValue);

			}
			ENDHLSL
        }

        
    }
    CustomEditor "livetoonGUI"
}
