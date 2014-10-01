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
#define kEditGCPTool   5

@class GeoMapScrollView;
@class GeoMapImageView;

@interface GeoMapDocument : NSDocument
    <NSToolbarDelegate,
    NSTableViewDelegate>

@property (strong) NSImage * image;
@property (assign) NSSize imageSize;
@property (strong) IBOutlet GeoMapScrollView * imageScrollView;
@property (strong) IBOutlet GeoMapImageView * imageView;
@property (assign) NSUInteger toolMode;
@property (strong) NSCursor * zoomInCursor;
@property (strong) NSCursor * zoomOutCursor;
@property (strong) NSCursor * addGCPCursor;

// Toolbars.
@property (assign) IBOutlet NSView * imageControlsToolbarItemView;
@property (assign) IBOutlet NSButton * panModeButton;
@property (assign) IBOutlet NSButton * zoomModeButton;
@property (assign) IBOutlet NSView * GCPControlsToolbarItemView;
@property (assign) IBOutlet NSButton * selectGCPModeButton;
@property (assign) IBOutlet NSButton * addGCPModeButton;

// GCPs.
@property (strong) NSMutableArray * GCPs;
@property (strong) IBOutlet NSArrayController * GCPController;
@property (strong) IBOutlet NSTableView * GCPTableView;
@property (assign) NSPoint currentGCPPoint;
@property (strong) NSImage * GCPImage;

@property (readonly) NSString * actionButtonTitle;
@property (readonly) BOOL canPreview;

- (IBAction) setTool: (id) sender;

- (IBAction) previewMap: (id) sender;
- (IBAction) exportMap: (id) sender;

- (void) addGCP: (NSPoint) point;

- (IBAction) commitLatitude: (id) sender;
- (IBAction) commitLongitude: (id) sender;

@end
