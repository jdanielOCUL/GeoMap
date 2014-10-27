//
//  GeoMapDocument.h
//  GeoMap
//
//  Created by John Daniel on 2014-09-17.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// Tool modes.
#define kPanTool     0
#define kZoomInTool  1
#define kZoomOutTool 2

#define kSelectGCPTool 3
#define kAddGCPTool    4
#define kEditGCPTool   5

@class GeoMapScrollView;
@class GeoMapImageView;
@class GeoMapGCP;
@class GeoMapMetadataViewController;

// A document type for georeferencing an image.
@interface GeoMapDocument : NSDocument
    <NSToolbarDelegate,
    NSTableViewDelegate,
    NSPopoverDelegate>

// The input file.
@property (strong) NSString * input;

// The image itself.
@property (strong) NSImage * image;

// The image size.
@property (assign) NSSize imageSize;

// Some views for displaying an image nicely.
@property (strong) IBOutlet GeoMapScrollView * imageScrollView;
@property (strong) IBOutlet GeoMapImageView * imageView;

// The current tool mode.
@property (assign) NSUInteger toolMode;

// Cursors to refect the tool mode.
@property (strong) NSCursor * zoomInCursor;
@property (strong) NSCursor * zoomOutCursor;
@property (strong) NSCursor * addGCPCursor;

// Only do setup once per document.
@property (assign) BOOL isSetup;

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
@property (strong) NSImage * GCPImage;
@property (strong) NSImage * GCPToolbarImage;
@property (strong) GeoMapGCP * currentGCP;
@property (assign) BOOL saveable;

// Metadata.
@property (strong) NSMutableArray * metadata;
@property (strong) IBOutlet NSArrayController * metadataController;
@property (strong) IBOutlet NSTableView * metadataTableView;
@property (readonly) NSPopover * metadataPopover;
@property (strong) IBOutlet
    GeoMapMetadataViewController * metadataViewController;

// Preview/Export.
@property (strong) IBOutlet WebView * mapView;
@property (assign) BOOL canPreview;
@property (strong) IBOutlet NSButton * previewButton;
@property (strong) IBOutlet NSButton * exportButton;
@property (strong) IBOutlet NSButton * cancelExportButton;
@property (strong) IBOutlet NSTextField * opacityLabel;
@property (strong) IBOutlet NSSlider * opacitySlider;
@property (strong) NSString * previewPath;
@property (strong) NSArray * coordinates;
@property (assign) double opacity;
@property (assign) BOOL previewing;
@property (strong) dispatch_semaphore_t previewReady;
@property (strong) NSNumber * progress;
@property (strong) IBOutlet NSPanel * progressPanel;
@property (strong) IBOutlet NSProgressIndicator * progressIndicator;
@property (strong) NSString * progressLabel;
@property (strong) NSTimer * progressTimer;
@property (assign) double previewScale;
@property (assign) NSUInteger formatIndex;
@property (strong) NSString * format;
@property (assign) NSUInteger datumIndex;
@property (strong) NSString * datum;
@property (assign) BOOL srsEnabled;
@property (strong) NSString * srs;
@property (strong) NSSavePanel * savePanel;
@property (strong) IBOutlet NSView * saveOptionslPanel;

- (IBAction) setTool: (id) sender;

- (IBAction) previewMap: (id) sender;
- (IBAction) exportMap: (id) sender;
- (IBAction) cancelExportMap: (id) sender;

- (void) addGCP: (NSPoint) point;
- (IBAction) removeGCP: (id) sender;
- (void) selectGCPAt: (NSPoint) point;

- (IBAction) commitLatitude: (id) sender;
- (IBAction) commitLongitude: (id) sender;

- (IBAction) addMetadata: (id) sender;
- (IBAction) removeMetadata: (id) sender;

// Show the metadata popover.
- (void) showMetadataPopover;

@end
