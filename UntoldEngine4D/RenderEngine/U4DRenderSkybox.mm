//
//  U4DRenderSkybox.cpp
//  MetalRendering
//
//  Created by Harold Serrano on 7/12/17.
//  Copyright © 2017 Untold Engine Studios. All rights reserved.
//

#include "U4DRenderSkybox.h"

#include "U4DDirector.h"
#include "U4DShaderProtocols.h"
#include "U4DCamera.h"
#include "U4DLogger.h"

namespace U4DEngine {
    
    U4DRenderSkybox::U4DRenderSkybox(U4DSkybox *uU4DSkybox){
        
        u4dObject=uU4DSkybox;
    }
    
    U4DRenderSkybox::~U4DRenderSkybox(){
        
    }
    
    void U4DRenderSkybox::initMTLRenderLibrary(){
        
        mtlLibrary=[mtlDevice newDefaultLibrary];
        
        std::string vertexShaderName=u4dObject->getVertexShader();
        std::string fragmentShaderName=u4dObject->getFragmentShader();
        
        vertexProgram=[mtlLibrary newFunctionWithName:[NSString stringWithUTF8String:vertexShaderName.c_str()]];
        fragmentProgram=[mtlLibrary newFunctionWithName:[NSString stringWithUTF8String:fragmentShaderName.c_str()]];
        
    }
    
    void U4DRenderSkybox::initMTLRenderPipeline(){
        
        U4DDirector *director=U4DDirector::sharedInstance();
        
        mtlRenderPipelineDescriptor=[[MTLRenderPipelineDescriptor alloc] init];
        mtlRenderPipelineDescriptor.vertexFunction=vertexProgram;
        mtlRenderPipelineDescriptor.fragmentFunction=fragmentProgram;
        mtlRenderPipelineDescriptor.colorAttachments[0].pixelFormat=director->getMTLView().colorPixelFormat;
        mtlRenderPipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
        
        //set the vertex descriptors
        
        vertexDesc=[[MTLVertexDescriptor alloc] init];
        
        vertexDesc.attributes[0].format=MTLVertexFormatFloat4;
        vertexDesc.attributes[0].bufferIndex=0;
        vertexDesc.attributes[0].offset=0;
        
        //stride 
        vertexDesc.layouts[0].stride=4*sizeof(float);
        
        vertexDesc.layouts[0].stepFunction=MTLVertexStepFunctionPerVertex;
        
        
        mtlRenderPipelineDescriptor.vertexDescriptor=vertexDesc;
        mtlRenderPipelineDescriptor.vertexFunction=vertexProgram;
        
        
        depthStencilDescriptor=[[MTLDepthStencilDescriptor alloc] init];
        
        depthStencilDescriptor.depthCompareFunction=MTLCompareFunctionLess;
        
        depthStencilDescriptor.depthWriteEnabled=NO;
        
        depthStencilState=[mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        
        //create the rendering pipeline object
        
        mtlRenderPipelineState=[mtlDevice newRenderPipelineStateWithDescriptor:mtlRenderPipelineDescriptor error:nil];
        
    }
    
    bool U4DRenderSkybox::loadMTLBuffer(){
        
        //Align the attribute data
        alignedAttributeData();
        
        if (attributeAlignedContainer.size()==0) {
            
            eligibleToRender=false;
            
            return false;
        }
        
        attributeBuffer=[mtlDevice newBufferWithBytes:&attributeAlignedContainer[0] length:sizeof(AttributeAlignedSkyboxData)*attributeAlignedContainer.size() options:MTLResourceOptionCPUCacheModeDefault];
        
        //create the uniform
        uniformSpaceBuffer=[mtlDevice newBufferWithLength:sizeof(UniformSpace) options:MTLResourceStorageModeShared];
        
        //load the index into the buffer
        indicesBuffer=[mtlDevice newBufferWithBytes:&u4dObject->bodyCoordinates.indexContainer[0] length:sizeof(int)*3*u4dObject->bodyCoordinates.indexContainer.size() options:MTLResourceOptionCPUCacheModeDefault];
        
        eligibleToRender=true;
        
        return true;
    }
    
    void U4DRenderSkybox::loadMTLTexture(){
        
        //Create the texture descriptor
        
        if (getSkyboxTexturesContainer().size()==6){
            
            createTextureObject();
            
            createSamplerObject();
            
        }else{
            
            U4DLogger *logger=U4DLogger::sharedInstance();
            logger->log("ERROR: The skybox requires 6 textures");
        }
        
        clearRawImageData();
        
    }
    
    void U4DRenderSkybox::createTextureObject(){
        
        int skyboxTextureSize;
        //decode the image to get the height of the texture so we can create
        decodeImage(getSkyboxTexturesContainer().at(0));
        
        skyboxTextureSize=imageWidth;
        
        clearRawImageData();
        
        //once we have the total size of the texture, then proceed with creating the texture object.
        
        MTLTextureDescriptor *textureDescriptor=[MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm size:skyboxTextureSize mipmapped:NO];
        
        //Create the texture object
        textureObject=[mtlDevice newTextureWithDescriptor:textureDescriptor];
        
        std::vector<unsigned char> skyboxImage;
        
        for (int slice=0; slice<6; slice++) {
            
            skyboxImage=decodeImage(getSkyboxTexturesContainer().at(slice));
            
            MTLRegion region=MTLRegionMake2D(0, 0, imageWidth, imageHeight);
            
            [textureObject replaceRegion:region mipmapLevel:0 slice:slice withBytes:&skyboxImage[0] bytesPerRow:4*imageWidth bytesPerImage:4*imageWidth*imageHeight];
            
            skyboxImage.clear();
            
        }

    }
    
    void U4DRenderSkybox::setDiffuseTexture(const char* uTexture){
        
        u4dObject->textureInformation.diffuseTexture=uTexture;
        
    }
    
    U4DDualQuaternion U4DRenderSkybox::getEntitySpace(){
        
        return u4dObject->getAbsoluteSpace();
    }
    
    void U4DRenderSkybox::updateSpaceUniforms(){
        
        U4DCamera *camera=U4DCamera::sharedInstance();
        U4DDirector *director=U4DDirector::sharedInstance();
        
        U4DMatrix4n modelSpace=getEntitySpace().transformDualQuaternionToMatrix4n();
        
        U4DMatrix4n worldSpace(1,0,0,0,
                               0,1,0,0,
                               0,0,1,0,
                               0,0,0,1);
        
        //YOU NEED TO MODIFY THIS SO THAT IT USES THE U4DCAMERA Position
        U4DEngine::U4DMatrix4n viewSpace=camera->getLocalSpace().transformDualQuaternionToMatrix4n();
        viewSpace.invert();
        
        U4DMatrix4n modelWorldSpace=worldSpace*modelSpace;
        
        U4DMatrix4n modelWorldViewSpace=viewSpace*modelWorldSpace;
        
        U4DMatrix4n perspectiveProjection=director->getPerspectiveSpace();
        
        U4DMatrix4n mvpSpace=perspectiveProjection*modelWorldViewSpace;
        
        
        matrix_float4x4 mvpSpaceSIMD=convertToSIMD(mvpSpace);
        
        
        UniformSpace uniformSpace;
        uniformSpace.modelViewProjectionSpace=mvpSpaceSIMD;
        
        memcpy(uniformSpaceBuffer.contents, (void*)&uniformSpace, sizeof(UniformSpace));
        
    }
    
    void U4DRenderSkybox::render(id <MTLRenderCommandEncoder> uRenderEncoder){
        
        if (eligibleToRender==true) {
            
            updateSpaceUniforms();
            
            //encode the pipeline
            [uRenderEncoder setRenderPipelineState:mtlRenderPipelineState];
            
            [uRenderEncoder setDepthStencilState:depthStencilState];
            
            //encode the buffers
            [uRenderEncoder setVertexBuffer:attributeBuffer offset:0 atIndex:0];
            
            [uRenderEncoder setVertexBuffer:uniformSpaceBuffer offset:0 atIndex:1];
            
            [uRenderEncoder setFragmentTexture:textureObject atIndex:0];
            
            [uRenderEncoder setFragmentSamplerState:samplerStateObject atIndex:0];
            
            //set the draw command
            [uRenderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:[indicesBuffer length]/sizeof(int) indexType:MTLIndexTypeUInt32 indexBuffer:indicesBuffer indexBufferOffset:0];
            
        }
        
        
    }
    
    void U4DRenderSkybox::alignedAttributeData(){
        
        for(int i=0;i<u4dObject->bodyCoordinates.getVerticesDataFromContainer().size();i++){
            
            AttributeAlignedSkyboxData attributeAlignedData;
            
            attributeAlignedData.position.x=u4dObject->bodyCoordinates.verticesContainer.at(i).x;
            attributeAlignedData.position.y=u4dObject->bodyCoordinates.verticesContainer.at(i).y;
            attributeAlignedData.position.z=u4dObject->bodyCoordinates.verticesContainer.at(i).z;
            attributeAlignedData.position.w=1.0;
            
            attributeAlignedContainer.push_back(attributeAlignedData);
        }
        
    }
    
    void U4DRenderSkybox::clearModelAttributeData(){
        
        //clear the attribute data contatiner
        attributeAlignedContainer.clear();
        
        u4dObject->bodyCoordinates.verticesContainer.clear();
        
    }
    
    
}
