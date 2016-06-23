//
//  GLFbo.h
//  SpringDemo
//
//  Created by ZhangXiaoJun on 14-7-28.
//  Copyright (c) 2014年 mtt0122. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GLFbo : NSObject

@property (nonatomic, assign) CGSize fboSize;
@property (nonatomic, readonly, assign) GLuint frameBuffer;
@property (nonatomic, readonly, assign) GLuint texture;
- (instancetype)initWithSize:(CGSize)size;
- (void)useFBO;
- (UIImage *)snapshot;
@end
