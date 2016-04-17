//
//  ISO8601ForCocoaTimeOnlyTests.m
//  ISO8601ForCocoa
//
//  Created by Peter Hosey on 2013-09-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import "ISO8601ForCocoaTimeOnlyTests.h"
#import "ISO8601DateFormatter.h"

static const NSTimeInterval gSecondsPerHour = 3600.0;
static const NSTimeInterval gSecondsPerMinute = 60.0;

@implementation ISO8601ForCocoaTimeOnlyTests
{
	ISO8601DateFormatter *_iso8601DateFormatter;
}

- (void) setUp {
	[super setUp];

	_iso8601DateFormatter = [[ISO8601DateFormatter alloc] init];
}

- (void) tearDown {
	_iso8601DateFormatter = nil;

	[super tearDown];
}

- (NSString *) dateStringWithHour:(NSTimeInterval)hour
	minute:(NSTimeInterval)minute
	second:(NSTimeInterval)second
	timeZone:(NSTimeZone *)timeZone
{
	NSString *format =
		  second > 0.0 ? @"T%02g:%02g:%02g"
		: minute > 0.0 ? @"T%02g:%02g"
		: hour > 0.0 ? @"T%02g"
		: @"no non-zero components provided!"
	;
	NSString *string = [NSString stringWithFormat:format, hour, minute, second];
	NSInteger secondsFromGMT = [timeZone secondsFromGMT];
	string = secondsFromGMT == 0.0
		? [string stringByAppendingString:@"Z"]
		: [string stringByAppendingFormat:@"%+03g%02g", secondsFromGMT / gSecondsPerHour, fabs(fmod(secondsFromGMT / gSecondsPerMinute, gSecondsPerMinute))];
	return string;
}

- (NSDateComponents *_Nonnull) dateComponentsForHour:(NSTimeInterval)hour
	minute:(NSTimeInterval)minute
	second:(NSTimeInterval)second
	timeZone:(NSTimeZone *_Nonnull)timeZone
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	calendar.timeZone = timeZone;


	NSDateComponents *components = [NSDateComponents new];
	components.hour = (NSInteger)hour;
	components.minute = (NSInteger)minute;
	if (! isnan(second)) {
		components.second = (NSInteger)second;
	}
	components.timeZone = timeZone;
	components.calendar = calendar;

	return components;
}
- (NSDate *_Nonnull) dateForTodayWithHour:(NSTimeInterval)hour
	minute:(NSTimeInterval)minute
	second:(NSTimeInterval)second
	timeZone:(NSTimeZone *_Nonnull)timeZone
{
	NSDateComponents *_Nonnull const components = [self dateComponentsForHour:hour minute:minute second:second timeZone:timeZone];
	NSCalendar *_Nonnull const calendar = components.calendar;

	NSDate *_Nonnull const now = [NSDate date];
	NSDate *_Nullable today = nil;
	[calendar rangeOfUnit:NSDayCalendarUnit startDate:&today interval:NULL forDate:now];

	NSDate *_Nonnull const date = [calendar dateByAddingComponents:components toDate:today options:0];
	return date;
}

- (NSString *_Nonnull const) ISORepresentationOfComponents:(NSDateComponents *_Nonnull) components {
	NSMutableString *_Nonnull const result = [NSMutableString stringWithCapacity:@"21016-05-01T12:34:56".length];
#define HAS_INTEGER(property) (components. property != NSUndefinedDateComponent)
#define APPEND_INTEGER(property) if (components. property == NSUndefinedDateComponent) [result appendString:@"??"]; else [result appendFormat:@"%ld", (long)components. property]
	if (HAS_INTEGER(year) || HAS_INTEGER(month) || HAS_INTEGER(weekOfYear) || HAS_INTEGER(day)) {
		APPEND_INTEGER(year);
		[result appendString:@"-"];
		if (! HAS_INTEGER(year))
			[result appendString:@"-"];
		APPEND_INTEGER(month);
		APPEND_INTEGER(weekOfYear);
		[result appendString:@"-"];
		APPEND_INTEGER(day);
	}
	if (HAS_INTEGER(hour) || HAS_INTEGER(minute) || HAS_INTEGER(second)) {
		[result appendString:@"T"];
		APPEND_INTEGER(hour);
		[result appendString:@":"];
		APPEND_INTEGER(minute);
		[result appendString:@":"];
		APPEND_INTEGER(second);
	}
	return result;
}

- (void) attemptToParseString:(NSString *)dateString
	expectDateComponents:(NSDateComponents *_Nonnull)expectedComponents
	expectTimeZoneWithHoursFromGMT:(NSTimeInterval)expectedHoursFromGMT
{
	const NSTimeInterval expectedSecondsFromGMT = expectedHoursFromGMT * gSecondsPerHour;

	NSTimeZone *timeZone = nil;
	NSDate *date = [_iso8601DateFormatter dateFromString:dateString timeZone:&timeZone];
	XCTAssertNotNil(date, @"Parsing a valid ISO 8601 date string (%@) should return an NSDate object", dateString);
	XCTAssertNotNil(timeZone, @"Parsing a valid ISO 8601 date string (%@) that specifies a time zone offset should return an NSTimeZone object", dateString);
	NSDateComponents *_Nullable const components = [_iso8601DateFormatter dateComponentsFromString:dateString timeZone:&timeZone];
	XCTAssertNotNil(components, @"Parsing a valid ISO 8601 date string (%@) should return an NSDate object", dateString);
	XCTAssertNotNil(timeZone, @"Parsing a valid ISO 8601 date string (%@) that specifies a time zone offset should return an NSTimeZone object", dateString);
	//The formatter doesn't set these and I don't currently want to make it API that it will. -- boredzo
	if (components.calendar == nil) components.calendar = expectedComponents.calendar;
	if (components.timeZone == nil) components.timeZone = expectedComponents.timeZone;
	XCTAssertEqualObjects(expectedComponents, components, @"Parsing a valid ISO 8601 date string (%@) should have returned %@, not %@", dateString, [self ISORepresentationOfComponents:expectedComponents], [self ISORepresentationOfComponents:components]);
	NSInteger secondsFromGMTForDate = [timeZone secondsFromGMTForDate:date];
	XCTAssertEqual(secondsFromGMTForDate, (NSInteger)expectedSecondsFromGMT, @"Time zone parsed from '%@' should be %f seconds (%f hours) from GMT, not %ld seconds (%f hours)", dateString, expectedSecondsFromGMT, expectedHoursFromGMT, secondsFromGMTForDate, secondsFromGMTForDate / gSecondsPerHour);
}

/*TODO: These tests are inherently flaky.
 *You can't build a stable test on [NSDate date]—the results will vary according to the current date and are likely to vary by time zone.
 *These tests should probably use some sort of “default date” property of the date formatter, and the date formatter should fill in from the current date if and only if its default date is not set.
 *Additionally, the behavior we're testing is probably best modeled by dateComponentsFromString::, not dateFromString::, once dCFS:: is changed to return only the components that were specified by the string.
 */

- (void) testParsingStringWithOnlyHourMinuteSecondZulu {
	NSTimeInterval hour = 14.0, minute = 23.0, second = 56.0;
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	NSString *string = [self dateStringWithHour:hour minute:minute second:second timeZone:timeZone];
	NSDateComponents *_Nonnull const components = [self dateComponentsForHour:hour minute:minute second:second timeZone:timeZone];
	[self attemptToParseString:string
		expectDateComponents:components
		expectTimeZoneWithHoursFromGMT:0.0];
}

- (void) testParsingStringWithOnlyHourMinuteZulu {
	NSTimeInterval hour = 14.0, minute = 23.0;
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	NSString *string = [self dateStringWithHour:hour minute:minute second:0.0 timeZone:timeZone];
	NSDateComponents *_Nonnull const components = [self dateComponentsForHour:hour minute:minute second:NAN timeZone:timeZone];
	[self attemptToParseString:string
		expectDateComponents:components
		expectTimeZoneWithHoursFromGMT:0.0];
}

- (void) testParsingStringWithOnlyHourMinuteSecondAndTimeZone {
	NSTimeInterval hour = 14.0, minute = 23.0, second = 56.0;
	NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(NSInteger)(-8.0 * gSecondsPerHour)];
	NSString *string = [self dateStringWithHour:hour minute:minute second:second timeZone:timeZone];
	NSDateComponents *_Nonnull const components = [self dateComponentsForHour:hour minute:minute second:second timeZone:timeZone];
	[self attemptToParseString:string
		expectDateComponents:components
		expectTimeZoneWithHoursFromGMT:-8.0];
}

- (void) testParsingStringWithOnlyHourMinuteAndTimeZone {
	NSTimeInterval hour = 14.0, minute = 23.0;
	NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(NSInteger)(-8.0 * gSecondsPerHour)];
	NSString *string = [self dateStringWithHour:hour minute:minute second:0.0 timeZone:timeZone];
	NSDateComponents *_Nonnull const components = [self dateComponentsForHour:hour minute:minute second:NAN timeZone:timeZone];
	[self attemptToParseString:string
		expectDateComponents:components
		expectTimeZoneWithHoursFromGMT:-8.0];
}

@end
