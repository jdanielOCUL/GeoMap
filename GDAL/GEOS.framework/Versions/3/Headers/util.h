/**********************************************************************
 *
 * GEOS - Geometry Engine Open Source
 * http://geos.osgeo.org
 *
 * Copyright (C) 2001-2002 Vivid Solutions Inc.
 * Copyright (C) 2006 Refractions Research Inc.
 *
 * This is free software; you can redistribute and/or modify it under
 * the terms of the GNU Lesser General Public Licence as published
 * by the Free Software Foundation. 
 * See the COPYING file for more information.
 *
 **********************************************************************
 *
 * Utility header to retain a bit of backward compatibility.
 * Try to avoid including this header directly.
 *
 **********************************************************************/

#ifndef GEOS_UTIL_H
#define GEOS_UTIL_H

//#include <GEOS/util/AssertionFailedException.h>
#include <GEOS/util/GEOSException.h>
#include <GEOS/util/IllegalArgumentException.h>
#include <GEOS/util/TopologyException.h>
//#include <GEOS/util/UnsupportedOperationException.h>
//#include <GEOS/util/CoordinateArrayFilter.h>
//#include <GEOS/util/UniqueCoordinateArrayFilter.h>
#include <GEOS/util/GeometricShapeFactory.h>
//#include <GEOS/util/math.h>

//
// Private macros definition 
// 

namespace geos
{
    template<class T>
    void ignore_unused_variable_warning(T const& ) {}
}


#endif // GEOS_UTIL_H
