//
//  CustomeAnnotationView.h
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface CustomeAnnotationView : MAAnnotationView
@property (nonatomic,strong) UILabel *label;
@property(nonatomic)NSInteger count;
@property(nonatomic,strong)UIImageView *iconImage;


@end
