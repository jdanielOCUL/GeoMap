//
//  GCP.m
//  GeoMap
//
//  Created by John Daniel on 2014-09-29.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapGCP.h"

@implementation GeoMapGCP

@synthesize latitude = myLatitude;
@synthesize longitude = myLongitude;

- (double) latitude
{
    return myLatitude;
}

- (void) setLatitude: (double) latitude
{
    if(myLatitude != latitude)
    {
        [self willChangeValueForKey: @"latitude"];
    
        myLatitude = latitude;
    
        if(!self.latitudeString)
            self.latitudeString =
                [NSString stringWithFormat: @"%lf", latitude];
    
        [self didChangeValueForKey: @"latitude"];
    }
}

- (double) longitude
{
    return myLongitude;
}

- (void) setLongitude: (double) longitude
{
    if(myLongitude != longitude)
    {
        [self willChangeValueForKey: @"longitude"];
    
        myLongitude = longitude;
    
        if(!self.longitudeString)
            self.longitudeString =
                [NSString stringWithFormat: @"%lf", longitude];
    
        [self didChangeValueForKey: @"longitude"];
    }
}

@end
