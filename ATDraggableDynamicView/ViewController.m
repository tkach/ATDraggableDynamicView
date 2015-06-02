//
//  ViewController.m
//  ATDraggableDynamicView
//
//  Created by Alex Tkachenko on 6/2/15.
//  Copyright (c) 2015 Alex Tkachenko. All rights reserved.
//

#import "ViewController.h"
#import "ATDraggableDynamicView.h"

@implementation ViewController

#pragma mark - View Controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button callbacks

- (IBAction)presentView:(id)sender {
    ATDraggableDynamicView *view = [[ATDraggableDynamicView alloc] initWithFrame:CGRectMake(0, 0, 300, 120)];
    view.backgroundColor = [UIColor greenColor];
    view.center = self.view.center;
    [self.view addSubview:view];
}

@end
