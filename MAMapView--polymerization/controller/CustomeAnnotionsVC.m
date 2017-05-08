//
//  CustomeAnnotionsVC.m
//  MAMapView--polymerization
//
//  Created by Michael on 2017/5/2.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "CustomeAnnotionsVC.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

#import "CoordinateQuadTree.h"
#import "CustomeAnnotation.h"
#import "CustomeAnnotationView.h"
#import "CommonUtility.h"


/* 使用高德SearchV3, 请首先注册APIKey, 注册APIKey请参考 http://api.amap.com
 */
#define APIKey @"d46fc2d606ce3a61434453e960948b5d";

#define kCalloutViewMargin  -12
#define Button_Height       70.0
#define SCREEN_WIDTH                    ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT                   ([UIScreen mainScreen].bounds.size.height)



@interface CustomeAnnotionsVC ()<MAMapViewDelegate,AMapLocationManagerDelegate>
/**
 *  高德地图
 */
@property(nonatomic,strong)MAMapView *mapView;
@property(nonatomic,strong)CoordinateQuadTree* coordinateQuadTree;
@property(nonatomic,strong)AMapLocationManager *locationManager;
@property (nonatomic,strong)UIView *bottomView;
/**
 *  卫星
 */
@property (nonatomic,strong)UIButton *satelliteBtn;
/**
 *  定位
 */
@property (nonatomic,strong)UIButton *locationBtn;
/**
 *  是否需要重新计算
 */
@property (nonatomic, assign) BOOL shouldRegionChangeReCalculate;
/**
 *  是否采用卫星地图
 */
@property(nonatomic)BOOL isSaatelliteMap;
/**
 *  是否定位
 */
@property(nonatomic)BOOL isLocation;
@property(nonatomic,strong)NSMutableArray *images;

@end

@implementation CustomeAnnotionsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [AMapServices sharedServices].apiKey = APIKey;
    self.coordinateQuadTree = [[CoordinateQuadTree alloc] init];
    [self hl_setWorkSectionUI];
    [self configLocationManager];
    self.mapView.mapType = MAMapTypeStandard;
    self.mapView.delegate = self;
    [self hl_addAnnotations];
    
    
}

- (void)hl_setWorkSectionUI{
    self.mapView = [[MAMapView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    UIView *sateliteView = [self getCustonmeViewWithFrame:CGRectMake(SCREEN_WIDTH - 50, 55, 40, 40) andBackgroundColor:[UIColor whiteColor]];
    self.satelliteBtn = [self getCustomeButtonWithFrame:CGRectMake(5, 5, 30, 30) andNormalImage:@"wx.png" andHighlightedImage:@"wx_select.png" andSelectedImage:@"wx_select.png" andAction:@selector(satelliteBtn:)];
    [sateliteView addSubview:self.satelliteBtn];
    [self.mapView addSubview:sateliteView];
    
    UIView *locationView = [self getCustonmeViewWithFrame:CGRectMake(SCREEN_WIDTH - 50, 100, 40, 40) andBackgroundColor:[UIColor whiteColor]];
    self.locationBtn = [self getCustomeButtonWithFrame:CGRectMake(5, 5, 30, 30) andNormalImage:@"dw.png" andHighlightedImage:@"dw_select.png" andSelectedImage:@"dw_select.png" andAction:@selector(locationBtn:)];
    [locationView addSubview:self.locationBtn];
    [self.mapView addSubview:locationView];
    self.satelliteBtn.layer.masksToBounds = YES;
    self.satelliteBtn.layer.cornerRadius = 1;
    self.locationBtn.layer.masksToBounds = YES;
    self.locationBtn.layer.cornerRadius = 1;
    
    
}

- (void)satelliteBtn:(UIButton *)sender {
    if (!self.isSaatelliteMap) {
        self.isSaatelliteMap = YES;
        self.mapView.mapType = MAMapTypeSatellite;
    }else{
        self.isSaatelliteMap = NO;
        self.mapView.mapType = MAMapTypeStandard;
    }
    [self.view reloadInputViews];
}

- (void)locationBtn:(UIButton *)sender {
    if (!self.isLocation) {
        self.locationBtn.selected = YES;
        self.isLocation = YES;
        self.mapView.showsUserLocation = YES;
        self.mapView.userTrackingMode = MAUserTrackingModeFollow;
        [self startSerialLocation];
    }else{
        self.locationBtn.selected = NO;
        self.isLocation = NO;
        self.mapView.showsUserLocation = NO;
        [self stopSerialLocation];
    }
    
}

#pragma mark -- annotation
/* 根据点击 显示相应类别的大头针 */
- (void)hl_addAnnotations{
    NSMutableArray *annotations = [NSMutableArray array];
    NSString *txtPath=[[NSBundle mainBundle]pathForResource:@"mapData" ofType:@"txt"];
    NSData *data = [NSData dataWithContentsOfFile:txtPath];
    NSString *resultStr  =[[ NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray * array = [resultStr componentsSeparatedByString:@"|"];
    self.images = [NSMutableArray array];
    for (NSInteger i = 0; i < 10; i++) {
        NSString *str = array[i];
        NSArray *temp = [str componentsSeparatedByString:@","];
        NSString *lon = temp[0];
        NSString *lat = temp[1];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);
        CustomeAnnotation *annotation = [[CustomeAnnotation alloc]init];
        annotation.coordinate = coordinate;
        NSString *imageName = @"01.png";
        [self.images addObject:imageName];
        [annotations addObject:annotation];
    }
    
    @synchronized(self)
    {
        self.shouldRegionChangeReCalculate = NO;
        // 清理
        [self.mapView removeAnnotations:self.mapView.annotations];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /* 建立四叉树. */
            [weakSelf.coordinateQuadTree buildTreeWithAnnotations:annotations];
            self.shouldRegionChangeReCalculate = YES;
            [weakSelf addAnnotationsToMapView:weakSelf.mapView];
        });
    }
    MAMapRect rec = [CommonUtility minMapRectForAnnotations:annotations];
    [self.mapView setVisibleMapRect:rec edgePadding:UIEdgeInsetsMake(40, 40, 40, 40) animated:YES];
    
}

/* 更新annotation. */
- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations{
    /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    /* 保留仍然位于屏幕内的annotation. */
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    /* 需要添加的annotation. */
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    /* 删除位于屏幕外的annotation. */
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    /* 更新. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    });
}

- (void)removeAnnotationsWithArray:(NSArray *)array{
    [self.mapView removeAnnotations:array];
}

- (void)addAnnotationsToMapView:(MAMapView *)mapView{
    @synchronized(self){
        if (self.coordinateQuadTree.root == nil || !self.shouldRegionChangeReCalculate){
            return;
        }
        
        /* 根据当前zoomLevel和zoomScale 进行annotation聚合. */
        MAMapRect visibleRect = self.mapView.visibleMapRect;
        double zoomScale = self.mapView.bounds.size.width / visibleRect.size.width;
        double zoomLevel = self.mapView.zoomLevel;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray *annotations = [weakSelf.coordinateQuadTree clusteredAnnotationsWithinMapRect:visibleRect withZoomScale:zoomScale andZoomLevel:zoomLevel andImages:self.images];
            /* 更新annotation. */
            [weakSelf updateMapViewAnnotationsWithAnnotations:annotations];
        });
    }
}

#pragma mark ------ mapViewDelegate
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    [self addAnnotationsToMapView:self.mapView];
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{
    if ([annotation isKindOfClass:[CustomeAnnotation class]]){
        /* dequeue重用annotationView. */
        static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";
        CustomeAnnotationView *annotationView = (CustomeAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];
        if (!annotationView){
            annotationView = [[CustomeAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:AnnotatioViewReuseID];
        }
        /* 设置annotationView的属性. */
        annotationView.annotation = annotation;
        annotationView.count = [(CustomeAnnotation *)annotation count];
        annotationView.canShowCallout = NO;
        CustomeAnnotation *customeAnnotation = (CustomeAnnotation *)annotation;
        annotationView.iconImage.image = [UIImage imageNamed:customeAnnotation.images[0]];
        return annotationView;
    }
    
    return nil;
}

- (void)dealloc{
    [self.coordinateQuadTree clean];
}

#pragma mark -- 定位
- (void)configLocationManager{
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
}

- (void)startSerialLocation{
    //开始定位
    [self.locationManager startUpdatingLocation];
}

- (void)stopSerialLocation{
    //停止定位
    [self.locationManager stopUpdatingLocation];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error{
    //定位错误
    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    //定位结果
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
}

//根据传入的annotation展示相应的地图区域
- (void)showsAnnotations:(NSArray *)annotations edgePadding:(UIEdgeInsets)insets andMapView:(MAMapView *)mapView {
    MAMapRect rect = MAMapRectZero;
    for (MAPointAnnotation *annotation in annotations) {
        ///annotation相对于中心点的对角线坐标
        CLLocationCoordinate2D diagonalPoint = CLLocationCoordinate2DMake(mapView.centerCoordinate.latitude - (annotation.coordinate.latitude - mapView.centerCoordinate.latitude),mapView.centerCoordinate.longitude - (annotation.coordinate.longitude - mapView.centerCoordinate.longitude));
        
        MAMapPoint annotationMapPoint = MAMapPointForCoordinate(annotation.coordinate);
        MAMapPoint diagonalPointMapPoint = MAMapPointForCoordinate(diagonalPoint);
        
        ///根据annotation点和对角线点计算出对应的rect（相对于中心点）
        MAMapRect annotationRect = MAMapRectMake(MIN(annotationMapPoint.x, diagonalPointMapPoint.x), MIN(annotationMapPoint.y, diagonalPointMapPoint.y), ABS(annotationMapPoint.x - diagonalPointMapPoint.x), ABS(annotationMapPoint.y - diagonalPointMapPoint.y));
        
        rect = MAMapRectUnion(rect, annotationRect);
    }
    
    [mapView setVisibleMapRect:rect edgePadding:insets animated:YES];
}

#pragma mark -- customedMethod
- (UIButton *)getCustomeButtonWithFrame:(CGRect)frame andNormalImage:(NSString *__nullable)normalImageName andHighlightedImage:(NSString *__nullable)highlightedImageName andSelectedImage:(NSString *__nullable)selectedImageName andAction:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    [button setImage:[UIImage imageNamed:normalImageName] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:highlightedImageName] forState:UIControlStateHighlighted];
    [button setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)getCustonmeViewWithFrame:(CGRect)frame andBackgroundColor:(UIColor *)color{
    UIView *lineView = [[UIView alloc]initWithFrame:frame];
    lineView.backgroundColor = color;
    return lineView;
}






@end
