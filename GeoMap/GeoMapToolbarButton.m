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
              bezierPathWithRoundedRect: self.bounds xRadius: 6 yRadius: 6];
    
        [[NSColor colorWithCalibratedRed: .6 green: .6 blue: .6 alpha: 1] set];
        [path fill];
    }
    
    [super drawRect: dirtyRect];
    
    // Drawing code here.
}

@end
