#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "ISO8601DateFormatter.h"

@interface ISO8601DateFormatter (CachePurgeTest)
+ (void) purgeGlobalCaches;
@end

int main(void) {
	@autoreleasepool {
		ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
		[formatter dateFromString:@"2013-09-18T07:34:21-0800"];

		dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
		dispatch_group_t group = dispatch_group_create();
		__block volatile int stop = 0;
		__block volatile int failures = 0;
		for (int worker = 0; worker < 8; worker++) {
			dispatch_group_async(group, queue, ^{
				while (!stop) {
					NSDate *west = [formatter dateFromString:@"2013-09-18T07:34:21-0800"];
					NSDate *east = [formatter dateFromString:@"2013-09-18T07:34:21+0530"];
					if (west == nil || east == nil) {
						failures = 1;
						stop = 1;
					}
				}
			});
		}

		for (int i = 0; i < 20000; i++) {
			[ISO8601DateFormatter purgeGlobalCaches];
			if ([formatter dateFromString:@"2013-09-18T07:34:21-0800"] == nil) {
				failures = 1;
				break;
			}
		}

		stop = 1;
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		[formatter release];
		return failures == 0 ? 0 : 1;
	}
}
