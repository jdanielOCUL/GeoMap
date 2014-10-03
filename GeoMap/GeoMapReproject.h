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

typedef struct GCP
{
    double pixel;
    double line;
    double x;
    double y;
    const char * identifier;
} GCP;

int reproject(const char * input, const char * output, int gcpc, GCP * gcpv);

#ifdef __cplusplus
}
#endif

#endif /* defined(__GeoMap__GeoMapReproject__) */
