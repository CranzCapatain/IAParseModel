//
//  NSObject+IAParse.h
//  IAParseModel
//
//  Created by JinFeng on 2019/4/25.
//  Copyright © 2019 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (IAParse)

/// You can parse NSDictionary,NSArray,NSData,NSString...and XML.

/// @param from which need to parse.
/// @result instance from Class you pass.
+ (instancetype)ia_parseFrom:(id)from;

- (void)ia_parseForm:(id)from;



- (void)testParse:(Class)cls;

@end

NS_ASSUME_NONNULL_END
