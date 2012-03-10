//
//  IEData.m
//  objiax
//
//  Created by Tim Panton on 27/03/2010.
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
#import "IEData.h"


@implementation IEData
@synthesize rawData;


- (void) addIETypeWithInt : (IAXIETypes) ietype  value: (NSUInteger) value {
	uint8_t thisIE[6];
	thisIE[0] = ietype;
	thisIE[1] = 4;
	thisIE[2] = 0xff & (value >> 24);
	thisIE[3] = 0xff & (value >> 16);
	thisIE[4] = 0xff & (value >> 8);
	thisIE[5] = 0xff & (value);
	[rawData appendBytes:(void *)thisIE length:6];
}

- (void) addIETypeWithString : (IAXIETypes) ietype  value: (NSString *)value {
	NSData * d = [value dataUsingEncoding:NSUTF8StringEncoding];
	[self addIETypeWithData:ietype value:d];
}
- (void) addIETypeWithByte : (IAXIETypes) ietype  value: (NSInteger) value{
	uint8_t thisIE[3];
	thisIE[0] = ietype;
	thisIE[1] = 1;
	thisIE[2] = 0xff & (value);
	[rawData appendBytes:(void *)thisIE length:3];
}
- (void) addIETypeWithShort : (IAXIETypes) ietype  value: (NSInteger) value{
	uint8_t thisIE[4];
	thisIE[0] = ietype;
	thisIE[1] = 2;
	thisIE[2] = 0xff & (value >> 8);
	thisIE[3] = 0xff & (value);
	[rawData appendBytes:(void *)thisIE length:4];
}
- (void) addIETypeWithData : (IAXIETypes) ietype  value: (NSData *) value{
	uint8_t thisIE[2];
	thisIE[0] = ietype;
	thisIE[1] = [value length];
	[rawData appendBytes:thisIE length: 2];
	[rawData appendData:value];
}
- (void) addIEType : (IAXIETypes) ietype{
	[rawData appendBytes:(const void*)&ietype length:1];
}

- (id) mkIETypeWithBytesAndLength: (IAXIETypes) ietype data:(uint8_t *) data length:(NSInteger)len{
	id ret = nil;
	switch (ietype) {
			// shorts
		case IAXIETypeAuthmethods:{
			int itret = 0;
			itret = (*data << 8 ) |  *(data+1);
			ret = [NSNumber numberWithInt: itret];
            NSLog(@"got AuthMethosd is value = %d length = %d\n",itret,len);
			break;
		}
            // ints
        case IAXIETypeFormat :{
            uint32_t itret = 0;
            itret = (*data << 24 ) |  *(data+1) << 16 | *(data+2) << 8 | *(data+3);
			ret = [NSNumber numberWithInt: itret];
            NSLog(@"got int of value = %d length = %d\n",itret,len);
            break;
        }
// strings
        case IAXIETypeCalltoken:
        case IAXIETypeCause:
		case IAXIETypeUsername:{
			NSString * stret = [[NSString alloc] initWithBytes:data length:len encoding:NSUTF8StringEncoding];
			ret = stret;
			break;
		}
        case IAXIETypeCausecode:
            ret = [NSNumber numberWithChar:*data];
            break;
        case IAXIETypeChallenge:
		default:{
			NSData * dtret = [NSData dataWithBytes:data length:len];
			ret = dtret;
			break;
		}
            
	}
	return ret;
}
- (id) getIEOfType :(IAXIETypes) ietype{
	uint8_t * buff, *p, *end, *iep;
	id 	ret = nil;
	iep = NULL;
	int len = [rawData length];
	buff = (uint8_t *) [rawData bytes];
	p = buff;
	end = p + len;
	while (p < end){
		if ( *p == ietype ){
			// found one..
			iep = p;
			break;
		}
        p++; // skip the type byte
        len = *p++; // and length
		p += len; // which we also add
	}
	if (iep != NULL) {
		//  found
		len = *(++iep);
		if ((iep + len) < end){
			iep++;
			ret = [self mkIETypeWithBytesAndLength:ietype data:iep length:len] ;
		}
	}
	return ret;
}

	
@end
