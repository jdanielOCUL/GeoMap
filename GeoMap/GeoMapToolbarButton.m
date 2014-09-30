//
//  GeoMapToolbarButton.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-30.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapToolbarButton.h"

@implementation GeoMapToolbarButton

- (void) drawRect: (NSRect) dirtyRect
{
    if(self.state == NSOnState)
    {
        NSBezierPath * path =
          [NSBezierPath
              bezierPathWithRoundedRect: self.bounds xRadius: 8 yRadius: 8];
    
        [[NSColor grayColor] set];
        [path fill];
    }
    
    [super drawRect: dirtyRect];
    
    // Drawing code here.
}

@end
