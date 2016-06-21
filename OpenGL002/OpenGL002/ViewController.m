//
//  ViewController.m
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	

}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	OpenGLView *view = [[OpenGLView alloc] initWithFrame:screenBounds] ;
	
	_glView = view;
	[self.view addSubview:view];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
