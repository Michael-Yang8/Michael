//
//  CustomeAnnotation.h
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapCommonObj.h>


@interface CustomeAnnotation : NSObject<MAAnnotation>
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign, nonatomic) NSInteger count;
@property (nonatomic, strong) NSMutableArray *images;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate count:(NSInteger)count;


@end
