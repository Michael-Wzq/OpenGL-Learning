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
 	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_WRAP_S     , GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_WRAP_T     , GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_MAG_FILTER , GL_LINEAR        );
	glTexParameteri( GL_TEXTURE_2D , GL_TEXTURE_MIN_FILTER , GL_LINEAR        );

 
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
	_boolOfDrawCircle =  [_programResult uniformIndex:@"DrawCircle"];
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
			_mosaicRadius = _mosaicRadius / _proportion;
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



- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	CGPoint previousTouchPoint = [touch previousLocationInView:self];
	
	
	switch (_picType) {
		case 0:
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self oneWithPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 0);
			[self oneWithPoint:touchPoint previousPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self oneWithPoint:touchPoint];
			[self drawFbo];
			break;
	
		
		case 1:
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self twoWithPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 0);
			[self twoWithPoint:touchPoint previousPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self twoWithPoint:touchPoint];
			[self drawFbo];
			
			
		
			break;
		case 2:
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self threeWithPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 0);
			[self threeWithPoint:touchPoint previousPoint:previousTouchPoint];
			[self drawFbo];
			
			[_programResult use];
			glUniform1i(_boolOfDrawCircle, 1);
			[self threeWithPoint:touchPoint];
			[self drawFbo];
			
		
			break;
		default:
			break;
	}
	  
}
	
	

	



- (void)drawFbo {

	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	
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
	glUniform1f(_mosaicSizeUniform, _mosaicRadius);
	glUniform2f(_touchPointUniform, _touchx,_touchy);
	
	
	
	glVertexAttribPointer(_positionSlottwo, 2, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), 0);
	glVertexAttribPointer(_colorSlottwo, 4, GL_FLOAT, GL_FALSE,
        sizeof(Vertex), (GLvoid*) (sizeof(float) *2));
	glVertexAttribPointer(_texCoordSlottwo, 2, GL_FLOAT, GL_FALSE,
						  sizeof(Vertex), (GLvoid*) (sizeof(float) *6));
	glDrawElements(GL_TRIANGLE_STRIP, 4 ,GL_UNSIGNED_BYTE, Indices);
	
	
	
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



- (void)threeWithPoint:(CGPoint)touchPoint previousPoint:(CGPoint)previousPoint {
	CGFloat midHeight;
	midHeight = (_imageHeight - _glViewHeight)/2;
	
	_touchx =  touchPoint.x;
	_touchy	=  midHeight + touchPoint.y;
	


	
	CGFloat _previousTouchx,_previousTouchy;
	_previousTouchx =   previousPoint.x ;
	_previousTouchy	=  midHeight + previousPoint.y;
	
	CGFloat k,b;
	CGFloat x1,x2,y1,y2;
	CGFloat x3,x4,y3,y4;
	if (touchPoint.y == previousPoint.y) {
		x1 = previousPoint.x ;
		y1 = previousPoint.y - _mosaicRadius;
		x2 = previousPoint.x ;
		y2 = previousPoint.y + _mosaicRadius;
		x3 = touchPoint.x ;
		y3 = touchPoint.y -_mosaicRadius;
		x4 = touchPoint.x ;
		y4 = touchPoint.y + _mosaicRadius;
	}else {
		k = -(touchPoint.x-previousPoint.x)/(touchPoint.y-previousPoint.y);
		
		b = touchPoint.y - k * touchPoint.x;
		CGFloat a,c,d;
		a = 1 + k*k;
		c = 2*k*b-2*touchPoint.x-2*k*touchPoint.y;
		d = touchPoint.x*touchPoint.x+touchPoint.y*touchPoint.y-2*b*touchPoint.y+b*b-_mosaicRadius*_mosaicRadius;
		
		
		x1 = (-c - sqrtf(c*c-4*a*d))/(2*a);
		y1 = k * x1 + b;
		x2 = (-c + sqrtf(c*c-4*a*d))/(2*a);
		y2 = k * x2 + b;
		
		
		b = previousPoint.y - k * previousPoint.x;
		c = 2*k*b-2*previousPoint.x-2*k*previousPoint.y;
		d = previousPoint.x*previousPoint.x+previousPoint.y*previousPoint.y-2*b*previousPoint.y+b*b-_mosaicRadius*_mosaicRadius;
		x3 = (-c - sqrtf(c*c-4*a*d))/(2*a);
		y3 = k * x3 + b;
		x4 = (-c + sqrtf(c*c-4*a*d))/(2*a);
		y4 = k * x4 + b;
	}
	
	
	
	
	FVertices[0].Position[0] =  x1;
	FVertices[0].Position[1] =   midHeight + y1;
	FVertices[1].Position[0] =  x2;
	FVertices[1].Position[1] =   midHeight + y2;
	FVertices[2].Position[0] =  x3;
	FVertices[2].Position[1] =   midHeight + y3;
	FVertices[3].Position[0] = x4;
	FVertices[3].Position[1] =   midHeight + y4;
	
	FVertices[0].TexCoord[0] = ( x1) / (_imageWidth);
	FVertices[0].TexCoord[1] = ( midHeight +y1) / (_imageHeight);
	FVertices[1].TexCoord[0] = (x2) / (_imageWidth);
	FVertices[1].TexCoord[1] = ( midHeight +y2) / (_imageHeight);
	FVertices[2].TexCoord[0] = ( x3) / (_imageWidth);
	FVertices[2].TexCoord[1] = ( midHeight +y3) / (_imageHeight);
	FVertices[3].TexCoord[0] = (x4) / (_imageWidth);
	FVertices[3].TexCoord[1] = ( midHeight +y4) / (_imageHeight);
}



- (void)twoWithPoint:(CGPoint)touchPoint previousPoint:(CGPoint)previousPoint {
	
	
	
	_touchx = touchPoint.x;
	_touchy = touchPoint.y;
	
	CGFloat _previousTouchx,_previousTouchy;
	_previousTouchx =  previousPoint.x ;
	_previousTouchy	=  previousPoint.y;
	
	CGFloat k,b;
	CGFloat x1,x2,y1,y2;
	CGFloat x3,x4,y3,y4;
	if (touchPoint.y == previousPoint.y) {
		x1 = previousPoint.x ;
		y1 = previousPoint.y - _mosaicRadius;
		x2 = previousPoint.x ;
		y2 = previousPoint.y + _mosaicRadius;
		x3 = touchPoint.x ;
		y3 = touchPoint.y -_mosaicRadius;
		x4 = touchPoint.x ;
		y4 = touchPoint.y + _mosaicRadius;
	}else {
		k = -(touchPoint.x-previousPoint.x)/(touchPoint.y-previousPoint.y);
		
		b = touchPoint.y - k * touchPoint.x;
		CGFloat a,c,d;
		a = 1 + k*k;
		c = 2*k*b-2*touchPoint.x-2*k*touchPoint.y;
		d = touchPoint.x*touchPoint.x+touchPoint.y*touchPoint.y-2*b*touchPoint.y+b*b-_mosaicRadius*_mosaicRadius;
		
		
		x1 = (-c - sqrtf(c*c-4*a*d))/(2*a);
		y1 = k * x1 + b;
		x2 = (-c + sqrtf(c*c-4*a*d))/(2*a);
		y2 = k * x2 + b;
		
		
		b = previousPoint.y - k * previousPoint.x;
		c = 2*k*b-2*previousPoint.x-2*k*previousPoint.y;
		d = previousPoint.x*previousPoint.x+previousPoint.y*previousPoint.y-2*b*previousPoint.y+b*b-_mosaicRadius*_mosaicRadius;
		x3 = (-c - sqrtf(c*c-4*a*d))/(2*a);
		y3 = k * x3 + b;
		x4 = (-c + sqrtf(c*c-4*a*d))/(2*a);
		y4 = k * x4 + b;
	}
	
	
	
	
	FVertices[0].Position[0] =   x1;
	FVertices[0].Position[1] =   y1;
	FVertices[1].Position[0] =   x2;
	FVertices[1].Position[1] =   y2;
	FVertices[2].Position[0] =   x3;
	FVertices[2].Position[1] =   y3;
	FVertices[3].Position[0] =   x4;
	FVertices[3].Position[1] =   y4;
	
	FVertices[0].TexCoord[0] = (x1) / (_imageWidth);
	FVertices[0].TexCoord[1] = (y1) / (_imageHeight);
	FVertices[1].TexCoord[0] = (x2) / (_imageWidth);
	FVertices[1].TexCoord[1] = (y2) / (_imageHeight);
	FVertices[2].TexCoord[0] = (x3) / (_imageWidth);
	FVertices[2].TexCoord[1] = (y3) / (_imageHeight);
	FVertices[3].TexCoord[0] = (x4) / (_imageWidth);
	FVertices[3].TexCoord[1] = (y4) / (_imageHeight);
}

- (void)oneWithPoint:(CGPoint)touchPoint previousPoint:(CGPoint)previousPoint{
	CGFloat midWidth;
	CGFloat midHeight;
	
	midWidth = (_imageWidth - _glViewWidth)/2;
	midHeight = 0;
	
	_touchx = midWidth + touchPoint.x ;
	_touchy = touchPoint.y ;
	
	CGFloat _previousTouchx,_previousTouchy;
	_previousTouchx = midWidth + previousPoint.x ;
	_previousTouchy	=  previousPoint.y;
	
	CGFloat k,b;
	CGFloat x1,x2,y1,y2;
	CGFloat x3,x4,y3,y4;
	if (touchPoint.y == previousPoint.y) {
		x1 = previousPoint.x ;
		y1 = previousPoint.y - _mosaicRadius;
		x2 = previousPoint.x ;
		y2 = previousPoint.y + _mosaicRadius;
		x3 = touchPoint.x ;
		y3 = touchPoint.y -_mosaicRadius;
		x4 = touchPoint.x ;
		y4 = touchPoint.y + _mosaicRadius;
	}else {
	k = -(touchPoint.x-previousPoint.x)/(touchPoint.y-previousPoint.y);
	
	b = touchPoint.y - k * touchPoint.x;
	CGFloat a,c,d;
	a = 1 + k*k;
	c = 2*k*b-2*touchPoint.x-2*k*touchPoint.y;
	d = touchPoint.x*touchPoint.x+touchPoint.y*touchPoint.y-2*b*touchPoint.y+b*b-_mosaicRadius*_mosaicRadius;

	
	x1 = (-c - sqrtf(c*c-4*a*d))/(2*a);
	y1 = k * x1 + b;
	x2 = (-c + sqrtf(c*c-4*a*d))/(2*a);
	y2 = k * x2 + b;
	
	
	b = previousPoint.y - k * previousPoint.x;
	c = 2*k*b-2*previousPoint.x-2*k*previousPoint.y;
	d = previousPoint.x*previousPoint.x+previousPoint.y*previousPoint.y-2*b*previousPoint.y+b*b-_mosaicRadius*_mosaicRadius;
	x3 = (-c - sqrtf(c*c-4*a*d))/(2*a);
	y3 = k * x3 + b;
	x4 = (-c + sqrtf(c*c-4*a*d))/(2*a);
	y4 = k * x4 + b;
	}
	
	

	
	FVertices[0].Position[0] = midWidth +  x1;
	FVertices[0].Position[1] =   y1;
	FVertices[1].Position[0] = midWidth +  x2;
	FVertices[1].Position[1] =   y2;
	FVertices[2].Position[0] = midWidth +  x3;
	FVertices[2].Position[1] =   y3;
	FVertices[3].Position[0] = midWidth +  x4;
	FVertices[3].Position[1] =   y4;
	
	FVertices[0].TexCoord[0] = (midWidth  + x1) / (_imageWidth);
	FVertices[0].TexCoord[1] = (y1) / (_imageHeight);
	FVertices[1].TexCoord[0] = (midWidth  + x2) / (_imageWidth);
	FVertices[1].TexCoord[1] = (y2) / (_imageHeight);
	FVertices[2].TexCoord[0] = (midWidth  + x3) / (_imageWidth);
	FVertices[2].TexCoord[1] = (y3) / (_imageHeight);
	FVertices[3].TexCoord[0] = (midWidth  + x4) / (_imageWidth);
	FVertices[3].TexCoord[1] = (y4) / (_imageHeight);
	

	
	
	

}



- (void)oneWithPoint:(CGPoint)touchPoint {
	CGFloat midWidth;
	CGFloat midHeight;
	
	midWidth = (_imageWidth - _glViewWidth)/2;
	midHeight = 0;
	
	_touchx = midWidth + touchPoint.x;
	_touchy = touchPoint.y;
	
	
		FVertices[0].Position[0] = _touchx - _mosaicRadius ;
		FVertices[0].Position[1] = _touchy - _mosaicRadius ;
		FVertices[1].Position[0] = _touchx + _mosaicRadius ;
		FVertices[1].Position[1] = _touchy - _mosaicRadius ;
		FVertices[2].Position[0] = _touchx - _mosaicRadius ;
		FVertices[2].Position[1] = _touchy + _mosaicRadius ;
		FVertices[3].Position[0] = _touchx + _mosaicRadius ;
		FVertices[3].Position[1] = _touchy + _mosaicRadius ;
	
		FVertices[0].TexCoord[0] = (_touchx - _mosaicRadius) / (_imageWidth);
		FVertices[0].TexCoord[1] = (_touchy - _mosaicRadius) / (_imageHeight);
		FVertices[1].TexCoord[0] = (_touchx + _mosaicRadius) / (_imageWidth);
		FVertices[1].TexCoord[1] = (_touchy - _mosaicRadius) / (_imageHeight);
		FVertices[2].TexCoord[0] = (_touchx - _mosaicRadius) / (_imageWidth);
		FVertices[2].TexCoord[1] = (_touchy + _mosaicRadius) / (_imageHeight);
		FVertices[3].TexCoord[0] = (_touchx + _mosaicRadius) / (_imageWidth);
		FVertices[3].TexCoord[1] = (_touchy + _mosaicRadius) / (_imageHeight);
	
	
	
	
	
}
- (void)twoWithPoint:(CGPoint)touchPoint {
	
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
- (void)threeWithPoint:(CGPoint)touchPoint {
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
