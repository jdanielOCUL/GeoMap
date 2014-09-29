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
    NSPoint position =
        [[self.scrollView contentView]
            convertPoint: event.locationInWindow fromView: nil];
  
    switch(self.document.toolMode)
    {
        case kPanTool:
            [NSCursor pop];
            break;
      
        case kZoomInTool:
            if(magnification < self.scrollView.maxMagnification)
            {
                magnification *= kZoomInFactor;
                [[self.scrollView animator]
                    setMagnification: magnification centeredAtPoint: position];
            }
            break;
    
        case kZoomOutTool:
            if(magnification > self.scrollView.minMagnification)
            {
                magnification *= kZoomOutFactor;
                [[self.scrollView animator]
                    setMagnification: magnification centeredAtPoint: position];
            }
            break;

        case kSelectGCPTool:
            break;
      
        case kAddGCPTool:
            break;

        default:
            break;
    }
}

- (void) zoomToRect: (NSRect) rect
{
    double zoomInX = self.frame.size.width / rect.size.width;
    double zoomInY = self.frame.size.height / rect.size.height;
  
    double zoomIn = fmin(zoomInX, zoomInY);
  
    NSRect idealRect = rect;
  
    idealRect.size.width =  self.frame.size.width / zoomIn;
    idealRect.size.height = self.frame.size.height / zoomIn;
  
    if(idealRect.size.width > rect.size.width)
    {
        rect.origin.x =
            rect.origin.x + (rect.size.width / 2) - (idealRect.size.width / 2);
        rect.size.width = idealRect.size.width;
    }
  
    if(idealRect.size.height > rect.size.height)
    {
        rect.origin.y =
            rect.origin.y + (rect.size.height / 2) - (idealRect.size.height / 2);
        rect.size.height = idealRect.size.height;
    }

    if(zoomIn > self.scrollView.maxMagnification)
      zoomIn = self.scrollView.maxMagnification;

    magnification = zoomIn;
  
    NSPoint centre = rect.origin;
  
    centre.x += rect.size.width / 2;
    centre.y += rect.size.height / 2;
  
    NSPoint newOrigin =
      [[self.scrollView contentView] convertPoint: rect.origin fromView: self];
  
    [NSAnimationContext
        runAnimationGroup:
            ^(NSAnimationContext * context)
            {
                [[self.scrollView animator]
                    setMagnification: magnification centeredAtPoint: centre];
            }
        completionHandler:
            ^{
                dispatch_async(
                    dispatch_get_main_queue(),
                    ^{
                        [[[self.scrollView contentView] animator]
                            scrollToPoint: newOrigin];                  
                    });
            }];
}

@end
