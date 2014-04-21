//
//  PixelRead.h
//  PixelRead
//
//  Created by tjaz on 27/10/13.
//
//

#ifndef __PixelRead__PixelRead__
#define __PixelRead__PixelRead__

#include <iostream>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreVideo/CoreVideo.h>
#include "cocos2d.h"


using namespace cocos2d;

struct ccV3F_T2F {
    //! vertices (3F)
    ccVertex3F        vertices;            // 12 bytes
    // tex coords (2F)
    ccTex2F           texCoords;            // 8 bytes
};

struct ccV3F_T2F_Quad {
    //! top left
    ccV3F_T2F    tl;
    //! bottom left
    ccV3F_T2F    bl;
    //! top right
    ccV3F_T2F    tr;
    //! bottom right
    ccV3F_T2F    br;
};

class PixelRead : public CCLayer
{
private:
    GLuint d_width, d_height;
    CVOpenGLESTextureCacheRef textureCache;
    ccV3F_C4B_T2F_Quad pixelProcessQuad;
    ccV3F_T2F_Quad renderQuad;
    CCTexture2D *texture;
    CCGLProgram *pixelProcessShaderProg;
    CCGLProgram *renderShaderProg;
    void initPixelProcessShader();
    void initRenderShader();
    void processPixelsGPU();
    void gpuCreateSmileBackground();
    void cpuCreateSmileFeatures();
    
    void draw();
    
    CVOpenGLESTextureRef renderTexture;
    CVPixelBufferRef renderTarget;
    
public:
    virtual bool init();    
};

#endif /* defined(__PixelRead__PixelRead__) */
