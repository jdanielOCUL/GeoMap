//
//  GeoMapReproject.cpp
//  GeoMap
//
//  Created by John Daniel on 2014-10-03.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#include "GeoMapGDAL.h"
#include <stdio.h>

#include "GDAL/gdalwarper.h"
#include "GDAL/ogr_spatialref.h"
#include "GDAL/cpl_conv.h" // for CPLMalloc()
#include "GDAL/gdal.h"
#include "GDAL/gdal_alg.h"
#include "GDAL/ogr_srs_api.h"
#include "GDAL/cpl_string.h"
#include "GDAL/cpl_conv.h"
#include "GDAL/cpl_multiproc.h"
#import "GeoMapGCP.h"
#import "GeoMapMetadata.h"

// Reproject an image. This part isn't working yet. I am just feeding
// coordinates to gdal_translate and gdalwarp for now.
// Should this ever work, ideally it should be in an XPC.
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
  
    //CPLErr eErr =
        GDALSuggestedWarpOutput(
            hSrcDS,
            GDALGenImgProjTransform,
            hTransformArg,
            adfDstGeoTransform,
            & nPixels,
            & nLines);
    //CPLAssert( eErr == CE_None );

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

// Get coordinates from a projected image. This is working but should be in an
// XPC.

static void GDALInfoReportCorner(
    GDALDatasetH hDataset,
    OGRCoordinateTransformationH hTransform,
    double x,
    double y,
    NSMutableArray * coordinates);

NSArray * getCoordinates(NSString * path)
{
    GDALAllRegister();

    GDALDatasetH hDataset =
        GDALOpen([path fileSystemRepresentation], GA_ReadOnly);

    if(!hDataset)
        return nil;

    OGRCoordinateTransformationH hTransform = NULL;
    const char * pszProjection = NULL;
    double adfGeoTransform[6];

    if(GDALGetGeoTransform( hDataset, adfGeoTransform ) == CE_None)
        pszProjection = GDALGetProjectionRef(hDataset);

    if(pszProjection && strlen(pszProjection) > 0)
    {
        OGRSpatialReferenceH hProj, hLatLong = NULL;

        hProj = OSRNewSpatialReference(pszProjection);
        if( hProj != NULL )
            hLatLong = OSRCloneGeogCS(hProj);

        if(hLatLong)
        {
            CPLPushErrorHandler(CPLQuietErrorHandler);
            hTransform = OCTNewCoordinateTransformation(hProj, hLatLong);
            CPLPopErrorHandler();
            
            OSRDestroySpatialReference(hLatLong);
        }

        if(hProj)
            OSRDestroySpatialReference(hProj);
    }

    NSMutableArray * result = [NSMutableArray array];
  
    // Lower right.
    GDALInfoReportCorner(
        hDataset, hTransform,
        GDALGetRasterXSize(hDataset),
        GDALGetRasterYSize(hDataset),
        result);
  
    // Upper left.
    GDALInfoReportCorner(hDataset, hTransform, 0.0, 0.0, result);

    if(hTransform)
        OCTDestroyCoordinateTransformation(hTransform);
  
    GDALClose(hDataset);
    
    GDALDestroyDriverManager();

    CPLDumpSharedList(NULL);
    CPLCleanupTLS();
  
    return result;
}

static void GDALInfoReportCorner(
    GDALDatasetH hDataset,
    OGRCoordinateTransformationH hTransform,
    double x,
    double y,
    NSMutableArray * coordinates)
{
    double adfGeoTransform[6];
        
    if(GDALGetGeoTransform( hDataset, adfGeoTransform ) == CE_None)
    {
        double dfGeoX =
            adfGeoTransform[0] +
            adfGeoTransform[1] *
            x +
            adfGeoTransform[2] *
            y;
    
        double dfGeoY =
            adfGeoTransform[3] +
            adfGeoTransform[4] *
            x +
            adfGeoTransform[5] *
            y;

        if(fabs(dfGeoX) <= 180 && fabs(dfGeoY) <= 90)
        {
            [coordinates
                addObject: [NSString stringWithFormat: @"%12.7f", dfGeoY]];
            [coordinates
                addObject: [NSString stringWithFormat: @"%12.7f", dfGeoX]];
        }
        else
        {
            [coordinates
                addObject: [NSString stringWithFormat: @"%12.3f", dfGeoY]];
            [coordinates
                addObject: [NSString stringWithFormat: @"%12.3f", dfGeoX]];
        }
    }
}

// Get GCPs from a file.
NSArray * getGCPs(NSString * path)
{
    GDALAllRegister();

    GDALDatasetH hDataset =
        GDALOpen([path fileSystemRepresentation], GA_ReadOnly);

    if(!hDataset)
        return nil;

    NSMutableArray * result = [NSMutableArray array];
  
    int GCPCount = GDALGetGCPCount(hDataset);
  
    const GDAL_GCP * GCPs = GDALGetGCPs(hDataset);
  
    double width = GDALGetRasterXSize(hDataset);
    double height = GDALGetRasterYSize(hDataset);
  
    for(int i = 0; i < GCPCount; ++i)
    {
        GeoMapGCP * GCP = [GeoMapGCP new];
    
        GCP.normalizedImagePoint =
            NSMakePoint(GCPs[i].dfGCPPixel / width, GCPs[i].dfGCPLine / height);
        GCP.latitude = GCPs[i].dfGCPY;
        GCP.longitude = GCPs[i].dfGCPX;
    
        [result addObject: GCP];
    }
  
    GDALClose(hDataset);
    
    GDALDestroyDriverManager();

    CPLDumpSharedList(NULL);
    CPLCleanupTLS();
  
    return result;
}

// Get metadata from a file.
NSArray * getMetadata(NSString * path)
{
    GDALAllRegister();

    GDALDatasetH hDataset =
        GDALOpen([path fileSystemRepresentation], GA_ReadOnly);

    if(!hDataset)
        return nil;

    NSMutableArray * result = [NSMutableArray array];
  
    char ** domains = GDALGetMetadataDomainList(hDataset);
  
    while(char * domain = *domains++)
    {
        char ** metadata = GDALGetMetadata(hDataset, domain);
    
        while(char * keyValue = *metadata++)
        {
            NSString * keyValueString =
              [NSString stringWithUTF8String: keyValue];
        
            NSMutableArray * parts =
              [NSMutableArray
                  arrayWithArray:
                      [keyValueString componentsSeparatedByString: @"="]];
        
            if(parts.count >= 2)
            {
                NSString * key = [parts firstObject];
            
                [parts removeObjectAtIndex: 0];
            
                NSString * value = [parts componentsJoinedByString: @"="];
            
                GeoMapMetadata * metadata = [GeoMapMetadata new];
            
                metadata.domain = [NSString stringWithUTF8String: domain];
                metadata.key = key;
                metadata.value = value;
            
                [result addObject: metadata];
            }
        }
    }
  
    GDALClose(hDataset);
    
    GDALDestroyDriverManager();

    CPLDumpSharedList(NULL);
    CPLCleanupTLS();
  
    return result;
}

// Set metadata in a file.
void setMetadata(NSString * path, NSArray * metadataList)
{
    GDALAllRegister();

    GDALDatasetH hDataset =
        GDALOpen([path fileSystemRepresentation], GA_ReadOnly);

    if(!hDataset)
        return;

    for(GeoMapMetadata * metadata in metadataList)
    {
        GDALSetMetadataItem(
            hDataset,
            [metadata.key UTF8String],
            [metadata.value UTF8String],
            [metadata.domain UTF8String]);
    }
  
    GDALClose(hDataset);
    
    GDALDestroyDriverManager();

    CPLDumpSharedList(NULL);
    CPLCleanupTLS();
}

