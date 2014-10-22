//
//  GeoMapCoordinateValueTransformer.m
//  GeoMap
//
//  Created by John Daniel on 2014-10-21.
//  Copyright (c) 2014 John Daniel. All rights reserved.
//

#import "GeoMapCoordinateValueTransformer.h"

@implementation GeoMapCoordinateValueTransformer

+ (Class) transformedValueClass
{
    return [NSString class];
}

+ (BOOL) allowsReverseTransformation
{
    return NO;
}

- (id) transformedValue: (id) value
{
    if(!value)
        return nil;
  
    double coordinate = [value doubleValue];
  
    if(coordinate == 0.0)
      return @"";
      
    return [NSString stringWithFormat: @"%lf", coordinate];
}

- (id) reverseTransformedValue: (id) value
{
    if(!value)
        return nil;
  
    double coordinate;
  
    if([self parseCoordinate: value to: & coordinate])
        return [NSNumber numberWithDouble: coordinate];
  
    return nil;
}

// Parse a coordinate in various formats.
// Return YES if the coordinate is valid.
// I have to admit, a Swift optional would be handy here.
- (BOOL) parseCoordinate: (NSString *) value to: (double *) coordinate
{
    if(!coordinate)
        return NO;
  
    // Use a good 'ole scanner.
    NSScanner * scanner = [NSScanner scannerWithString: value];
  
    // First, look for directional indicators like NSEW or +=.
    // I won't use my other multiplier logic since I may have + and - too.
    double multiplier = 1;
  
    NSString * direction;
  
    BOOL found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet
                    characterSetWithCharactersInString: @"-NnSsEeWw"]
            intoString: & direction];

    if(found)
    {
        direction = [direction lowercaseString];
    
        if([direction hasPrefix: @"s"])
            multiplier = -1;
        else if([direction hasPrefix: @"w"])
            multiplier = -1;
        else if([direction hasPrefix: @"-"])
            multiplier = -1;
    }
  
    // Now look for degrees. If this is a stand-alone, fractional degree value,
    // I can go ahead and quit.
    double degrees;
  
    found = [scanner scanDouble: & degrees];
  
    if(!found)
        return NO;
  
    // Now look for some character that might signal the beginning of a DMS
    // format.
    found =
        [scanner
            scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
            intoString: NULL];
  
    // Look for a minutes value. Again, a fractional value is fine.
    double minutes;
  
    found = [scanner scanDouble: & minutes];

    // Maybe I am done.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }
  
    // Increment the degrees now.
    degrees += (minutes / 60.0);
  
    // Look for a units indicator and toss it.
    found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"m'’"]
            intoString: NULL];
  
    // This is fine. I'm done.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }

    // Now look for a seconds value. This may very well be a fractional.
    double seconds;
  
    found = [scanner scanDouble: & seconds];

    // If I didn't find anything, I'm still good.
    if(!found)
    {
        *coordinate = [self scanDirection: degrees scanner: scanner];
  
        return YES;
    }
  
    // Increment the degrees.
    degrees += (seconds / 60.0 / 60.0);
  
    // Scan and toss the seconds unit.
    found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"s\"”"]
            intoString: NULL];

    *coordinate = [self scanDirection: degrees scanner: scanner];

    return YES;
}

// Check for a trailing directional indicator.
- (double) scanDirection: (double) degrees scanner: (NSScanner *) scanner
{
    double multiplier = 1.0;
  
    NSString * direction = nil;
  
    BOOL found =
        [scanner
            scanCharactersFromSet:
                [NSCharacterSet characterSetWithCharactersInString: @"NnSsEeWw"]
            intoString: & direction];

    if(found)
    {
        direction = [direction lowercaseString];
    
        if([direction hasPrefix: @"s"])
            multiplier = -1;
        else if([direction hasPrefix: @"w"])
            multiplier = -1;
    }
  
    return degrees * multiplier;
}

@end
