#import "ISO8601DateFormatter.h"
#import "ARCMacros.h"

int main(int argc, const char **argv) {
	SAFE_ARC_AUTORELEASE_POOL_START()

	ISO8601DateFormatter *formatter = SAFE_ARC_AUTORELEASE([[ISO8601DateFormatter alloc] init]);
	formatter.format = ISO8601DateFormatWeek;

	while(--argc) {
		NSString *arg = [NSString stringWithUTF8String:*++argv];
		NSTimeZone *timeZone = nil;
		printf("%s\n", [[NSString stringWithFormat:@"%@:\t%@", arg, [formatter stringFromDate:[formatter dateFromString:arg timeZone:&timeZone] timeZone:timeZone]] UTF8String]);
	}

	SAFE_ARC_AUTORELEASE_POOL_END()
	return 0;
}
