//
// Created by Alex Tkachenko on 6/2/15.
// Copyright (c) 2015 Alex Tkachenko. All rights reserved.
//

#import "ATDraggableDynamicAnimator.h"

static const int kATATDraggableDynamicViewScalarVelocityToSnap = 300;

@interface ATDraggableDynamicAnimator()

@property(nonatomic, weak) UIView *view;
@property(nonatomic, weak) UIGestureRecognizer *panGesture;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIDynamicItemBehavior *dynamicItemBehavior;
@property (nonatomic, weak) UIAttachmentBehavior *attachment;
@property (nonatomic, weak) UISnapBehavior *snapBehavior;

@property (nonatomic) CGPoint startTouchCenter;

@end


@implementation ATDraggableDynamicAnimator

#pragma mark - Init

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        self.view = view;
        [self setupAnimators];
    }
    return self;
}


#pragma mark - Setup

- (void)setupAnimators {
    UIDynamicItemBehavior *behavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.view]];
    behavior.angularResistance = 1.25f;
    typeof(self) __weak weakSelf = self;
    behavior.action = ^{
        if (!CGRectIntersectsRect(weakSelf.view.superview.bounds, weakSelf.view.frame)) {
            //view is outside it's superview bounds
            [self cleanupUIKitDynamics];
        }
    };
    self.dynamicItemBehavior = behavior;

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    self.panGesture = panGestureRecognizer;

    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view.superview];
    [animator addBehavior:behavior];
    self.animator = animator;
}


#pragma mark - Pan gesture

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // variables for calculating angular velocity
    static CFAbsoluteTime        lastTime;
    static CGFloat               lastAngle;
    static CGFloat               angularVelocity;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.snapBehavior) {
            [self.animator removeBehavior:self.snapBehavior];
        }
        self.startTouchCenter = gesture.view.center;

        // calculate the center offset and anchor point
        CGPoint pointWithinAnimatedView = [gesture locationInView:gesture.view];

        UIOffset offset = UIOffsetMake((CGFloat) (pointWithinAnimatedView.x - gesture.view.bounds.size.width / 2.0),
                (CGFloat) (pointWithinAnimatedView.y - gesture.view.bounds.size.height / 2.0));

        CGPoint anchor = [gesture locationInView:gesture.view.superview];

        UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:gesture.view
                                                                     offsetFromCenter:offset
                                                                     attachedToAnchor:anchor];
        self.attachment = attachment;

        // code to calculate angular velocity (seems curious that I have to calculate this myself, but I can if I have to)

        lastTime = CFAbsoluteTimeGetCurrent();
        lastAngle = [self angleOfView:gesture.view];

        typeof(self) __weak weakSelf = self;

        self.attachment.action = ^{
            CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
            CGFloat angle = [weakSelf angleOfView:gesture.view];
            if (time > lastTime) {
                angularVelocity = (CGFloat) ((angle - lastAngle) / (time - lastTime));
                lastTime = time;
                lastAngle = angle;
            }
        };

        [self.animator addBehavior:attachment];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // as user makes gesture, update attachment behavior's anchor point, achieving drag 'n' rotate

        CGPoint anchor = [gesture locationInView:gesture.view.superview];
        self.attachment.anchorPoint = anchor;
    } else if (gesture.state == UIGestureRecognizerStateEnded || (gesture.state == UIGestureRecognizerStateCancelled)) {
        [self.animator removeBehavior:self.attachment];

        CGPoint velocity = [gesture velocityInView:gesture.view.superview];

        float scalarVelocity = sqrtf((velocity.x * velocity.x) +
                (velocity.y * velocity.y));
        // If scalarVelocity is not enough we just snap it back
        if (scalarVelocity < kATATDraggableDynamicViewScalarVelocityToSnap) {
            UISnapBehavior *behavior = [[UISnapBehavior alloc] initWithItem:gesture.view snapToPoint:self.startTouchCenter];
            [self.animator addBehavior:behavior];
            self.snapBehavior = behavior;
            return;
        }

        [self.dynamicItemBehavior addLinearVelocity:velocity forItem:gesture.view];
        [self.dynamicItemBehavior addAngularVelocity:angularVelocity forItem:gesture.view];
    }
}


- (void)moveOutsideWithTheVelocity:(CGPoint)velocity {
    [self.dynamicItemBehavior addLinearVelocity:velocity forItem:self.view];
}


- (CGFloat)angleOfView:(UIView *)view {
    return (CGFloat) atan2(view.transform.b, view.transform.a);
}


#pragma mark - Cleanup

- (void)cleanupUIKitDynamics {
    [self.animator removeAllBehaviors];
    [self.view removeGestureRecognizer:self.panGesture];
    [self.view removeFromSuperview];
    self.animator = nil;
}

@end