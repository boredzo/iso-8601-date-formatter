#import <Foundation/Foundation.h>
#import "ISO8601DateFormatter.h"

int main(void) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
	formatter.includeTime = YES;
	NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:336614400.0];
	NSLog(@"2011-09-01 at 5 PM ET: %@", [formatter stringFromDate:date]);
	[pool drain];
	return EXIT_SUCCESS;
}
