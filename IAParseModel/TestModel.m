//
//  TestModel.m
//  IAParseModel
//
//  Created by 金峰 on 2018/8/18.
//  Copyright © 2018年 IA.Alter.com. All rights reserved.
//

#import "TestModel.h"
#import "NSObject+IAParse.h"

@implementation TestModel

- (NSDictionary *)classInModelArrayForKeys {
    return @{@"subs":[SubModel class]};
}


- (NSDictionary *)replaceKeysForKeys {
    return @{@"ID":@"id"};
}

@end
