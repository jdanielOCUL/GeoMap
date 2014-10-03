/**********************************************************************
 *
 * GEOS - Geometry Engine Open Source
 * http://geos.osgeo.org
 *
 * Copyright (C) 2001-2002 Vivid Solutions Inc.
 * Copyright (C) 2005 Refractions Research Inc.
 *
 * This is free software; you can redistribute and/or modify it under
 * the terms of the GNU Lesser General Public Licence as published
 * by the Free Software Foundation. 
 * See the COPYING file for more information.
 *
 **********************************************************************/

#ifndef GEOS_OPBUFFER_H
#define GEOS_OPBUFFER_H

namespace geos {
namespace operation { // geos.operation

/// Provides classes for computing buffers of geometries
namespace buffer { 
} // namespace geos.operation.buffer
} // namespace geos.operation
} // namespace geos

#include <GEOS/operation/buffer/BufferOp.h>

// This is needed for enum values
#include <GEOS/operation/buffer/OffsetCurveBuilder.h>

//#include <GEOS/operation/buffer/BufferBuilder.h>
//#include <GEOS/operation/buffer/OffsetCurveSetBuilder.h>
//#include <GEOS/operation/buffer/BufferSubgraph.h>
//#include <GEOS/operation/buffer/SubgraphDepthLocater.h>
//#include <GEOS/operation/buffer/RightmostEdgeFinder.h>

#endif // ndef GEOS_OPBUFFER_H

