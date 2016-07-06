//
//  ViewController.m
//  OpenGL002
//
//  Created by zj-db0519 on 16/6/19.
//  Copyright © 2016年 wzq. All rights reserved.
//

#import "ViewController.h"
#import "MTTabCollectionView.h"
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
	
	UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 530, [UIScreen mainScreen].bounds.size.width, 30)];
	slider.minimumValue = 5;
	slider.maximumValue	= 50;
	slider.value =  10;
	_slider = slider;
	[slider addTarget:self action:@selector(controlValueChanged:) forControlEvents:UIControlEventValueChanged];
	slider.continuous = YES;
	[self.view addSubview:slider];
	
	
	
	MTTabCollectionViewLayout *itemsLayout = [[MTTabCollectionViewLayout alloc]initWithHeight:35 width:60 contentWidth:[UIScreen mainScreen].bounds.size.width itemsSpacing:10];
	itemsLayout.zoomFactor = 0.3;
	
	MTTabCollectionView *tabView = [[MTTabCollectionView alloc]
									initWithFrame:CGRectMake(0, 480, [UIScreen mainScreen].bounds.size.width, 50)
								 collectionViewLayout:itemsLayout
								 defaultIndex:0
								 selectedBlock:^(MTTabCollectionView *tabCollectionView, NSIndexPath *selectedIndexPath){
										switch (selectedIndexPath.row) {
											case 0:
												[self lashenPicture];
												break;
											case 1:
												[self pingpuPicture];
												break;
											case 2:
												[self juzhongPicture];
												break;
											default:
												break;
										}
								 }];
	//	view.normalColor = [UIColor blackColor];
	//	view.selectedColor = [UIColor redColor];
	//  view.pointColor = [UIColor grayColor];
	//	view.pointRadius = 3 ;
	NSArray *array = [[NSArray alloc] initWithObjects:@"居中",@"拉伸",@"原图",nil];
	tabView.titlesArray = array;
	[self.view addSubview:tabView];
	
	
	
	
}
- (IBAction)controlValueChanged:(id)sender{
	_glView.mosaicRadius = _slider.value;
}
- (void)lashenPicture {
	_glView = nil;
	OpenGLView *view = [[OpenGLView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 480) type:0] ;
	view.mosaicRadius =  _slider.value;
	_glView = view;
	[self.view addSubview:view];
	
}
- (void)pingpuPicture {
	_glView = nil;
	OpenGLView *view = [[OpenGLView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 480) type:1] ;
	view.mosaicRadius =  _slider.value;
	_glView = view;
	[self.view addSubview:view];
	
}
- (void)juzhongPicture {
	_glView = nil;
	OpenGLView *view = [[OpenGLView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 480) type:2] ;
	view.mosaicRadius =  _slider.value;
	_glView = view;
	[self.view addSubview:view];
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
