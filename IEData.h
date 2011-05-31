//
//  IEData.h
//  objiax
//
//  Created by Tim Panton on 27/03/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAXFrame.h"

@interface IEData : NSObject {
	NSMutableData * rawData;
}
@property (nonatomic, assign) NSMutableData *rawData;
- (void) addIETypeWithInt : (IAXIETypes) ietype  value: (NSUInteger) value;
- (void) addIETypeWithString : (IAXIETypes) ietype  value: (NSString *) value;
- (void) addIETypeWithByte : (IAXIETypes) ietype  value: (NSInteger) value;
- (void) addIETypeWithShort : (IAXIETypes) ietype  value: (NSInteger) value;
- (void) addIETypeWithData : (IAXIETypes) ietype  value: (NSData *) value;
- (void) addIEType : (IAXIETypes) ietype;

- (id) getIEOfType :(IAXIETypes) ietype;

- (id) mkIETypeWithBytesAndLength: (IAXIETypes) ietype data:(uint8_t *) data length:(NSInteger)len;

@end
