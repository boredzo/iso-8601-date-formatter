/*NSCalendarDate+ISO8601Unparsing.m
 *
 *Created by Peter Hosey on 2006-05-29.
 *Copyright 2006 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

static BOOL is_leap_year(unsigned year) {
	return \
	    ((year %   4U) == 0U)
	&& (((year % 100U) != 0U)
	||  ((year % 400U) == 0U));
}

@implementation NSCalendarDate(ISO8601Unparsing)

#pragma mark Private methods

- (unsigned) ISO8601Unparsing_numberOfDaysSinceStartOfYear {
	static const unsigned accumulatedDaysByMonth[12] = {
		  0U,  31U,  59U, //JFM
		 90U, 120U, 151U, //AMJ
		181U, 212U, 243U, //JAS
		273U, 304U, 334U  //OND
	};
	return accumulatedDaysByMonth[[self monthOfYear] - 1U] + [self dayOfMonth];
}

- (unsigned) ISO8601Unparsing_dayOfISOWeek {
	return ([self dayOfWeek] + 6U) % 7U;
}

+ (unsigned) ISO8601Unparsing_January1WeekdayForYear:(unsigned)year isLeapYear:(out BOOL *)outIsLeapYear{
	//Derived from: http://personal.ecu.edu/mccartyr/ISOwdALG.txt
	--year;

	unsigned YY, C, G, isLeapYear;
	YY = year % 100U;
	C = year - YY;
	G = YY + YY / 4U;

	isLeapYear = (((C / 100U) % 4U) * 5U);
//	isLeapYear = is_leap_year(year);
	if(outIsLeapYear) *outIsLeapYear = isLeapYear;

//	return G % 7U;
	return (isLeapYear + G) % 7U;
}

#pragma mark Public methods

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:(includeTime ? @"%Y-%m-%d" : @"%Y-%m-%dT%H:%m:%S%z") allowNaturalLanguage:NO];
	NSString *str = [formatter stringFromDate:self];
	[formatter release];
	return str;
}
#if USE_MY_PARSER
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime {
	enum {
		monday, tuesday, wednesday, thursday, friday/*, saturday, sunday*/
	};
	enum {
		january = 1U, february, march,
		april, may, june,
		july, august, september,
		october, november, december
	};

	unsigned year = [self yearOfCommonEra], nextYear = year + 1U, prevYear = year - 1U;
	BOOL isLeapYear;
	unsigned month = [self monthOfYear];

	//Compute -01-01 for next year.
	unsigned nextJan1Weekday = [[self class] ISO8601Unparsing_January1WeekdayForYear:year + 1U isLeapYear:NULL];

	//Compute -01-01 for this year.
	unsigned Jan1Weekday = [[self class] ISO8601Unparsing_January1WeekdayForYear:year isLeapYear:&isLeapYear];

	unsigned daysSinceStartOfWeek;
	unsigned week, daysSinceW01_01;
	if((month == december) && ([self dayOfMonth] >= (31U - nextJan1Weekday))) {
		//Return a date on week 1 of next year.
		year = nextYear;
		//XXX Do we need to do something with nextJan1Weekday?
		week = 1U;
		daysSinceW01_01 = ((Jan1Weekday + (365 + isLeapYear)) % 7U + 7U - (31U - [self dayOfMonth])) % 7U;
		daysSinceStartOfWeek = daysSinceW01_01;
		NSLog(@"(%@) Used -01-01 from NEXT year: daysSinceW01_01: %u", self, daysSinceW01_01);

	} else {

//		daysSinceW01_01 = [self ISO8601Unparsing_numberOfDaysSinceStartOfYear] + Jan1Weekday;
		daysSinceW01_01 = [self dayOfYear] + Jan1Weekday;
		NSLog(@"J1Wd for %u is %u (compared to thursday=%u)", year, Jan1Weekday, thursday);
		if(Jan1Weekday > thursday) {
			if(daysSinceW01_01 <= 7U) {
				//This is a day on week 52 or 53 of the previous ISO year.

				unsigned prevJan1Weekday = [[self class] ISO8601Unparsing_January1WeekdayForYear:--year isLeapYear:NULL];
				//My own leap year logic works better here.
				isLeapYear = is_leap_year(year);
				NSLog(@"%u is a leap year: %hhi", year, isLeapYear, isLeapYear ? @"YES" : @"NO");

				double week_dbl = (365.0 + (isLeapYear - (signed)(prevJan1Weekday * (prevJan1Weekday <= thursday)) + (Jan1Weekday * (Jan1Weekday > thursday)))) / 7.0;
				week = week_dbl;
//				NSLog(@"365.0 + isLeapYear %@ - prevJan1Weekday? %u + Jan1Weekday? %u / 7.0 = %g; %u", isLeapYear ? @"YES" : @"NO", prevJan1Weekday * (prevJan1Weekday <= thursday), Jan1Weekday * (Jan1Weekday > thursday), week_dbl, week);
				NSLog(@"365.0 + isLeapYear %@ - prevJan1Weekday? %u / 7.0 = %g; %u", isLeapYear ? @"YES" : @"NO", prevJan1Weekday * (prevJan1Weekday <= thursday), week_dbl, week);

				daysSinceW01_01 = [self ISO8601Unparsing_dayOfISOWeek];
				NSLog(@"This day is on W%u of the previous ISO year. daysSinceW01_01 is %u", week, daysSinceW01_01);
				daysSinceStartOfWeek = (daysSinceW01_01 % 7U) + 1U;
			} else {
				daysSinceW01_01 -= 7U;
				week = (daysSinceW01_01 / 7U) + 1U;
				NSLog(@"(%@) Used -01-01 from THIS year (1): daysSinceW01_01: %u", self, daysSinceW01_01);
				daysSinceStartOfWeek = (daysSinceW01_01 % 7U);
			}
		} else {
			week = (daysSinceW01_01 / 7U) + 1U;
			NSLog(@"(%@) Used -01-01 from THIS year (2): daysSinceW01_01: %u", self, daysSinceW01_01);
			daysSinceStartOfWeek = (daysSinceW01_01 % 7U);
		}
	}

	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"T%H:%m:%S%z" allowNaturalLanguage:NO];
		timeString = [formatter stringFromDate:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-W%02u-%02u%@", year, week, daysSinceStartOfWeek, timeString];
}
#else
/*Adapted from:
 *	Algorithm for Converting Gregorian Dates to ISO 8601 Week Date
 *	Rick McCarty, 1999
 *	http://personal.ecu.edu/mccartyr/ISOwdALG.txt
 */
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime {
	enum {
		monday, tuesday, wednesday, thursday, friday, saturday, sunday
	};
	enum {
		january = 1U, february, march,
		april, may, june,
		july, august, september,
		october, november, december
	};

	unsigned year = [self yearOfCommonEra];
	unsigned week = 0U;
	unsigned dayOfWeek = ([self dayOfWeek] + 6U) % 7U;
	unsigned dayOfYear = [self dayOfYear];

	unsigned prevYear = year - 1U;

	BOOL yearIsLeapYear = is_leap_year(year);
	BOOL prevYearIsLeapYear = is_leap_year(prevYear);

	unsigned YY = prevYear % 100U;
	unsigned C = prevYear - YY;
	unsigned G = YY + YY / 4U;
	unsigned Jan1Weekday = (((((C / 100U) % 4U) * 5U) + G) % 7U);

	unsigned weekday = ((dayOfYear + Jan1Weekday) - 1U) % 7U;

	if((dayOfYear <= (7U - Jan1Weekday)) && (Jan1Weekday > thursday)) {
		week = 52U + ((Jan1Weekday == friday) || ((Jan1Weekday == saturday) && prevYearIsLeapYear));
		--year;
	} else {
		unsigned lengthOfYear = 365U + yearIsLeapYear;
		if((lengthOfYear - dayOfYear) < (thursday - weekday)) {
			++year;
			week = 1U;
		} else {
			unsigned J = dayOfYear + (sunday - weekday) + Jan1Weekday;
			week = J / 7U - (Jan1Weekday > thursday);
		}
	}

	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"T%H:%m:%S%z" allowNaturalLanguage:NO];
		timeString = [formatter stringFromDate:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-W%02u-%02u%@", year, week, dayOfWeek + 1U, timeString];
}
#endif
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime {
	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"T%H:%m:%S%z" allowNaturalLanguage:NO];
		timeString = [formatter stringFromDate:self];
		[formatter release];
	} else
		timeString = @"";

//	return [NSString stringWithFormat:@"%u-%03u%@", [self yearOfCommonEra], [self dayOfYear], timeString];
	return [NSString stringWithFormat:@"%u-%03u%@", [self yearOfCommonEra], [self ISO8601Unparsing_numberOfDaysSinceStartOfYear], timeString];
}

#pragma mark -

- (NSString *)ISO8601DateString {
	return [self ISO8601DateStringWithTime:YES];
}
- (NSString *)ISO8601WeekDateString {
	return [self ISO8601WeekDateStringWithTime:YES];
}
- (NSString *)ISO8601OrdinalDateString {
	return [self ISO8601OrdinalDateStringWithTime:YES];
}

@end
