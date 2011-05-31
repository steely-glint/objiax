//
//  IAXFrameIn.h
//  objiax
//
//  Created by Tim Panton on 28/02/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAXFrame.h"

@interface IAXFrameIn : NSObject <IAXFrame> {
	NSData * frameData;
}
@property (nonatomic, retain) NSData *frameData;

- (NSInteger) getSourceCall;
- (void) dumpFrame:(NSString*)prompt;
- (NSData *) getPayload;
- (NSData *) getFrameData;
- (NSString *)getFrameTypeName;
- (NSString *)getSubClassName;
- (NSString *)getFrameDescription;

- (BOOL) mustSendAck;

@end
