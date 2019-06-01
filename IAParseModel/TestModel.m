//
//  TestModel.m
//  IAParseModel
//
//  Created by 金峰 on 2018/8/18.
//  Copyright © 2018年 IA.Alter.com. All rights reserved.
//

#import "TestModel.h"
#import "NSObject+IAParse.h"
#import <YYModel.h>

@implementation TestModel

+ (NSDictionary *)ia_classInModelArrayForKeys {
    return @{@"array":[SubModel class]};
}

+ (BOOL)ia_notCacheClass {
    return NO;
}

+ (BOOL)ia_autoParseSuper {
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self ia_encodeWithCoder:aCoder];
//    [self yy_modelEncodeWithCoder:aCoder];
}
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self ia_initWithCoder:aDecoder];
//    return [self yy_modelInitWithCoder:aDecoder];
}

@end
