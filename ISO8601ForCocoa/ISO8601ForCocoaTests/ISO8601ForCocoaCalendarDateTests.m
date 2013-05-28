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

- (void) testParsingDateInPacificStandardTime {
	static NSString *const dateString = @"2013-01-01T01:01:01-0800";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 378723661.0;
	static NSTimeInterval const expectedHoursFromGMT = -8.0;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInPacificStandardTime {
}

- (void) testParsingDateInPacificDaylightTime {
	static NSString *const dateString = @"2013-08-01T01:01:01-0700";
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 397036861.0;
	static NSTimeInterval const expectedHoursFromGMT = -7.0;

	[self attemptToParseString:dateString expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInPacificDaylightTime {

}

- (void) testParsingDateInGreenwichMeanTime {
	static NSTimeInterval const expectedTimeIntervalSinceReferenceDate = 381373261.0;
	static NSTimeInterval const expectedHoursFromGMT = -0.0;

	[self attemptToParseString:@"2013-02-01T01:01:01-0000"
		expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
		expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
	[self attemptToParseString:@"2013-02-01T01:01:01Z"
		expectTimeIntervalSinceReferenceDate:expectedTimeIntervalSinceReferenceDate
		expectTimeZoneWithHoursFromGMT:expectedHoursFromGMT];
}

- (void) testUnparsingDateInGreenwichMeanTime {

}

@end
