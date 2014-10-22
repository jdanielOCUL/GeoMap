//
//  GeoMapReproject.h
//  GeoMap
//
//  Created by John Daniel on 2014-10-03.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#ifndef __GeoMap__GeoMapReproject__
#define __GeoMap__GeoMapReproject__

#ifdef __cplusplus
extern "C" {
#endif

// Native interface to GDAL.

// Reproject an image. This part isn't working yet. I am just feeding
// coordinates to gdal_translate and gdalwarp for now.
// Should this ever work, ideally it should be in an XPC.
typedef struct GCP
{
    double pixel;
    double line;
    double x;
    double y;
    const char * identifier;
} GCP;

int reproject(const char * input, const char * output, int gcpc, GCP * gcpv);

// Get coordinates from a projected image. This is working but should be in an
// XPC.
NSArray * getCoordinates(NSString * path);

// Get GCPs from a file.
NSArray * getGCPs(NSString * path);

#ifdef __cplusplus
}
#endif

#endif /* defined(__GeoMap__GeoMapReproject__) */
