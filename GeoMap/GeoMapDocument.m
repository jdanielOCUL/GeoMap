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

// View sorter.
NSComparisonResult sortViews(id v1, id v2, void * context);

// A document type for georeferencing an image.
@implementation GeoMapDocument

@synthesize toolMode = myToolMode;

@synthesize GCPs = myGCPs;

@synthesize canPreview = myCanPreview;

@synthesize opacity = myOpacity;

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

              [self projectMapTo: self.previewPath preview: YES];
          
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
        completionHandler:
            ^{
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
                          callWebScriptMethod: @"zoomTo"
                          withArguments: self.coordinates];
                      [win
                          callWebScriptMethod: @"showPreview"
                          withArguments: args];
                  });
            }];
  
    self.toolMode = kPanTool;
    self.previewing = YES;
  
    [[self.windowForSheet contentView]
        sortSubviewsUsingFunction: sortViews context: (__bridge void *)(self)];
}

// Export a full-resolution georeferenced image.
- (IBAction) exportMap: (id) sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
  
    // Initialize the file name with a variant of the original name.
    savePanel.nameFieldStringValue =
        [NSString
            stringWithFormat:
                NSLocalizedString(@"%@_WGS84", NULL),
                [[self.input lastPathComponent] stringByDeletingPathExtension]];
  
    // I only create GeoTiff files.
    savePanel.allowedFileTypes = @[@"tif"];
  
    if([savePanel runModal] != NSFileHandlingPanelOKButton)
        return;
  
    // Project the map, but not in preview mode.
    [self projectMapTo: [savePanel.URL path] preview: NO];

    // Leave preview mode.
    [self cancelExportMap: sender];
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
  
    GCP.imagePoint = point;

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
    [self.imageView drawGCPAt: GCP.imagePoint];
    [self.imageView setNeedsDisplay: YES];
}

// Remove the selected GCP.
- (void) remove: (id) sender
{
    [self.GCPController remove: sender];
  
    [self.imageView setNeedsDisplay: YES];
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
    double latitude;
  
    if(![self parseLatitude: [sender stringValue] to: & latitude])
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    
        [self.windowForSheet makeFirstResponder: sender];
    
        return;
    }
  
    [self.windowForSheet makeFirstResponder: [sender nextKeyView]];
}

// Validate and save a longitude value for a GCP.
- (IBAction) commitLongitude: (id) sender
{
    double longitude;
  
    if(![self parseLongitude: [sender stringValue] to: & longitude])
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    
        [self.windowForSheet makeFirstResponder: sender];
    
        return;
    }

    self.toolMode = kAddGCPTool;
}

#pragma mark - Coordinate helpers.

// Parse a latitude text value.
- (BOOL) parseLatitude: (NSString *) value to: (double *) coordinate
{
    if([self parseCoordinate: value to: coordinate])
        if(fabs(*coordinate) < 90)
            return YES;
  
    return NO;
}

// Parse a longitude text value.
- (BOOL) parseLongitude: (NSString *) value to: (double *) coordinate
{
    if([self parseCoordinate: value to: coordinate])
        if(fabs(*coordinate) < 180)
            return YES;
  
    return NO;
}

// Parse a coordinate in various formats.
// Return YES if the coordinate is valid.
// I have to admit, a Swift optional would be handy here.
- (BOOL) parseCoordinate: (NSString *) value to: (double *) coordinate
{
    if(!coordinate)
        return NO;
  
    // Use a good 'ole scanner.
    NSScanner * scanner = [NSScanner scannerWithString: value];
  
    // First, look for directional indicators like NSEW or +=.
    // I won't use my other multiplier logic since I may have + and - too.
    double multiplier = 1;
  
    NSString * direction;
  
    BOOL found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet
                    characterSetWithCharactersInString: @"-NnSsEeWw"]
            intoString: & direction];

    if(found)
    {
        direction = [direction lowercaseString];
    
        if([direction hasPrefix: @"s"])
            multiplier = -1;
        else if([direction hasPrefix: @"w"])
            multiplier = -1;
        else if([direction hasPrefix: @"-"])
            multiplier = -1;
    }
  
    // Now look for degrees. If this is a stand-alone, fractional degree value,
    // I can go ahead and quit.
    double degrees;
  
    found = [scanner scanDouble: & degrees];
  
    if(!found)
        return NO;
  
    // Now look for some character that might signal the beginning of a DMS
    // format.
    found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"d°"]
            intoString: NULL];
  
    // Maybe I am done.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }
  
    // Look for a minutes value. Again, a fractional value is fine.
    double minutes;
  
    found = [scanner scanDouble: & minutes];

    // Maybe I am done.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }
  
    // Increment the degrees now.
    degrees += (minutes / 60.0);
  
    // Look for a units indicator and toss it.
    found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"m'’"]
            intoString: NULL];
  
    // This is fine. I'm done.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }

    // Now look for a seconds value. This may very well be a fractional.
    double seconds;
  
    found = [scanner scanDouble: & seconds];

    // If I didn't find anything, I'm still good.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }
  
    // Increment the degrees.
    degrees += (seconds / 60.0 / 60.0);
  
    // Scan and toss the seconds unit.
    found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"s\"”"]
            intoString: NULL];

    *coordinate = [self scanDirection: degrees scanner: scanner];

    return YES;
}

// Check for a trailing directional indicator.
- (double) scanDirection: (double) degrees scanner: (NSScanner *) scanner
{
    double multiplier = 1.0;
  
    NSString * direction = nil;
  
    BOOL found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"NnSsEeWw"]
            intoString: & direction];

    if(found)
    {
        direction = [direction lowercaseString];
    
        if([direction hasPrefix: @"s"])
            multiplier = -1;
        else if([direction hasPrefix: @"w"])
            multiplier = -1;
    }
  
    return degrees * multiplier;
}

// Project an image.
- (void) projectMapTo: (NSString *) output preview: (BOOL) preview
{
    // Maybe try this again at some point. It should be in an XPC though.
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
  
    // Get the gdal_translate arguments
    NSMutableArray * args = [NSMutableArray array];
  
    [args addObject: self.input];
  
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
        double latitude;
    
        if([self parseLatitude: GCP.latitude to: & latitude])
            GCP.lat = latitude;

        double longitude;

        if([self parseLongitude: GCP.longitude to: & longitude])
            GCP.lon = longitude;
    
        if(!haveMin || (GCP.imagePoint.x < minX))
        {
            minX = GCP.imagePoint.x;
            minLong = GCP.lon;

            haveMin = YES;
        }
    
        if(!haveMax || (GCP.imagePoint.x > maxX))
        {
            maxX = GCP.imagePoint.x;
            maxLong = GCP.lon;
        
            haveMax = YES;
        }
    
        if(GCP.imagePoint.y > maxY)
            maxY = GCP.imagePoint.y;
    }
  
    if(minLong > maxLong)
        for(GeoMapGCP * GCP in self.GCPs)
            GCP.lon *= -1.0;
  
    // See what the scale would be if I were previewing this projection.
    double scaleX = 1.0;
    double scaleY = 1.0;
  
    if(preview)
    {
        if(self.image.size.width > 1000)
            scaleX = 1000.0/self.image.size.width;

        if(self.image.size.height > 1000)
            scaleY = 1000.0/self.image.size.height;
    }
  
    double scale = fmax(scaleX, scaleY);
  
    // Don't display progress to standard out.
    [args addObject: @"-q"];
  
    // Add GCPs. Scale the coordinates based on the preview scale, if necessary.
    for(GeoMapGCP * GCP in self.GCPs)
    {
        [args addObject: @"-gcp"];
    
        [args
            addObject:
                [NSString stringWithFormat: @"%lf", scale * GCP.imagePoint.x]];
        [args
            addObject:
                [NSString
                    stringWithFormat:
                        @"%lf",
                        scale * (self.image.size.height - GCP.imagePoint.y)]];
    
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.lon]];
        [args addObject: [NSString stringWithFormat: @"%lf", GCP.lat]];
    }

    // If previewing, scale the output.
    if(preview)
    {
        [args addObject: @"-outsize"];
    
        [args
            addObject:
                [NSString
                    stringWithFormat: @"%lf", self.image.size.width * scale]];
        [args
            addObject:
                [NSString
                    stringWithFormat: @"%lf", self.image.size.height * scale]];
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
  
    // Now do a true projection and create a GeoTiff.
    NSTask * warp = [NSTask new];
  
    warp.launchPath = [GDALPath stringByAppendingPathComponent: @"gdalwarp"];
    warp.arguments =
        @[
        @"-q",
        tempPath,
        output
        ];
  
    [warp launch];
    [warp waitUntilExit];
  
    [[NSFileManager defaultManager] removeItemAtPath: tempPath error: nil];
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