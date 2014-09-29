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

@implementation GeoMapImageView
{
    NSPoint mouseDownLocation;
    NSRect mouseDownRect;
    double magnification;
}

- (void) awakeFromNib
  {
  magnification = 1.0;

  self.scrollView = [self enclosingScrollView];
  
  self.scrollView.minMagnification = 1.0;
  self.scrollView.maxMagnification = 100.0;
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
      
        default:
            break;
    }
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
                [self.scrollView
                    setMagnification: magnification centeredAtPoint: position];
            }
            break;
    
        case kZoomOutTool:
            if(magnification > self.scrollView.minMagnification)
            {
                magnification *= kZoomOutFactor;
                [self.scrollView
                    setMagnification: magnification centeredAtPoint: position];
            }
            break;

        default:
            break;
    }
}

@end
