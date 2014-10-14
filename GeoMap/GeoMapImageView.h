//
//  GeoMapImageView.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GeoMapDocument;
@class GeoMapGCP;

@interface GeoMapImageView : NSImageView

@property (strong) GeoMapDocument * document;
@property (strong) NSScrollView * scrollView;
@property (assign) double scale;
@property (assign) BOOL zooming;

- (void) drawGCPAt: (NSPoint) point;
- (void) selectGCP: (GeoMapGCP *) GCP;

@end
