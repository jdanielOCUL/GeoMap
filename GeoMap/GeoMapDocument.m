//
//  GeoMapDocument.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-17.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapDocument.h"
#import "GeoMapToolbarItem.h"
#import "GeoMapScrollView.h"
#import "GeoMapImageView.h"
#import "GeoMapGCPTableCellView.h"
#import "GeoMapGCP.h"
//#import "GeoMapReproject.h"

// Toolbar items.
#define kImageControlsToolbarItemID @"imagecontrolstoolbaritem"
#define kGCPControlsToolbarItemID @"gcpcontrolstoolbaritem"

@implementation GeoMapDocument

@synthesize toolMode = myToolMode;

@synthesize GCPs = myGCPs;

@dynamic actionButtonTitle;
@synthesize canPreview = myCanPreview;

- (NSUInteger) toolMode
{
    return myToolMode;
}

- (void) setToolMode: (NSUInteger) toolMode
{
    if(toolMode != myToolMode)
    {
        [self willChangeValueForKey: @"toolMode"];

        myToolMode = toolMode;

        [self didChangeValueForKey: @"toolMode"];
    
        switch (myToolMode)
        {
            case kPanTool:
                self.panModeButton.state = NSOnState;
                self.zoomModeButton.state = NSOffState;
                self.selectGCPModeButton.state = NSOffState;
                self.addGCPModeButton.state = NSOffState;
          
                [self.imageScrollView
                    setDocumentCursor: [NSCursor openHandCursor]];
                break;

            case kZoomInTool:
                self.panModeButton.state = NSOffState;
                self.zoomModeButton.state = NSOnState;
                self.selectGCPModeButton.state = NSOffState;
                self.addGCPModeButton.state = NSOffState;
          
                [self.imageScrollView setDocumentCursor: self.zoomInCursor];
                break;

            case kZoomOutTool:
                [self.imageScrollView setDocumentCursor: self.zoomOutCursor];
                break;
          
            case kSelectGCPTool:
                self.panModeButton.state = NSOffState;
                self.zoomModeButton.state = NSOffState;
                self.selectGCPModeButton.state = NSOnState;
                self.addGCPModeButton.state = NSOffState;
          
                [self.imageScrollView
                    setDocumentCursor: [NSCursor arrowCursor]];
                break;

            case kAddGCPTool:
                self.panModeButton.state = NSOffState;
                self.zoomModeButton.state = NSOffState;
                self.selectGCPModeButton.state = NSOffState;
                self.addGCPModeButton.state = NSOnState;
          
                [self.imageScrollView setDocumentCursor: self.addGCPCursor];
                break;

            case kEditGCPTool:
                self.panModeButton.state = NSOffState;
                self.zoomModeButton.state = NSOffState;
                self.selectGCPModeButton.state = NSOffState;
                self.addGCPModeButton.state = NSOffState;
          
                [self.imageScrollView
                    setDocumentCursor: [NSCursor arrowCursor]];
                break;
        }
    }
}

- (NSString *) actionButtonTitle
{
    return NSLocalizedString(@"Preview", NULL);
}

- (id) init
{
    self = [super init];
  
    if (self)
    {
        // Set the inital value here so it gets reset in awakeFromNib and
        // actually sets the initial cursor.
        myToolMode = kZoomInTool;
        myGCPs = [NSMutableArray new];
    }
  
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document
    // supports multiple NSWindowControllers, you should remove this method and
    // override -makeWindowControllers instead.
    return @"GeoMapDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has
    // loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (BOOL) writeToURL: (NSURL *) url
    ofType: (NSString *) typeName error: (NSError * __autoreleasing *) outError
{
    /* GCP * gcps = (GCP *)malloc(self.GCPs.count * sizeof(GCP));
  
    int i = 0;
  
    for(GeoMapGCP * GCP in self.GCPs)
    {
        GCP.lon = [GCP.longitude doubleValue];
        GCP.lat = [GCP.latitude doubleValue];
        
        gcps[i].pixel = GCP.imagePoint.x;
        gcps[i].line = GCP.imagePoint.y;
        gcps[i].x = GCP.lon;
        gcps[i].y = GCP.lat;
    
        ++i;
    }
  
    BOOL result =
        reproject(
            [self.input fileSystemRepresentation],
            [url fileSystemRepresentation],
            (int)self.GCPs.count,
            gcps);
  
    free(gcps);
  
    return result; */
  
    NSMutableArray * args = [NSMutableArray array];
  
    [args addObject: self.input];
  
    for(GeoMapGCP * GCP in self.GCPs)
    {
        GCP.lon = [GCP.longitude doubleValue];
        GCP.lat = [GCP.latitude doubleValue];
    
        [args addObject: @"-gcp"];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.imagePoint.x]];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.imagePoint.y]];
        [args addObject: GCP.longitude];
        [args addObject: GCP.latitude];
    }

    NSString * tempName =
      [[[[self.input lastPathComponent]
          stringByDeletingPathExtension]
              stringByAppendingString: @"_gcp"]
                  stringByAppendingPathExtension:@"tif"];
  
    NSString * tempPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent: tempName];
  
    [args addObject: tempPath];
  
    NSString * frameworksPath = [[NSBundle mainBundle] privateFrameworksPath];
    NSString * GDALPath =
        [frameworksPath
            stringByAppendingPathComponent:
                @"GDAL.framework/Versions/1.11/Programs"];
  
    NSTask * translate = [NSTask new];
  
    translate.launchPath =
        [GDALPath stringByAppendingPathComponent: @"gdal_translate"];
    translate.arguments = args;
  
    [translate launch];
    [translate waitUntilExit];
  
    NSTask * warp = [NSTask new];
  
    warp.launchPath = [GDALPath stringByAppendingPathComponent: @"gdalwarp"];
    warp.arguments =
        @[
        tempPath,
        [url path]
        ];
  
    [warp launch];
    [warp waitUntilExit];

    return YES;
}

- (BOOL) readFromURL: (NSURL *) url
    ofType: (NSString *) typeName error: (NSError * __autoreleasing *) outError
{
    self.input = [url path];
  
    self.image =
        [[NSImage alloc] initWithData: [NSData dataWithContentsOfURL: url]];
    
    for(NSImageRep * rep in [self.image representations])
      {
      NSSize size;
      
      size.width = [rep pixelsWide];
      size.height = [rep pixelsHigh];
      
      NSSize imageSize = self.imageSize;
      
      if((size.height > imageSize.height) && (size.width > imageSize.width))
        self.imageSize = size;
      }
    
    [self.image setSize: self.imageSize];
    
    return YES;
}

#pragma mark - NSToolbarDelegate conformance

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) flag
  {
  if([itemIdentifier isEqualToString: kImageControlsToolbarItemID])
    {
    // Create the NSToolbarItem and setup its attributes.
    GeoMapToolbarItem * item =
      [[GeoMapToolbarItem alloc]
        initWithItemIdentifier: itemIdentifier];
    
    [item setLabel: NSLocalizedString(@"Image controls", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Image controls", nil)];
    [item setTarget: self];
    [item setAction: nil];
    [item setView: self.imageControlsToolbarItemView];
    
    return item;
    }
    
  if([itemIdentifier isEqualToString: kGCPControlsToolbarItemID])
    {
    // Create the NSToolbarItem and setup its attributes.
    GeoMapToolbarItem * item =
      [[GeoMapToolbarItem alloc]
        initWithItemIdentifier: itemIdentifier];
    
    [item setLabel: NSLocalizedString(@"GCP controls", nil)];
    [item setPaletteLabel: NSLocalizedString(@"GCP controls", nil)];
    [item setTarget: self];
    [item setAction: nil];
    [item setView: self.GCPControlsToolbarItemView];
    
    return item;
    }

  return nil;
  }

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kImageControlsToolbarItemID,
      NSToolbarSpaceItemIdentifier,
      kGCPControlsToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier
    ];
    
  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "default" list of items.
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kImageControlsToolbarItemID,
      NSToolbarSpaceItemIdentifier,
      kGCPControlsToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier
    ];

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

- (void) awakeFromNib
{
    static dispatch_once_t onceToken;
  
    dispatch_once(
        & onceToken,
        ^{
            [self setup];
        });
}

- (void) setup
{
    NSImage * zoomIn = [NSImage imageNamed: @"ZoomIn"];
    NSImage * zoomOut = [NSImage imageNamed: @"ZoomOut"];
    self.GCPImage = [NSImage imageNamed: @"GCP"];
    
    self.toolMode = kPanTool;
    self.zoomInCursor =
        [[NSCursor alloc]
            initWithImage: zoomIn hotSpot: NSMakePoint(7, 7)];
    self.zoomOutCursor =
        [[NSCursor alloc]
            initWithImage: zoomOut hotSpot: NSMakePoint(7, 7)];
    self.addGCPCursor =
        [[NSCursor alloc]
            initWithImage: self.GCPImage hotSpot: NSMakePoint(12.5, 12.5)];
    
    NSImage * zoomInToolbar = [NSImage imageNamed: @"ZoomInToolbar"];
    NSImage * GCPToolbar = [NSImage imageNamed: @"GCPToolbar"];

    [self.panModeButton setImage: [[NSCursor openHandCursor] image]];
    [self.zoomModeButton setImage: zoomInToolbar];
    [self.addGCPModeButton setImage: GCPToolbar];
    
    [self.selectGCPModeButton setImage: [[NSCursor arrowCursor] image]];

    self.imageView.document = self;
    
    [NSEvent
      addLocalMonitorForEventsMatchingMask: NSFlagsChangedMask
      handler:
          ^NSEvent *(NSEvent * event)
          {
              if(self.toolMode == kZoomInTool)
              {
                  if([NSEvent modifierFlags] & NSAlternateKeyMask)
                      self.toolMode = kZoomOutTool;
              }
              else if(self.toolMode == kZoomOutTool)
              {
                  if(!([NSEvent modifierFlags] & NSAlternateKeyMask))
                      self.toolMode = kZoomInTool;
              }
          
              return event;
          }];
    
    //NSRect frame = [self.imageView frame];
    
    //frame.size = self.imageSize;
    
    //[self.imageView setFrame: frame];
    //[self.imageView setImageScaling: NSImageScaleNone];
}

- (IBAction) setTool: (id) sender
{
    if(sender == self.panModeButton)
        self.toolMode = kPanTool;
    else if(sender == self.zoomModeButton)
        self.toolMode = kZoomInTool;
    else if(sender == self.selectGCPModeButton)
        self.toolMode = kSelectGCPTool;
    else if(sender ==self.addGCPModeButton)
        self.toolMode = kAddGCPTool;
}

- (IBAction) previewMap: (id) sender
{
    NSLog(@"preview map");
}

- (IBAction) exportMap: (id) sender
{
    NSLog(@"export map");
}

- (void) addGCP: (NSPoint) point
{
    GeoMapGCP * GCP = [GeoMapGCP new];
  
    GCP.imagePoint = point;

    [self.GCPController addObject: GCP];
  
    myCanPreview = ([self.GCPs count] >= 4);
  
    [self.GCPTableView
        editColumn: 0
        row: [self.GCPs count] - 1
        withEvent: nil
        select: YES];
  
    self.toolMode = kEditGCPTool;
    [self.imageView drawGCPAt: GCP.imagePoint];
    [self.imageView setNeedsDisplay: YES];
}

- (void) remove: (id) sender
{
    [self.GCPController remove: sender];
  
    [self.imageView setNeedsDisplay: YES];
}

- (void) selectGCPAt: (NSPoint) point
{
    double closetDistance = 0;
    GeoMapGCP * closest = nil;
  
    for(GeoMapGCP * GCP in self.GCPs)
    {
        double distance =
            sqrt(
                pow(
                    GCP.imagePoint.x - point.x, 2) +
                    pow(GCP.imagePoint.y - point.y, 2));
    
        if((distance < closetDistance) || !closest)
        {
            closest = GCP;
            closetDistance = distance;
        }
    }
  
    if(closest)
        [self.GCPController setSelectedObjects: @[closest]];
}

- (NSView *) tableView: (NSTableView *) tableView
    viewForTableColumn: (NSTableColumn *) tableColumn
    row: (NSInteger) row
    {
    if([tableColumn.identifier isEqualToString: @"GCP"])
    {
        GeoMapGCPTableCellView * GCPCellView =
            [tableView
                makeViewWithIdentifier: tableColumn.identifier owner: self];
    
        [GCPCellView.latitudeField setEditable: YES];
        [GCPCellView.longitudeField setEditable: YES];
    
        GCPCellView.latitudeField.nextKeyView = GCPCellView.longitudeField;
    
        return GCPCellView;
    }
    
    return nil;
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
    for(GeoMapGCP * GCP in self.GCPController.selectedObjects)
        [self.imageView selectGCP: GCP];
}

- (IBAction) commitLatitude: (id) sender;
{
    [self.windowForSheet makeFirstResponder: [sender nextKeyView]];
}

- (IBAction) commitLongitude: (id) sender
{
    self.toolMode = kPanTool;
}

@end

