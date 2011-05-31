//
//  IAXCall.m
//  objiax
//
//  Created by Tim Panton on 28/02/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//
#include <CommonCrypto/CommonDigest.h>
#import "IAXCall.h"
#import "IAXFrameOut.h"
#import "IEData.h"
#import "PfhAudio.h"
#include <sys/time.h>


@implementation IAXCall
@synthesize pass,user,codecName,runner, srcNo, destNo, calledNo, callingNo, callerID, statusListener,state;

NSString *codecNames [] = {	@"NONE",
    @"G723",
	@"GSM",
	@"ULAW",
	@"ALAW",
	@"G726",
	@"DPCM",
	@"SLIN",
	@"LPC10",
	@"G729",
	@"SPEEX",
	@"ILBC",
	@"G726AAL2",
	@"G722",
    @"SIREN7",
    @"SIREN14",
    @"SLINEAR16",
    @"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",
    @"24",@"25",@"26",@"27",@"28",@"29",@"30",@"31",
    @"G719",
    @"SPEEX16"};


uint64_t getTime () {
    uint64_t ret = 0;
    struct timeval tp;
    gettimeofday(&tp, NULL);
    ret = (tp.tv_sec *1000L) + (tp.tv_usec /1000);
    return ret;
}
-(uint32_t) getTimeStampNow{
    uint64_t t = getTime() - startStamp;
    return 0x7fffffff & t;
}

//---------- housekeeping 

// build the IAX codec map
- (void) mkCodecMap{
    codecmap = 0;
    NSArray * codecList = [audio listCodecs];
    NSString *pc;
    for (pc in codecList){
        for (int i=0;i<33;i++){
            if ([codecNames[i] compare:pc] == NSOrderedSame){
                codecmap |= 1<<(i-1);
                NSLog(@"adding %@ as %d",codecNames[i],(i-1));
            }
        }
    }
}
- (void) initQ {
    sendLock = [[NSRecursiveLock alloc] init];
    sentFullFrames = [[NSMutableDictionary alloc] init];
    lack =0;
    callToken = @"";
    firstVoiceFrame = YES;
    audio = [[PfhAudio alloc] init];
    [self mkCodecMap];
    for (int i=0;i<33;i++){
        if ([codecNames[i] compare:codecName] == NSOrderedSame){
            codecmap |= 1<<(i-1);
            NSLog(@"set codec  %@ as %d",codecNames[i],(i-1));
        }
    }
    if (codec == 0){
        codec = 2;
    }
    startStamp = getTime();
}

- (IAXFrameOut *) mkFullFrame{
    uint32_t now = [self getTimeStampNow];
    IAXFrameOut * ff = [[IAXFrameOut alloc] initFull];
    [ff setDestinationCall:destNo];
    [ff setSourceCall:srcNo];
    [ff setTimestamp:now];
    [ff setRetryFrame:NO];
    [ff setIsq: iseq];
    [ff setOsq: oseq];
    return ff;
}

- (void) ackedTo:(NSInteger) upto{
    // check list for 'uptos' in the sent list 
    // range is our lack to upto     
    int poss = upto - lack;
    if ( poss > 0){
        int o;
        NSLog(@"Acking from %d  upto %d",lack,upto);
        
        for(o=lack;o<upto;o++){
            NSNumber * num = [NSNumber numberWithInt:o];
            id ob = [sentFullFrames objectForKey:num];
            if (ob != nil){
                [ob dumpFrame:@"Acked this "];
                [sentFullFrames removeObjectForKey:num];
            }
        }
        lack = upto;
    } else if (poss < -250){
        // wrapped.
        NSLog(@"Full frame seqno wrapped - want to Ack from %d  upto %d",lack,upto);

        [self ackedTo:256];
        lack=0;
        [self ackedTo:upto];
    }
}



- (BOOL) incrementMessageCount:(IAXFrameIn *)frame {
    BOOL doIncrement = YES;
    if ([frame getFrameType]== IAXFrameTypeIAXControl) {
        switch ([frame getSubClass]) {
            case IAXProtocolControlFrameTypeACK:
            case IAXProtocolControlFrameTypeINVAL:
            case IAXProtocolControlFrameTypeTXCNT:
            case IAXProtocolControlFrameTypeTXACC:
            case IAXProtocolControlFrameTypeVNAK:
            case IAXProtocolControlFrameTypeCALLTOKEN:
                doIncrement = NO;
                break;
            default:
                break;
        }
    }
    return doIncrement;
}

- (void) sendFullFrame:(IAXFrameOut *) full{
    [sendLock lock];
    BOOL sent = [runner sendFrame:full];
    [full dumpFrame:@"-> "];
    if ((sent == YES) && (NO == [full isRetryFrame]) && (NO == [full iAmAnAck])) {
        [sentFullFrames setObject:full forKey:[NSNumber numberWithInteger:[full getOsq]]];
        if ([self incrementMessageCount:full] == YES){
            oseq++;
            NSLog(@"Incremented oseq to %d for %@ ",(int)oseq,[full getFrameDescription] );
            
        }
    }
    if (NO == [full isRetryFrame]){
        [full release]; // free it, or anyway pass ownership to the retry list.
    }
    if (NO == [full iAmAnAck]){
        uint32_t now = [self getTimeStampNow];
        
        if (NO == [full setNextRetryTime:now] ){
            NSLog(@"Giving up on %d srcNo timeout of %@ ",srcNo,[full getOsq]);
            [runner hungupCall:self cause:@"timeout" code:0 ];
        }
    }
    [sendLock unlock];
}


- (void) offerRetry{
    [sendLock lock];
    uint32_t now = [self getTimeStampNow];
    NSArray * vals = [sentFullFrames allValues];

    for (IAXFrameOut * v in vals){
        if (YES == [v isRetryDue:now]){
            [self sendFullFrame:v];
        }
    }
    [sendLock unlock];
    
}

-(void) cleanUp{
    
}

void hexDump(NSData *blob){
    NSInteger clength = [blob length];
    const char * cbytes = [blob bytes];
    NSMutableString *repl = [[NSMutableString alloc] init ];
    
    for (int i=0;i<clength;i++){
        [repl appendFormat:@"%02x",(0x0ff & cbytes[i])];
        if ((i % 16) == 0){
            [repl appendFormat:@"\n"];
        }
    }
    NSLog(@"HexDump \n %@",repl);
    
}

///-----------------Sending stuff 
- (void) sendNew{
    iseq = 0;
    oseq = 0;
    destNo = 0;
    lack = 0; // ugly, ugly, ugly.
    IAXFrameOut * new = [self mkFullFrame];
    [new setFrameType:IAXFrameTypeIAXControl];
    [new setSubClass:IAXProtocolControlFrameTypeNEW];
    NSMutableData *payload = [NSMutableData alloc];
    IEData * ied = [IEData alloc];
    [ied setRawData:payload];
       // todo here.....
    [ied addIETypeWithShort:IAXIETypeVersion value:2];
    [ied addIETypeWithString:IAXIETypeCallednumber value:calledNo];
    [ied addIETypeWithInt:IAXIETypeCapability value:codecmap]; // strictly all codecs or'd
    [ied addIETypeWithInt:IAXIETypeFormat value:codec];
    [ied addIETypeWithString:IAXIETypeCallingname value:callerID];
    [ied addIETypeWithString:IAXIETypeCallingnumber value:callingNo];
    [ied addIETypeWithString:IAXIETypeUsername value:user];
    [ied addIETypeWithString:IAXIETypeCalltoken value:callToken];
    
    [new setPayload:payload];
    state = kIAXCallStateWAITING;
    [self sendFullFrame:new];
}


- (void) sendAck:(IAXFrameIn *) frame{
    NSLog(@"Acking frame - %d",[frame getOsq]);
    IAXFrameOut * ack = [self mkFullFrame];
    [ack setFrameType:IAXFrameTypeIAXControl];
    [ack setSubClass:IAXProtocolControlFrameTypeACK];
    [ack setTimestamp:[frame getTimeStamp]];
    [ack setIAmAnAck:YES];
    [self sendFullFrame:ack];
}
- (void) hangup{
    IAXFrameOut * hang = [self mkFullFrame];
    [hang setFrameType:IAXFrameTypeIAXControl];
    [hang setSubClass:IAXProtocolControlFrameTypeHANGUP];
    [self sendFullFrame:hang];
    [runner hungupCall:self cause:@"Local Hangup" code:0 ];
    [audio stop];
}



-(void) sendAuthRep:(NSData *)challenge{
    CC_MD5_CTX      md5Context;
    NSInteger clength = [challenge length];
    const char * cbytes = [challenge bytes];
    NSInteger plength = [pass length];
    const char * pbytes = [pass UTF8String];
    char * result = alloca(16);
    // perform the outer MD5
    CC_MD5_Init( &md5Context);
    CC_MD5_Update( &md5Context, cbytes, clength );
    CC_MD5_Update( &md5Context, pbytes, plength );
    CC_MD5_Final( (void*)result, &md5Context);
    NSMutableString *repl = [[NSMutableString alloc] init ];
    for (int i=0;i<16;i++){
        [repl appendFormat:@"%02x",(0x0ff & result[i])];
    }
    IAXFrameOut *repF = [self mkFullFrame];
    [repF setFrameType:IAXFrameTypeIAXControl];
    [repF setSubClass:IAXProtocolControlFrameTypeAUTHREP];
    NSMutableData *payload = [NSMutableData alloc];
    IEData * ied = [IEData alloc];
    [ied setRawData:payload];
    [ied addIETypeWithString:IAXIETypeMd5result value:repl];
    NSLog(@"Call %d sending pass = %s AuthRep with %@\n",srcNo,pbytes,repl);

    [repF setPayload:payload];
    [self sendFullFrame:repF];
}

- (void) sendLagrp:(IAXFrameIn *) frame{
    NSLog(@"lagrp frame - %d",[frame getOsq]);
    IAXFrameOut * lagrp = [self mkFullFrame];
    [lagrp setFrameType:IAXFrameTypeIAXControl];
    [lagrp setSubClass:IAXProtocolControlFrameTypeLAGRP];
    [lagrp setTimestamp:[frame getTimeStamp]];
    [self sendFullFrame:lagrp];
}

- (void) sendPong:(IAXFrameIn *) frame{
    NSLog(@"pong frame - %d",[frame getOsq]);
    IAXFrameOut * pong = [self mkFullFrame];
    [pong setFrameType:IAXFrameTypeIAXControl];
    [pong setSubClass:IAXProtocolControlFrameTypePONG];
    [pong setTimestamp:[frame getTimeStamp]];
    [self sendFullFrame:pong];
}


//------------------ Core FRAME Types inbound
- (void) gotVoiceFrame:(IAXFrameIn*) frame{
    //  throw it to audio system
    [runner addAudioCall:self];
    [audio start];
    NSData * pay = [frame getPayload];
    NSInteger st = [frame getTimeStamp];
    [audio consumeWireData:pay time:st];
}
- (void) gotDTMFFrame:(IAXFrameIn*) frame{
    NSLog(@"Call %d ignoring (for now) frame type %@\n",srcNo,[frame getFrameDescription]);
}
- (void) gotTextFrame:(IAXFrameIn*) frame{
    NSMutableData *md = [NSMutableData dataWithData:[frame getPayload]];
    [md setLength:[md length]+1];
    NSString *s = [NSString stringWithUTF8String:[md bytes]];
    NSLog(@"Call %d got text frame type %@",srcNo, s);
    if (statusListener != nil){
        [statusListener recvdText:s];
    }
}
void logInvalidStateFrameReceived(IAXFrameIn *frame){
    NSLog(@"Protocol mixup - wrong state to get %@ ",[frame getFrameDescription]);
}
- (void) gotControlFrame:(IAXFrameIn*) frame{
    NSLog(@"Call %d ignoring (for now) frame type %@\n",srcNo,[frame getFrameDescription]);
    switch ([frame getSubClass]) {
        case IAXControlFrameTypeAnswer:
            // state Linked -> Up
            if (state == kIAXCallStateLINKED ) {
                state = kIAXCallStateUP;
                [statusListener callStatusChanged:@"Answered"];
            } else {
                NSLog(@"Protocol mixup - wrong state to get %@ ",[frame getFrameDescription]);
            }
            break;
        case IAXControlFrameTypeBusy:
            // should only happen in Linked state??
            if (state == kIAXCallStateLINKED) {
            } else {
                logInvalidStateFrameReceived(frame);
            }
            break;
        case IAXControlFrameTypeProceeding:
            // should only happen in Linked state
            if (state == kIAXCallStateLINKED) {
            } else {
                logInvalidStateFrameReceived(frame);
            }
            break;
        case IAXControlFrameTypeCallProgress:
            break;
        case IAXControlFrameTypeCongestion:
            break;
        case IAXControlFrameTypeFlashHook:
            break;
        case IAXControlFrameTypeHangup:
            state = kIAXCallStateINITIAL;
            [runner hungupCall:self cause:@"Hungup" code:0 ];
            [audio stop];
            [statusListener callStatusChanged:@"Hungup"];
            break;
        case IAXControlFrameTypeHold:
            break;
        case IAXControlFrameTypeKeyRadio:
            break;
        case IAXControlFrameTypeOption:
            break;
        case IAXControlFrameTypeRinging:
            // should only happen in Linked state
            if (state == kIAXCallStateLINKED) {
                [statusListener callStatusChanged:@"Ringing"];
            } else {
                logInvalidStateFrameReceived(frame);
            }
            break;
        case IAXControlFrameTypeUnhold:
            break;
        case IAXControlFrameTypeUnkeyRadio:
            break;
/*        case IAXControlFrameTypeSRCUPDT:
            break; */
    }
}

-(void) gotPCF:(IAXFrameIn *) pcf{
    NSLog(@"Call %d got Protocol Control frame class %@\n",srcNo,[pcf getFrameDescription]);
    IEData * ied = [IEData alloc];
    [ied setRawData:[NSMutableData dataWithData:[pcf getPayload]]];
    //hexDump([pcf getPayload]);
 

    switch ([pcf getSubClass]){
        case IAXProtocolControlFrameTypeACK:
            NSLog(@"ACK \n");
            break;
        case IAXProtocolControlFrameTypeCALLTOKEN:
            if ([callToken length] < 1) {
                callToken = [ied getIEOfType:IAXIETypeCalltoken];
                NSLog(@"CallToken is %@\n", callToken);
                [self sendNew];
            } else {
                NSLog(@"Been there, done that, got the calltoken");
            }
            break;
        case IAXProtocolControlFrameTypeREJECT:
            state = kIAXCallStateINITIAL;
            NSString * reason = [ied getIEOfType:IAXIETypeCause];
            NSNumber * code = [ied getIEOfType:IAXIETypeCausecode];
            [runner hungupCall:self cause:reason code:code ];
            [statusListener callStatusChanged:@"Hungup"];

            break; 
        case IAXProtocolControlFrameTypeACCEPT:
        {
            NSNumber *formatN = [ied getIEOfType:IAXIETypeFormat];
            int f = [formatN intValue];
            NSString *cname =@"GSM"; 
            for (int i=1;i<32;i++){
                if ((1<<(i-1)) == f){
                    cname = codecNames[i];
                    break;
                }
            }
            NSLog(@"frame format is %@ (%ul)",cname,f);
            [audio setCodec:cname];
            [audio setWireConsumer:self];
            codec = f;
            break; 
        }
        case IAXProtocolControlFrameTypeAUTHREQ:
            if (state == kIAXCallStateWAITING) {
                short am = [[ied getIEOfType:IAXIETypeAuthmethods] shortValue];
                if (am & 0x02){
                    NSData *challenge = [ied getIEOfType:IAXIETypeChallenge];
                    [self sendAuthRep:challenge];
                } else {
                    NSLog(@"No auth method we support offer was = %d \n", am);
                }
            } else {
                NSLog(@"InvalidStateFrameReceived");
            }
            break;
        case IAXProtocolControlFrameTypeLAGRQ:
            [self sendLagrp:pcf];
            break;
        case IAXProtocolControlFrameTypePING:
            // answer with PONG
            [self sendPong:pcf];
            break;
        case IAXProtocolControlFrameTypePOKE:
            // answer with PONG
            [self sendPong:pcf];
            break;
        case IAXProtocolControlFrameTypeHANGUP:{
            state = kIAXCallStateINITIAL;
            
            NSString * reason = [ied getIEOfType:IAXIETypeCause];
            NSNumber * code = [ied getIEOfType:IAXIETypeCausecode];
            [runner hungupCall:self cause:reason code:code ];
            [audio stop];
            [statusListener callStatusChanged:@"Hungup"];
            
        }
            break;
        default:
            NSLog(@"ignoring it for now\n");
            break;
    }
    [ied release];
}

- (NSInteger) getFrameTimeWithFrame:(IAXFrameIn *)frame{
    uint16_t stamp = [frame getTimeStamp];
    int wrapdiff = 2<<14;
    
    int32_t v = roc; // default assumption
    
    // detect wrap(s)
    int diff = stamp - s_l; // normally we expect this to be 20
    if (diff < (-wrapdiff)) {
        // large negative offset so
        v = roc + 1;
        // then we have wrapped
        NSLog(@"Big negative %d %d - %d",diff,stamp , s_l);
        
    }
    if (diff > (wrapdiff)) {
        // big positive offset
        v = roc - 1; // we  wrapped recently and this is an older packet.
        NSLog(@"Big positive %d %d - %d",diff,stamp , s_l);
    }
    if (v < 0) {
        v = 0; // trap odd initial cases
    }
    int32_t low = (int32_t) stamp;
    int32_t high = (v << 16);
    s_l = stamp;
    roc = v;
    NSInteger ret = low | high;
    if (diff != 20) {
        NSLog(@"diff != 20 %d %d - %d (new roc %d) returning %d",diff,stamp , s_l, roc,ret);
    }
    return ret;
    
}



- (void) rcv:(IAXFrameIn *) frame {
    // - really us ?
    if ([frame isMiniFrame]){
        [audio consumeWireData:[frame getPayload] time:[self getFrameTimeWithFrame:frame]];
    } else {
        [frame dumpFrame:@"<- "];
        if (destNo > 1) {
            if ([frame getSourceCall] != destNo){
                [frame dumpFrame:[NSString stringWithFormat:@"Discarding srcNo does not match %d this:", destNo]];
                return; // I hate early returns.
            }
        } else {
            // assume that was our first reply so take a note
            destNo = [frame getSourceCall];
            NSLog(@"Setting our destNo to  %d \n", destNo);
        }
        // house keeping for all full frames
        [self ackedTo:[frame getIsq]];
        NSInteger farOsq = [frame getOsq];
        if (iseq <= farOsq) {
            // difference should be exactly 0 - 
            // otherwise we have a sequence problem
            if ((iseq - farOsq) == 0){
                if ([self incrementMessageCount:frame]){
                    iseq = farOsq +1;
                }
                switch ([frame getFrameType]) {
                    case IAXFrameTypeIAXControl:
                        [self gotPCF:frame];
                        break;
                    case IAXFrameTypeVoice:
                        [self gotVoiceFrame:frame];
                        break;
                    case IAXFrameTypeDTMF:
                        [self gotDTMFFrame:frame];
                        break;
                    case IAXFrameTypeText:
                        [self gotTextFrame:frame];
                        break;
                    case IAXFrameTypeControl:
                        [self gotControlFrame:frame];
                        break;
                    default:
                        NSLog(@"Call %d ignoring (for now) frame type %@\n",srcNo,[frame getFrameTypeName]);
                }
                if ([frame mustSendAck]){
                    [self sendAck:frame];
                }
            } else {
                NSLog(@"Missed frame - should VNAK %d %d ",iseq , farOsq);
            }
        } else {
            NSLog(@"Back in time %d %d ?" , iseq , farOsq);
        }
    }
}
- (void) consumeAudioData:(NSData*)data time:(NSInteger)stamp{
    NSInteger ts = stamp;
    if (firstVoiceFrame == YES){
        IAXFrameOut * ff = [self mkFullFrame];
        [ff setFrameType:IAXFrameTypeVoice];
        [ff setSubClass:codec];
        [ff setPayload:data];
        [ff setTimestamp:ts];
        [self sendFullFrame:ff];
        firstVoiceFrame = NO;
        // release is done in the ack/retry management code
    } else {
        IAXFrameOut * mf = [[IAXFrameOut alloc] initMini];
        [mf setSourceCall:srcNo];
        [mf setPayload:data];
        [mf setTimestamp:ts];
        [runner sendFrame:mf];
        //[[mf getFrameData] release];
        [mf release];
    }
}

-(void) sendDtmf:(NSString *)dtmfs{
    const char *s = [dtmfs UTF8String];
    IAXFrameOut * ff = [self mkFullFrame];
    [ff setFrameType:IAXFrameTypeDTMF];
    [ff setSubClass:*s];
    [self sendFullFrame:ff];
    if ([dtmfs length] > 1){
        dtmfs = [dtmfs substringFromIndex:1];
        [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(dtmfTimer:) userInfo:dtmfs repeats:NO];
    }
}
- (void)dtmfTimer:(NSTimer*)theTimer {
    NSString *dtmfs = [theTimer userInfo];
    [self sendDtmf:dtmfs];
}
@end