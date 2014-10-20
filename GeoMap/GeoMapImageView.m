//
//  GeoMapImageView.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapImageView.h"
#import "GeoMapDocument.h"
#import "GeoMapGCP.h"

// Standard zoom factors.
#define kZoomInFactor  1.414214
#define kZoomOutFactor 0.7071068

// Wrap an image view into something a bit smarter. But don't fall for the
// IKImageView trap again.
@interface GeoMapImageView ()

// Use the same color for the selection marquee.
@property (strong) NSColor * selectionFillColor;

@end

@implementation GeoMapImageView
{
    // I will need to keep track of various values between mouse events.
    NSPoint mouseDownLocation;
    NSRect mouseDownRect;
    double magnification;
    NSRect selectionMarquee;
}

// Setup the view.
- (void) awakeFromNib
{
    magnification = 1.0;

    self.scrollView = [self enclosingScrollView];

    self.scrollView.minMagnification = 1.0;
    self.scrollView.maxMagnification = 100.0;

    self.selectionFillColor =
        [NSColor colorWithCalibratedRed: .5 green: .5 blue: .5 alpha: .4];
  
    [self updateScale];
}

// Draw the view, including GCPs and any in-progress selection marquee.
- (void) drawRect: (NSRect) dirtyRect
{
    [super drawRect: dirtyRect];
  
    // If I have a selection rectangle, draw a marquee around it.
    if(!NSEqualRects(selectionMarquee, NSZeroRect))
    {
        NSRect drawRect = NSInsetRect(selectionMarquee, 1, 1);
    
        NSBezierPath * marquee =
          [NSBezierPath bezierPathWithRect: drawRect];
    
        [self.selectionFillColor set];
        [marquee fill];
    }
}

// Add a GCP.
- (void) addGCP: (GeoMapGCP *) GCP
{
    double imageSize =
        self.document.GCPImage.size.height / 6 / magnification * self.scale;

    NSRect GCPRect =
        NSMakeRect(
            (GCP.previewPoint.x / self.scale) - imageSize/2,
            (GCP.previewPoint.y / self.scale) - imageSize/2,
            imageSize,
            imageSize);

    GCP.view = [[NSImageView alloc] initWithFrame: GCPRect];
  
    GCP.view.image = self.document.GCPImage;
  
    [self addSubview: GCP.view];
}

// Pan around to the given GCP.
- (void) selectGCP: (GeoMapGCP *) GCP
{
    NSClipView * clipView = [self.scrollView contentView];

    NSSize size = clipView.bounds.size;
  
    NSPoint zoomPoint =
        NSMakePoint(
            (GCP.previewPoint.x / self.scale) - (size.width / 2),
            (GCP.previewPoint.y / self.scale) - (size.height / 2));
  
    [self scrollPoint: zoomPoint];
}

// Remove a GCP.
- (void) removeGCP: (GeoMapGCP *) GCP
{
    [GCP.view removeFromSuperview];
}

// Handle a mouse down event.
- (void) mouseDown: (NSEvent *) event
{
    // Remember where we parked.
    mouseDownLocation = [event locationInWindow];
    mouseDownRect = [self visibleRect];
  
    // Some tools need to start specific actions on mouse down.
    switch(self.document.toolMode)
    {
        // Drag the clip view around.
        case kPanTool:
            [[NSCursor closedHandCursor] push];
            break;
      
        // Start a selection marquee.
        case kZoomInTool:
            [self drawMarquee: event];
            break;
      
        case kSelectGCPTool:
            break;
      
        case kAddGCPTool:
            break;
      
        default:
            break;
    }
}

// Draw a selection marquee.
- (void) drawMarquee: (NSEvent *) event
{
    // Dequeue and handle mouse events until the user lets go of the mouse
    // button.
    NSPoint originalMouseLocation =
      [self convertPoint: [event locationInWindow] fromView: nil];
  
    selectionMarquee = NSZeroRect;
  
    while([event type] != NSLeftMouseUp)
    {
        event =
            [[self window]
                nextEventMatchingMask:
                    (NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
    
	      [self autoscroll: event];
	
        NSPoint currentMouseLocation =
            [self convertPoint: [event locationInWindow] fromView: nil];

	      // Figure out a new a selection rectangle based on the mouse location.
	      NSRect newMarqueeSelectionBounds =
            NSMakeRect(
                fmin(originalMouseLocation.x, currentMouseLocation.x),
                fmin(originalMouseLocation.y, currentMouseLocation.y),
                fabs(currentMouseLocation.x - originalMouseLocation.x),
                fabs(currentMouseLocation.y - originalMouseLocation.y));
    
	      if(!NSEqualRects(newMarqueeSelectionBounds, selectionMarquee))
        {
	          // Erase the old selection rectangle and draw the new one.
	          [self setNeedsDisplayInRect: selectionMarquee];
        
            selectionMarquee = newMarqueeSelectionBounds;
        
            [self setNeedsDisplayInRect: selectionMarquee];
        }
    }

    // Schedule the drawing of the place wherew the rubber band isn't anymore.
    [self setNeedsDisplayInRect: selectionMarquee];

    NSRect zoomRect = selectionMarquee;
  
    dispatch_async(
        dispatch_get_main_queue(),
        ^{
            if(!NSEqualSizes(zoomRect.size, NSZeroSize))
                [self zoomToRect: zoomRect];
            else
                [self mouseUp: event];
        });

    selectionMarquee = NSZeroRect;
}

// Handle a drag of the mouse. This only has an effect for the pan tool. The
// behaviour isn't quite right though.
- (void) mouseDragged: (NSEvent *) event
{
    NSPoint dragLocation = [event locationInWindow];

    NSRect dragRect = mouseDownRect;
    dragRect.origin.x -= (dragLocation.x - mouseDownLocation.x);
    dragRect.origin.y -= (dragLocation.y - mouseDownLocation.y);

    switch(self.document.toolMode)
    {
        case kPanTool:
            [self scrollRectToVisible: dragRect];
            break;
      
        default:
            break;
    }
}

// Handle a mouse up event.
- (void) mouseUp: (NSEvent *) event
{
    // The clip view is the big driver. With magnification, it shrinks down to
    // a fraction of the frame view.
    NSClipView * clipView = [self.scrollView contentView];
  
    // Get the mouse coordinates in the context of the clip view.
    NSPoint clipPosition =
        [clipView convertPoint: event.locationInWindow fromView: nil];

    NSPoint imagePosition = clipPosition;
  
    [self updateScale];
    
    imagePosition.x *= self.scale;
    imagePosition.y *= self.scale;

    // Take the appropriate action for the current tool.
    switch(self.document.toolMode)
    {
        // Stop dragging around.
        case kPanTool:
            [NSCursor pop];
            break;
      
        // Perform a zoom in.
        case kZoomInTool:
            if(magnification < self.scrollView.maxMagnification)
            {
                magnification *= kZoomInFactor;
 
                if(magnification > self.scrollView.maxMagnification)
                    magnification = self.scrollView.maxMagnification;

                [self zoomToPoint: clipPosition];
            }
            break;
    
        // Perform a zoom out.
        case kZoomOutTool:
            if(magnification > self.scrollView.minMagnification)
            {
                magnification *= kZoomOutFactor;
 
                if(magnification < self.scrollView.minMagnification)
                    magnification = self.scrollView.minMagnification;

                [self zoomToPoint: clipPosition];
            }
            break;

        // Select a GCP.
        case kSelectGCPTool:
            [self.document selectGCPAt: imagePosition];
            break;
      
        // Add a GCP.
        case kAddGCPTool:
            [self.document addGCP: imagePosition];
            break;

        default:
            break;
    }
}

// Zoom in on an image view. This uses the new magnification options for
// NSImageView. It is a bit clunky, but far better than IKImageView and easier
// to get up and running. Ideally, figure out how to do this properly at some
// point.
- (void) zoomToRect: (NSRect) rect
{
    // Now do a nice zoom with animation.
    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
                [[self.scrollView animator] magnifyToFitRect: rect];
            }
        completionHandler:
            ^{
                magnification = [self.scrollView magnification];
                [self updateScale];
            }];
}

// Zoom in on an image view. This uses the new magnification options for
// NSImageView. It is a bit clunky, but far better than IKImageView and easier
// to get up and running. Ideally, figure out how to do this properly at some
// point.
- (void) zoomToPoint: (NSPoint) point
{
    // Now do a nice zoom with animation.
    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
                [[self.scrollView animator]
                    setMagnification: magnification
                    centeredAtPoint: point];
            }
        completionHandler:
            ^{
                magnification = [self.scrollView magnification];
                [self updateScale];
            }];
}

// Keep track of the scale of the image.
- (void) updateScale
{
    // Now for the tricky part. The aspect ratio of the image probably doesn't
    // match the frame. I need to have the location and size of the padding.
    double frameAspectRatio = self.bounds.size.width / self.bounds.size.height;
    double imageAspectRatio = self.image.size.width / self.image.size.height;
  
    // The frame is proportionally wider than the image. There is extra space
    // on the sides.
    if(frameAspectRatio > imageAspectRatio)
        self.scale = self.image.size.height / self.bounds.size.height;
  
    // The frame is proportionally narrower than the iamge. There is extra space
    // at the top and bottom, or none at all.
    else
        self.scale = self.image.size.width / self.bounds.size.width;
}

@end
