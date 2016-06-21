//
//  OpenGLView.h
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface OpenGLView : UIView {
	CAEAGLLayer* _eaglLayer;
	EAGLContext* _context;
	GLuint _colorRenderBuffer;
	
	GLuint _positionSlot;
	GLuint _colorSlot;
	
	float _currentRotation;
	GLuint _modelViewUniform;
	GLuint _texSizeUniform;
	GLuint _floorTexture;
	GLuint _fishTexture;
	GLuint _texCoordSlot;
	GLuint _textureUniform;
	GLuint _touchSizeUniform;
}


@end
