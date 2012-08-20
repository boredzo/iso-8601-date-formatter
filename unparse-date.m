#import "ISO8601DateFormatter.h"
#import "ARCMacros.h"


int main(int argc, const char **argv) {
	SAFE_ARC_AUTORELEASE_POOL_START()

	ISO8601DateFormatter *formatter = SAFE_ARC_AUTORELEASE([[ISO8601DateFormatter alloc] init]);
	formatter.format = ISO8601DateFormatCalendar;

	BOOL forceUTC = NO;

	while (argv[1]) {
		if (strcmp(argv[1], "--include-time") == 0)
			formatter.includeTime = YES;
		else if (strcmp(argv[1], "--force-utc") == 0)
			forceUTC = YES;
		else
			break;
		--argc;
		++argv;
	}

	while(--argc) {
		NSString *arg = [NSString stringWithUTF8String:*++argv];
		NSTimeZone *timeZone = nil;
		NSDate *date = [formatter dateFromString:arg timeZone:&timeZone];
		if (forceUTC)
			timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
		printf("%s\n", [[NSString stringWithFormat:@"%@:\t%@", arg, [formatter stringFromDate:date timeZone:timeZone]] UTF8String]);
	}

	SAFE_ARC_AUTORELEASE_POOL_END()
	return 0;
}
