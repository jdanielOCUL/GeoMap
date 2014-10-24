//
//  GeoMapGCPTableView.m
//  GeoMap
//
//  Created by John Daniel on 2014-10-20.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapMetadataTableView.h"
#import "GeoMapDocument.h"

@implementation GeoMapMetadataTableView

// Delete table rows if any "delete" key gets pressed.
- (void) keyDown: (NSEvent *) theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
  
    switch(key)
    {
        case NSDeleteCharacter:
        case NSBackspaceCharacter:
        case NSDeleteFunctionKey:
          [self.document removeMetadata: nil];
          return;
    
        case NSRightArrowFunctionKey:
        case NSEnterCharacter:
        case 13:
          [self.document showMetadataPopover];
          break;
          
        default:
          break;
    }

    [super keyDown: theEvent];
}

@end
