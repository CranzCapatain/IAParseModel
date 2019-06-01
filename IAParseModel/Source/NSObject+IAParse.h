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

/// You can parse NSDictionary,NSData,NSString,XML.
/// @param from which need to parse.
/// @result instance from Class you pass.
+ (instancetype)ia_parseFrom:(id)from;

- (void)ia_parseForm:(id)from;

/// Parse model to json model like: NSString, NSArrary, NSDictionary.
/// Parse except C point type,Union,C Array,Bits,nomal Struct.
- (nullable id)ia_parseToJSONModel;

/// Parse model to json string
- (nullable NSString *)ia_parseToJSONString;


/// NSCoding
- (void)ia_encodeWithCoder:(NSCoder *)aCoder;
- (nullable instancetype)ia_initWithCoder:(NSCoder *)aDecoder;

/// description
- (NSString *)debugIvarsDescription;

@end


/// need to override
@interface NSObject (IAParseExtern)

/// 是否自动解析父类,NSObject,NSProxy基类并不会被解析出来,默认YES
/// @result 如果你不想自动解析父类,可重写此方法返回NO
+ (BOOL)ia_autoParseSuper;

/// 映射json中的key到模型中的key, 比如,‘id’是模型中的key,'ID'是json中的key,我们需要将它转化成‘ID’与json中的key相匹配,可写成 return @{@"ID":@"id"}
/// @result @{@"ID":@"id"}
+ (NSDictionary *)ia_mapKeysToModelKeys;


/// 将模型中的key对应的数组类型做映射
/// @result @{@"items":cls}
+ (NSDictionary *)ia_classInModelArrayForKeys;

/// 是否缓存类的属性变量信息
/// @result 默认返回NO
+ (BOOL)ia_notCacheClass;

@end

NS_ASSUME_NONNULL_END
