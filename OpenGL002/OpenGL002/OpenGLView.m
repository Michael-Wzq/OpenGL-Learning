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


typedef struct {
	float Position[2];
	float Color[4];
	float TexCoord[2];
} Vertex;

Vertex Vertices[];
Vertex FVertices[];

const GLubyte Indices[] = {0,1,2,3};

@interface OpenGLView ()
@property (nonatomic, strong) GLFbo *fbo;
@property (nonatomic, assign) CGFloat proportion;
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;
@property (nonatomic, assign) CGFloat glViewWidth;
@property (nonatomic, assign) CGFloat glViewHeight;
@property (nonatomic, assign) CGFloat touchx;
@property (nonatomic, assign) CGFloat touchy;
@end


@implementation OpenGLView
- (GLuint)setupTexture:(NSString *)fileName {
	CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
	if (!spriteImage) {
		NSLog(@"Failed to load image %@", fileName);
		exit(1);
	}
	
	size_t width = _imageWidth;
	size_t height = _imageHeight;

	//  red，green，blue和alpha通道，每一个通道准备一个字节，所以就要乘以4
	GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
	
	CGColorSpaceRef spriteColor = CGImageGetColorSpace(spriteImage);

	//  每个通道8比特 一个字节
	CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, spriteColor, kCGImageAlphaPremultipliedLast);

	CGContextDrawImage(spriteContext, CGRectMake( 0, 0, width, height),spriteImage);
	
	
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
	_touchPointUniform = [_programResult uniformIndex:@"TouchPoint"];
	_mosaicSizeUniform = [_programResult uniformIndex:@"MosaicRadius"];
	[_programResult use];
	

}

- (id)initWithFrame:(CGRect)frame type:(NSInteger)type
{
	self = [super initWithFrame:frame];
	if (self) {
		_picType = type;
		_glViewWidth = self.frame.size.width;
		_glViewHeight = self.frame.size.height;
	
		[self setupValue:@"aaa.jpg"];
		[self setupLayer];
		[self setupContext];
		[self setupRenderBuffer];
		[self setupFrameBuffer];
		[self compileShaders];
		[self setupVBOs];
		_floorTexture = [self setupTexture:@"aaa.jpg"];
		_fbo = [[GLFbo alloc] initWithSize:CGSizeMake(_imageWidth, _imageHeight)];
		[self touchesBegan:nil withEvent:nil];
	}
	return self;
}

- (void)setupValue:(NSString *)fileName {
	CGFloat midWidth;
	CGFloat midHeight;
	CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
	if (!spriteImage) {
		NSLog(@"Failed to load image %@", fileName);
		exit(1);
	}
	size_t width = CGImageGetWidth(spriteImage);
	size_t height = CGImageGetHeight(spriteImage);
	
	switch (_picType) {
		case 0:
			_imageHeight = height;
			_imageWidth = width;
			_proportion = _imageHeight / _glViewHeight ;
			_imageWidth = _imageWidth / _proportion;
			_imageHeight = self.frame.size.height;
			if (_imageWidth > _glViewWidth) {
				midWidth = -(_imageWidth - _glViewWidth)/2;
			}else {
				midWidth = (_glViewWidth-_imageWidth)/2;
			}
			Vertices[0].Position[0] = midWidth;
			Vertices[0].Position[1] = 0;
			Vertices[1].Position[0] = midWidth+_imageWidth;
			Vertices[1].Position[1] = 0;
			Vertices[2].Position[0] = midWidth;
			Vertices[2].Position[1] = _imageHeight;
			Vertices[3].Position[0] = midWidth +_imageWidth;
			Vertices[3].Position[1] = _imageHeight;
			
			Vertices[0].TexCoord[0] = 0;
			Vertices[0].TexCoord[1] = 1;
			Vertices[1].TexCoord[0] = 1;
			Vertices[1].TexCoord[1] = 1;
			Vertices[2].TexCoord[0] = 0;
			Vertices[2].TexCoord[1] = 0;
			Vertices[3].TexCoord[0] = 1;
			Vertices[3].TexCoord[1] = 0;
			break;
		case 1:
			_imageHeight = _glViewHeight;
			_imageWidth	 = _glViewWidth;
			Vertices[0].Position[0] = 0;
			Vertices[0].Position[1] = 0;
			Vertices[1].Position[0] = _imageWidth;
			Vertices[1].Position[1] = 0;
			Vertices[2].Position[0] = 0;
			Vertices[2].Position[1] = _imageHeight;
			Vertices[3].Position[0] = _imageWidth;
			Vertices[3].Position[1] = _imageHeight;
			
			Vertices[0].TexCoord[0] = 0;
			Vertices[0].TexCoord[1] = 1;
			Vertices[1].TexCoord[0] = 1;
			Vertices[1].TexCoord[1] = 1;
			Vertices[2].TexCoord[0] = 0;
			Vertices[2].TexCoord[1] = 0;
			Vertices[3].TexCoord[0] = 1;
			Vertices[3].TexCoord[1] = 0;
			break;
		case 2:
			_imageHeight = height;
			_imageWidth = width;
			_proportion = _imageWidth / _glViewWidth ;
			_imageHeight = _imageHeight / _proportion;
			_imageWidth = _glViewWidth;
			if (_imageHeight > _glViewHeight) {
				midHeight = -(_imageHeight - _glViewHeight)/2;
			}else {
				midHeight = (_glViewHeight-_imageHeight)/2;
			}
			Vertices[0].Position[0] = 0;
			Vertices[0].Position[1] = midHeight;
			Vertices[1].Position[0] = _imageWidth;
			Vertices[1].Position[1] = midHeight;
			Vertices[2].Position[0] = 0;
			Vertices[2].Position[1] = midHeight + _imageHeight;
			Vertices[3].Position[0] = _imageWidth;
			Vertices[3].Position[1] = midHeight + _imageHeight;
			
			Vertices[0].TexCoord[0] = 0;
			Vertices[0].TexCoord[1] = 1;
			Vertices[1].TexCoord[0] = 1;
			Vertices[1].TexCoord[1] = 1;
			Vertices[2].TexCoord[0] = 0;
			Vertices[2].TexCoord[1] = 0;
			Vertices[3].TexCoord[0] = 1;
			Vertices[3].TexCoord[1] = 0;
			break;
			
			
 
		default:
			break;
	}
	
	
	
}





- (void)setupVBOs {
 
	
	glGenBuffers(1, &_vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	//  把Vertices数据传到GL_ARRAY_BUFFER
	glBufferData(GL_ARRAY_BUFFER, ((2+4+2) * 4 * 4 ), Vertices, GL_STATIC_DRAW);
 
	glGenBuffers(1, &_vertexBuffer2);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
	//  把FVertices数据传到GL_ARRAY_BUFFER
	glBufferData(GL_ARRAY_BUFFER,  ((2+4+2) * 4 * 4 ), FVertices, GL_STATIC_DRAW);
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



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesMoved:touches withEvent:nil];
}





- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event	{
	
}

- (CGFloat )addTouchPointWithX:(CGFloat)x gradient:(CGFloat)k b:(CGFloat)b{
	CGFloat y ;
	y = k * x + b;
	return y;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	CGPoint previousTouchPoint = [touch previousLocationInView:self];
	
//	NSLog(@"---------（%f，%f）---------",touchPoint.x,touchPoint.y);

	NSLog(@"%lu",(unsigned long)touch.timestamp);
	
//	NSLog(@"---------（%f，%f）---------",previousTouchPoint.x,previousTouchPoint.y);
	
	
	CGFloat differX = touchPoint.x - previousTouchPoint.x ;
	CGFloat differY = touchPoint.y - previousTouchPoint.y ;
	CGFloat gradient ;
	CGFloat b ;
	if (touchPoint.x > previousTouchPoint.x) {
		CGPoint temp;
		temp = touchPoint;
		touchPoint = previousTouchPoint;
		previousTouchPoint = temp;
	}
	
	
	if (differX != 0 ) {
		gradient = differY / differX;
		b = touchPoint.y - gradient*touchPoint.x;
	
	for (float i = touchPoint.x; i <= previousTouchPoint.x; i = i + 0.5 ) {
		CGPoint	addPoint;
		addPoint.x = i ;
		addPoint.y = [self addTouchPointWithX:i gradient:gradient b:b];
		NSLog(@"---------(%f,%f)---------",addPoint.x,addPoint.y);
	switch (_picType) {
		case 0:
			[self lashenWithPoint:addPoint];
			break;
		case 1:
			[self pingpuWithPoint:addPoint];
			break;
		case 2:
			[self juzhongWithPoint:addPoint];
			break;
		default:
			break;
	}
	[self drawFbo];
		
	}
	
	
	}else {
		for (float i = touchPoint.y; i <= previousTouchPoint.y; i = i + 0.5 ) {
			CGPoint	addPoint;
			addPoint.x = touchPoint.x;
			addPoint.y = i;
			NSLog(@"---------(%f,%f)---------",addPoint.x,addPoint.y);
			switch (_picType) {
				case 0:
					[self lashenWithPoint:addPoint];
					break;
				case 1:
					[self pingpuWithPoint:addPoint];
					break;
				case 2:
					[self juzhongWithPoint:addPoint];
					break;
				default:
					break;
			}
			[self drawFbo];
		}
	}
	

	
}


- (void)drawFbo {
	GLKMatrix4 matrix;
	matrix = GLKMatrix4MakeOrtho(0,
								 _imageWidth,
								 0,
								 _imageHeight,
								 -1,
								 1);
	[_programResult use];
	[self.fbo useFBO];
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
	glBufferSubData(GL_ARRAY_BUFFER, 0,  ((2+4+2) * 4 * 4 ), FVertices);
	glUniformMatrix4fv(_modelViewUniformone, 1, 0, matrix.m);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, _floorTexture);
	glUniform1i(_textureUniform, 0);
	glUniform2f(_texSizeUniform, _imageWidth, _imageHeight);
	glUniform1f(_mosaicSizeUniform, _mosaicRadius/2.0);
	glUniform2f(_touchPointUniform, _touchx,_touchy);
	
	
	
	glVertexAttribPointer(_positionSlottwo, 2, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), 0);
	glVertexAttribPointer(_colorSlottwo, 4, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), (GLvoid*) (sizeof(float) *2));
	glVertexAttribPointer(_texCoordSlottwo, 2, GL_FLOAT, GL_FALSE,
						  sizeof(Vertex), (GLvoid*) (sizeof(float) *6));
	glDrawElements(GL_TRIANGLE_STRIP, 4,GL_UNSIGNED_BYTE, Indices);
	
	
	
	matrix = GLKMatrix4MakeOrtho(0,
								 _glViewWidth,
								 0,
								 _glViewHeight,
								 -1,
								 1);
	glViewport(0, 0, _glViewWidth, _glViewHeight);
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
	glDrawElements(GL_TRIANGLE_STRIP, 4 ,GL_UNSIGNED_BYTE, Indices);
	
	[_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)lashenWithPoint:(CGPoint)touchPoint {
	CGFloat midWidth;
	CGFloat midHeight;
	
	midWidth = (_imageWidth - _glViewWidth)/2;
	midHeight = 0;
	
	_touchx = midWidth + touchPoint.x;
	_touchy = touchPoint.y;
	FVertices[0].Position[0] = midWidth + touchPoint.x - _mosaicRadius;
	FVertices[0].Position[1] =   touchPoint.y - _mosaicRadius;
	FVertices[1].Position[0] = midWidth +  touchPoint.x + _mosaicRadius;
	FVertices[1].Position[1] =   touchPoint.y - _mosaicRadius;
	FVertices[2].Position[0] = midWidth +  touchPoint.x - _mosaicRadius;
	FVertices[2].Position[1] =   touchPoint.y + _mosaicRadius;
	FVertices[3].Position[0] = midWidth +   touchPoint.x + _mosaicRadius;
	FVertices[3].Position[1] =   touchPoint.y + _mosaicRadius;
	
	FVertices[0].TexCoord[0] = (midWidth  + touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[0].TexCoord[1] = (touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[1].TexCoord[0] = (midWidth  + touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[1].TexCoord[1] = (touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[2].TexCoord[0] = (midWidth  + touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[2].TexCoord[1] = (touchPoint.y + _mosaicRadius) / (_imageHeight);
	FVertices[3].TexCoord[0] = (midWidth  + touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[3].TexCoord[1] = (touchPoint.y + _mosaicRadius) / (_imageHeight);
	
}
- (void)pingpuWithPoint:(CGPoint)touchPoint {
	
	_touchx = touchPoint.x;
	_touchy = touchPoint.y;
	FVertices[0].Position[0] =  touchPoint.x - _mosaicRadius;
	FVertices[0].Position[1] =  touchPoint.y - _mosaicRadius;
	FVertices[1].Position[0] =  touchPoint.x + _mosaicRadius;
	FVertices[1].Position[1] =  touchPoint.y - _mosaicRadius;
	FVertices[2].Position[0] =  touchPoint.x - _mosaicRadius;
	FVertices[2].Position[1] =  touchPoint.y + _mosaicRadius;
	FVertices[3].Position[0] =  touchPoint.x + _mosaicRadius;
	FVertices[3].Position[1] =  touchPoint.y + _mosaicRadius;
	
	FVertices[0].TexCoord[0] = (touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[0].TexCoord[1] = (touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[1].TexCoord[0] = (touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[1].TexCoord[1] = (touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[2].TexCoord[0] = (touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[2].TexCoord[1] = (touchPoint.y + _mosaicRadius) / (_imageHeight);
	FVertices[3].TexCoord[0] = (touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[3].TexCoord[1] = (touchPoint.y + _mosaicRadius) / (_imageHeight);
}
- (void)juzhongWithPoint:(CGPoint)touchPoint {
	CGFloat midHeight;
	midHeight = (_imageHeight - _glViewHeight)/2;
	
	_touchx =  touchPoint.x;
	_touchy	=  midHeight + touchPoint.y;
	
	FVertices[0].Position[0] = touchPoint.x - _mosaicRadius;
	FVertices[0].Position[1] =   midHeight + touchPoint.y - _mosaicRadius;
	FVertices[1].Position[0] =  touchPoint.x + _mosaicRadius;
	FVertices[1].Position[1] =  midHeight +  touchPoint.y - _mosaicRadius;
	FVertices[2].Position[0] =   touchPoint.x - _mosaicRadius;
	FVertices[2].Position[1] = midHeight +  touchPoint.y + _mosaicRadius;
	FVertices[3].Position[0] =   touchPoint.x + _mosaicRadius;
	FVertices[3].Position[1] =  midHeight +  touchPoint.y + _mosaicRadius;
	
	FVertices[0].TexCoord[0] = ( touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[0].TexCoord[1] = (midHeight  +touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[1].TexCoord[0] = (touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[1].TexCoord[1] = (midHeight  + touchPoint.y - _mosaicRadius) / (_imageHeight);
	FVertices[2].TexCoord[0] = ( touchPoint.x - _mosaicRadius) / (_imageWidth);
	FVertices[2].TexCoord[1] = (midHeight  +touchPoint.y + _mosaicRadius) / (_imageHeight);
	FVertices[3].TexCoord[0] = ( touchPoint.x + _mosaicRadius) / (_imageWidth);
	FVertices[3].TexCoord[1] = (midHeight  +touchPoint.y + _mosaicRadius) / (_imageHeight);
}
@end
