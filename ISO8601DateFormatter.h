/*ISO8601DateFormatter.h
 *
 *Created by Peter Hosey on 2009-04-11.
 *Copyright 2009–2013 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

///Which of ISO 8601's three date formats the formatter should produce.
typedef NS_ENUM(NSUInteger, ISO8601DateFormat) {
	///YYYY-MM-DD.
	ISO8601DateFormatCalendar,
	///YYYY-DDD, where DDD ranges from 1 to 366; for example, 2009-32 is 2009-02-01.
	ISO8601DateFormatOrdinal,
	///YYYY-Www-D, where ww ranges from 1 to 53 (the 'W' is literal) and D ranges from 1 to 7; for example, 2009-W05-07.
	ISO8601DateFormatWeek,
};

///The default separator for time values. Currently, this is ':'.
extern const unichar ISO8601DefaultTimeSeparatorCharacter;

/*!
 *This class converts dates to and from ISO 8601 strings. A good introduction to ISO 8601 is [“A summary of the international standard date and time notation” by Markus Kuhn](http://www.cl.cam.ac.uk/~mgk25/iso-time.html).
 *
 *Parsing can be done strictly, or not.
 *
 *When you parse strictly, the parser will only accept a string if the date is the entire string.
 *
 *When you parse loosely, leading whitespace is ignored, as is anything after the date.
 *The loose parser will return an NSDate for this string: `@" \t\r\n\f\t  2006-03-02!!!"`
 *Some of the methods take a pointer to an NSRange, with which they will tell you what part of the string was the date.
 *
 *Leading non-whitespace is never ignored; the string will be rejected, and `nil` returned. See the README that came with this addition.
 *
 *The loose parser provides some extensions that the strict parser doesn't.
 *For example, the standard says for "-DDD" (an ordinal date in the implied year) that the logical representation (meaning, hierarchically) would be "--DDD", but because that extra hyphen is "superfluous", it was omitted.
 *The loose parser will accept the extra hyphen; the strict parser will not.
 *A full list of these extensions is in the README file.
 */

@interface ISO8601DateFormatter: NSFormatter

@property(nonatomic, retain) NSTimeZone *defaultTimeZone;

#pragma mark Parsing
/*!
 *	@name	Parsing
 */

//As a formatter, this object converts strings to dates.

///If set to `YES`, disables various leniencies in how the formatter parses strings. Does not affect unparsing.
@property BOOL parsesStrictly;

/*!
 *	@brief	Parse a string into individual date components.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@returns	An NSDateComponents object containing most of the information parsed from the string, aside from the fraction of second and time zone (which are lost).
 *	@sa	dateComponentsFromString:timeZone:
 *	@sa	dateComponentsFromString:timeZone:range:fractionOfSecond:
 */
- (NSDateComponents *) dateComponentsFromString:(NSString *)string;
/*!
 *	@brief	Parse a string into individual date components.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@param	outTimeZone	If non-`NULL`, an NSTimeZone object or `nil` will be stored here, depending on whether the string specified a time zone.
 *	@returns	An NSDateComponents object containing most of the information parsed from the string, aside from the fraction of second (which is lost) and time zone.
 *	@sa	dateComponentsFromString:
 *	@sa	dateComponentsFromString:timeZone:range:fractionOfSecond:
 */
- (NSDateComponents *) dateComponentsFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone;
/*!
 *	@brief	Parse a string into individual date components.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@param	outTimeZone	If non-`NULL`, an NSTimeZone object or `nil` will be stored here, depending on whether the string specified a time zone.
 *	@param	outRange	If non-`NULL`, an NSRange structure will be stored here, identifying the substring of `string` that specified the date.
 *	@param	outFractionOfSecond	If non-`NULL`, an NSTimeInterval value will be stored here, containing the fraction of a second, if the string specified one. If it didn't, this will be set to zero.
 *	@returns	An NSDateComponents object containing most of the information parsed from the string, aside from the fraction of second and time zone.
 *	@sa	dateComponentsFromString:
 *	@sa	dateComponentsFromString:timeZone:
 */
- (NSDateComponents *) dateComponentsFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone range:(out NSRange *)outRange fractionOfSecond:(NSTimeInterval *)outFractionOfSecond;

/*!
 *	@brief	Parse a string.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@returns	An NSDate object containing most of the information parsed from the string, aside from the time zone (which is lost).
 *	@sa	dateComponentsFromString:
 *	@sa	dateFromString:timeZone:
 *	@sa	dateFromString:timeZone:range:
 */
- (NSDate *) dateFromString:(NSString *)string;
/*!
 *	@brief	Parse a string.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@param	outTimeZone	If non-`NULL`, an NSTimeZone object or `nil` will be stored here, depending on whether the string specified a time zone.
 *	@returns	An NSDate object containing most of the information parsed from the string, aside from the time zone.
 *	@sa	dateComponentsFromString:timeZone:
 *	@sa	dateFromString:
 *	@sa	dateFromString:timeZone:range:
 */
- (NSDate *) dateFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone;
/*!
 *	@brief	Parse a string into a single date, identified by an NSDate object.
 *
 *	@param	string	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@param	outTimeZone	If non-`NULL`, an NSTimeZone object or `nil` will be stored here, depending on whether the string specified a time zone.
 *	@param	outRange	If non-`NULL`, an NSRange structure will be stored here, identifying the substring of `string` that specified the date.
 *	@returns	An NSDate object containing most of the information parsed from the string, aside from the time zone.
 *	@sa	dateComponentsFromString:timeZone:range:fractionOfSecond:
 *	@sa	dateFromString:
 *	@sa	dateFromString:timeZone:
 */
- (NSDate *) dateFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone range:(out NSRange *)outRange;

#pragma mark Unparsing
/*!
 *	@name	Unparsing
 */

/*!
 *	@brief	Which ISO 8601 format to format dates in.
 *
 *	@details	See ISO8601DateFormat for possible values.
 */
@property ISO8601DateFormat format;
/*!
 *	@brief	Whether strings should include time of day.
 *
 *	@details	If `NO`, strings include only the date, nothing after it.
 *
 *	@sa	timeSeparator
 *	@sa	timeZoneSeparator
 */
@property BOOL includeTime;
/*!
 *	@brief	The character to use to separate components of the time of day.
 *
 *	@details	This is used in both parsing and unparsing.
 *
 * The default value is ISO8601DefaultTimeSeparatorCharacter.
 *
 *	@sa	includeTime
 *	@sa	timeZoneSeparator
 */
@property unichar timeSeparator;
/*!
 *	@brief	The character to use to separate the hour and minute in a time zone specification.
 *
 *	@details	This is used in both parsing and unparsing.
 *
 * If zero, no separator is inserted into time zone specifications.
 *
 * The default value is zero (no separator).
 *
 *	@sa	includeTime
 *	@sa	timeSeparator
 */
@property unichar timeZoneSeparator;

/*!
 *	@brief	Produce a string that represents a date in UTC.
 *
 *	@param	date	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@returns	A string that represents the date in UTC.
 *	@sa	stringFromDate:timeZone:
 */
- (NSString *) stringFromDate:(NSDate *)date;
/*!
 *	@brief	Produce a string that represents a date.
 *
 *	@param	date	The string to parse. Must represent a date in one of the ISO 8601 formats.
 *	@param	timeZone	An NSTimeZone object identifying the time zone in which to specify the date.
 *	@returns	A string that represents the date in the requested time zone, if possible.
 *
 *	@details	Not all dates are representable in all time zones (because of historical calendar changes, such as transitions from the Julian to the Gregorian calendar).
 *	For an example, see http://stackoverflow.com/questions/18663407/date-formatter-returns-nil-for-june .
 *	The ISO 8601 formatter *should* return `nil` in such cases.
 *
 *	@sa	stringFromDate:
 */
- (NSString *) stringFromDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone;

@end
