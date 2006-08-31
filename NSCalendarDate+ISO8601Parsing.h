/*NSCalendarDate+ISO8601Parsing.h
 *
 *Created by Peter Hosey on 2006-02-20.
 *Copyright 2006 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*This addition parses ISO 8601 dates. A good introduction: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
 *
 *Parsing can be done strictly, or not. When you parse loosely, leading whitespace is ignored, as is anything after the date.
 *The loose parser will return an NSCalendarDate for this string: @" \t\r\n\f\t  2006-03-02!!!"
 *Leading non-whitespace will not be ignored; the string will be rejected, and nil returned. See the README that came with this addition.
 *
 *The strict parser will only accept a string if the date is the entire string. The above string would be rejected immediately, solely on these grounds.
 *Also, the loose parser provides some extensions that the strict parser doesn't.
 *For example, the standard says for "-DDD" (an ordinal date in the implied year) that the logical representation (meaning, hierarchically) would be "--DDD", but because that extra hyphen is "superfluous", it was omitted.
 *The loose parser will accept the extra hyphen; the strict parser will not.
 *A full list of these extensions is in the README file.
 */

//The default separator for time values. Currently, this is ':'.
extern unichar ISO8601ParserDefaultTimeSeparatorCharacter;

@interface NSCalendarDate(ISO8601Parsing)

//This method is the one that does all the work. All the others are convenience methods.
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str strictly:(BOOL)strict getRange:(out NSRange *)outRange;
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str strictly:(BOOL)strict;

//Strictly: NO.
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str timeSeparator:(unichar)timeSep getRange:(out NSRange *)outRange;
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str timeSeparator:(unichar)timeSep;
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str getRange:(out NSRange *)outRange;
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str;

@end
