//
// Created by Alex Tkachenko on 6/2/15.
// Copyright (c) 2015 Alex Tkachenko. All rights reserved.
//

#import "ATDraggableDynamicView.h"
#import "ATDraggableDynamicAnimator.h"

@interface ATDraggableDynamicView()
@property(nonatomic, weak) ATDraggableDynamicAnimator *draggableAnimator;
@end

@implementation ATDraggableDynamicView

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        //uikit dynamics animator should be set up in the next runloop when superview will be ready
        typeof(self) __weak weakSelf = self;
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^(void) {
            ATDraggableDynamicAnimator *animator = [[ATDraggableDynamicAnimator alloc] initWithView:weakSelf];
            weakSelf.draggableAnimator = animator;
        });
    }
    else {
        self.draggableAnimator = nil;
    }
}


@end