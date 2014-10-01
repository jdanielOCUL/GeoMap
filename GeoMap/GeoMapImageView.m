//
//  GeoMapImageView.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapImageView.h"
#import "GeoMapDocument.h"

#define kZoomInFactor  1.414214
#define kZoomOutFactor 0.7071068

@interface GeoMapImageView ()

@property (strong) NSColor * selectionFrameColor;
@property (strong) NSColor * selectionFillColor;

@end

@implementation GeoMapImageView
{
    NSPoint mouseDownLocation;
    NSRect mouseDownRect;
    double magnification;
    NSRect selectionMarquee;
}

- (void) awakeFromNib
{
    magnification = 1.0;

    self.scrollView = [self enclosingScrollView];

    self.scrollView.minMagnification = 1.0;
    self.scrollView.maxMagnification = 100.0;

    self.selectionFillColor =
        [NSColor colorWithCalibratedRed: .5 green: .5 blue: .5 alpha: .4];
}

- (void) drawRect: (NSRect) dirtyRect
{
    [super drawRect: dirtyRect];
  
    if(!NSEqualRects(selectionMarquee, NSZeroRect))
    {
        NSRect drawRect = NSInsetRect(selectionMarquee, 1, 1);
    
        NSBezierPath * marquee =
          [NSBezierPath bezierPathWithRect: drawRect];
    
        [self.selectionFillColor set];
        [marquee fill];
    }
}

- (void) mouseDown: (NSEvent *) event
{
    mouseDownLocation = [event locationInWindow];
    mouseDownRect = [self visibleRect];
  
    switch(self.document.toolMode)
    {
        case kPanTool:
            [[NSCursor closedHandCursor] push];
            break;
      
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

- (void) mouseUp: (NSEvent *) event
{
    // The clip view is the big driver. With magnification, it shrinks down to
    // a fraction of the frame view.
    NSClipView * clipView = [self.scrollView contentView];
  
    // Get the mouse coordinates in the context of the clip view.
    NSPoint clipPosition =
        [clipView convertPoint: event.locationInWindow fromView: nil];

    NSPoint imagePosition = clipPosition;
  
    // Now for the tricky part. The aspect ratio of the image probably doesn't
    // match the frame. I need to have the location and size of the padding.
    double frameAspectRatio = self.bounds.size.width / self.bounds.size.height;
    double imageAspectRatio = self.image.size.width / self.image.size.height;
  
    double scale = 1;
  
    // The frame is proportionally wider than the image. There is extra space
    // on the sides.
    if(frameAspectRatio > imageAspectRatio)
        scale = self.image.size.height / self.bounds.size.height;
  
    // The frame is proportionally narrower than the iamge. There is extra space
    // at the top and bottom, or none at all.
    else
        scale = self.image.size.width / self.bounds.size.width;
  
    imagePosition.x *= scale;
    imagePosition.y *= scale;

    NSLog(@"Mouse %@", NSStringFromPoint(imagePosition));
  
    switch(self.document.toolMode)
    {
        case kPanTool:
            [NSCursor pop];
            break;
      
        case kZoomInTool:
            if(magnification < self.scrollView.maxMagnification)
            {
                magnification *= kZoomInFactor;
 
                if(magnification > self.scrollView.maxMagnification)
                    magnification = self.scrollView.maxMagnification;

                [[self.scrollView animator]
                    setMagnification: magnification
                    centeredAtPoint: clipPosition];
            }
            break;
    
        case kZoomOutTool:
            if(magnification > self.scrollView.minMagnification)
            {
                magnification *= kZoomOutFactor;
 
                if(magnification < self.scrollView.minMagnification)
                    magnification = self.scrollView.minMagnification;

                [[self.scrollView animator]
                    setMagnification: magnification
                    centeredAtPoint: clipPosition];
            }
            break;

        case kSelectGCPTool:
            break;
      
        case kAddGCPTool:
            [self.document addGCP: imagePosition];
            break;

        default:
            break;
    }
}

- (void) zoomToRect: (NSRect) rect
{
    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
                [[self.scrollView animator] magnifyToFitRect: rect];
            }
        completionHandler:
            ^{
                magnification = [self.scrollView magnification];
            }];
}

@end
