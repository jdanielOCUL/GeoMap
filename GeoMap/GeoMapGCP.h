//
//  GCP.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-29.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

// Associate a given location on an image with a hand-entered location in any
// format and actual corresponding latitude and longitude coordinates.
@interface GeoMapGCP : NSObject

@property (assign) NSPoint normalizedImagePoint;
@property (assign) double latitude;
@property (assign) double longitude;
@property (strong) NSImageView * view;

@end
