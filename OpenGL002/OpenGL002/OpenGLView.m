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


//  用于跟踪组成每个三角形的索引信息？
const GLubyte Indices[] = {0,1,2,3};

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




- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
	NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
	NSError *error;
	NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
	if (!shaderString) {
		NSLog(@"Error loading shader: %@",error.localizedDescription);
		exit(1);
	}
	GLuint shaderHandle = glCreateShader(shaderType);
	const char *shaderStringUTF8 = [shaderString UTF8String];
	int shaderStringLength =(int) [shaderString length];
	glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
	glCompileShader(shaderHandle);
	GLint compileSuccess;
	glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
	if (compileSuccess == GL_FALSE) {
		GLchar messages[256];
		glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"%@", messageString);
		exit(1);
	}
	return shaderHandle;
}

- (void)compileShaders {
 
	// 1
	GLuint vertexShader = [self compileShader:@"SimpleVertex"
									 withType:GL_VERTEX_SHADER];
	GLuint fragmentShader = [self compileShader:@"SimpleFragment"
									   withType:GL_FRAGMENT_SHADER];
 
	// 2
	GLuint programHandle = glCreateProgram();
	glAttachShader(programHandle, vertexShader);
	glAttachShader(programHandle, fragmentShader);
	glLinkProgram(programHandle);
 
	// 3
	GLint linkSuccess;
	glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
	if (linkSuccess == GL_FALSE) {
		GLchar messages[256];
		glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"%@", messageString);
		exit(1);
	}
 
	// 4
	glUseProgram(programHandle);
 
	// 5
	_positionSlot = glGetAttribLocation(programHandle, "Position");
	glEnableVertexAttribArray(_positionSlot);
	
	_colorSlot = glGetAttribLocation(programHandle, "SourceColor");
	glEnableVertexAttribArray(_colorSlot);
	
	_texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
	glEnableVertexAttribArray(_texCoordSlot);
	

	_modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
	_textureUniform = glGetUniformLocation(programHandle, "Texture");
	_texSizeUniform = glGetUniformLocation(programHandle, "TexSize");
	_touchSizeUniform = glGetUniformLocation(programHandle, "TouchSize");
    
	
}

- (void)setupDisplayLink {
	CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
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
		
		
	}
	return self;
}

- (void)setupVBOs {
 
	GLuint vertexBuffer;
	glGenBuffers(1, &vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	//  把Vertices数据传到GL_ARRAY_BUFFER
	glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
 
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
	GLuint framebuffer;
	glGenFramebuffers(1, &framebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	//  把前面的render buffer依附在frame buffer的GL_COLOR_ATTACHMENT0位置上
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
							  GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)render:(CADisplayLink*)displayLink {
	glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
 
	
	GLKMatrix4 matrix = GLKMatrix4MakeOrtho(0,
											self.frame.size.width,
											0,
											self.frame.size.height,
											-1,
											1);
	_currentRotation += displayLink.duration ;

//	matrix = GLKMatrix4Rotate(matrix, _currentRotation, 0, 0, 1);

	
	
	//	CC3GLMatrix *modelView = [CC3GLMatrix matrix];
//	[modelView populateFromTranslation:CC3VectorMake(0, 0, 0)];
//	_currentRotation += displayLink.duration * 90;
//	[modelView rotateBy:CC3VectorMake(0,  0, _currentRotation)];
	glUniformMatrix4fv(_modelViewUniform, 1, 0, matrix.m);
	
	
	// 1
	glViewport(0, 0, self.frame.size.width, self.frame.size.height);
 
	// 2
	glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), 0);
	glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), (GLvoid*) (sizeof(float) *2));
 
	glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE,
						  sizeof(Vertex), (GLvoid*) (sizeof(float) *6));
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, _floorTexture);
	glUniform1i(_textureUniform, 0);
	glUniform2f(_texSizeUniform, self.frame.size.width, self.frame.size.height);
	
	// 3
	glDrawElements(GL_TRIANGLE_STRIP, 4,GL_UNSIGNED_BYTE, Indices);
//	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
 
	[_context presentRenderbuffer:GL_RENDERBUFFER];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event

{
	
	UITouch *touch = [touches anyObject];
	
	CGPoint touchPoint = [touch locationInView:self];
	
	NSLog(@"%f==%f",touchPoint.x,touchPoint.y);
	
	glUniform2f(_touchSizeUniform, touchPoint.x, touchPoint.y);
	
	
	
}

@end
