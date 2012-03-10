//
//  IAXFrame.h
//  objiax
//
//  Created by Tim Panton on 06/03/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//
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
#import "IAXNSLog.h"
enum {
	IAXFrameTypeDTMF =1, IAXFrameTypeVoice,IAXFrameTypeVideo,IAXFrameTypeControl,IAXFrameTypeNull,IAXFrameTypeIAXControl,
	IAXFrameTypeText,IAXFrameTypeImage,IAXFrameTypeHTML,IAXFrameTypeComfort
};
typedef NSUInteger IAXFrameTypes;

enum {
	IAXControlFrameTypeHangup = 1,
	IAXControlFrameTypeA,
	IAXControlFrameTypeRinging,
	IAXControlFrameTypeAnswer,
	IAXControlFrameTypeBusy,
	IAXControlFrameTypeB,
	IAXControlFrameTypeC,
	IAXControlFrameTypeCongestion,
	IAXControlFrameTypeFlashHook,
	IAXControlFrameTypeReservedD,
	IAXControlFrameTypeOption,
	IAXControlFrameTypeKeyRadio,
	IAXControlFrameTypeUnkeyRadio,
	IAXControlFrameTypeCallProgress,
	IAXControlFrameTypeCall,
	IAXControlFrameTypeProceeding,
	IAXControlFrameTypeHold,
	IAXControlFrameTypeUnhold
};
typedef NSUInteger IAXControlFrameTypes;

enum {
	IAXProtocolControlFrameTypeNEW=1,
	IAXProtocolControlFrameTypePING,
	IAXProtocolControlFrameTypePONG,
	IAXProtocolControlFrameTypeACK,
	IAXProtocolControlFrameTypeHANGUP,
	IAXProtocolControlFrameTypeREJECT,
	IAXProtocolControlFrameTypeACCEPT,
	IAXProtocolControlFrameTypeAUTHREQ,
	IAXProtocolControlFrameTypeAUTHREP,
	IAXProtocolControlFrameTypeINVAL,
	IAXProtocolControlFrameTypeLAGRQ,
	IAXProtocolControlFrameTypeLAGRP,
	IAXProtocolControlFrameTypeREGREQ,
	IAXProtocolControlFrameTypeREGAUTH,
	IAXProtocolControlFrameTypeREGACK,
	IAXProtocolControlFrameTypeREGREJ,
	IAXProtocolControlFrameTypeREGREL,
	IAXProtocolControlFrameTypeVNAK,
	IAXProtocolControlFrameTypeDPREQ,
	IAXProtocolControlFrameTypeDPREP,
	IAXProtocolControlFrameTypeDIAL,
	IAXProtocolControlFrameTypeTXREQ,
	IAXProtocolControlFrameTypeTXCNT,
	IAXProtocolControlFrameTypeTXACC,
	IAXProtocolControlFrameTypeTXREADY,
	IAXProtocolControlFrameTypeTXREL,
	IAXProtocolControlFrameTypeTXREJ,
	IAXProtocolControlFrameTypeQUELCH,
	IAXProtocolControlFrameTypeUNQUELCH,
	IAXProtocolControlFrameTypePOKE,
	IAXProtocolControlFrameTypeReservedA,
	IAXProtocolControlFrameTypeMWI,
	IAXProtocolControlFrameTypeUNSUPPORT,
	IAXProtocolControlFrameTypeTRANSFER,
	IAXProtocolControlFrameTypeReservedB,
	IAXProtocolControlFrameTypeReservedC,
	IAXProtocolControlFrameTypeReservedD,
    IAXProtocolControlFrameTypeTXMEDIA =   38,
    IAXProtocolControlFrameTypeRTKEY =     39,
    IAXProtocolControlFrameTypeCALLTOKEN = 40,

	
};
typedef NSUInteger IAXProtocolControlFrameTypes;

enum {
	IAXIETypeCallednumber = 1,
	IAXIETypeCallingnumber,
	IAXIETypeCallingani,
	IAXIETypeCallingname,
	IAXIETypeCalledcontext,
	IAXIETypeUsername,
	IAXIETypePassword,
	IAXIETypeCapability,
	IAXIETypeFormat,
	IAXIETypeLanguage,
	IAXIETypeVersion,
	IAXIETypeAdsicpe,
	IAXIETypeDnid,
	IAXIETypeAuthmethods,
	IAXIETypeChallenge,
	IAXIETypeMd5result,
	IAXIETypeRsaresult,
	IAXIETypeApparentaddr,
	IAXIETypeRefresh,
	IAXIETypeDpstatus,
	IAXIETypeCallno,
	IAXIETypeCause,
	IAXIETypeIaxunknown,
	IAXIETypeMsgcount,
	IAXIETypeAutoanswer,
	IAXIETypeMusiconhold,
	IAXIETypeTransferid,
	IAXIETypeRdnis,
	IAXIETypeReservedA,
	IAXIETypeReservedB,
	IAXIETypeDatetime,
	IAXIETypeReservedC,
	IAXIETypeReservedD,
	IAXIETypeReservedE,
	IAXIETypeReservedF,
	IAXIETypeReservedG,
	IAXIETypeReservedH,
	IAXIETypeCallingpres,
	IAXIETypeCallington,
	IAXIETypeCallingtns,
	IAXIETypeSamplingrate,
	IAXIETypeCausecode,
	IAXIETypeEncryption,
	IAXIETypeEnckey,
	IAXIETypeCodecprefs,
	IAXIETypeRrjitter,
	IAXIETypeRrloss,
	IAXIETypeRrpkts,
	IAXIETypeRrdelay,
	IAXIETypeRrdropped,
	IAXIETypeRrooo,
    IAXIETypeVariable,
    IAXIETypeOsptoken ,
    IAXIETypeCalltoken ,
    IAXIETypeCapability2,
    IAXIETypeFormat2
};
typedef NSUInteger IAXIETypes;


enum  {
	IAXCodecTypeG723 = 1,
	IAXCodecTypeGSMFullRate,
	IAXCodecTypeG711u,
	IAXCodecTypeG711a,
	IAXCodecTypeG726,
	IAXCodecTypeIMAADPCM,
	IAXCodecTypeSLIN,
	IAXCodecTypeLPC10,
	IAXCodecTypeG729,
	IAXCodecTypeSpeex,
	IAXCodecTypeILBC,
	IAXCodecTypeG726AAL2,
	IAXCodecTypeG722,
	IAXCodecTypeAMR
};
typedef NSUInteger IAXCodecTypes;


@protocol IAXFrame

- (NSUInteger) getTimeStamp;
- (NSInteger) getSourceCall;
- (NSInteger) getDestinationCall;
- (IAXFrameTypes) getFrameType;
- (BOOL) isMiniFrame;
- (BOOL) isRetryFrame;
- (NSInteger) getSubClass;
- (uint8_t) getIsq;
- (uint8_t) getOsq;

// do IE stuff here.

@end
