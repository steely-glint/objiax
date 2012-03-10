//
//  PfhAudio.h
//  objiax
//
//  Created by Tim Panton on 14/05/2011.
//  Copyright 2011 phonefromhere.com. 
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
#import <AudioToolbox/AudioQueue.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "AudioDataConsumer.h"
#import "CodecProtocol.h"


@interface PfhAudio : NSObject {
    NSMutableDictionary * codecs;
    id <CodecProtocol> codec;
    id <AudioDataConsumer> wire;
    NSInteger nextDue;
    NSInteger aframeLen;
    AudioQueueRef playQ;
	AudioQueueRef recQ;
/*    NSMutableArray *buffers;
    NSLock *bufflock; */
    BOOL playing;
    NSMutableDictionary *rcvdAudio;
    NSLock *rcvdLock;
    NSThread *audioThread;
    BOOL firstWired;
    NSInteger sent;
    NSMutableData *audioIn;
    NSLock *ainLock;
    NSMutableData *wout;
}
- (void) consumeWireData:(NSData*)data time:(NSInteger) stamp;
- (NSArray *) listCodecs;
- (BOOL) isCodecSupported:(NSString *) codecname;
- (NSInteger) getSampleRateForCodec:(NSString *) codecname;
- (BOOL) setCodec:(NSString *) codecname;
- (void) start;
- (void) stop;
- (void) setWireConsumer:(id<AudioDataConsumer>)a;
- (void) consumeWireData:(NSData*)data time:(NSInteger)stamp;

@end
