//
//  CoordinateQuadTree.m
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "CoordinateQuadTree.h"
#import "CoordinateQuadTree.h"
#import "CustomeAnnotation.h"

QuadTreeNodeData QuadTreeNodeDataForAnnotation(CustomeAnnotation* annotation){
    return QuadTreeNodeDataMake(annotation.coordinate.latitude, annotation.coordinate.longitude, (__bridge_retained void *)(annotation));
}

BoundingBox BoundingBoxForMapRect(MAMapRect mapRect){
    CLLocationCoordinate2D topLeft = MACoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MACoordinateForMapPoint(MAMapPointMake(MAMapRectGetMaxX(mapRect), MAMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    return BoundingBoxMake(minLat, minLon, maxLat, maxLon);
}

float CellSizeForZoomLevel(double zoomLevel){
    /*zoomLevel越大，cellSize越小. */
    if (zoomLevel < 13.0){
        return 64;
    }
    else if (zoomLevel <15.0){
        return 32;
    }
    else if (zoomLevel <18.0){
        return 16;
    }
    else if (zoomLevel < 20.0){
        return 8;
    }
    return 64;
}

BoundingBox quadTreeNodeDataArrayForAnnotations(QuadTreeNodeData *dataArray, NSArray * annotations){
    CLLocationDegrees minX = ((CustomeAnnotation *)annotations[0]).coordinate.latitude;
    CLLocationDegrees maxX = ((CustomeAnnotation *)annotations[0]).coordinate.latitude;
    
    CLLocationDegrees minY = ((CustomeAnnotation *)annotations[0]).coordinate.longitude;
    CLLocationDegrees maxY = ((CustomeAnnotation *)annotations[0]).coordinate.longitude;
    
    for (NSInteger i = 0; i < [annotations count]; i++){
        dataArray[i] = QuadTreeNodeDataForAnnotation(annotations[i]);
        
        if (dataArray[i].x < minX){
            minX = dataArray[i].x;
        }
        
        if (dataArray[i].x > maxX){
            maxX = dataArray[i].x;
        }
        
        if (dataArray[i].y < minY){
            minY = dataArray[i].y;
        }
        
        if (dataArray[i].y > maxY){
            maxY = dataArray[i].y;
        }
    }
    
    return BoundingBoxMake(minX, minY, maxX, maxY);
}

#pragma mark -
@implementation CoordinateQuadTree
#pragma mark Utility
- (NSArray *)clusteredAnnotationsWithinMapRect:(MAMapRect)rect withZoomScale:(double)zoomScale andZoomLevel:(double)zoomLevel andImages:(NSMutableArray *)images{
    double CellSize = CellSizeForZoomLevel(zoomLevel);
    double scaleFactor = zoomScale / CellSize;
    
    NSInteger minX = floor(MAMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MAMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MAMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MAMapRectGetMaxY(rect) * scaleFactor);
    
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSInteger x = minX; x <= maxX; x++)
    {
        for (NSInteger y = minY; y <= maxY; y++)
        {
            MAMapRect mapRect = MAMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int     count = 0;
            
            NSMutableArray *annotations = [[NSMutableArray alloc] init];
            /* 查询区域内数据的个数. */
            QuadTreeGatherDataInRange(self.root, BoundingBoxForMapRect(mapRect), ^(QuadTreeNodeData data){
                totalX += data.x;
                totalY += data.y;
                count++;
                [annotations addObject:(__bridge CustomeAnnotation *)data.data];
            });
            
            /* 若区域内仅有一个数据. */
            if (count == 1){
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX, totalY);
                CustomeAnnotation *annotation = [[CustomeAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.images = images;
                
                [clusteredAnnotations addObject:annotation];
            }
            
            /* 若区域内有多个数据 按数据的中心位置画点. */
            if (count > 1){
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                CustomeAnnotation *annotation = [[CustomeAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.images  = images;

                [clusteredAnnotations addObject:annotation];
            }
        }
    }
    
    return [NSArray arrayWithArray:clusteredAnnotations];
}



#pragma mark Initilization
- (void)buildTreeWithAnnotations:(NSArray *)annotations{
    QuadTreeNodeData *dataArray = malloc(sizeof(QuadTreeNodeData) * [annotations count]);
    
    BoundingBox maxBounding = quadTreeNodeDataArrayForAnnotations(dataArray, annotations);
    
    /*若已有四叉树，清空.*/
    [self clean];
    
    NSLog(@"build tree.");
    /*建立四叉树索引. */
    self.root = QuadTreeBuildWithData(dataArray, [annotations count], maxBounding, 4);
    
    free(dataArray);
}

#pragma mark Life Cycle
- (void)clean{
    if (self.root){
        NSLog(@"free tree.");
        FreeQuadTreeNode(self.root);
    }
}

@end




