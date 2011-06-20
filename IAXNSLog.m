//
//  IAXNSLog.m
//  objiax
//
//  Created by Tim Panton on 20/06/2011.
//  Copyright 2011 Westhhawk Ltd. All rights reserved.
//

#import "IAXNSLog.h"


@implementation IAXNSLog
@synthesize level;
#pragma mark Singleton

-(void) dealloc {
	[super dealloc] ;
}

static IAXNSLog *singleLog = nil;

+(IAXNSLog *) sharedInstance {
	@synchronized(self) {
		if (!singleLog) {
			singleLog = [[[IAXNSLog alloc] init] retain];
            [singleLog setLevel:LOGWARN];
		}
	}
	return singleLog;
}



/*
void IAXLog (
             int level,
               NSString *format,
               ...
               ){
    IAXNSLog *logger =    [IAXNSLog sharedInstance];
    if (level <= [logger level]){
        va_list argp;
        
		va_start(argp, format);
        NSLog(format, argp);
		va_end(argp);
    }
}*/
void setIAXLogLevel(int level){
    IAXNSLog *logger =    [IAXNSLog sharedInstance];
    [logger setLevel:level];
}
#pragma mark methods
@end
