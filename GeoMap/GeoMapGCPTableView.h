//
//  GeoMapGCPTableView.h
//  GeoMap
//
//  Created by John Daniel on 2014-10-20.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GeoMapDocument;

@interface GeoMapGCPTableView : NSTableView

@property (strong) IBOutlet GeoMapDocument * document;

@end
