//
//  GeoMapDocument.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-17.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Tool modes.
#define kPanTool     0
#define kZoomInTool  1
#define kZoomOutTool 2

#define kSelectGCPTool 3
#define kAddGCPTool    4

@class GeoMapScrollView;
@class GeoMapImageView;

@interface GeoMapDocument : NSDocument <NSToolbarDelegate>

@property (strong) NSImage * image;
@property (assign) NSSize imageSize;
@property (strong) IBOutlet GeoMapScrollView * imageScrollView;
@property (strong) IBOutlet GeoMapImageView * imageView;
@property (assign) NSUInteger toolMode;
@property (strong) NSCursor * zoomInCursor;
@property (strong) NSCursor * zoomOutCursor;

// Toolbars.
@property (assign) IBOutlet NSView * imageControlsToolbarItemView;
@property (assign) IBOutlet NSSegmentedControl * imageControls;
@property (assign) IBOutlet NSView * GCPControlsToolbarItemView;
@property (assign) IBOutlet NSSegmentedControl * GCPControls;

@property (strong) NSMutableArray * GCPs;
@property (strong) IBOutlet NSArrayController * GCPController;

@property (readonly) BOOL canPreview;
@property (readonly) BOOL canExport;

- (IBAction) previewMap: (id) sender;
- (IBAction) exportMap: (id) sender;

@end
