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

//Test case for https://github.com/boredzo/iso-8601-date-formatter/issues/15
- (void) testUnparsingDateAtRiskOfAccidentalPM;

- (void) testParsingDateInGreenwichMeanTime;
- (void) testUnparsingDateInGreenwichMeanTime;

- (void) testParsingDateWithFractionOfSecondWithoutLosingPrecision;

- (void) testParsingDateWithUnusualTimeSeparator;
- (void) testUnparsingDateWithUnusualTimeSeparator;

- (void) testParsingDateWithTimeZoneSeparator;
- (void) testUnparsingDateWithTimeZoneSeparator;

//Test case for https://github.com/boredzo/iso-8601-date-formatter/issues/6
- (void) testUnparsingDateInDaylightSavingTime;

//Test case for https://github.com/boredzo/iso-8601-date-formatter/issues/3 and https://github.com/boredzo/iso-8601-date-formatter/issues/5
- (void) testUnparsingDateWithinBritishSummerTimeAsUTC;

@end
