//
//  GeoMapApplication.m
//  GeoMap
//
//  Created by John Daniel on 2014-10-14.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapApplication.h"

@implementation GeoMapApplicationDelegate

// Don't open an untitled file.
- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) sender
{
    return NO;
}

@end
