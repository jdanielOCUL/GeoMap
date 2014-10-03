/* 
/ rasterlite.h
/
/ public RasterLite declarations
/
/ version 1.1a, 2011 November 12
/
/ Author: Sandro Furieri a.furieri@lqt.it
/
/ ------------------------------------------------------------------------------
/ 
/ Version: MPL 1.1/GPL 2.0/LGPL 2.1
/ 
/ The contents of this file are subject to the Mozilla Public License Version
/ 1.1 (the "License"); you may not use this file except in compliance with
/ the License. You may obtain a copy of the License at
/ http://www.mozilla.org/MPL/
/ 
/ Software distributed under the License is distributed on an "AS IS" basis,
/ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
/ for the specific language governing rights and limitations under the
/ License.
/
/ The Original Code is the RasterLite library
/
/ The Initial Developer of the Original Code is Alessandro Furieri
/ 
/ Portions created by the Initial Developer are Copyright (C) 2009
/ the Initial Developer. All Rights Reserved.
/
/ Alternatively, the contents of this file may be used under the terms of
/ either the GNU General Public License Version 2 or later (the "GPL"), or
/ the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
/ in which case the provisions of the GPL or the LGPL are applicable instead
/ of those above. If you wish to allow use of your version of this file only
/ under the terms of either the GPL or the LGPL, and not to allow others to
/ use your version of this file under the terms of the MPL, indicate your
/ decision by deleting the provisions above and replace them with the notice
/ and other provisions required by the GPL or the LGPL. If you do not delete
/ the provisions above, a recipient may use your version of this file under
/ the terms of any one of the MPL, the GPL or the LGPL.
/ 
*/

#ifdef DLL_EXPORT
#define RASTERLITE_DECLARE __declspec(dllexport)
#else
#define RASTERLITE_DECLARE extern
#endif

#ifndef _RASTERLITE_H
#define _RASTERLITE_H

#ifdef __cplusplus
extern "C"
{
#endif

#define GAIA_RGB_ARRAY	1001
#define GAIA_RGBA_ARRAY	1002
#define GAIA_ARGB_ARRAY	1003
#define GAIA_BGR_ARRAY	1004
#define GAIA_BGRA_ARRAY	1005

#define RASTERLITE_OK	0
#define RASTERLITE_ERROR	1

    RASTERLITE_DECLARE void *rasterliteOpen (const char *path,
					     const char *table_prefix);
    RASTERLITE_DECLARE void rasterliteClose (void *handle);
    RASTERLITE_DECLARE int rasterliteHasTransparentColor (void *handle);
    RASTERLITE_DECLARE void rasterliteSetTransparentColor (void *handle,
							   unsigned char red,
							   unsigned char green,
							   unsigned char blue);
    RASTERLITE_DECLARE int rasterliteGetTransparentColor (void *handle,
							  unsigned char *red,
							  unsigned char *green,
							  unsigned char *blue);
    RASTERLITE_DECLARE void rasterliteSetBackgroundColor (void *handle,
							  unsigned char red,
							  unsigned char green,
							  unsigned char blue);
    RASTERLITE_DECLARE int rasterliteGetBackgroundColor (void *handle,
							 unsigned char *red,
							 unsigned char *green,
							 unsigned char *blue);
    RASTERLITE_DECLARE int rasterliteGetRaster (void *handle, double cx,
						double cy, double pixel_size,
						int width, int height,
						int image_type,
						int quality_factor,
						void **raster, int *size);
    RASTERLITE_DECLARE int rasterliteGetRaster2 (void *handle, double cx,
						 double cy, double pixel_x_size,
						 double pixel_y_size, int width,
						 int height, int image_type,
						 int quality_factor,
						 void **raster, int *size);
    RASTERLITE_DECLARE int rasterliteGetRasterByRect (void *handle, double x1,
						      double y1, double x2,
						      double y2,
						      double pixel_size,
						      int width, int height,
						      int image_type,
						      int quality_factor,
						      void **raster, int *size);
    RASTERLITE_DECLARE int rasterliteGetRasterByRect2 (void *handle, double x1,
						       double y1, double x2,
						       double y2,
						       double pixel_x_size,
						       double pixel_y_size,
						       int width, int height,
						       int image_type,
						       int quality_factor,
						       void **raster,
						       int *size);
    RASTERLITE_DECLARE int rasterliteGetRawImage (void *handle, double cx,
						  double cy, double pixel_size,
						  int width, int height,
						  int raw_format,
						  void **raster, int *size);
    RASTERLITE_DECLARE int rasterliteGetRawImage2 (void *handle, double cx,
						   double cy,
						   double pixel_x_size,
						   double pixel_y_size,
						   int width, int height,
						   int raw_format,
						   void **raster, int *size);
    RASTERLITE_DECLARE int rasterliteGetRawImageByRect (void *handle, double x1,
							double y1, double x2,
							double y2,
							double pixel_size,
							int width, int height,
							int raw_format,
							void **raster,
							int *size);
    RASTERLITE_DECLARE int rasterliteGetRawImageByRect2 (void *handle,
							 double x1, double y1,
							 double x2, double y2,
							 double pixel_x_size,
							 double pixel_y_size,
							 int width, int height,
							 int raw_format,
							 void **raster,
							 int *size);
    RASTERLITE_DECLARE int rasterliteIsError (void *handle);
    RASTERLITE_DECLARE const char *rasterliteGetPath (void *handle);
    RASTERLITE_DECLARE const char *rasterliteGetTablePrefix (void *handle);
    RASTERLITE_DECLARE const char *rasterliteGetLastError (void *handle);
    RASTERLITE_DECLARE const char *rasterliteGetSqliteVersion (void *handle);
    RASTERLITE_DECLARE const char *rasterliteGetSpatialiteVersion (void
								   *handle);
    RASTERLITE_DECLARE const char *rasterliteGetVersion (void);

    RASTERLITE_DECLARE int rasterliteGetLevels (void *handle);
    RASTERLITE_DECLARE int rasterliteGetResolution (void *handle, int level,
						    double *pixel_x_size,
						    double *pixel_y_size,
						    int *tile_count);
    RASTERLITE_DECLARE int rasterliteGetSrid (void *handle, int *srid,
					      const char **auth_name,
					      int *auth_srid,
					      const char **ref_sys_name,
					      const char **proj4text);
    RASTERLITE_DECLARE int rasterliteGetExtent (void *handle, double *min_x,
						double *min_y, double *max_x,
						double *max_y);
    RASTERLITE_DECLARE int rasterliteExportGeoTiff (void *handle,
						    const char *img_path,
						    void *raster, int size,
						    double cx, double cy,
						    double pixel_x_size,
						    double pixel_y_size,
						    int width, int height);
    RASTERLITE_DECLARE int rasterliteGetBestAccess (void *handle,
						    double pixel_size,
						    double *pixel_x_size,
						    double *pixel_y_size,
						    sqlite3_stmt ** stmt,
						    int *use_rtree);

/*
/ utility functions returning a Raw image
*/
    RASTERLITE_DECLARE int rasterliteJpegBlobToRawImage (const void *blob,
							 int blob_size,
							 int raw_format,
							 void **raw, int *width,
							 int *height);
    RASTERLITE_DECLARE int rasterlitePngBlobToRawImage (const void *blob,
							int blob_size,
							int raw_format,
							void **raw, int *width,
							int *height);
    RASTERLITE_DECLARE int rasterliteGifBlobToRawImage (const void *blob,
							int blob_size,
							int raw_format,
							void **raw, int *width,
							int *height);
    RASTERLITE_DECLARE int rasterliteTiffBlobToRawImage (const void *blob,
							 int blob_size,
							 int raw_format,
							 void **raw, int *width,
							 int *height);

/*
/ utility functions generating an image file from a Raw Image
*/
    RASTERLITE_DECLARE int rasterliteRawImageToJpegFile (const void *raw,
							 int raw_format,
							 int width, int height,
							 const char *path,
							 int quality);
    RASTERLITE_DECLARE int rasterliteRawImageToPngFile (const void *raw,
							int raw_format,
							int width, int height,
							const char *path);
    RASTERLITE_DECLARE int rasterliteRawImageToGifFile (const void *raw,
							int raw_format,
							int width, int height,
							const char *path);
    RASTERLITE_DECLARE int rasterliteRawImageToGeoTiffFile (const void *raw,
							    int raw_format,
							    int width,
							    int height,
							    const char *path,
							    double x_size,
							    double y_size,
							    double xllcorner,
							    double yllcorner,
							    const char
							    *proj4text);

/*
/ utility functions generating an image mem-buffer from a Raw Image
*/
    RASTERLITE_DECLARE unsigned char *rasterliteRawImageToJpegMemBuf (const void
								      *raw,
								      int
								      raw_format,
								      int width,
								      int
								      height,
								      int *size,
								      int
								      quality);
    RASTERLITE_DECLARE unsigned char *rasterliteRawImageToPngMemBuf (const void
								     *raw,
								     int
								     raw_format,
								     int width,
								     int height,
								     int *size);
    RASTERLITE_DECLARE unsigned char *rasterliteRawImageToGifMemBuf (const void
								     *raw,
								     int
								     raw_format,
								     int width,
								     int height,
								     int *size);
    RASTERLITE_DECLARE unsigned char *rasterliteRawImageToTiffMemBuf (const void
								      *raw,
								      int
								      raw_format,
								      int width,
								      int
								      height,
								      int
								      *size);

#ifdef __cplusplus
}
#endif

#endif				/* _RASTERLITE_H */
