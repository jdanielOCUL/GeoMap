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

// Toolbar items.
#define kImageControlsToolbarItemID @"imagecontrolstoolbaritem"

#define kPanSegment  0
#define kZoomSegment 1

@implementation GeoMapDocument

@synthesize toolMode = myToolMode;

@synthesize GCPs = myGCPs;

@synthesize canPreview = myCanPreview;
@synthesize canExport = myCanExport;

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
                [self.imageScrollView
                    setDocumentCursor: [NSCursor openHandCursor]];
                break;

            case kZoomInTool:
                [self.imageScrollView setDocumentCursor: self.zoomInCursor];
                break;

            case kZoomOutTool:
                [self.imageScrollView setDocumentCursor: self.zoomOutCursor];
                break;
        }
    }
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
  // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"GeoMapDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
  
  [self.GCPController
      addObserver: self
      forKeyPath: @"arrangedObjects"
      options: NSKeyValueObservingOptionNew
      context: NULL];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
    ofObject: (id) object
    change: (NSDictionary *) change
    context: (void *) context
{
    if(object == self.GCPController)
        if([keyPath isEqualToString: @"arrangedObjects"])
        {
            [self willChangeValueForKey: @"canPreview"];
            [self willChangeValueForKey: @"canExport"];
        
            myCanPreview = myCanExport = ([self.GCPs count] >= 4);
        
            [self didChangeValueForKey: @"canExport"];
            [self didChangeValueForKey: @"canPreview"];
        }
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  return [self.image TIFFRepresentation];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
  self.image = [[NSImage alloc] initWithData: data];
  
  for(NSImageRep * rep in [self.image representations])
    {
    NSSize size;
    
    size.width = [rep pixelsWide];
    size.height = [rep pixelsHigh];
    
    if((size.height > self.imageSize.height) && (size.width > self.imageSize.width))
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
    
    item.control = self.imageControls;
    [item setLabel: NSLocalizedString(@"Image controls", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Image controls", nil)];
    [item setTarget: self];
    [item setAction: nil];
    [item setView: self.imageControlsToolbarItemView];
    
    return item;
    }
    
  return nil;
  }

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kImageControlsToolbarItemID,
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
      NSToolbarFlexibleSpaceItemIdentifier
    ];

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

- (void) awakeFromNib
  {
  NSImage * zoomIn = [NSImage imageNamed: @"ZoomIn"];
  NSImage * zoomOut = [NSImage imageNamed: @"ZoomOut"];
  
  self.toolMode = kPanTool;
  self.zoomInCursor =
      [[NSCursor alloc]
          initWithImage: zoomIn hotSpot: NSMakePoint(7, 7)];
  self.zoomOutCursor =
      [[NSCursor alloc]
          initWithImage: zoomOut hotSpot: NSMakePoint(7, 7)];
  
  [[self.imageControls cell]
    setImage: [[NSCursor openHandCursor] image] forSegment: kPanSegment];
  [[self.imageControls cell]
    setImage: zoomIn forSegment: kZoomSegment];
  
  [[self.imageControls cell]
    setToolTip: NSLocalizedString(@"Pan image", NULL)
    forSegment: kPanSegment];
  [[self.imageControls cell]
    setToolTip: NSLocalizedString(@"Zoom image", NULL)
    forSegment: kZoomSegment];

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

- (IBAction) changeTool: (id)sender
{
    // switch the tool mode...
    
    if ([sender isKindOfClass: [NSSegmentedControl class]])
    {
        self.toolMode = [sender selectedSegment];
    }
}

- (IBAction) previewMap: (id) sender
{
    NSLog(@"preview map");
}

- (IBAction) exportMap: (id) sender
{
    NSLog(@"export map");
}

@end

