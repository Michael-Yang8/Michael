//
//  CustomeAnnotationView.m
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "CustomeAnnotationView.h"


static CGFloat const ScaleFactorAlpha = 0.3;
static CGFloat const ScaleFactorBeta = 0.4;

/* 返回rect的中心. */
CGPoint RectCenter(CGRect rect){
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

/* 返回中心为center，尺寸为rect.size的rect. */
CGRect CenterRect(CGRect rect, CGPoint center){
    CGRect r = CGRectMake(center.x - rect.size.width/2.0,
                          center.y - rect.size.height/2.0,
                          rect.size.width,
                          rect.size.height);
    return r;
}

/* 根据count计算annotation的scale. */
CGFloat ScaledValueForValue(CGFloat value){
    return 1.0 / (1.0 + expf(-1 * ScaleFactorAlpha * powf(value, ScaleFactorBeta)));
}

@implementation CustomeAnnotationView
#pragma mark Initialization
- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self){
        self.backgroundColor = [UIColor clearColor];
        self.iconImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 36, 32)];
        [self addSubview:self.iconImage];
        self.label = [self getSmallCircleWithFrame:CGRectMake( 26, -9, 18, 18) andTitle:self.count];
        [self addSubview:self.label];
        [self setCount:1];
    }
    return self;
}

- (void)setCount:(NSInteger)count{
    _count = count;
    self.label.text = [@(_count) stringValue];
    [self setNeedsDisplay];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    NSArray *subViews = self.subviews;
    if ([subViews count] > 1){
        for (UIView *aSubView in subViews){
            if ([aSubView pointInside:[self convertPoint:point toView:aSubView] withEvent:event] || [aSubView isKindOfClass:[UIImageView class]]){
                return YES;
            }
        }
    }
    if (point.x > 0 && point.x < self.frame.size.width && point.y > 0 && point.y < self.frame.size.height){
        return YES;
    }
    return NO;
}

#pragma mark - annimation
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    [self addBounceAnnimation];
}

- (void)addBounceAnnimation{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    bounceAnimation.duration = 0.6;
    
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++)
    {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    
    bounceAnimation.removedOnCompletion = NO;
    
    [self.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

//小圆
- (UILabel *)getSmallCircleWithFrame:(CGRect)frame andTitle:(NSInteger )title{
    UILabel *label = [[UILabel alloc]init];
    label.frame = frame;
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = frame.size.width / 2;
    label.layer.borderWidth = 1.5;
    label.layer.borderColor = [UIColor whiteColor].CGColor;
    label.backgroundColor = [UIColor redColor];
    NSString *titleStr = [NSString stringWithFormat:@"%ld",(long)title];
    label.text = titleStr;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:11];
    label.textColor = [UIColor whiteColor];
    return label;
}





@end
