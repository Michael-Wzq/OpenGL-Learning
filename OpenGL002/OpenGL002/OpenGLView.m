//
//  OpenGLView.m
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"
#import <GLKit/GLKit.h>

const CGFloat kHEIGHT = 568;
const CGFloat kWIDTH  = 320;
typedef struct {
	float Position[2];
	float Color[4];
	float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
	{  {0, 0},            {1, 1, 1, 1},   {0, 1}  },
	{  {kWIDTH, 0},       {1, 1, 1, 1},   {1, 1}  },
	{  {0, kHEIGHT},      {1, 1, 1, 1},   {0, 0}  },
	{  {kWIDTH, kHEIGHT}, {1, 1, 1, 1},   {1, 0}  }
};
static Vertex FVertices[] = {
	{  {0, 0},            {1, 1, 1, 1},   {0, 0}   },
	{  {kWIDTH, 0},       {1, 1, 1, 1},   {1, 0}   },
	{  {0, kHEIGHT},      {1, 1, 1, 1},   {0, 1}   },
	{  {kWIDTH, kHEIGHT}, {1, 1, 1, 1},   {1, 1}   }
};
const GLubyte Indices[] = {0,1,2,3};

@interface OpenGLView ()
@property (nonatomic, strong) GLFbo *fbo;
@property (nonatomic, assign) BOOL isFirst;
@end


@implementation OpenGLView
- (GLuint)setupTexture:(NSString *)fileName {
	CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
	if (!spriteImage) {
		NSLog(@"Failed to load image %@", fileName);
		exit(1);
	}
	
	size_t width = CGImageGetWidth(spriteImage);
	size_t height = CGImageGetHeight(spriteImage);
	
	
	
	//  red，green，blue和alpha通道，每一个通道准备一个字节，所以就要乘以4
	GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
	
	CGColorSpaceRef spriteColor = CGImageGetColorSpace(spriteImage);

	//  每个通道8比特 一个字节
	CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, spriteColor, kCGImageAlphaPremultipliedLast);
	
	CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
	CGContextRelease(spriteContext);
	
	GLuint texName;
	// 创建纹理对象
	glGenTextures(1, &texName);
	glBindTexture(GL_TEXTURE_2D, texName);
 
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_MAG_FILTER , GL_LINEAR        );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_MIN_FILTER , GL_LINEAR        );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_WRAP_S     , GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_WRAP_T     , GL_CLAMP_TO_EDGE );
 
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei) height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
	free(spriteData);
	return texName;
	
}





- (void)compileShaders {
 	 NSString *vertexShaderString = @"MixVertex";
	 NSString *fragmentShaderString = @"MixFragment";
	
	_programHandle = [[GLProgram alloc]initWithVertexShaderFilename:vertexShaderString fragmentShaderFilename:fragmentShaderString];
	if (!_programHandle.initialized)
	{
		[_programHandle addAttribute:@"Position"];
		[_programHandle addAttribute:@"SourceColor"];
		[_programHandle addAttribute:@"TexCoordIn"];
		
		if (![_programHandle link])
		{
			NSString *progLog = [_programHandle programLog];
			NSLog(@"Program link log: %@", progLog);
			NSString *fragLog = [_programHandle fragmentShaderLog];
			NSLog(@"Fragment shader compile log: %@", fragLog);
			NSString *vertLog = [_programHandle vertexShaderLog];
			NSLog(@"Vertex shader compile log: %@", vertLog);
			_programHandle = nil;
			NSAssert(NO, @"Filter shader link failed");
		}
	}
	_positionSlot = [_programHandle attributeIndex:@"Position"];
	glEnableVertexAttribArray(_positionSlot);
	_colorSlot = [_programHandle attributeIndex:@"SourceColor"];
	glEnableVertexAttribArray(_colorSlot);
	_texCoordSlot = [_programHandle attributeIndex:@"TexCoordIn"];
	glEnableVertexAttribArray(_texCoordSlot);
	_textureUniform = [_programHandle uniformIndex:@"Texture"];
	_modelViewUniformone = [_programHandle uniformIndex:@"Modelview"];
	_textureUniformThree = [_programHandle uniformIndex:@"Texture1"];
    [_programHandle use];


	
	 NSString *vertexShaderString1 = @"SimpleVertex";
	 NSString *fragmentShaderString1 = @"SimpleFragment";

	_programResult = [[GLProgram alloc]initWithVertexShaderFilename:vertexShaderString1 fragmentShaderFilename:fragmentShaderString1];
	if (!_programResult.initialized)
	{
		[_programResult addAttribute:@"Position"];
		[_programResult addAttribute:@"SourceColor"];
		[_programResult addAttribute:@"TexCoordIn"];
		
		if (![_programResult link])
		{
			NSString *progLog = [_programResult programLog];
			NSLog(@"Program link log: %@", progLog);
			NSString *fragLog = [_programResult fragmentShaderLog];
			NSLog(@"Fragment shader compile log: %@", fragLog);
			NSString *vertLog = [_programResult vertexShaderLog];
			NSLog(@"Vertex shader compile log: %@", vertLog);
			_programResult = nil;
			NSAssert(NO, @"Filter shader link failed");
		}
	}
	_positionSlottwo = [_programResult attributeIndex:@"Position"];
	glEnableVertexAttribArray(_positionSlottwo);
	_colorSlottwo = [_programResult attributeIndex:@"SourceColor"];
	glEnableVertexAttribArray(_colorSlottwo);
	_texCoordSlottwo	= [_programResult attributeIndex:@"TexCoordIn"];
	glEnableVertexAttribArray(_texCoordSlottwo);
	_textureUniformtwo = [_programResult uniformIndex:@"Texture"];
	_texSizeUniform = [_programResult uniformIndex:@"TexSize"];
	_touchSizeUniform = [_programResult uniformIndex:@"TouchSize"];
	_modelViewUniformone = [_programResult uniformIndex:@"Modelview"];
	
	[_programResult use];
	

}


- (void)setupDisplayLink {
//	CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
//	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		
		[self setupLayer];
		[self setupContext];
		[self setupRenderBuffer];
		[self setupFrameBuffer];
		[self compileShaders];
		[self setupVBOs];
		[self setupDisplayLink];
		_floorTexture = [self setupTexture:@"qq.png"];
	
		
		
		_fbo = [[GLFbo alloc] initWithSize:frame.size];
	
	}
	return self;
}

- (void)setupVBOs {
 
	
	glGenBuffers(1, &_vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	//  把Vertices数据传到GL_ARRAY_BUFFER
	glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
 
	glGenBuffers(1, &_vertexBuffer2);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
	//  把FVertices数据传到GL_ARRAY_BUFFER
	glBufferData(GL_ARRAY_BUFFER, sizeof(FVertices), FVertices, GL_STATIC_DRAW);
	
	
//	GLuint indexBuffer;
//	glGenBuffers(1, &indexBuffer);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
//	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
 
}

- (void)dealloc
{
	_context = nil;
}

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (void)setupLayer {
	_eaglLayer = (CAEAGLLayer*) self.layer;
	_eaglLayer.opaque = YES;
}

- (void)setupContext {
	EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
	_context = [[EAGLContext alloc] initWithAPI:api];
	if (!_context) {
		NSLog(@"Failed to initialize OpenGLES 2.0 context");
		exit(1);
	}
 
	if (![EAGLContext setCurrentContext:_context]) {
		NSLog(@"Failed to set current OpenGL context");
		exit(1);
	}
}

- (void)setupRenderBuffer {
	//  创建一个新的render buffer object 用把这个唯一值传入buffer作为标记
	glGenRenderbuffers(1, &_colorRenderBuffer);
	//  告诉OpenGL 定义的buffer对象是属于哪一种OpenGL对象 
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
	//  为render buffer 分配空间
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

//  设置帧缓冲区 
- (void)setupFrameBuffer {
	
	glGenFramebuffers(1, &_framebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
	//  把前面的render buffer依附在frame buffer的GL_COLOR_ATTACHMENT0位置上
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
							  GL_RENDERBUFFER, _colorRenderBuffer);

}

- (void)render:(CADisplayLink*)displayLink {
	
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	glBlendFunc(GL_ONE, GL_ZERO);
//	glEnable(GL_BLEND);
	UITouch *touch = [touches anyObject];
	
	CGPoint touchPoint = [touch locationInView:self];
	
	NSLog(@"%f==%f",touchPoint.x,touchPoint.y);

	[_programResult use];
	glUniform2f(_touchSizeUniform, touchPoint.x, touchPoint.y);
	FVertices[0].Position[0] = touchPoint.x - 50;
	FVertices[0].Position[1] = touchPoint.y - 50;
	FVertices[1].Position[0] = touchPoint.x + 50;
	FVertices[1].Position[1] = touchPoint.y - 50;
	FVertices[2].Position[0] = touchPoint.x - 50;
	FVertices[2].Position[1] = touchPoint.y + 50;
	FVertices[3].Position[0] = touchPoint.x + 50;
	FVertices[3].Position[1] = touchPoint.y + 50;
	
	FVertices[0].TexCoord[0] = (touchPoint.x - 50) / kWIDTH;
	FVertices[0].TexCoord[1] = (touchPoint.y - 50) /kHEIGHT;
	FVertices[1].TexCoord[0] = (touchPoint.x + 50)/ kWIDTH;
	FVertices[1].TexCoord[1] = (touchPoint.y - 50)/kHEIGHT;
	FVertices[2].TexCoord[0] = (touchPoint.x - 50)/ kWIDTH;
	FVertices[2].TexCoord[1] = (touchPoint.y + 50)/kHEIGHT;
	FVertices[3].TexCoord[0] = (touchPoint.x + 50)/ kWIDTH;
	FVertices[3].TexCoord[1] = (touchPoint.y + 50)/kHEIGHT;
	
	
	glClearColor(1.0,1.0, 1.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
//	glClear(GL_COLOR_ATTACHMENT0);
 
	
	GLKMatrix4 matrix = GLKMatrix4MakeOrtho(0,
											self.frame.size.width,
											0,
											self.frame.size.height,
											-1,
											1);
	
	glViewport(0, 0, self.frame.size.width, self.frame.size.height);
	
		
	
	[_programResult use];
	[self.fbo useFBO];
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
	glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(FVertices), FVertices);
	glUniformMatrix4fv(_modelViewUniformone, 1, 0, matrix.m);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, _floorTexture);
	glUniform1i(_textureUniform, 0);
	glUniform2f(_texSizeUniform, self.frame.size.width, self.frame.size.height);
	
	glVertexAttribPointer(_positionSlottwo, 2, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), 0);
	glVertexAttribPointer(_colorSlottwo, 4, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), (GLvoid*) (sizeof(float) *2));
	glVertexAttribPointer(_texCoordSlottwo, 2, GL_FLOAT, GL_FALSE,
						  sizeof(Vertex), (GLvoid*) (sizeof(float) *6));
	glDrawElements(GL_TRIANGLE_STRIP, 4,GL_UNSIGNED_BYTE, Indices);
	
	[_programHandle use];
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
	glUniformMatrix4fv(_modelViewUniformone, 1, 0, matrix.m);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, [self.fbo texture]);
	glUniform1i(_textureUniformtwo, 0);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, _floorTexture);
	glUniform1i(_textureUniformThree, 1);
	glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE,
	        sizeof(Vertex), 0);
	glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
	        sizeof(Vertex), (GLvoid*) (sizeof(float) *2));
	glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE,
							  sizeof(Vertex), (GLvoid*) (sizeof(float) *6));
	glDrawElements(GL_TRIANGLE_STRIP, 4,GL_UNSIGNED_BYTE, Indices);
	
	
	
	[_context presentRenderbuffer:GL_RENDERBUFFER];

}

@end
