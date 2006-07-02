/*NSString+calendarDateValue.m
 *
 *Created by Peter Hosey on 2006-02-20.
 *Copyright 2006 Peter Hosey. All rights reserved.
 */

#include <ctype.h>

#import "NSString+calendarDateValue.h"

static unsigned read_segment(const unsigned char *str, const unsigned char **next, unsigned *out_num_digits) {
	unsigned num_digits = 0U;
	unsigned value = 0U;

	while(isdigit(*str)) {
		value *= 10U;
		value += *str - '0';
		++num_digits;
		++str;
	}

	if(next) *next = str;
	if(out_num_digits) *out_num_digits = num_digits;

	return value;
}
static unsigned read_segment_4digits(const unsigned char *str, const unsigned char **next, unsigned *out_num_digits) {
	unsigned num_digits = 0U;
	unsigned value = 0U;

	if(isdigit(*str)) {
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(next) *next = str;
	if(out_num_digits) *out_num_digits = num_digits;

	return value;
}
static unsigned read_segment_2digits(const unsigned char *str, const unsigned char **next) {
	unsigned value = 0U;

	if(isdigit(*str))
		value += *str - '0';

	if(isdigit(*++str)) {
		value *= 10U;
		value += *(str++) - '0';
	}

	if(next) *next = str;

	return value;
}

//strtod doesn't support ',' as a separator. this does.
static double read_double(const unsigned char *str, const unsigned char **next) {
	double value = 0.0;

	if(str) {
		unsigned int_value = 0;

		while(isdigit(*str)) {
			int_value *= 10U;
			int_value += (*(str++) - '0');
		}
		value = int_value;

		if((*str == ',') || (*str == '.')) {
			++str;

			register double multiplier, multiplier_multiplier;
			multiplier = multiplier_multiplier = 0.1;

			while(isdigit(*str)) {
				value += (*(str++) - '0') * multiplier;
				multiplier *= multiplier_multiplier;
			}
		}
	}

	if(next) *next = str;

	return value;
}

@implementation NSString(BZISO8601)

/*valid ISO 8601 date formats:
 *
 *YYYYMMDD
 *YYYY-MM-DD
 *YYYY-MM
 *YYYY
 *YY //century 
 * //implied century: YY is 00-99
 *  YYMMDD
 *  YY-MM-DD
 * -YYMM
 * -YY-MM
 * -YY
 * //implied year
 *  --MMDD
 *  --MM-DD
 *  --MM
 * //implied year and month
 *   ---DD
 * //ordinal dates: DDD is the number of the day in the year (1-366)
 *YYYYDDD
 *YYYY-DDD
 *  YYDDD
 *  YY-DDD
 *   -DDD
 * //week-based dates: ww is the number of the week, and d is the number (1-7) of the day in the week
 *yyyyWwwd
 *yyyy-Www-d
 *yyyyWww
 *yyyy-Www
 *yyWwwd
 *yy-Www-d
 *yyWww
 *yy-Www
 * //year of the implied decade
 *-yWwwd
 *-y-Www-d
 *-yWww
 *-y-Www
 * //week and day of implied year
 *  -Wwwd
 *  -Www-d
 * //week only of implied year
 *  -Www
 * //day only of implied week
 *  -W-d
 */
- (NSCalendarDate *)calendarDateValue {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	unsigned
		//date
		year,
		month_or_week,
		day,
		//time
		hour = 0U;
	NSTimeInterval
		minute = 0.0,
		second = 0.0;
	//time zone
	signed tz_hour = 0;
	signed tz_minute = 0;

	enum {
		monthAndDate,
		week,
		dateOnly
	} dateSpecification = monthAndDate;

	BOOL isValidDate = ([self length] > 0U);
	NSTimeZone *timeZone = nil;
	NSCalendarDate *date = nil;

	const unsigned char *ch = (const unsigned char *)[self UTF8String];

	//skip leading whitespace.
	while(isspace(*ch)) ++ch;

	const unsigned char *next_ch, *start_of_date;
	unsigned segment;
	unsigned num_leading_hyphens = 0U, num_middle_hyphens = 0U, num_digits = 0U;

	if(*ch == 'T') {
		//there is no date here, only a time. set the date to now; then we'll parse the time.
		isValidDate = isdigit(*++ch);

		year = [now yearOfCommonEra];
		month_or_week = [now monthOfYear];
		day = [now dayOfMonth];
	} else {
		segment = 0U;

		while(*ch == '-') {
			++num_leading_hyphens;
			++ch;
		}

		segment = read_segment(ch, &ch, &num_digits);
		switch(num_digits) {
			case 0:
				if((num_leading_hyphens == 1U) && (*ch == 'W')) {
					
				} else
					isValidDate = NO;
				break;

			case 8: //YYYY MM DD
				if(num_leading_hyphens > 0U)
					isValidDate = NO;
				else {
					day = segment % 100U;
					segment /= 100U;
					month_or_week = segment % 100U;
					year = segment / 100U;
				}
				break;

			case 7: //YYYY DDD (ordinal date)
				if(num_leading_hyphens > 0U)
					isValidDate = NO;
				else {
					day = segment % 1000U;
					year = segment / 1000U;
					dateSpecification = dateOnly;
				}
				break;

			case 6: //YYMMDD (implicit century)
				if(num_leading_hyphens > 0U)
					isValidDate = NO;
				else {
					day = segment % 100U;
					segment /= 100U;
					month_or_week = segment % 100U;
					year  = [now yearOfCommonEra];
					year -= (year % 100U);
					year += segment / 100U;
				}
				break;

			case 4:
				switch(num_leading_hyphens) {
					case 0: //YYYY
						year = segment;

						if(*ch == '-') ++ch;

						if(!isdigit(*ch)) {
							if(*ch == 'W')
								goto parseWeekAndDay;
							else
								month_or_week = day = 1U;
						} else {
							segment = read_segment(ch, &ch, &num_digits);
							switch(num_digits) {
								case 4: //MMDD
									day = segment % 100U;
									month_or_week = segment / 100U;
									break;
	
								case 2: //MM
									month_or_week = segment;

									if(*ch == '-') ++ch;
									if(!isdigit(*ch))
										day = 1U;
									else
										day = read_segment(ch, &ch, NULL);
									break;
	
								case 3: //DDD
									day = segment % 1000U;
									dateSpecification = dateOnly;
									break;
	
								default:
									isValidDate = NO;
							}
						}
						break;

					case 1: //YYMM
						month_or_week = segment % 100U;
						year = segment / 100U;

						if(*ch == '-') ++ch;
						if(!isdigit(*ch))
							day = 1U;
						else
							day = read_segment(ch, &ch, NULL);

						break;

					case 2: //MMDD
						day = segment % 100U;
						month_or_week = segment / 100U;
						year = [now yearOfCommonEra];

						break;

					default:
						isValidDate = NO;
				} //switch(num_leading_hyphens) (4 digits)
				break;

			case 2:
				switch(num_leading_hyphens) {
					case 0:
					afterYear:
						if(*ch == '-') {
							//implicit century
							year  = [now yearOfCommonEra];
							year -= (year % 100U);
							year += segment;

							if(*++ch == 'W') {
								goto parseWeekAndDay;
							} else {
								//get month and/or date
								NSLog(@"(%@) reading month and date from %s", self, ch);
								segment = read_segment_4digits(ch, &ch, &num_digits);
								NSLog(@"(%@) got segment: %u", self, segment);
								switch(num_digits) {
									case 4: //YY-MMDD
										day = segment % 100U;
										month_or_week = segment / 100U;
										break;

									case 2: //YY-MM; YY-MM-DD
										month_or_week = segment;
										if(*ch == '-') {
											NSLog(@"(%@) reading date from %s", self, &ch[1]);
											if(isdigit(*++ch))
												day = read_segment_2digits(ch, &ch);
										}
										break;

									case 3: //ordinal date
										day = segment;
										dateSpecification = dateOnly;
										break;
								}
							}
						} else if(*ch == 'W') {
							year  = [now yearOfCommonEra];
							year -= (year % 100U);
							year += segment;

						parseWeekAndDay:
							month_or_week = read_segment_2digits(++ch, &ch);
							if(*ch == '-') ++ch;
							day = isdigit(*ch) ? read_segment_2digits(ch, &ch) : 1U;
							dateSpecification = week;
						} else {
							//century only
							year = segment * 100U;
							month_or_week = day = 1U;
						}
						break;

					case 1: //-YY; YY-MM (implicit century)
						year = segment + ([now yearOfCommonEra] % 100U);
						if(*ch == '-')
							month_or_week = read_segment_2digits(++ch, &ch);
						day = 1U;
						break;

					case 2: //--MM; --MM-DD
						year = [now yearOfCommonEra];
						month_or_week = segment;
						if(*ch == '-')
							day = read_segment_2digits(++ch, &ch);
						break;

					case 3: //---DD
						year = [now yearOfCommonEra];
						month_or_week = [now monthOfYear];
						day = read_segment_2digits(++ch, &ch);
						break;

					default:
						isValidDate = NO;
				} //switch(num_leading_hyphens) (2 digits)
				break;

			case 1:
				if(num_leading_hyphens == 1U) //-Y (implicit decade)
					goto afterYear;

			default:
				isValidDate = NO;
		}
#if 0
		while(isdigit(*ch) || (*ch == '-')) {
			if(*ch != '-') {
				segment *= 10U;
				segment += (*ch - '0');
				++num_digits;
			}
			++ch;
		}
#endif //0
	}

#if 0
	if(num_digits) {
		switch(num_leading_hyphens) {
			//no hyphens: explicit century. year within century is optional.
			case 0:
				switch(num_digits) {
					case 8: //YYYY MMDD
						day = segment % 100U;
						segment /= 100U;
						month_or_week = segment % 100U;
						year = segment / 100U;
						break;

					case 7: //YYYY DDD
						day = segment % 1000U;
						year = segment / 1000U;
						dateSpecification = dateOnly;
						break;

					case 6:
						//YYYY-MM
						//YY-MM-DD/YYMMDD
						//YYY-DDD
						//YYY-M-DD
						//YYY-MM-D
						//YYYY-M-D
						//YY-DDD
						day = 1U;
						month_or_week = segment % 100U;
						year = segment / 100U;
						break;

					case 4: //YYYY
						year = segment;
						if(*ch == 'W') {
							//week of year.
							++ch;
							if(!isdigit(*ch))
								isValidDate = NO;
							else {
								dateSpecification = week;

								month_or_week = *(ch++) - '0';
								if(isdigit(*ch)) {
									month_or_week *= 10U;
									month_or_week += *(ch++) - '0';
								}

								if(*ch == '-') ++ch;

								if(!isdigit(*ch))
									day = 1;
								else {
									day = *(ch++) - '0';
									if(isdigit(*ch)) {
										day *= 10U;
										day += *(ch++) - '0';
									}
								}
							}
						} else {
							day = month_or_week = 1U;
						}
						break;

					case 2: //YY (century only)
					case 1: //Y (century only) (technically a violation, but we allow it)
						year = segment * 100U;
						month_or_week = day = 1U;
						break;

					default:
						isValidDate = NO;
				}
				break;

			//one hyphen: implicit century.
			case 1:
				day = month_or_week = 1U; //initialize to default
				switch(num_digits) {
					case 6:
						day = segment % 100U;
						segment /= 100U;
					case 4:
						month_or_week = segment % 100U;
					case 2:
						year = segment / 100U;
						if(year < 70)
							year += 2000;
						else if(year < 100)
							year += 1900;
						break;

					default:
						isValidDate = NO;
				}
				break;

			//two hyphens: implicit year. we use the current year.
			case 2:
				year = [now yearOfCommonEra];
				switch(num_digits) {
					case 4:
						day = segment % 100U;
						month_or_week = segment / 100U;
						break;

					case 2:
						day = 1U;
						month_or_week = segment;
						break;

					default:
						isValidDate = NO;
				}
				break;

			//three hyphens: implicit year and month. we use the current month, too.
			case 3:
				year = [now yearOfCommonEra];
				month_or_week = [now monthOfYear];
				day = segment;
				break;

			default:
				isValidDate = NO;
		} //switch(num_leading_hyphens) (parsing the date)
	}
#endif //0

	if(isValidDate) {
		if(isspace(*ch) || (*ch == 'T')) ++ch;

		if(isdigit(*ch)) {
			hour = read_segment_2digits(ch, &ch);
			if(*ch == ':') {
				minute = read_double(++ch, &ch);
				second = modf(minute, &minute);
				if(second > DBL_EPSILON)
					second *= 60.0;
				else if(*ch == ':')
					second = read_double(++ch, &ch);
			}

			switch(*ch) {
				case 'Z':
					timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
					break;

				case '+':
				case '-':;
					BOOL negative = (*ch == '-');
					if(isdigit(*++ch)) {
						//read hour offset.
						segment = *ch - '0';
						if(isdigit(*++ch)) {
							segment *= 10U;
							segment += *(ch++) - '0';
						}
						tz_hour = (signed)segment;
						if(negative) tz_hour = -tz_hour;

						//optional separator.
						if(*ch == ':') ++ch;

						if(isdigit(*ch)) {
							//read minute offset.
							segment = *ch - '0';
							if(isdigit(*++ch)) {
								segment *= 10U;
								segment += *ch - '0';
							}
							tz_minute = segment;
							if(negative) tz_minute = -tz_minute;
						}

//						NSLog(@"(%@) creating time zone with hour: %i and minute: %i", self, tz_hour, tz_minute);
						timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(tz_hour * 3600) + (tz_minute * 60)];
					}
			}
		}
	}

	if(isValidDate) {
		switch(dateSpecification) {
			case monthAndDate:
				date = [NSCalendarDate dateWithYear:year
											  month:month_or_week
												day:day
											   hour:hour
											 minute:minute
											 second:second
										   timeZone:timeZone];
				break;

			case week: //XXX THIS IS BORKEN!
				date = [NSCalendarDate dateWithYear:year
											  month:1
												day:1
											   hour:hour
											 minute:minute
											 second:second
										   timeZone:timeZone];
				NSLog(@"(%@) week: %u; day: %u", self, month_or_week, day);
				date = [date dateByAddingYears:0
				                        months:0
				                          days:((month_or_week - 1) * 7) + (day - 1)
				                         hours:0
				                       minutes:0
				                       seconds:0];
				break;

			case dateOnly: //an 'ordinal date'.
				date = [NSCalendarDate dateWithYear:year
											  month:1
												day:1
											   hour:hour
											 minute:minute
											 second:second
										   timeZone:timeZone];
				date = [date dateByAddingYears:0
				                        months:0
				                          days:(day - 1)
				                         hours:0
				                       minutes:0
				                       seconds:0];
				break;
		}
	}

	return date;
}

@end
