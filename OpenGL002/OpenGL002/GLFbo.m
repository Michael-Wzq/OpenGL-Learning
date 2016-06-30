//
//  GLFbo.m
//  SpringDemo
//
//  Created by ZhangXiaoJun on 14-7-28.
//  Copyright (c) 2014年 mtt0122. All rights reserved.
//

#import "GLFbo.h"
#import <OpenGLES/ES2/gl.h>

@interface GLFbo ()
@property (nonatomic, readwrite, assign) GLuint frameBuffer;
@property (nonatomic, readwrite, assign) GLuint texture;
@end

@implementation GLFbo

- (void)dealloc
{
    [self unBindFBO];
    
    if (self.frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        self.frameBuffer = 0;
    }
    
    if (self.texture) {
        glDeleteTextures(1, &_texture);
        self.texture = 0;
    }
}

- (instancetype)initWithSize:(CGSize)size
{
    self = [super init];
    if (self)
    {
        _fboSize = size;
        [self createFBOWithSize:size];
    }
    return self;
}

- (void)createFBOWithSize:(CGSize)size
{
    if (_frameBuffer == 0)
    {
        glGenFramebuffers(1, &_frameBuffer);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    
   	if(_texture == 0)
	{
		_texture = [GLFbo createTextureWithSize:size];
		if (_texture==0)
		{
			NSLog(@"m_CompyTexture is 0");
		}
	}
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if(status != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"GLFbo:failed to make complete framebuffer object %x", status);
        assert(false);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
}

- (void)unBindFBO
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

 /**
 *  创建fbo纹理
 *
 *  @param size 纹理大小
 *
 *  @return 创建后的纹理
 */
+ (GLuint)createTextureWithSize:(CGSize)size
{
    
    GLint width = size.width;
    GLint height = size.height;
    
	GLuint textureID;
	glGenTextures(1, &textureID);
	if (textureID == 0)
	{
		return 0;
	}
	glBindTexture(GL_TEXTURE_2D, textureID);
	//unsigned char* pData = (unsigned char*)malloc(width*height*4);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	//free(pData);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
	return textureID;
}

- (void)useFBO
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
	glViewport(0, 0, (int)self.fboSize.width, (int)self.fboSize.height);
}

- (id)debugQuickLookObject
{
    return [self snapshot];
}

void framebuffer1PixelDataRelease (void *info, const void *data, size_t size)
{
    free((void *)data);
}

- (UIImage *)snapshot
{
    return [self snapshotForRect:CGRectMake(0, 0, self.fboSize.width, self.fboSize.height)];
}

- (UIImage *)snapshotForRect:(CGRect)rect
{
    CGImageRef cgImage = [self newCGImageFromFramebufferWithRect:rect];
    UIImage *finalImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return finalImage;
}

- (CGImageRef)newCGImageFromFramebuffer
{
    return [self newCGImageFromFramebufferWithRect:CGRectMake(0, 0, _fboSize.width, _fboSize.height)];
}

- (CGImageRef)newCGImageFromFramebufferWithRect:(CGRect)rect
{
    [self bind];
    // 初始化图片数据信息
    size_t bytes = 4;
    NSUInteger totalBytesForImage = rect.size.width * rect.size.height * bytes;
    
    // 获取图片数据指针
    GLubyte *rawImagePixelsTemp = [self createSnapshotDataForRect:rect];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData((__bridge void *)(self), rawImagePixelsTemp, totalBytesForImage, framebuffer1PixelDataRelease);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 创建CGImage
    CGImageRef cgImageFromBytes = CGImageCreate(rect.size.width, rect.size.height, 8, 32, bytes * rect.size.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    // 释放无用数据
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    
    
    return cgImageFromBytes;
}

- (GLvoid *)createSnapshotData
{
    return [self createSnapshotDataForRect:CGRectMake(0, 0, self.fboSize.width, self.fboSize.height)];
}

- (GLvoid *)createSnapshotDataForRect:(CGRect)rect
{
    [self bind];
    size_t bytes = 4;
    NSUInteger paddedBytesForImage = rect.size.width * rect.size.height * bytes;
    void *rawImagePixelsTemp = malloc(paddedBytesForImage);
    glReadPixels(rect.origin.x, rect.origin.y,rect.size.width,rect.size.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixelsTemp);
    [self unBind];
    return rawImagePixelsTemp;
}

- (void)bind
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, (int)self.fboSize.width, (int)self.fboSize.height);
}

- (void)unBind
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

@end
