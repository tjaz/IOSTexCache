//
//  PixelRead.cpp
//  PixelRead
//
//  Created by tjaz on 27/10/13.
//
//

#include <cassert>
#include "PixelRead.h"
#import "EAGLView.h"
//#include <kazmath/vec4.h>

typedef struct vec4b {
    unsigned char b;
    unsigned char g;
    unsigned char r;
    unsigned char a;
    
    bool operator== (const vec4b &v) {
        return r == v.r && g == v.g && b == v.b && a == v.a;
    }
    
} vec4b;

bool PixelRead::init()
{
    //////////////////////////////
    // 1. super init first
    if ( !CCNode::init() )
    {
        return false;
    }
    
    // get texture for processing.
    texture = CCTextureCache::sharedTextureCache()->addImage("Smile_128x128.png");
    
    // init shaders.
    initPixelProcessShader();
    initRenderShader();
    
    // get main window fbo
    GLint screenFBO;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &screenFBO);
    
    // create new framebuffer for offscreen rendering
    GLuint renderFrameBuffer;
    glGenFramebuffers(1, &renderFrameBuffer);
    
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    

    CVPixelBufferCreate(kCFAllocatorDefault, texture->getContentSize().width, texture->getContentSize().height,
                        kCVPixelFormatType_32BGRA,
                        attrs,
                        &renderTarget);
    // in real life check the error return value of course.
    
    EAGLContext *eaglContext = [[EAGLView sharedEGLView] context];
    
    CVReturn err = CVOpenGLESTextureCacheCreate(
                                                kCFAllocatorDefault,
                                                NULL,
                                                eaglContext,
                                                NULL,
                                                &textureCache);
    
    assert(err == kCVReturnSuccess && "CVOpenGLESTextureCacheCreate failed");
    
    // first create a texture from our renderTarget
    // textureCache will be what you previously made with CVOpenGLESTextureCacheCreate
    CVOpenGLESTextureCacheCreateTextureFromImage (
                                                  kCFAllocatorDefault,
                                                  textureCache,
                                                  renderTarget,
                                                  NULL, // texture attributes
                                                  GL_TEXTURE_2D,
                                                  GL_RGBA, // opengl format
                                                  texture->getContentSize().width,
                                                  texture->getContentSize().height,
                                                  GL_BGRA, // native iOS format
                                                  GL_UNSIGNED_BYTE,
                                                  0,
                                                  &renderTexture);
    // check err value
    
    // set the texture up like any other texture
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture),
                  CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // bind the texture to the framebuffer you're going to render to 
    // (boilerplate code to make a framebuffer not shown)
    glBindFramebuffer(GL_FRAMEBUFFER, renderFrameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    
    ccGLBindTexture2D(0);
    // great, now you're ready to render to your image.
    processPixelsGPU();
    glFlush();
    
    // process pixels how you like!
    // unlock memory with texture data for CPU processing
    if (kCVReturnSuccess == CVPixelBufferLockBaseAddress(renderTarget,
                                                         kCVPixelBufferLock_ReadOnly)) {
        uint32_t* pixels=(uint32_t*)CVPixelBufferGetBaseAddress(renderTarget);
        for (int i = 0; i < texture->getContentSize().height; i++) {
            for (int j = texture->getContentSize().width * 0.5f; j < texture->getContentSize().width; j++) {
                vec4b* pixel = (vec4b*)(pixels + (((int)(texture->getContentSize().width) * i) + j));
                // apple has textures saved as BGRA
                const vec4b White  = {255,255,255,255};
                const vec4b Black  = {0  ,0  ,0  ,255};
                const vec4b Red    = {0  ,0  ,255,255};
                const vec4b Yellow = {0  ,255,255,255};
                if (*pixel == White) {
                    *pixel = Red;
                } else if (*pixel == Black) {
                    *pixel = Yellow;
                }
            }
        }
        // lock the memory back, so the graphic card could have access to it
        CVPixelBufferUnlockBaseAddress(renderTarget, kCVPixelBufferLock_ReadOnly);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, screenFBO);
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    glViewport(0, 0, size.width, size.height);
    
    return true;
}

void PixelRead::initPixelProcessShader() {
    
    ccV3F_C4B_T2F_Quad quad_tmp = {
        //         Position                         Color                  Texture coord.
        { { -1.0f, +1.0f, 0.0f },           {255, 255, 255, 255},          {0.0f, 1.0f} },
        { { -1.0f, -1.0f, 0.0f },           {255, 255, 255, 255},          {0.0f, 0.0f} },
        { { +1.0f, +1.0f, 0.0f },           {255, 255, 255, 255},          {1.0f, 1.0f} },
        { { +1.0f, -1.0f, 0.0f },           {255, 255, 255, 255},          {1.0f, 0.0f} }
    };
    pixelProcessQuad = quad_tmp;
    
    pixelProcessShaderProg = new CCGLProgram;
    pixelProcessShaderProg->initWithVertexShaderFilename("pixelProcess.vsh", "pixelProcess.fsh");
    
    CHECK_GL_ERROR_DEBUG();
    
    pixelProcessShaderProg->addAttribute(kCCAttributeNamePosition, kCCVertexAttrib_Position);
    pixelProcessShaderProg->addAttribute(kCCAttributeNameColor, kCCVertexAttrib_Color);
    pixelProcessShaderProg->addAttribute(kCCAttributeNameTexCoord, kCCVertexAttrib_TexCoords);
    
    pixelProcessShaderProg->link();
    
    CHECK_GL_ERROR_DEBUG();
    
    pixelProcessShaderProg->updateUniforms();
    d_width = pixelProcessShaderProg->getUniformLocationForName("width");
    d_height = pixelProcessShaderProg->getUniformLocationForName("height");
    
    CHECK_GL_ERROR_DEBUG();
    
    //pixelProcessShaderProg->setUniformsForBuiltins();
}

void PixelRead::initRenderShader() {
    
    ccV3F_T2F_Quad quad_tmp = {
        //         Position               Color
        { { -1.0f, +1.0f, 0.0f },     {1.0f, 0.0f} },
        { { -1.0f, -1.0f, 0.0f },     {1.0f, 1.0f} },
        { { +1.0f, +1.0f, 0.0f },     {0.0f, 0.0f} },
        { { +1.0f, -1.0f, 0.0f },     {0.0f, 1.0f} }
    };
    renderQuad = quad_tmp;
    
    renderShaderProg = new CCGLProgram;
    renderShaderProg->initWithVertexShaderFilename("render.vsh", "render.fsh");
    
    CHECK_GL_ERROR_DEBUG();
    
    renderShaderProg->addAttribute(kCCAttributeNamePosition, kCCVertexAttrib_Position);
    renderShaderProg->addAttribute(kCCAttributeNameTexCoord, kCCVertexAttrib_TexCoords);
    
    renderShaderProg->link();
    
    CHECK_GL_ERROR_DEBUG();
    
    renderShaderProg->updateUniforms();
    
    CHECK_GL_ERROR_DEBUG();
    
}

void PixelRead::processPixelsGPU() {
    pixelProcessShaderProg->use();
    glViewport (0, 0, texture->getContentSize().width, texture->getContentSize().height);
    
    glUniform1i(d_width, texture->getContentSize().width);
    glUniform1i(d_height, texture->getContentSize().height);
    
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_PosColorTex );
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture->getName());
    glUniform1i(glGetUniformLocation(pixelProcessShaderProg->getProgram(), "u_texture"), 0);
    
    int vertSize = sizeof(pixelProcessQuad.bl);
    long offset = (long)&pixelProcessQuad;
   
    int diff = offsetof( ccV3F_C4B_T2F, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, vertSize, (GLvoid*) (offset + diff));
    diff = offsetof( ccV3F_C4B_T2F, colors);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertSize, (GLvoid*) (offset + diff));
    diff = offsetof( ccV3F_C4B_T2F, texCoords);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, vertSize, (GLvoid*) (offset + diff));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    CHECK_GL_ERROR_DEBUG();
}

void PixelRead::draw() {
    glEnable(GL_CULL_FACE);
    renderShaderProg->use();    
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords );
    
    int vertSize = sizeof(renderQuad.bl);
    long offset = (long)&renderQuad;

    ccGLBindTexture2D( CVOpenGLESTextureGetName(renderTexture) );
    
    int diff = 0;
    glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, vertSize, (GLvoid*) (offset + diff));
    diff = sizeof(ccVertex3F);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, vertSize, (GLvoid*) (offset + diff));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    ccGLBindTexture2D(0);
    
    CHECK_GL_ERROR_DEBUG();
    
    glDisable(GL_CULL_FACE);
    
}
