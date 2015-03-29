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


// Sections of this code come from phono (github/phono/phonSDK) with the following copyright

/*
 * Copyright 2011 Voxeo Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
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
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

#import "AudioDataConsumer.h"
#import "CodecProtocol.h"

#define ENOUGH (320*10)
#define MAXJITTER 40

@interface PfhAudio : NSObject {
    NSMutableDictionary * codecs;
    id <CodecProtocol> codec;
    id <AudioDataConsumer> wire;
    BOOL playing;
    BOOL muted;
    char currentDigit;
    int currentDigitDuration;
    NSRunLoop* audioRunLoop;
    NSMutableData *wout;
    NSInteger aframeLen;
    AURenderCallbackStruct inRenderProc;
    AURenderCallbackStruct outRenderProc;
    AudioUnit vioUnitMic;
    AudioUnit vioUnitSpeak;
    
    //   NSMutableData *ringInD;
    int16_t inslop[ENOUGH];
    int16_t ringIn[ENOUGH];
    NSInteger ringInsz;
    int64_t putIn;
    int64_t getIn;
    
    //    NSMutableData *ringOutD;
    int16_t  ringOut[ENOUGH];
    NSInteger ringOutsz;
    int64_t putOut;
    int64_t getOut;
    int64_t getOutold;
    NSInteger ostamp;
    UInt32 wanted;
    int sent;
    NSTimer *send;
    BOOL firstOut;
    BOOL stopped;
    double outEnergy;
    double inEnergy;

}

@property (readonly) double outEnergy;
@property (readonly) double inEnergy;

- (void) consumeWireData:(NSData*)data time:(NSInteger) stamp;
- (NSArray *) listCodecs;
- (BOOL) isCodecSupported:(NSString *) codecname;
- (NSInteger) getSampleRateForCodec:(NSString *) codecname;
- (BOOL) setCodec:(NSString *) codecname;
- (void) start;
- (void) stop;
- (void) setWireConsumer:(id<AudioDataConsumer>)a;
- (void) consumeWireData:(NSData*)data time:(NSInteger)stamp;
- (void) failTo: (NSString*) functionName withOSStatus: (OSStatus) stat ;


@end
