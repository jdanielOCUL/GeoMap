//
//  GeoMapReproject.cpp
//  GeoMap
//
//  Created by John Daniel on 2014-10-03.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#include "GeoMapReproject.h"
#include <stdio.h>

#include "GDAL/gdalwarper.h"
#include "GDAL/ogr_spatialref.h"
#include "GDAL/cpl_conv.h" // for CPLMalloc()

int reproject(const char * input, const char * output, int gcpc, GCP * gcpv)
{
    printf("Reprojecting from %s to %s", input, output);
  
    // Create my GDAL GCPs.
    GDAL_GCP * gcps = (GDAL_GCP *)malloc(gcpc * sizeof(GDAL_GCP));
  
    for(int i = 0; i < gcpc; ++i)
    {
        gcps[i].dfGCPPixel = gcpv[i].pixel;
 			  gcps[i].dfGCPLine  = gcpv[i].line;
        gcps[i].dfGCPX = gcpv[i].x;
 			  gcps[i].dfGCPY = gcpv[i].y;
 			  gcps[i].pszId = (char *)gcpv[i].identifier;
    }
  
    // Open the source file.

    GDALDatasetH hSrcDS = GDALOpen(input, GA_ReadOnly);
    CPLAssert(hSrcDS != NULL);
    GDALSetGCPs(hSrcDS, gcpc, gcps, "+proj=latlong +datum=WGS84");
  
    // Setup output coordinate system that is UTM 11 WGS84.

    OGRSpatialReference oSRS;

    oSRS.SetUTM(11, TRUE);
    oSRS.SetWellKnownGeogCS("WGS84");

    char * pszDstWKT = NULL;

    oSRS.exportToWkt(& pszDstWKT);

    void * hTransformArg =
        GDALCreateGenImgProjTransformer(
            hSrcDS, NULL, NULL, pszDstWKT, FALSE, 0, 1);
    CPLAssert( hTransformArg != NULL );

    // Get approximate output georeferenced bounds and resolution for file. 

    double adfDstGeoTransform[6];
  
    int nPixels = 0, nLines = 0;
  
    CPLErr eErr =
        GDALSuggestedWarpOutput(
            hSrcDS,
            GDALGenImgProjTransform,
            hTransformArg,
            adfDstGeoTransform,
            & nPixels,
            & nLines);
    CPLAssert( eErr == CE_None );

    GDALDestroyGenImgProjTransformer( hTransformArg );

    // Create the output file.  

    GDALDriverH hDriver = GDALGetDriverByName("GTiff");
    CPLAssert( hDriver != NULL );

    GDALDataType eDT = GDALGetRasterDataType(GDALGetRasterBand(hSrcDS, 1));

    GDALDatasetH hDstDS =
        GDALCreate(
            hDriver,
            output,
            nPixels,
            nLines,
            GDALGetRasterCount(hSrcDS),
            eDT,
            NULL);
    
    CPLAssert( hDstDS != NULL );

    // Write out the projection definition. 

    GDALSetProjection(hDstDS, pszDstWKT);
    GDALSetGeoTransform(hDstDS, adfDstGeoTransform);

    // Copy the color table, if required.

    GDALColorTableH hCT =
        GDALGetRasterColorTable( GDALGetRasterBand(hSrcDS, 1));
    if( hCT != NULL )
        GDALSetRasterColorTable( GDALGetRasterBand(hDstDS,1), hCT );

	  GDALWarpOptions * psWarpOptions = GDALCreateWarpOptions();
	
    psWarpOptions->hSrcDS = hSrcDS;
	  psWarpOptions->hDstDS = hDstDS;
	  psWarpOptions->nBandCount = GDALGetRasterCount(hSrcDS);
	  psWarpOptions->panSrcBands =
        (int *) CPLMalloc(sizeof(int)*psWarpOptions->nBandCount);
  
	  psWarpOptions->panDstBands =
        (int *) CPLMalloc(sizeof(int)*psWarpOptions->nBandCount);
  
    for(int i = 0; i < psWarpOptions->nBandCount; ++i)
        psWarpOptions->panDstBands[i] = i + 1;
  
    psWarpOptions->pfnProgress = GDALTermProgress;
	  psWarpOptions->pTransformerArg =
        GDALCreateGenImgProjTransformer(
            hSrcDS,
            GDALGetProjectionRef(hSrcDS),
            hDstDS,
            GDALGetProjectionRef(hDstDS),
            TRUE,
            0,
            1);
  
	  psWarpOptions->pfnTransformer = GDALGenImgProjTransform;

	  GDALWarpOperation oOperation;
  
    oOperation.Initialize(psWarpOptions);
	
    oOperation.ChunkAndWarpImage(
        0,
        0,
        GDALGetRasterXSize(hDstDS),
        GDALGetRasterYSize(hDstDS));

    GDALDestroyGenImgProjTransformer(psWarpOptions->pTransformerArg);
	  GDALDestroyWarpOptions( psWarpOptions );

	  GDALClose( hDstDS );
	  GDALClose( hSrcDS );

    return 1;
}

