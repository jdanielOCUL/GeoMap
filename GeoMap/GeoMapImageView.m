//
//  GeoMapImageView.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-24.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapImageView.h"
#import "GeoMapDocument.h"

@implementation GeoMapImageView
{
    NSPoint mouseDownLocation;
    NSRect mouseDownRect;
}

- (void) mouseDown: (NSEvent *) event
{
    [[NSCursor closedHandCursor] push];
  
    mouseDownLocation = [event locationInWindow];
    mouseDownRect = [self visibleRect];
}

- (void) mouseDragged: (NSEvent *) event
{
    NSPoint dragLocation = [event locationInWindow];

    NSRect dragRect = mouseDownRect;
    dragRect.origin.x -= (dragLocation.x - mouseDownLocation.x);
    dragRect.origin.y -= (dragLocation.y - mouseDownLocation.y);
    [self scrollRectToVisible: dragRect];
}

- (void) mouseUp: (NSEvent *) event
{
    [NSCursor pop];
}

@end
