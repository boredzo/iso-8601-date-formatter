//
//  ISO8601ForCocoaCalendarDateTests.h
//  ISO8601ForCocoaCalendarDateTests
//
//  Created by Peter Hosey on 2013-05-27.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface ISO8601ForCocoaCalendarDateTests : SenTestCase

- (void) testParsingDateInPacificStandardTime;
- (void) testUnparsingDateInPacificStandardTime;

- (void) testParsingDateInPacificDaylightTime;
- (void) testUnparsingDateInPacificDaylightTime;

- (void) testParsingDateInGreenwichMeanTime;
- (void) testUnparsingDateInGreenwichMeanTime;

- (void) testParsingDateWithFractionOfSecondWithoutLosingPrecision;

- (void) testParsingDateWithUnusualTimeSeparator;
- (void) testUnparsingDateWithUnusualTimeSeparator;

- (void) testParsingDateWithTimeZoneSeparator;
- (void) testUnparsingDateWithTimeZoneSeparator;

@end
