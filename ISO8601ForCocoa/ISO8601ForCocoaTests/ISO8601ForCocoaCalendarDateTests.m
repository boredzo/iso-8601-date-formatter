//
//  ISO8601ForCocoaCalendarDateTests.m
//  ISO8601ForCocoaCalendarDateTests
//
//  Created by Peter Hosey on 2013-05-27.
//  Copyright (c) 2013–2015 Peter Hosey. All rights reserved.
//

//#import <XCTest/XCTest.h>
#import "ISO8601ForCocoaCalendarDateTests.h"
#import "ISO8601DateFormatter.h"
#import "NSLocale+UnitTestSwizzling.h"
#import "ISO8601Testing.h"
#import "PRHNamedCharacter.h"
#include <vis.h>

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
	XCTAssertNotNil(date, @"Parsing a valid ISO 8601 calendar date should return an NSDate object");
	XCTAssertNotNil(timeZone, @"Parsing a valid ISO 8601 calendar date that specifies a time zone offset should return an NSTimeZone object");
	XCTAssertEqualWithAccuracy([date timeIntervalSinceReferenceDate], expectedTimeIntervalSinceReferenceDate, 0.0001, @"Date parsed from '%@' should be %f seconds since the reference date", dateString, expectedTimeIntervalSinceReferenceDate);
	NSInteger secondsFromGMTForDate = [timeZone secondsFromGMTForDate:date];
	XCTAssertEqual(secondsFromGMTForDate, (NSInteger)expectedSecondsFromGMT, @"Time zone parsed from '%@' should be %f seconds (%f hours) from GMT, not %ld seconds (%f hours)", dateString, expectedSecondsFromGMT, expectedHoursFromGMT, (long)secondsFromGMTForDate, secondsFromGMTForDate / gSecondsPerHour);
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
	XCTAssertNotNil(dateString, @"Unparsing a date should return a string");
	XCTAssertEqualObjects(dateString, expectedDateString, @"Got unexpected output for date with time interval since reference date %f in time zone %@", timeIntervalSinceReferenceDate, timeZone);
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
	XCTAssertEqualObjects([_iso8601DateFormatter stringFromDate:date timeZone:tz], @"2013-08-02T13:35:00Z", @"Unexpected date string for 13:35 on 2 August 2013 in London");

	tz = [NSTimeZone timeZoneWithName:@"Europe/London"];
	XCTAssertEqualObjects([_iso8601DateFormatter stringFromDate:date timeZone:tz], @"2013-08-02T14:35:00+0100", @"Unexpected date string for 13:35 on 2 August 2013 in London");
    
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
  
  XCTAssertEqualWithAccuracy(differenceBetweenDates, 0.123, 1e-3, @"Expected parsed dates to reflect difference in milliseconds");
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

- (void) testParsingDateWithIncompleteTime {
	NSString *string;
	NSTimeInterval expectedTimeIntervalSinceReferenceDate;
	NSDate *date;
	NSDate *expectedDate;

	string = @"2013-09-10T21:41:05Z";
	expectedTimeIntervalSinceReferenceDate = 400542065.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	date = [_iso8601DateFormatter dateFromString:string];
	XCTAssertEqualObjects(date, expectedDate, @"Date %@ doesn't match string %@", date, string);

	string = @"2013-09-10T21:41Z";
	expectedTimeIntervalSinceReferenceDate = 400542060.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	date = [_iso8601DateFormatter dateFromString:string];
	XCTAssertEqualObjects(date, expectedDate, @"Date %@ doesn't match string %@", date, string);

	string = @"2013-09-10T21Z";
	expectedTimeIntervalSinceReferenceDate = 400539600.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	date = [_iso8601DateFormatter dateFromString:string];
	XCTAssertEqualObjects(date, expectedDate, @"Date %@ doesn't match string %@", date, string);
}

#if POST_DATE_COMPONENTS_REFACTOR
- (void) testParsingDateWithTimeOnly {
	NSString *timeOnlyString;
	NSTimeInterval expectedSecondsFromGMT;
	NSDateComponents *components;
	NSTimeZone *timeZone;

	timeOnlyString = @"T22:63:24-11:21";
	expectedSecondsFromGMT = -11.0 * 3600.0 + -21.0 * 60.0;
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString timeZone:&timeZone];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)63, @"Expected minute of '%@' to be 63", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)24, @"Expected second of '%@' to be 24", timeOnlyString);
	XCTAssertNotNil(timeZone, @"Expected '%@' to yield a time zone", timeOnlyString);
	XCTAssertEqual(timeZone.secondsFromGMT, (NSInteger)expectedSecondsFromGMT, @"Expected time zone offset of '%@' to be 11 hours and 21 minutes west of GMT", timeOnlyString);

	timeOnlyString = @"T22:63:24+50:70";
	expectedSecondsFromGMT = +50.0 * 3600.0 + +70.0 * 60.0;
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString timeZone:&timeZone];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)63, @"Expected minute of '%@' to be 63", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)24, @"Expected second of '%@' to be 24", timeOnlyString);
	XCTAssertNotNil(timeZone, @"Expected '%@' to yield a time zone", timeOnlyString);
	XCTAssertEqual(timeZone.secondsFromGMT, (NSInteger)expectedSecondsFromGMT, @"Expected time zone offset of '%@' to be 50 hours and 70 minutes east of GMT", timeOnlyString);

	timeOnlyString = @"T22:1:2";
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)1, @"Expected minute of '%@' to be 1", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)2, @"Expected second of '%@' to be 2", timeOnlyString);

	timeOnlyString = @"T22:1Z";
	expectedSecondsFromGMT = 0.0;
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString timeZone:&timeZone];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)1, @"Expected minute of '%@' to be 1", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)NSUndefinedDateComponent, @"Expected second of '%@' to be undefined", timeOnlyString);
	XCTAssertEqual(timeZone.secondsFromGMT, (NSInteger)expectedSecondsFromGMT, @"Expected time zone offset of '%@' to be zero (GMT)", timeOnlyString);

	timeOnlyString = @"T22:";
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)NSUndefinedDateComponent, @"Expected minute of '%@' to be undefined", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)NSUndefinedDateComponent, @"Expected second of '%@' to be undefined", timeOnlyString);

	timeOnlyString = @"T22";
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString];
	XCTAssertEqual(components.hour, (NSInteger)22, @"Expected hour of '%@' to be 22", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)NSUndefinedDateComponent, @"Expected minute of '%@' to be undefined", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)NSUndefinedDateComponent, @"Expected second of '%@' to be undefined", timeOnlyString);

	timeOnlyString = @"T2";
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString];
	XCTAssertEqual(components.hour, (NSInteger)2, @"Expected hour of '%@' to be 2", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)NSUndefinedDateComponent, @"Expected minute of '%@' to be undefined", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)NSUndefinedDateComponent, @"Expected second of '%@' to be undefined", timeOnlyString);

	timeOnlyString = @"T2:2:2";
	components = [_iso8601DateFormatter dateComponentsFromString:timeOnlyString];
	XCTAssertEqual(components.hour, (NSInteger)2, @"Expected hour of '%@' to be 2", timeOnlyString);
	XCTAssertEqual(components.minute, (NSInteger)2, @"Expected minute of '%@' to be 2", timeOnlyString);
	XCTAssertEqual(components.second, (NSInteger)2, @"Expected second of '%@' to be 2", timeOnlyString);
}
#endif

- (void) testUnparsingDatesWithoutTime {
	_iso8601DateFormatter.includeTime = false;

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	XCTAssertNotNil(calendar, @"Couldn't create Gregorian calendar with which to set up date-unparsing tests");
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	XCTAssertNotNil(calendar, @"Couldn't create C/POSIX locale with which to set up date-unparsing tests");
	calendar.locale = locale;

	NSDateComponents *components = [NSDateComponents new];
	components.month = 1;
	components.day = 1;
	for (NSUInteger year = 1990; year < 2020; ++year) {
		components.year = year;

		NSDate *date = [calendar dateFromComponents:components];
		NSString *expectedString = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)components.year, (long)components.month, (long)components.day];
		NSString *string = [_iso8601DateFormatter stringFromDate:date];
		XCTAssertEqualObjects(string, expectedString, @"Got surprising string for January 1, %lu", (unsigned long)year);
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
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for first date in DST in Prague #1 (check whether DST is included in TZ offset)");

	date = [NSDate dateWithTimeIntervalSinceReferenceDate:373417200.0];
	string = [_iso8601DateFormatter stringFromDate:date];
	expectedString = @"2012-11-01T00:00:00+0100";
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for second date in DST in Prague #1 (check whether DST is included in TZ offset)");
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
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for April date in UTC (check whether DST is included in TZ offset)");

	_iso8601DateFormatter.defaultTimeZone = UTCTimeZone;
	string = [_iso8601DateFormatter stringFromDate:date];
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for April date in UTC-as-default (check whether DST is included in TZ offset)");

	//Date https://github.com/boredzo/iso-8601-date-formatter/issues/3 was filed.
	date = [NSDate dateWithTimeIntervalSinceReferenceDate:370245466.0];
	expectedString = @"2012-09-25T05:57:46Z";

	string = [_iso8601DateFormatter stringFromDate:date];
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for September date in UTC-as-default (check whether DST is included in TZ offset)");
}

//https://github.com/boredzo/iso-8601-date-formatter/issues/31
- (void) testParsingOctober9th2013 {
	NSDate *date = [_iso8601DateFormatter dateFromString:@"2013-10-09T13:00:00Z"];
	//#31 is a crash, so we shouldn't even get here.
	XCTAssertNotNil(date, @"1 PM UTC on October 9th, 2013 should not be nil");
}

//https://github.com/boredzo/iso-8601-date-formatter/issues/63
- (void) testParsingDecember1st2014 {
	NSString *_Nonnull const str = @"2014-12-01";
	ISO8601DateFormatter *_Nonnull const formatter = [[ISO8601DateFormatter alloc] init];
	formatter.defaultTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

	NSDateComponents *_Nonnull const components = [formatter dateComponentsFromString:str];
	components.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSDate *_Nonnull const dateCreatedHereFromComponents = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:components];
	XCTAssertEqual((int)dateCreatedHereFromComponents.timeIntervalSinceReferenceDate, 439084800, @"Expected @\"%@\" to be midnight on 2014-12-01 in UTC, not %@", str, dateCreatedHereFromComponents);

	NSDate *_Nonnull const date = [formatter dateFromString:str];
	XCTAssertNotNil(date, @"December 1st, 2014 should not be nil");
	XCTAssertEqual((int)date.timeIntervalSinceReferenceDate, 439084800, @"Expected @\"%@\" to be midnight on 2014-12-01 in UTC, not %@", str, date);
}

// https://github.com/boredzo/iso-8601-date-formatter/issues/36
- (void) testParsingFractionaryTimeZone
{
    _iso8601DateFormatter.includeTime = YES;
    
	NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:gSecondsPerHour*-2.5];
    
	NSDate *date= [NSDate dateWithTimeIntervalSinceReferenceDate:354987473.0];
    
	NSString *expectedString = @"2012-04-01T13:07:53-0230";

	NSString *string = [_iso8601DateFormatter stringFromDate:date
                                                    timeZone:UTCTimeZone];
	XCTAssertEqualObjects(string, expectedString, @"Got wrong string for fractionary time zone");
}

- (void) testStrictModeRejectsSlashyDates {
	_iso8601DateFormatter.parsesStrictly = true;

	NSString *dateString = @"11/27/1982";
	NSDate *date = [_iso8601DateFormatter dateFromString:dateString];

	XCTAssertNil(date, @"Slashy date string '%@' should not have been parsed as anything, let alone %@", dateString, date);
}

- (void) testParseNilIntoDateComponents {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	NSDateComponents *_Nullable const components = [_iso8601DateFormatter dateComponentsFromString:nil];
#pragma clang diagnostic pop
	XCTAssertNil(components, @"dateComponentsFromString:nil should have returned nil, but returned %@", components);
}

- (void) testParseNilIntoDate {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	NSDate *_Nullable const date = [_iso8601DateFormatter dateFromString:nil];
#pragma clang diagnostic pop
	XCTAssertNil(date, @"dateFromString:nil returned should have returned nil, but returned %@", date);
}

- (void) testParseNSNullIntoDate {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
    NSDate *date = [_iso8601DateFormatter dateFromString:[NSNull null]];
#pragma clang diagnostic pop
    
    STAssertNil(date, @"dateFromString:[NSNull null] returned should have returned nil, but returned %@", date);
}

- (void) testParseNSMutableStringIntoDate {
    NSString *dateString = @"2013-09-12T23:40Z";
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:400722000.0];
    NSDate *date = [_iso8601DateFormatter dateFromString:[[NSMutableString alloc] initWithString:dateString]];
    STAssertEquals(date, expectedDate, @"dateFromString: should have returned %@, but returned %@", expectedDate, date);
}

- (void) testStringFromInapplicableObjectValues {
	NSString *string = nil;
	XCTAssertNoThrow((string = [_iso8601DateFormatter stringForObjectValue:@42]), @"stringForObjectValue:@42 threw an exception");
	XCTAssertNil(string, @"stringForObjectValue:@42 should have returned nil, but returned %@", string);
	XCTAssertNoThrow((string = [_iso8601DateFormatter stringForObjectValue:[NSFileManager defaultManager]]), @"stringForObjectValue:[NSFileManager] failed to throw an exception");
	XCTAssertNil(string, @"stringForObjectValue:[NSFileManager] should have returned nil, but returned %@", string);
	XCTAssertNoThrow((string = [_iso8601DateFormatter stringForObjectValue:self]), @"stringForObjectValue:%@ failed to throw an exception", self);
	XCTAssertNil(string, @"stringForObjectValue:self should have returned nil, but returned %@", string);
}

- (void) testParsingDateWithSpaceInFrontOfItStrictly {
	NSString *dateString = @"2013-09-12T23:40Z";
	[self attemptToParseDateString:dateString prefixedWithString:@" "  strictMode:true expectedDate:nil];
	[self attemptToParseDateString:dateString prefixedWithString:@"\t" strictMode:true expectedDate:nil];
	[self attemptToParseDateString:dateString prefixedWithString:@"\n" strictMode:true expectedDate:nil];
	[self attemptToParseDateString:dateString prefixedWithString:@"\v" strictMode:true expectedDate:nil];
	[self attemptToParseDateString:dateString prefixedWithString:@"\f" strictMode:true expectedDate:nil];
	[self attemptToParseDateString:dateString prefixedWithString:@"\r" strictMode:true expectedDate:nil];
}
- (void) testParsingDateWithSpaceInFrontOfItNonStrictly {
	NSString *dateString = @"2013-09-12T23:40Z";
	NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:400722000.0];
	[self attemptToParseDateString:dateString prefixedWithString:@" "  strictMode:false expectedDate:expectedDate];
	[self attemptToParseDateString:dateString prefixedWithString:@"\t" strictMode:false expectedDate:expectedDate];
	[self attemptToParseDateString:dateString prefixedWithString:@"\n" strictMode:false expectedDate:expectedDate];
	[self attemptToParseDateString:dateString prefixedWithString:@"\v" strictMode:false expectedDate:expectedDate];
	[self attemptToParseDateString:dateString prefixedWithString:@"\f" strictMode:false expectedDate:expectedDate];
	[self attemptToParseDateString:dateString prefixedWithString:@"\r" strictMode:false expectedDate:expectedDate];
}

- (void) attemptToParseDateString:(NSString *)dateString
	prefixedWithString:(NSString *)prefix
	strictMode:(bool)strict
	expectedDate:(NSDate *)expectedDate
{
	_iso8601DateFormatter.parsesStrictly = strict;
	XCTAssertEqual(_iso8601DateFormatter.parsesStrictly, (typeof(_iso8601DateFormatter.parsesStrictly))strict, @"Date formatter %@ blew off an attempt to set whether it parses strictly to %@", _iso8601DateFormatter, strict ? @"true" : @"false");

	NSString *string = [prefix stringByAppendingString:dateString];
	NSDate *date = [_iso8601DateFormatter dateFromString:string];
	if (strict) {
		XCTAssertNil(date, @"Strictly parsing string '%@' should have returned nil, not %@", [self stringByEscapingString:string], date);
	} else {
		XCTAssertNotNil(date, @"Parsing string '%@' with strict mode off should have returned a date, not nil", [self stringByEscapingString:string]);
		XCTAssertEqualObjects(date, expectedDate, @"Parsing string '%@' with strict mode off returned wrong date (expected %f, got %f)", [self stringByEscapingString:string], expectedDate.timeIntervalSinceReferenceDate, date.timeIntervalSinceReferenceDate);
	}
}

- (NSString *) stringByEscapingString:(NSString *)string {
	NSData *unescapedData = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSUInteger length = unescapedData.length;

	//NUL-terminate it.
	{
		NSMutableData *tempData = [unescapedData mutableCopy];
		tempData.length = length + 1;
		unescapedData = tempData;
	}

	NSMutableData *escapedData = [NSMutableData dataWithLength:length * 4UL + 1UL];
	escapedData.length = (NSUInteger)strvis(escapedData.mutableBytes, unescapedData.bytes, VIS_WHITE | VIS_CSTYLE);
	return [[NSString alloc] initWithData:escapedData encoding:NSASCIIStringEncoding];
}

//This is really only here because test code counts toward code coverage.
- (void) testStringEscaping {
	NSString *string;
	NSString *escapedString;

	string = @"foo";
	escapedString = [self stringByEscapingString:string];
	XCTAssertEqualObjects(escapedString, string, @"Escaping an all-letters string should effect no change, not produce '%@'", escapedString);

	string = @"foo123";
	escapedString = [self stringByEscapingString:string];
	XCTAssertEqualObjects(escapedString, string, @"Escaping an alphanumeric string should effect no change, not produce '%@'", escapedString);

	NSString *expectedString;
	expectedString = @"\\t\\n\\v\\f\\r";
	string = @"\t\n\v\f\r";
	escapedString = [self stringByEscapingString:string];
	XCTAssertEqualObjects(escapedString, expectedString, @"Escaping a string of whitespace in order should produce escape sequences in order ('%@'), not '%@'", expectedString, escapedString);
}

- (void) testParsingSloppyDatesStrictly {
	_iso8601DateFormatter.parsesStrictly = true;

	NSString *string;
	NSDate *date;

	string = @"130918";
	date = [_iso8601DateFormatter dateFromString:string];
	XCTAssertNil(date, @"Parsing '%@' strictly should return nil, not %@ (%f)", string, date, date.timeIntervalSinceReferenceDate);

	string = @"2013-0918";
	date = [_iso8601DateFormatter dateFromString:string];
	XCTAssertNil(date, @"Parsing '%@' strictly should return nil, not %@ (%f)", string, date, date.timeIntervalSinceReferenceDate);
}

- (void) testParsingDateFromSubstring {
	NSString *string;
	NSTimeInterval expectedTimeIntervalSinceReferenceDate;
	NSDate *expectedDate;
	NSTimeZone *expectedTimeZone;
	NSRange expectedRange;
	NSDate *date;
	NSTimeZone *timeZone;
	NSRange range;

#define PREFIX @" \t\t "
#define DATE @"2013-09-18T04:18Z"
#define NOT_A_DATE @"\u2603"
#define SUFFIX @" \t\t "

	string = PREFIX DATE;
	expectedTimeIntervalSinceReferenceDate = 401170680.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	expectedTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	expectedRange = (NSRange){ PREFIX.length, DATE.length };
	date = [_iso8601DateFormatter dateFromString:string timeZone:&timeZone range:&range];
	XCTAssertEqualObjects(date, expectedDate, @"Date from substring of '%@' should be %@ (%f), not %@ (%f) (%+f seconds difference)", string, expectedDate, expectedTimeIntervalSinceReferenceDate, date, date.timeIntervalSinceReferenceDate, [date timeIntervalSinceDate:expectedDate]);
	XCTAssertEqualObjects(timeZone, expectedTimeZone, @"Time zone from substring of '%@' should be %@, not %@", string, expectedTimeZone, timeZone);
	ISO8601AssertEqualRanges(range, expectedRange, @"Range of date from substring of '%@' should be %@ ('%@'), not %@ ('%@')", string, NSStringFromRange(expectedRange), [string substringWithRange:expectedRange], NSStringFromRange(range), [string substringWithRange:range]);

	string = PREFIX DATE SUFFIX;
	expectedTimeIntervalSinceReferenceDate = 401170680.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	expectedTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	expectedRange = (NSRange){ PREFIX.length, DATE.length };
	date = [_iso8601DateFormatter dateFromString:string timeZone:&timeZone range:&range];
	XCTAssertEqualObjects(date, expectedDate, @"Date from substring of '%@' should be %@ (%f), not %@ (%f) (%+f seconds difference)", string, expectedDate, expectedTimeIntervalSinceReferenceDate, date, date.timeIntervalSinceReferenceDate, [date timeIntervalSinceDate:expectedDate]);
	XCTAssertEqualObjects(timeZone, expectedTimeZone, @"Time zone from substring of '%@' should be %@, not %@", string, expectedTimeZone, timeZone);
	ISO8601AssertEqualRanges(range, expectedRange, @"Range of date from substring of '%@' should be %@ ('%@'), not %@ ('%@')", string, NSStringFromRange(expectedRange), [string substringWithRange:expectedRange], NSStringFromRange(range), [string substringWithRange:range]);

	string = DATE SUFFIX;
	expectedTimeIntervalSinceReferenceDate = 401170680.0;
	expectedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate];
	expectedTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	expectedRange = (NSRange){ 0, DATE.length };
	date = [_iso8601DateFormatter dateFromString:string timeZone:&timeZone range:&range];
	XCTAssertEqualObjects(date, expectedDate, @"Date from substring of '%@' should be %@ (%f), not %@ (%f) (%+f seconds difference)", string, expectedDate, expectedTimeIntervalSinceReferenceDate, date, date.timeIntervalSinceReferenceDate, [date timeIntervalSinceDate:expectedDate]);
	XCTAssertEqualObjects(timeZone, expectedTimeZone, @"Time zone from substring of '%@' should be %@, not %@", string, expectedTimeZone, timeZone);
	ISO8601AssertEqualRanges(range, expectedRange, @"Range of date from substring of '%@' should be %@ ('%@'), not %@ ('%@')", string, NSStringFromRange(expectedRange), [string substringWithRange:expectedRange], NSStringFromRange(range), [string substringWithRange:range]);

	string = PREFIX NOT_A_DATE SUFFIX;
	//Note that timeZone and range are both set to previous results at this point. If dateFromString::: doesn't set them, that will cause a test failure.
	expectedTimeIntervalSinceReferenceDate = 0.0;
	expectedDate = nil;
	expectedTimeZone = nil;
	expectedRange = (NSRange){ NSNotFound, 0 };
	date = [_iso8601DateFormatter dateFromString:string timeZone:&timeZone range:&range];
	XCTAssertNil(date, @"Date from substring of '%@' should be nil, not %@ (%f)", string, date, date.timeIntervalSinceReferenceDate);
	XCTAssertNil(timeZone, @"Time zone from substring of '%@' should be nil, not %@", string, timeZone);
	ISO8601AssertEqualRanges(range, expectedRange, @"Range of date from substring of '%@' should be %@ ('%@'), not %@ ('%@')", string, NSStringFromRange(expectedRange), [string substringWithRange:expectedRange], NSStringFromRange(range), [string substringWithRange:range]);
}

// https://github.com/boredzo/iso-8601-date-formatter/issues/29
- (void) testParsingDoesNotMakeStuffUp {
	ISO8601DateFormatter *_Nonnull const formatter = [[ISO8601DateFormatter alloc] init];

	NSString *_Nonnull const dateOnlyString = @"2016-04-01";
	NSDateComponents *_Nullable const dateOnlyComponents = [formatter dateComponentsFromString:dateOnlyString];
	XCTAssertNil(dateOnlyComponents.timeZone);
	XCTAssertEqual(dateOnlyComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyComponents.second, NSUndefinedDateComponent);

	//Note: ISO 8601 defines -AA-BB as year AA (of implied century), month BB. For implied year, explicit month and day, we want --AA-BB.
	NSString *_Nonnull const dateOnlyNoYearString = @"--04-01";
	NSDateComponents *_Nullable const dateOnlyNoYearComponents = [formatter dateComponentsFromString:dateOnlyNoYearString];
	XCTAssertNil(dateOnlyNoYearComponents.timeZone);
	XCTAssertEqual(dateOnlyNoYearComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const dateOnlyWeekDateString = @"2016-W04-01";
	NSDateComponents *_Nullable const dateOnlyWeekDateComponents = [formatter dateComponentsFromString:dateOnlyWeekDateString];
	XCTAssertNil(dateOnlyWeekDateComponents.timeZone);
	XCTAssertEqual(dateOnlyWeekDateComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyWeekDateComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyWeekDateComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyWeekDateComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const dateOnlyNoYearWeekDateString = @"-W04-01";
	NSDateComponents *_Nullable const dateOnlyNoYearWeekDateComponents = [formatter dateComponentsFromString:dateOnlyNoYearWeekDateString];
	XCTAssertNil(dateOnlyNoYearWeekDateComponents.timeZone);
	XCTAssertEqual(dateOnlyNoYearWeekDateComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearWeekDateComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearWeekDateComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearWeekDateComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearWeekDateComponents.second, NSUndefinedDateComponent);
	
	NSString *_Nonnull const dateOnlyNoYearOrMonthString = @"---01";
	NSDateComponents *_Nullable const dateOnlyNoYearOrMonthComponents = [formatter dateComponentsFromString:dateOnlyNoYearOrMonthString];
	XCTAssertNil(dateOnlyNoYearOrMonthComponents.timeZone);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.month, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrMonthComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const dateOnlyOrdinalString = @"2016-012";
	NSDateComponents *_Nullable const dateOnlyOrdinalComponents = [formatter dateComponentsFromString:dateOnlyOrdinalString];
	XCTAssertNil(dateOnlyOrdinalComponents.timeZone);
	XCTAssertEqual(dateOnlyOrdinalComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyOrdinalComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyOrdinalComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyOrdinalComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const dateOnlyNoYearOrdinalString = @"-012";
	NSDateComponents *_Nullable const dateOnlyNoYearOrdinalComponents = [formatter dateComponentsFromString:dateOnlyNoYearOrdinalString];
	XCTAssertNil(dateOnlyNoYearOrdinalComponents.timeZone);
	XCTAssertEqual(dateOnlyNoYearOrdinalComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrdinalComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrdinalComponents.hour, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrdinalComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(dateOnlyNoYearOrdinalComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const timeOnlyString = @"T12:34:56";
	NSDateComponents *_Nullable const timeOnlyComponents = [formatter dateComponentsFromString:timeOnlyString];
	XCTAssertNil(timeOnlyComponents.timeZone);
	XCTAssertEqual(timeOnlyComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyComponents.month, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyComponents.day, NSUndefinedDateComponent);

	NSString *_Nonnull const timeOnlyNoSecondsString = @"T12:34";
	NSDateComponents *_Nullable const timeOnlyNoSecondsComponents = [formatter dateComponentsFromString:timeOnlyNoSecondsString];
	XCTAssertNil(timeOnlyNoSecondsComponents.timeZone);
	XCTAssertEqual(timeOnlyNoSecondsComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsComponents.month, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsComponents.day, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsComponents.second, NSUndefinedDateComponent);

	NSString *_Nonnull const timeOnlyNoSecondsOrMinutesString = @"T12";
	NSDateComponents *_Nullable const timeOnlyNoSecondsOrMinutesComponents = [formatter dateComponentsFromString:timeOnlyNoSecondsOrMinutesString];
	XCTAssertNil(timeOnlyNoSecondsOrMinutesComponents.timeZone);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.year, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.month, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.weekOfYear, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.day, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.minute, NSUndefinedDateComponent);
	XCTAssertEqual(timeOnlyNoSecondsOrMinutesComponents.second, NSUndefinedDateComponent);
}

@end
