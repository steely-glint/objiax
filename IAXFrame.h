//
//  IAXFrame.h
//  objiax
//
//  Created by Tim Panton on 06/03/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//
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
