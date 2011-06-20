//
//  IAXNSLog.h
//  objiax
//
//  Created by Tim Panton on 20/06/2011.
//  Copyright 2011 Westhhawk Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IAXNSLog : NSObject {
    int level;
}
@property int level;
+(IAXNSLog *) sharedInstance;

@end
/*void IAXLog ( int level,
               NSString *format,
               ...
               );
 */

#define DEBUG_NSLog 1

#ifdef DEBUG_NSLog
#define IAXLog(l, fmt, ...)\
if (l <=  [[IAXNSLog sharedInstance] level]){  NSLog((@"%s [Line %d] " fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);}
#else
#define IAXLog(...)
#endif
void setIAXLogLevel(int level);

/**
 * Log all text
 */
#define  LOGALL (9)

/**
 * Log IAX text (and down)
 */
#define  LOGIAX (6)

/**
 * Log verbose text (and down)
 */
#define  LOGVERB (5)

/**
 * Log debug text (and down)
 */
#define  LOGDEBUG (4)

/**
 * Log info text (and down)
 */
#define  LOGINFO (3)

/**
 * Log warning text (and down)
 */
#define  LOGWARN (2)

/**
 * Log error text (and down)
 */
#define  LOGERROR (1)

/**
 * Log nothing
 */
#define  LOGNONE (0)