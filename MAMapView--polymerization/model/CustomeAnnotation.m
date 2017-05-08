//
//  CustomeAnnotation.m
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "CustomeAnnotation.h"

@implementation CustomeAnnotation
#pragma mark - compare
- (NSUInteger)hash{
    NSString *toHash = [NSString stringWithFormat:@"%.5F%.5F%ld", self.coordinate.latitude, self.coordinate.longitude, (long)self.count];
    return [toHash hash];
}

- (BOOL)isEqual:(id)object{
    return [self hash] == [object hash];
}

#pragma mark - Life Cycle
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate count:(NSInteger)count{
    self = [super init];
    if (self){
        _coordinate = coordinate;
        _count = count;
        _images  = [NSMutableArray arrayWithCapacity:count];
    }
    return self;
}

@end
