#import "GeoMapToolbarItem.h"

@implementation GeoMapToolbarItem

- (void) validate
  {
  [self.control setEnabled: [[NSApplication sharedApplication] isActive]];
  }

@end
