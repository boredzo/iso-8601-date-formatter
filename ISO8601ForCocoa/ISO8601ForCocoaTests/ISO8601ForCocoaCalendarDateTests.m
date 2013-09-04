//
//  ISO8601ForCocoaCalendarDateTests.m
//  ISO8601ForCocoaCalendarDateTests
//
//  Created by Peter Hosey on 2013-05-27.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "ISO8601ForCocoaCalendarDateTests.h"
#import "ISO8601DateFormatter.h"
#import "NSLocale+UnitTestSwizzling.h"

typedef NS_ENUM(unichar, PRHNamedCharacter) {
	SNOWMAN = 0x2603
};

static const NSTimeInterval gSecondsPerHour = 3600.0;

@interface ISO8601ForCocoaCalendarDateTests ()

- (void)        attemptToParseString:(NSString *)dateString
expectTimeIntervalSinceReferenceDate:(NSTimeInterval)expectedTimeIntervalSinceReferenceDate
	  expectTimeZoneWithHoursFromGMT:(NSTimeInterval)expectedHoursFromGMT;

@end

@implementation ISO8601ForCocoaCalendarDateTests
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

- (void)        attemptToParseString:(NSString *)dateString
expectTimeIntervalSinceReferenceDate:(NSTimeInterval)expectedTimeIntervalSinceReferenceDate
	  expectTimeZoneWithHoursFromGMT:(NSTimeInterval)expectedHoursFromGMT
{
	const NSTimeInterval expectedSecondsFromGMT = expectedHoursFromGMT * gSecondsPerHour;

	NSTimeZone *timeZone = nil;
	NSDate *date = [_iso8601DateFormatter dateFromString:dateString timeZone:&timeZone];
	STAssertNotNil(date, @"Parsing a valid ISO 8601 calendar date should return an NSDate object");
	STAssertNotNil(timeZone, @"Parsing a valid ISO 8601 calendar date that specifies a time zone offset should return an NSTimeZone object");
	STAssertEqualsWithAccuracy([date timeIntervalSinceReferenceDate], expectedTimeIntervalSinceReferenceDate, 0.0001, @"Date parsed from '%@' should be %f seconds since the reference date", dateString, expectedTimeIntervalSinceReferenceDate);
	NSInteger secondsFromGMTForDate = [timeZone secondsFromGMTForDate:date];
	STAssertEquals(secondsFromGMTForDate, (NSInteger)expectedSecondsFromGMT, @"Time zone parsed from '%@' should be %ld seconds (%f hours) from GMT, not %ld seconds (%f hours)", dateString, expectedSecondsFromGMT, expectedHoursFromGMT, secondsFromGMTForDate, secondsFromGMTForDate / gSecondsPerHour);
}

- (void) attemptToUnparseDateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeIntervalSinceReferenceDate
                                                   timeZoneName:(NSString *)tzName
			                                   expectDateString:(NSString *)expectedDateString
							                        includeTime:(bool)includeTime
{
	NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate];
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:tzName];
	_iso8601DateFormatter.includeTime = includeTime;

	NSString *dateString = [_iso8601DateFormatter stringFromDate:date timeZone:timeZone];
	STAssertNotNil(dateString, @"Unparsing a date should return a string");
	STAssertEqualObjects(dateString, expectedDateString, @"Got unexpected output for date with time interval since reference date %f in time zone %@", timeIntervalSinceReferenceDate, timeZone);
}

- (void) testParsingDateInPacificStandardTime {
	static NSString *const dateString = @"2013-01-01T01:01:01-0800";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 378723661.0;
	static NSTimeInterval const expectedHoursFromGMT = -8.0;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInPacificStandardTime {
	NSTimeInterval timeIntervalSinceReferenceDate = 378723661.0;
	NSString *expectedDateString = @"2013-01-01T01:01:01-0800";
	NSString *tzName = @"America/Los_Angeles";

	[self attemptToUnparseDateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate
		timeZoneName:tzName
		expectDateString:expectedDateString
		includeTime:true];
}

- (void) testParsingDateInPacificDaylightTime {
	static NSString *const dateString = @"2013-08-01T01:01:01-0700";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 397036861.0;
	static NSTimeInterval const expectedHoursFromGMT = -7.0;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInPacificDaylightTime {
	NSTimeInterval timeIntervalSinceReferenceDate = 397036861.0;
	NSString *expectedDateString = @"2013-08-01T01:01:01-0700";
	NSString *tzName = @"America/Los_Angeles";

	[self attemptToUnparseDateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate
		timeZoneName:tzName
		expectDateString:expectedDateString
		includeTime:true];
}

- (void) testUnparsingDateAtRiskOfAccidentalPM {
    // swizzle [NSLocale currentLocale] with a method that returns a mock object which forces "12 hour mode" on the de_DE locale which naturally uses 24 hour formatting.
    SwizzleClassMethod([NSLocale class], @selector(currentLocale), @selector(mockCurrentLocale));

	_iso8601DateFormatter.includeTime = YES;
	NSTimeInterval timeIntervalSinceReferenceDate = 397143300.0;
	NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate];
	NSTimeZone *tz;

	tz = [NSTimeZone timeZoneWithName:@"GMT"];
	STAssertEqualObjects([_iso8601DateFormatter stringFromDate:date timeZone:tz], @"2013-08-02T13:35:00Z", @"Unexpected date string for 13:35 on 2 August 2013 in London");

	tz = [NSTimeZone timeZoneWithName:@"Europe/London"];
	STAssertEqualObjects([_iso8601DateFormatter stringFromDate:date timeZone:tz], @"2013-08-02T14:35:00+0100", @"Unexpected date string for 13:35 on 2 August 2013 in London");
    
    // swizzle back so only this test is affected
    SwizzleClassMethod([NSLocale class], @selector(currentLocale), @selector(mockCurrentLocale));
}

- (void) testParsingDateInGreenwichMeanTime {
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 381373261.0;
	static NSTimeInterval const expectedHoursFromGMT = -0.0;

	[self attemptToParseString:@"2013-02-01T01:01:01-0000"
		expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
		expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
	[self attemptToParseString:@"2013-02-01T01:01:01+0000"
		expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
		expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
	[self attemptToParseString:@"2013-02-01T01:01:01Z"
		expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
		expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInGreenwichMeanTime {
	NSTimeInterval timeIntervalSinceReferenceDate = 381373261.0;
	NSString *expectedDateString = @"2013-02-01T01:01:01Z";
	NSString *tzName = @"GMT";

	[self attemptToUnparseDateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate
		timeZoneName:tzName
		expectDateString:expectedDateString
		includeTime:true];
}

- (void) testParsingDateWithFractionOfSecondWithoutLosingPrecision {
  NSDate *referenceDate = [_iso8601DateFormatter dateFromString:@"2013-02-01T01:01:01-0000"];
  NSDate *referenceDateWithAddedMilliseconds = [_iso8601DateFormatter dateFromString:@"2013-02-01T01:01:01.123-0000"];
  
  NSTimeInterval differenceBetweenDates = [referenceDateWithAddedMilliseconds timeIntervalSinceDate:referenceDate];
  
  STAssertEqualsWithAccuracy(differenceBetweenDates, 0.123, 1e-3, @"Expected parsed dates to reflect difference in milliseconds");
}

- (void) testParsingDateWithUnusualTimeSeparator {
	_iso8601DateFormatter.parsesStrictly = false;
	_iso8601DateFormatter.timeSeparator = SNOWMAN;

	static NSString *const dateString = @"2013-01-01T01☃01☃01-0800";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 378723661.0;
	static NSTimeInterval const expectedHoursFromGMT = -8.0;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateWithUnusualTimeSeparator {
	_iso8601DateFormatter.timeSeparator = SNOWMAN;

	NSTimeInterval timeIntervalSinceReferenceDate = 378723661.0;
	NSString *expectedDateString = @"2013-01-01T01☃01☃01-0800";
	NSString *tzName = @"America/Los_Angeles";

	[self attemptToUnparseDateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate
	                                                timeZoneName:tzName
				                                expectDateString:expectedDateString
								                     includeTime:true];
}

- (void) testParsingDateWithTimeZoneSeparator {
	_iso8601DateFormatter.timeZoneSeparator = SNOWMAN;

	static NSString *const dateString = @"2013-08-01T01:01:01-07☃30";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 397038661.0;
	static NSTimeInterval const expectedHoursFromGMT = -7.5;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateWithTimeZoneSeparator {
	_iso8601DateFormatter.timeZoneSeparator = ':';

	NSTimeInterval timeIntervalSinceReferenceDate = 378723661.0;
	NSString *expectedDateString = @"2013-01-01T01:01:01-08:00";
	NSString *tzName = @"America/Los_Angeles";

	[self attemptToUnparseDateWithTimeIntervalSinceReferenceDate:timeIntervalSinceReferenceDate
	                                                timeZoneName:tzName
				                                expectDateString:expectedDateString
								                     includeTime:true];
}

- (void) testUnparsingDatesWithoutTime {
	_iso8601DateFormatter.includeTime = false;

	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	STAssertNotNil(calendar, @"Couldn't create Gregorian calendar with which to set up date-unparsing tests");
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	STAssertNotNil(calendar, @"Couldn't create C/POSIX locale with which to set up date-unparsing tests");
	calendar.locale = locale;

	NSDateComponents *components = [NSDateComponents new];
	components.month = 1;
	components.day = 1;
	for (NSUInteger year = 1990; year < 2020; ++year) {
		components.year = year;

		NSDate *date = [calendar dateFromComponents:components];
		NSString *expectedString = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", components.year, components.month, components.day];
		NSString *string = [_iso8601DateFormatter stringFromDate:date];
		STAssertEqualObjects(string, expectedString, @"Got surprising string for January 1, %lu", year);
	}
}

- (void) testUnparsingDateInDaylightSavingTime {
	_iso8601DateFormatter.defaultTimeZone = [NSTimeZone timeZoneWithName:@"Europe/Prague"];
	_iso8601DateFormatter.includeTime = YES;

	NSDate *date;
	NSString *string;
	NSString *expectedString;

	date = [NSDate dateWithTimeIntervalSinceReferenceDate:365464800.0];
	string = [_iso8601DateFormatter stringFromDate:date];
	expectedString = @"2012-08-01T00:00:00+0200";
	STAssertEqualObjects(string, expectedString, @"Got wrong string for first date in DST in Prague #1 (check whether DST is included in TZ offset)");

	date = [NSDate dateWithTimeIntervalSinceReferenceDate:373417200.0];
	string = [_iso8601DateFormatter stringFromDate:date];
	expectedString = @"2012-11-01T00:00:00+0100";
	STAssertEqualObjects(string, expectedString, @"Got wrong string for second date in DST in Prague #1 (check whether DST is included in TZ offset)");
}

- (void) testUnparsingDateWithinBritishSummerTimeAsUTC {
	_iso8601DateFormatter.includeTime = YES;

	NSDate *date;
	NSString *expectedString;
	NSString *string;
	NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];

	date = [NSDate dateWithTimeIntervalSinceReferenceDate:354987473.0];
	expectedString = @"2012-04-01T15:37:53Z";

	string = [_iso8601DateFormatter stringFromDate:date timeZone:UTCTimeZone];
	STAssertEqualObjects(string, expectedString, @"Got wrong string for April date in UTC (check whether DST is included in TZ offset)");

	_iso8601DateFormatter.defaultTimeZone = UTCTimeZone;
	string = [_iso8601DateFormatter stringFromDate:date];
	STAssertEqualObjects(string, expectedString, @"Got wrong string for April date in UTC-as-default (check whether DST is included in TZ offset)");

	//Date https://github.com/boredzo/iso-8601-date-formatter/issues/3 was filed.
	date = [NSDate dateWithTimeIntervalSinceReferenceDate:370245466.0];
	expectedString = @"2012-09-25T05:57:46Z";

	string = [_iso8601DateFormatter stringFromDate:date];
	STAssertEqualObjects(string, expectedString, @"Got wrong string for September date in UTC-as-default (check whether DST is included in TZ offset)");
}

- (void) testStrictModeRejectsSlashyDates {
	_iso8601DateFormatter.parsesStrictly = true;

	NSString *dateString = @"11/27/1982";
	NSDate *date = [_iso8601DateFormatter dateFromString:dateString];

	STAssertNil(date, @"Slashy date string '%@' should not have been parsed as anything, let alone %@", dateString, date);
}

@end
