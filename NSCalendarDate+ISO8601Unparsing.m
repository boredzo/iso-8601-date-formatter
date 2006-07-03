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

#pragma mark Public methods

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:(includeTime ? @"%Y-%m-%dT%H:%M:%S" : @"%Y-%m-%d") allowNaturalLanguage:NO];
	NSString *str = [formatter stringForObjectValue:self];
	[formatter release];
	if(includeTime) {
		int offset = [[self timeZone] secondsFromGMT];
		offset /= 60;  //bring down to minutes
		if(offset == 0)
			str = [str stringByAppendingString:@"Z"];
		if(offset < 0)
			str = [str stringByAppendingFormat:@"-%02d:%02d", -offset / 60, offset % 60];
		else
			str = [str stringByAppendingFormat:@"+%02d:%02d", offset / 60, offset % 60];
	}
	return str;
}
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
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"T%H:%M:%S%z" allowNaturalLanguage:NO];
		timeString = [formatter stringForObjectValue:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-W%02u-%02u%@", year, week, dayOfWeek + 1U, timeString];
}
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime {
	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"T%H:%M:%S%z" allowNaturalLanguage:NO];
		timeString = [formatter stringForObjectValue:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-%03u%@", [self yearOfCommonEra], [self dayOfYear], timeString];
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
