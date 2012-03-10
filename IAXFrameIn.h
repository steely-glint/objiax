//
//  IAXFrameIn.h
//  objiax
//
//  Created by Tim Panton on 28/02/2010.
//  Copyright 2010 phonefromhere.com. 
/* Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
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
