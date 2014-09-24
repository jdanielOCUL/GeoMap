//
//  GeoMapImageView.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GeoMapDocument;

@interface GeoMapImageView : NSImageView

@property (strong) GeoMapDocument * document;

@end
