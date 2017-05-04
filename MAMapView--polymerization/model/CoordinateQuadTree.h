//
//  CoordinateQuadTree.h
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import "QuadTree.h"


@interface CoordinateQuadTree : NSObject
@property(nonatomic,assign)QuadTreeNode *root;
- (void)buildTreeWithAnnotations:(NSArray *)annotations;
- (void)clean;
- (NSArray *)clusteredAnnotationsWithinMapRect:(MAMapRect)rect withZoomScale:(double)zoomScale andZoomLevel:(double)zoomLevel;


@end
