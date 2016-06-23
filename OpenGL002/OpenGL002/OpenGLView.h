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
	GLuint _filterProgram;
	CAEAGLLayer* _eaglLayer;
	EAGLContext* _context;
	GLuint _colorRenderBuffer;
	GLuint _floorTexture;
	GLuint _fishTexture;
	GLuint _positionSlot;
	GLuint _colorSlot;
	GLuint _texCoordSlot;
	
	GLuint _positionSlottwo;
	GLuint _colorSlottwo;
	GLuint _texCoordSlottwo;
	GLuint _textureUniformtwo;
	GLuint _textureUniformThree;
	
	
	float _currentRotation;
	GLuint _modelViewUniformone;
	GLuint _texSizeUniform;
	
	GLuint _vertexBuffer;
	GLuint _indexBuffer;
	GLuint _vertexBuffer2;
	GLuint _indexBuffer2;

	
	GLuint _textureUniform;
	GLuint _touchSizeUniform;
	
	GLuint _framebuffer;
	
	GLProgram *_programHandle;
	GLProgram *_programResult;
}


@end
