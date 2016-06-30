//
//  OpenGLView.h
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLFbo.h"
#import "GLProgram.h"

@interface OpenGLView : UIView {

	CAEAGLLayer* _eaglLayer;
	EAGLContext* _context;
	
	GLProgram *_programHandle;
	GLProgram *_programResult;
	
	GLuint _colorRenderBuffer;
	GLuint _floorTexture;

	GLuint _indexBuffer;
	GLuint _framebuffer;
	GLuint _vertexBuffer;
	GLuint _positionSlot;
	GLuint _colorSlot;
	GLuint _texCoordSlot;
	GLuint _modelViewUniformone; //正交矩阵
	GLuint _texSizeUniform;
	GLuint _textureUniform;
	
	
	GLuint _vertexBuffer2;
	GLuint _positionSlottwo;
	GLuint _colorSlottwo;
	GLuint _texCoordSlottwo;
	GLuint _textureUniformtwo;
	GLuint _textureUniformThree;
	GLuint _touchSizeUniform;
	
	float _currentRotation;
	
	CGPoint _touchPoint;
	CGPoint _movePoint;
	
	GLuint _touchPointUniform;
	

}
- (id)initWithFrame:(CGRect)frame type:(NSInteger)type;
@property (nonatomic, assign) NSInteger picType;
@property (nonatomic, assign) CGFloat mosaicRadius;


@end
