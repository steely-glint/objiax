//
//  IAXCall.h
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
#import "IAXFrameIn.h"
#import "PfhAudio.h"
#import "AudioDataConsumer.h"

enum  {
    kIAXCallStateINITIAL,
	kIAXCallStateWAITING,
	kIAXCallStateLINKED,
    kIAXCallStateUP
};
typedef NSUInteger kIAXCallStates;

@protocol callStatusListener
- (void) recvdDTMF:(char) dtmf;
- (void) recvdText:(NSString *)mess;
- (void) callStatusChanged:(NSString *) detail;
@end

@interface IAXCall : NSObject <AudioDataConsumer> {
    NSString *user;
    NSString *pass;
    IAXCodecTypes codec;
    NSString *codecName;
    id runner;
    uint8_t iseq;
    uint8_t oseq;
    NSInteger srcNo;
    NSInteger destNo;
    NSString *calledNo;
    NSString *callingNo;
    NSString *callerID;
    NSMutableDictionary *sentFullFrames;
    NSInteger lack; 
    NSString * callToken;
    NSInteger state;
    PfhAudio * audio;
    BOOL firstVoiceFrame;
    u_int64_t codecmap;
    NSString *codecMapString;
    uint64_t startStamp;
    id <callStatusListener> statusListener;
    NSInteger roc;
    uint16_t s_l;
    NSRecursiveLock *sendLock;
}
@property NSInteger state;
@property (retain, nonatomic) NSString *user;
@property (nonatomic, retain) NSString *pass;
@property (nonatomic, retain) NSString *calledNo;
@property (nonatomic, retain) NSString *callingNo;
@property (nonatomic, retain) NSString *callerID;

@property (nonatomic, retain) NSString * codecName;
@property (nonatomic, assign) id runner;
@property (nonatomic, readwrite) NSInteger srcNo;
@property (nonatomic, readonly) NSInteger destNo;
@property (nonatomic, assign) id<callStatusListener> statusListener;

-(void) sendNew;
-(void) initQ;
-(void) rcv:(IAXFrameIn *) frame;
-(void) cleanUp;
-(void) hangup;
-(void) offerRetry;
-(void) sendDtmf:(NSString *)dtmfs;


@end
