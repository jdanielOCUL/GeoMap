//
//  GeoMapMetadataTableView.h
//  GeoMap
//
//  Created by John Daniel on 2014-10-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GeoMapDocument;

@interface GeoMapMetadataTableView : NSTableView

@property (strong) IBOutlet GeoMapDocument * document;

@end
