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
#import "GeoMapReproject.h"
#import <AudioToolbox/AudioToolbox.h>

// Toolbar items.
#define kImageControlsToolbarItemID @"imagecontrolstoolbaritem"
#define kGCPControlsToolbarItemID @"gcpcontrolstoolbaritem"

#define kTiledMapServiceURL @"http://server.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"

#define kFormatGeoTIFF 0
#define kFormatGeoPDF  1

#define kDatumGCP    0
#define kDatumWGS84  1
#define kDatumNAD83  2
#define kDatumNAD27  3
#define kDatumWWW    4
#define kDatumCustom 5

// View sorter.
NSComparisonResult sortViews(id v1, id v2, void * context);

// A document type for georeferencing an image.
@implementation GeoMapDocument

@synthesize toolMode = myToolMode;

@synthesize GCPs = myGCPs;

@synthesize canPreview = myCanPreview;

@synthesize opacity = myOpacity;

@synthesize formatIndex = myFormatIndex;
@synthesize datumIndex = myDatumIndex;

- (NSUInteger) toolMode
{
    return myToolMode;
}

// Update the user interface to match the tool mode.
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

- (double) opacity
{
    return myOpacity;
}

// Update the opacity of the image preview to match the slider.
- (void) setOpacity: (double) opacity
{
    if(opacity != myOpacity)
    {
        [self willChangeValueForKey: @"opacity"];
    
        if(self.previewPath && self.coordinates)
        {
            NSMutableArray * args = [NSMutableArray array];
      
            [args addObject: self.previewPath];
            [args addObjectsFromArray: self.coordinates];
            [args addObject: [NSString stringWithFormat: @"%f", opacity]];
      
            id win = [self.mapView windowScriptObject];
        
            [win callWebScriptMethod: @"showPreview" withArguments: args];
        }
        
        myOpacity = opacity;
    
        [self didChangeValueForKey: @"opacity"];
    }
}

- (NSUInteger) formatIndex
{
    return myFormatIndex;
}

- (void) setFormatIndex: (NSUInteger) formatIndex
{
    if(myFormatIndex != formatIndex)
    {
        [self willChangeValueForKey: @"formatIndex"];
    
        myFormatIndex = formatIndex;
    
        [self didChangeValueForKey: @"formatIndex"];
    
        switch(myFormatIndex)
        {
            case kFormatGeoTIFF:
                [self.savePanel setAllowedFileTypes: @[@"tif"]];
                self.format = @"GTiff";
                break;

            case kFormatGeoPDF:
                [self.savePanel setAllowedFileTypes: @[@"pdf"]];
                self.format = @"PDF";
                break;
        }
    }
}

- (NSUInteger) datumIndex
{
    return myDatumIndex;
}

- (void) setDatumIndex: (NSUInteger) datumIndex
{
    if(myDatumIndex != datumIndex)
    {
        [self willChangeValueForKey: @"datumIndex"];
    
        myDatumIndex = datumIndex;
    
        [self didChangeValueForKey: @"datumIndex"];

        switch(myDatumIndex)
        {
            case kDatumGCP:
                self.srs = @"";
                self.srsEnabled = NO;
                self.datum = @"GCP";
                break;

            case kDatumWGS84:
                self.srs = @"+proj=latlong +datum=WGS84";
                self.srsEnabled = YES;
                self.datum = @"WGS84";
                break;

            case kDatumNAD83:
                self.srs = @"+proj=latlong +datum=NAD83";
                self.srsEnabled = YES;
                self.datum = @"NAD83";
                break;

            case kDatumNAD27:
                self.srs = @"+proj=latlong +datum=NAD27";
                self.srsEnabled = YES;
                self.datum = @"NAD27";
                break;

            case kDatumWWW:
                self.srs = @"EPSG:3857";
                self.srsEnabled = YES;
                self.datum = @"WWW";
                break;

            case kDatumCustom:
                self.srs = @"";
                self.srsEnabled = YES;
                self.datum = NSLocalizedString(@"Custom", NULL);
                break;
        }

        // Initialize the file name with a variant of the original name.
        self.savePanel.nameFieldStringValue =
            [NSString
                stringWithFormat:
                    NSLocalizedString(@"%@_%@", NULL),
                    [[self.input lastPathComponent] stringByDeletingPathExtension],
                    [self.datum uppercaseString]];
    }
}

// Constructor.
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

// Why does Apple make documents so hard to clean up?
- (void) dealloc
{
    [self cleanup];
}

// Clean up on manual close.
- (void) close
{
    [self cleanup];
    [super close];
}

- (NSString *) windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document
    // supports multiple NSWindowControllers, you should remove this method and
    // override -makeWindowControllers instead.
    return @"GeoMapDocument";
}

- (void) windowControllerDidLoadNib: (NSWindowController *) aController
{
    [super windowControllerDidLoadNib: aController];
    // Add any code here that needs to be executed once the windowController has
    // loaded the document's window.
}

// I don't want modern document-handling architecture for this application.
+ (BOOL) autosavesInPlace
{
    return NO;
}

// I don't save existing documents.
- (BOOL) writeToURL: (NSURL *) url
    ofType: (NSString *) typeName error: (NSError * __autoreleasing *) outError
{
    return NO;
}

// Read a new document.
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
  
    [self.GCPs addObjectsFromArray: getGCPs(self.input)];
    
    self.previewScale = 1.0;
  
    NSSize maxSize = self.imageSize;
  
    double area = maxSize.height * maxSize.width;
  
    // If the image is way too big, shrink it down to a manageable size.
    if(area > (4096 * 4096))
    {
        self.previewScale = sqrt(4096 * 4096 / area);
    
        maxSize.height *= self.previewScale;
        maxSize.width *= self.previewScale;

        NSImage * previewImage = [[NSImage alloc] initWithSize: maxSize];
    
        [previewImage lockFocus];
    
        [self.image setSize: maxSize];
    
        [[NSGraphicsContext currentContext]
            setImageInterpolation: NSImageInterpolationHigh];
            
        [self.image
            drawAtPoint: NSZeroPoint
            fromRect: NSZeroRect
            operation: NSCompositeCopy
            fraction: 1];
    
        [previewImage unlockFocus];
    
        self.image = previewImage;
    }
  
    [self.image setSize: maxSize];
  
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

#pragma - Setup

- (void) awakeFromNib
{
    [self setup];
}

// In documents, awakeFromNib can get called multiple times. Only do the setup
// once.
- (void) setup
{
    if(self.isSetup)
        return;
  
    // Grab images from resource.
    NSImage * zoomIn = [NSImage imageNamed: @"ZoomIn"];
    NSImage * zoomOut = [NSImage imageNamed: @"ZoomOut"];
    self.GCPImage = [NSImage imageNamed: @"GCP"];
  
    // Setup tools and cursors.
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
  
    // Get some more images.
    NSImage * zoomInToolbar = [NSImage imageNamed: @"ZoomInToolbar"];
    NSImage * GCPToolbar = [NSImage imageNamed: @"GCPToolbar"];

    // Setup toolbar buttons.
    [self.panModeButton setImage: [[NSCursor openHandCursor] image]];
    [self.zoomModeButton setImage: zoomInToolbar];
    [self.addGCPModeButton setImage: GCPToolbar];
    
    [self.selectGCPModeButton setImage: [[NSCursor arrowCursor] image]];

    self.imageView.document = self;
  
    // Keep track of modifier keys to have optional tool modes.
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
  
    // Setup buttons in their initial state.
    self.mapView.alphaValue = 0.0;
    self.exportButton.alphaValue = 0.0;
    self.cancelExportButton.alphaValue = 0.0;
    self.previewButton.alphaValue = 1.0;
    self.opacityLabel.alphaValue = 0.0;
    self.opacitySlider.alphaValue = 0.0;

    [self.exportButton setHidden: YES];
    [self.cancelExportButton setHidden: YES];
    [self.opacityLabel setHidden: YES];
    [self.opacitySlider setHidden: YES];

    self.imageView.image = self.image;
  
    // I might have loaded a file with GCPs.
    self.canPreview = ([self.GCPs count] >= 4);
  
    for(GeoMapGCP * GCP in self.GCPs)
        [self.imageView addGCP: GCP];

    self.isSetup = YES;
}

// Clean up resources.
- (void) cleanup
{
    if(self.previewPath)
        [[NSFileManager defaultManager]
            removeItemAtPath: self.previewPath error: NULL];
  
    self.previewPath = nil;
}

// Set the tool mode.
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

// Preview the map.
- (IBAction) previewMap: (id) sender
{
    self.previewReady = dispatch_semaphore_create(0);
  
    // Generate the preview asynchronously.
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            NSString * tempName =
                [[[[self.input lastPathComponent]
                    stringByDeletingPathExtension]
                        stringByAppendingString: @"_preview"]
                            stringByAppendingPathExtension:@"tif"];
            
              self.previewPath =
                  [NSTemporaryDirectory()
                      stringByAppendingPathComponent: tempName];

              [self previewMapTo: self.previewPath];
          
              self.coordinates = getCoordinates(self.previewPath);
          
              // Now I can preview.
              dispatch_semaphore_signal(self.previewReady);
          });
  
    // Setup the web view to display the preview.
    NSString * htmlPath =
        [[NSBundle mainBundle] pathForResource: @"index" ofType: @"html"];
  
    NSURL * baseURL = [[NSBundle mainBundle] resourceURL];
  
    NSString * html =
        [NSString
            stringWithContentsOfFile: htmlPath
            encoding: NSUTF8StringEncoding
            error: NULL];
  
    [self.mapView setFrameLoadDelegate: self];
  
    [[self.mapView mainFrame] loadHTMLString: html baseURL: baseURL];
}

// The web view is loaded.
- (void) webView: (WebView *) sender didFinishLoadForFrame: (WebFrame *) frame
{
    // Now wait for the preview to be ready.
    dispatch_semaphore_wait(self.previewReady, DISPATCH_TIME_FOREVER);

    // Display the preview in the web view.
    dispatch_async(
        dispatch_get_main_queue(),
        ^{
            NSMutableArray * args = [NSMutableArray array];
          
            [args addObject: self.previewPath];
            [args addObjectsFromArray: self.coordinates];
            [args addObject: @"0.75"];

            id win = [self.mapView windowScriptObject];
        
            [win
                callWebScriptMethod: @"zoomTo" withArguments: self.coordinates];
            [win callWebScriptMethod: @"showPreview" withArguments: args];
        });

    self.opacity = 0.75;
  
    [self.exportButton setHidden: NO];
    [self.cancelExportButton setHidden: NO];
    [self.opacityLabel setHidden: NO];
    [self.opacitySlider setHidden: NO];

    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
            context.allowsImplicitAnimation = YES;
            
            self.mapView.alphaValue = 1.0;
            self.exportButton.alphaValue = 1.0;
            self.cancelExportButton.alphaValue = 1.0;
            self.previewButton.alphaValue = 0.0;
            self.opacityLabel.alphaValue = 1.0;
            self.opacitySlider.alphaValue = 1.0;
            }
        completionHandler: nil];
  
    self.toolMode = kPanTool;
    self.previewing = YES;
  
    [[self.windowForSheet contentView]
        sortSubviewsUsingFunction: sortViews context: (__bridge void *)(self)];
}

// Export a full-resolution georeferenced image.
- (IBAction) exportMap: (id) sender
{
    self.savePanel = [NSSavePanel savePanel];
  
    self.savePanel.accessoryView = self.saveOptionslPanel;
  
    // Force a change.
    myFormatIndex = 10;
    self.formatIndex = kFormatGeoTIFF;
  
    myDatumIndex = 10;
    self.datumIndex = kDatumGCP;
  
    if([self.savePanel runModal] != NSFileHandlingPanelOKButton)
        return;
  
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            if(self.datumIndex == kDatumGCP)
              [self exportMapTo: [self.savePanel.URL path]];
            else
              [self projectMapTo: [self.savePanel.URL path]];
           
            dispatch_async(
                dispatch_get_main_queue(),
                ^{
                    // Leave preview mode.
                    [self cancelExportMap: sender];
                });
        });
}

// Leave preview mode.
- (IBAction) cancelExportMap: (id) sender
{
    // Clean up the preview file.
    if(self.previewPath)
        [[NSFileManager defaultManager]
            removeItemAtPath: self.previewPath error: NULL];

    self.previewPath = nil;
  
    // Leave preview mode.
    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
                context.allowsImplicitAnimation = YES;
                
                self.mapView.alphaValue = 0.0;
                self.exportButton.alphaValue = 0.0;
                self.cancelExportButton.alphaValue = 0.0;
                self.previewButton.alphaValue = 1.0;
                self.opacityLabel.alphaValue = 0.0;
                self.opacitySlider.alphaValue = 0.0;
            }
        completionHandler:
            ^{
                [self.exportButton setHidden: YES];
                [self.cancelExportButton setHidden: YES];
                [self.opacityLabel setHidden: YES];
                [self.opacitySlider setHidden: YES];
            }];

    // Re-order the views.
    self.previewing = NO;
  
    [[self.windowForSheet contentView]
        sortSubviewsUsingFunction: sortViews context: (__bridge void *)(self)];
}

// Add a new GCP. This UI still needs work.
- (void) addGCP: (NSPoint) point
{
    GeoMapGCP * GCP = [GeoMapGCP new];
  
    GCP.normalizedImagePoint = point;
  
    [self.GCPController setSelectedObjects: nil];
  
    [self.GCPController addObject: GCP];
  
    // Update the preview button in case I have enough points now.
    self.canPreview = ([self.GCPs count] >= 4);
  
    // Start editing.
    [self.GCPTableView
        editColumn: 0
        row: [self.GCPs count] - 1
        withEvent: nil
        select: YES];
  
    // Draw the GCP.
    self.toolMode = kEditGCPTool;
    [self.imageView addGCP: GCP];
    self.currentGCP = GCP;
  
    dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(),
      ^{
          [[GCP.view animator] setAlphaValue: 0.5];
      });
}

// Remove the selected GCP.
- (void) remove: (id) sender
{
    for(GeoMapGCP * GCP in self.GCPController.selectedObjects)
        [self.imageView removeGCP: GCP];

    [self.GCPController remove: sender];
}

// Select a GCP.
- (void) selectGCPAt: (NSPoint) point
{
    // Find the closest GCP to the clicked point and select it.
    double closetDistance = 0;
    GeoMapGCP * closest = nil;
  
    for(GeoMapGCP * GCP in self.GCPs)
    {
        double distance =
            sqrt(
                pow(
                    GCP.normalizedImagePoint.x - point.x, 2) +
                    pow(GCP.normalizedImagePoint.y - point.y, 2));
    
        if((distance < closetDistance) || !closest)
        {
            closest = GCP;
            closetDistance = distance;
        }
    }
  
    if(closest)
        [self.GCPController setSelectedObjects: @[closest]];
}

#pragma mark - NSTableViewDelegate conformance.

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

#pragma mark - UI actions.

// Validate and save a latitude value for a GCP.
- (IBAction) commitLatitude: (id) sender;
{
    if(fabs(self.currentGCP.latitude) > 180)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    
        self.currentGCP.latitude = 0;
    
        [self.windowForSheet makeFirstResponder: sender];
    
        return;
    }
  
    [self.windowForSheet makeFirstResponder: [sender nextKeyView]];
}

// Validate and save a longitude value for a GCP.
- (IBAction) commitLongitude: (id) sender
{
    if(fabs(self.currentGCP.longitude) > 180)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    
        self.currentGCP.longitude = 0;
    
        [self.windowForSheet makeFirstResponder: sender];
    
        return;
    }

    self.toolMode = kAddGCPTool;

    [[self.currentGCP.view animator] setAlphaValue: 1.0];
}

// Preview an image.
- (void) previewMapTo: (NSString *) output
{
    NSString * frameworksPath = [[NSBundle mainBundle] privateFrameworksPath];
    NSString * GDALPath =
        [frameworksPath
            stringByAppendingPathComponent: @"GDAL.framework/Programs"];
  
    NSString * GDAL_DATA =
        [frameworksPath
            stringByAppendingPathComponent:
                @"GDAL.framework/Versions/Current/unix/share"];

    // Get the gdal_translate arguments
    NSMutableArray * args = [NSMutableArray array];
  
    [args addObject: self.input];
  
    // Users may not add the Longitude coordinates correctly and they really
    // shouldn't have to. Calculate the max and min GCP X positions and the
    // max and min longitude positions. If they are out of order, then this
    // image is a western hemisphere image without the proper directional
    // indicators on the coordinates. If so, fix 'em.
    [self fixLongitude];
  
    // See what the scale would be if I were previewing this projection.
    double scaleX = 1.0;
    double scaleY = 1.0;
  
    if(self.image.size.width > 1000)
        scaleX = 1000.0/self.image.size.width;

    if(self.image.size.height > 1000)
        scaleY = 1000.0/self.image.size.height;
  
    [args addObjectsFromArray: @[@"--config", @"GDAL_DATA", GDAL_DATA]];
    [args addObjectsFromArray: @[@"--config", @"GDAL_CACHEMAX", @"1024"]];
  
    double scale = fmax(scaleX, scaleY);
  
    // Add GCPs. Scale the coordinates based on the preview scale, if necessary.
    for(GeoMapGCP * GCP in self.GCPs)
    {
        [args addObject: @"-gcp"];
    
        NSPoint point = GCP.normalizedImagePoint;
    
        point.x *= self.image.size.width;
        point.y *= self.image.size.height;
    
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.x]];
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.y]];
    
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.longitude]];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.latitude]];
    }

    // Add metadata.
    for(NSString * tag in self.metadata)
    {
        [args addObject: @"-mo"];
        [args
            addObject:
                [NSString
                    stringWithFormat: @"\"%@=%@\"", tag, self.metadata[tag]]];
    }
  
    // If previewing, scale the output.
    [args addObject: @"-outsize"];

    [args
        addObject:
            [NSString
                stringWithFormat: @"%lf", self.image.size.width * scale]];
    [args
        addObject:
            [NSString
                stringWithFormat: @"%lf", self.image.size.height * scale]];
  
    // Now use gdal_translate to create a TIFF file with GCPs.
    NSString * tempName =
      [[[[self.input lastPathComponent]
          stringByDeletingPathExtension]
              stringByAppendingString: @"_gcp"]
                  stringByAppendingPathExtension:@"tif"];
  
    NSString * tempPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent: tempName];
  
    [args addObject: tempPath];
  
    NSTask * translate = [NSTask new];
  
    translate.launchPath =
        [GDALPath stringByAppendingPathComponent: @"gdal_translate"];
    translate.arguments = args;
  
    NSPipe * pipe = [NSPipe pipe];
  
    translate.standardOutput = pipe.fileHandleForWriting;
  
    pipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle * input)
        {
            [self updateProgress: input start: 0];
        };
  
    [self showProgress: NSLocalizedString(@"Previewing...", NULL)];
  
    NSLog(@"%@ %@", translate.launchPath, translate.arguments);

    [translate launch];
    [translate waitUntilExit];
  
    // Now do a true projection and create a GeoTiff.
    NSTask * warp = [NSTask new];
  
    warp.launchPath = [GDALPath stringByAppendingPathComponent: @"gdalwarp"];
    warp.arguments =
        @[
        @"--config", @"GDAL_DATA", GDAL_DATA,
        @"--config", @"GDAL_CACHEMAX", @"1024",
        @"--config", @"GDAL_DATA", GDAL_DATA,
        @"--config", @"GDAL_CACHEMAX", @"1024",
        @"-multi",
        @"-of",
        @"GTiff",
        @"-t_srs",
        @"EPSG:3857",
        tempPath,
        output
        ];
  
    pipe = [NSPipe pipe];
  
    warp.standardOutput = pipe.fileHandleForWriting;

    pipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle * input)
        {
            [self updateProgress: input start: 100];
        };

    NSLog(@"%@ %@", warp.launchPath, warp.arguments);

    [warp launch];
    [warp waitUntilExit];
  
    [[NSFileManager defaultManager] removeItemAtPath: tempPath error: nil];
  
    [self hideProgress];
}

// Export an image.
- (void) exportMapTo: (NSString *) output
{
    NSString * frameworksPath = [[NSBundle mainBundle] privateFrameworksPath];
    NSString * GDALPath =
        [frameworksPath
            stringByAppendingPathComponent: @"GDAL.framework/Programs"];
  
    NSString * GDAL_DATA =
        [frameworksPath
            stringByAppendingPathComponent:
                @"GDAL.framework/Versions/Current/unix/share"];

    // Get the gdal_translate arguments
    NSMutableArray * args = [NSMutableArray array];
  
    [args addObject: self.input];
  
    // Users may not add the Longitude coordinates correctly and they really
    // shouldn't have to. Calculate the max and min GCP X positions and the
    // max and min longitude positions. If they are out of order, then this
    // image is a western hemisphere image without the proper directional
    // indicators on the coordinates. If so, fix 'em.
    [self fixLongitude];
  
    // See what the scale would be if I were previewing this projection.
    double scaleX = 1.0;
    double scaleY = 1.0;
  
    [args addObjectsFromArray: @[@"--config", @"GDAL_DATA", GDAL_DATA]];
    [args addObjectsFromArray: @[@"--config", @"GDAL_CACHEMAX", @"1024"]];
  
    double scale = fmax(scaleX, scaleY);
  
    // Add GCPs. Scale the coordinates based on the preview scale, if necessary.
    for(GeoMapGCP * GCP in self.GCPs)
    {
        [args addObject: @"-gcp"];
    
        NSPoint point = GCP.normalizedImagePoint;
    
        point.x *= self.imageSize.width;
        point.y *= self.imageSize.height;

        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.x]];
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.y]];
    
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.longitude]];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.latitude]];
    }

    // Add metadata.
    for(NSString * tag in self.metadata)
    {
        [args addObject: @"-mo"];
        [args
            addObject:
                [NSString
                    stringWithFormat: @"\"%@=%@\"", tag, self.metadata[tag]]];
    }
  
    [args addObject: @"-of"];
    [args addObject: self.format];
  
    [args addObject: output];
  
    NSTask * translate = [NSTask new];
  
    translate.launchPath =
        [GDALPath stringByAppendingPathComponent: @"gdal_translate"];
    translate.arguments = args;
  
    NSPipe * pipe = [NSPipe pipe];
  
    translate.standardOutput = pipe.fileHandleForWriting;
  
    pipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle * input)
        {
            [self updateProgress: input start: 0];
        };
  
    [self showProgress: NSLocalizedString(@"Exporting...", NULL)];
  
    [[NSFileManager defaultManager] removeItemAtPath: output error: NULL];
  
    NSLog(@"%@ %@", translate.launchPath, translate.arguments);

    [translate launch];
    [translate waitUntilExit];
  
    [self hideProgress];
}

// Project an image.
- (void) projectMapTo: (NSString *) output
{
    NSString * frameworksPath = [[NSBundle mainBundle] privateFrameworksPath];
    NSString * GDALPath =
        [frameworksPath
            stringByAppendingPathComponent: @"GDAL.framework/Programs"];
  
    NSString * GDAL_DATA =
        [frameworksPath
            stringByAppendingPathComponent:
                @"GDAL.framework/Versions/Current/unix/share"];

    // Get the gdal_translate arguments
    NSMutableArray * args = [NSMutableArray array];
  
    [args addObject: self.input];
  
    // Users may not add the Longitude coordinates correctly and they really
    // shouldn't have to. Calculate the max and min GCP X positions and the
    // max and min longitude positions. If they are out of order, then this
    // image is a western hemisphere image without the proper directional
    // indicators on the coordinates. If so, fix 'em.
    [self fixLongitude];
  
    // See what the scale would be if I were previewing this projection.
    double scaleX = 1.0;
    double scaleY = 1.0;
  
    [args addObjectsFromArray: @[@"--config", @"GDAL_DATA", GDAL_DATA]];
    [args addObjectsFromArray: @[@"--config", @"GDAL_CACHEMAX", @"1024"]];
  
    double scale = fmax(scaleX, scaleY);
  
    // Add GCPs. Scale the coordinates based on the preview scale, if necessary.
    for(GeoMapGCP * GCP in self.GCPs)
    {
        [args addObject: @"-gcp"];
    
        NSPoint point = GCP.normalizedImagePoint;
    
        point.x *= self.imageSize.width;
        point.y *= self.imageSize.height;
    
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.x]];
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * point.y]];
    
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.longitude]];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.latitude]];
    }

    // Add metadata.
    for(NSString * tag in self.metadata)
    {
        [args addObject: @"-mo"];
        [args
            addObject:
                [NSString
                    stringWithFormat: @"\"%@=%@\"", tag, self.metadata[tag]]];
    }
  
    // Now use gdal_translate to create a TIFF file with GCPs.
    NSString * tempName =
      [[[[self.input lastPathComponent]
          stringByDeletingPathExtension]
              stringByAppendingString: @"_gcp"]
                  stringByAppendingPathExtension:@"tif"];
  
    NSString * tempPath =
        [NSTemporaryDirectory() stringByAppendingPathComponent: tempName];
  
    [args addObject: tempPath];
  
    NSTask * translate = [NSTask new];
  
    translate.launchPath =
        [GDALPath stringByAppendingPathComponent: @"gdal_translate"];
    translate.arguments = args;
  
    NSPipe * pipe = [NSPipe pipe];
  
    translate.standardOutput = pipe.fileHandleForWriting;
  
    pipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle * input)
        {
            [self updateProgress: input start: 0];
        };
  
    [self showProgress: NSLocalizedString(@"Exporting...", NULL)];
  
    [[NSFileManager defaultManager] removeItemAtPath: tempPath error: NULL];

    NSLog(@"%@ %@", translate.launchPath, translate.arguments);

    [translate launch];
    [translate waitUntilExit];
  
    // Now do a true projection and create a GeoTiff.
    NSTask * warp = [NSTask new];
  
    warp.launchPath = [GDALPath stringByAppendingPathComponent: @"gdalwarp"];
    warp.arguments =
        @[
        @"--config", @"GDAL_DATA", GDAL_DATA,
        @"--config", @"GDAL_CACHEMAX", @"1024",
        @"-multi",
        @"-of",
        self.format,
        @"-t_srs",
        self.srs,
        tempPath,
        output
        ];
  
    pipe = [NSPipe pipe];
  
    warp.standardOutput = pipe.fileHandleForWriting;

    pipe.fileHandleForReading.readabilityHandler =
        ^(NSFileHandle * input)
        {
            [self updateProgress: input start: 100];
        };

    [[NSFileManager defaultManager] removeItemAtPath: output error: NULL];

    NSLog(@"%@ %@", warp.launchPath, warp.arguments);
  
    [warp launch];
    [warp waitUntilExit];
  
    [[NSFileManager defaultManager] removeItemAtPath: tempPath error: nil];
  
    [self hideProgress];
}

// Show the progress panel.
- (void) showProgress: (NSString *) labelString
{
    dispatch_async(
        dispatch_get_main_queue(),
        ^{
            [self.progressIndicator setIndeterminate: YES];
            [self.progressIndicator startAnimation: nil];
          
            self.progressLabel = labelString;
            self.progressTimer =
                [NSTimer
                    scheduledTimerWithTimeInterval: 0.5
                    target: self
                    selector: @selector(timerShowProgress:)
                    userInfo: NULL
                    repeats: NO];
        });
}

- (void) timerShowProgress: (NSTimer *) timer
{
    [[NSApplication sharedApplication]
        beginSheet: self.progressPanel
        modalForWindow: self.windowForSheet
        modalDelegate: nil
        didEndSelector: nil
        contextInfo: NULL];
}

// Hide the progress panel.
- (void) hideProgress
{
    dispatch_async(
        dispatch_get_main_queue(),
        ^{
            if([self.progressPanel isVisible])
            {
                [self.progressIndicator stopAnimation: nil];
                [[NSApplication sharedApplication]
                    endSheet: self.progressPanel];
                [self.progressPanel orderOut: self];
            }
            else
                [self.progressTimer invalidate];
        });
}

// Update the progress with output from GDAL status.
- (void) updateProgress: (NSFileHandle *) input start: (int) start
{
    NSData * data = [input availableData];
    NSString * string =
        [[NSString alloc]
            initWithBytes: data.bytes
            length: data.length
            encoding: NSUTF8StringEncoding];
    
    NSScanner * scanner = [NSScanner scannerWithString: string];
    
    scanner.charactersToBeSkipped =
        [NSCharacterSet characterSetWithCharactersInString: @"."];

    int progress = 0;
    
    BOOL found = [scanner scanInt: & progress];

    while(found)
    {
        dispatch_async(
            dispatch_get_main_queue(),
            ^{
                [self.progressIndicator setIndeterminate: NO];
                self.progress = [NSNumber numberWithInt: progress + start];
            });
    
        found = [scanner scanInt: & progress];
    }
}

// Fix the east-west hemisphere problems.
- (void) fixLongitude
{
    // Users may not add the Longitude coordinates correctly and they really
    // shouldn't have to. Calculate the max and min GCP X positions and the
    // max and min longitude positions. If they are out of order, then this
    // image is a western hemisphere image without the proper directional
    // indicators on the coordinates. If so, fix 'em.
    BOOL haveMin = NO;
    double minX = 0;
    double minLong = 0;
  
    bool haveMax = NO;
    double maxX = 0;
    double maxLong = 0;
  
    double maxY = 0;
  
    for(GeoMapGCP * GCP in self.GCPs)
    {
        if(!haveMin || (GCP.normalizedImagePoint.x < minX))
        {
            minX = GCP.normalizedImagePoint.x;
            minLong = GCP.longitude;

            haveMin = YES;
        }
    
        if(!haveMax || (GCP.normalizedImagePoint.x > maxX))
        {
            maxX = GCP.normalizedImagePoint.x;
            maxLong = GCP.longitude;
        
            haveMax = YES;
        }
    
        if(GCP.normalizedImagePoint.y > maxY)
            maxY = GCP.normalizedImagePoint.y;
    }
  
    if(minLong > maxLong)
        for(GeoMapGCP * GCP in self.GCPs)
            GCP.longitude *= -1.0;
}

@end

// View sorter. This will make sure either the image view or the map preview
// is the top-most view, as appropriate.
NSComparisonResult sortViews(id v1, id v2, void * context)
{
    GeoMapDocument * self = (__bridge GeoMapDocument *) context;
  
    if((v1 == self.mapView) && self.previewing)
        return NSOrderedDescending;
  
    if((v1 == self.imageScrollView) && !self.previewing)
        return NSOrderedDescending;

    if((v1 == self.imageView) && !self.previewing)
        return NSOrderedDescending;

    return NSOrderedSame;
}