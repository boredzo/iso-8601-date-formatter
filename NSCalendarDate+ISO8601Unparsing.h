/*NSCalendarDate+ISO8601Unparsing.h
 *
 *Created by Peter Hosey on 2006-05-29.
 *Copyright 2006 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*This addition unparses dates to ISO 8601 strings. A good introduction to ISO 8601: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
 */

@interface NSCalendarDate(ISO8601Unparsing)

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime;
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime;
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime;

//includeTime: YES.
- (NSString *)ISO8601DateString;
- (NSString *)ISO8601WeekDateString;
- (NSString *)ISO8601OrdinalDateString;

@end

