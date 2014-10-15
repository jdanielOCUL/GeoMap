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

// Wrap an image view into something a bit smarter. But don't fall for the
// IKImageView trap again.
@interface GeoMapImageView : NSImageView

// The document handles most of the conceptual-level details.
@property (strong) GeoMapDocument * document;

// I have to manually hack around on the enclosing scroll view quite a bit.
@property (strong) NSScrollView * scrollView;

// Keep track of the current image scale factor.
@property (assign) double scale;

// A special zooming mode to prevent display artifacts.
@property (assign) BOOL zooming;

// Draw a GCP location.
- (void) drawGCPAt: (NSPoint) point;

// Select a GCP by zooming to it.
- (void) selectGCP: (GeoMapGCP *) GCP;

@end
