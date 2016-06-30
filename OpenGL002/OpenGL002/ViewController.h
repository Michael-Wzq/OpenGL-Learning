//
//  ViewController.h
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenGLView.h"
@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet OpenGLView *glView;
@property (nonatomic, weak) IBOutlet UISlider *slider;
@end

