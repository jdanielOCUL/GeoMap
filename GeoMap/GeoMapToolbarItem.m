#import "GeoMapToolbarItem.h"

@implementation GeoMapToolbarItem

// Disable toolbar items when the application isn't active.
- (void) validate
  {
  [self.control setEnabled: [[NSApplication sharedApplication] isActive]];
  }

@end
