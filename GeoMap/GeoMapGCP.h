//
//  GCP.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-29.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeoMapGCP : NSObject

@property (assign) double x;
@property (assign) double y;
@property (assign) double lat;
@property (assign) double lon;
@property (strong) NSString * latitude;
@property (strong) NSString * longitude;

@end
