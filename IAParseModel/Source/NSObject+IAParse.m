//
//  NSObject+IAParse.m
//  IAParseModel
//
//  Created by JinFeng on 2019/4/25.
//  Copyright © 2019 Netease. All rights reserved.
//

#import "NSObject+IAParse.h"
#import <objc/runtime.h>

#define kOPEN_PARSE_LOG 1

@class IAClassInfo, IAPropertyInfo, IAIvarInfo;


/**
 Get the type from Documents.

 Objective-C type encodings
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 
 Property Type String.
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 */

typedef enum : unsigned {
    /// ?
    kTypeEncodingsUnknownType = 0,
    /// c : char
    kTypeEncodingsChar,
    /// i : int
    kTypeEncodingsInt,
    /// s : short
    kTypeEncodingsShort,
    /// l : long
    kTypeEncodingsLong,
    /// q : longlong
    kTypeEncodingsLongLong,
    /// C : unsigned char
    kTypeEncodingsUnsignedChar,
    /// I : unsigned int
    kTypeEncodingsUnsignedInt,
    /// S : unsigned short
    kTypeEncodingsUnsignedShort,
    /// L : unsigned long
    kTypeEncodingsUnsignedLong,
    /// Q : unsigned long long
    kTypeEncodingsUnsignedLongLong,
    /// f : float
    kTypeEncodingsFloat,
    /// d : double
    kTypeEncodingsDouble,
    /// B : A C++ bool or a C99 _Bool
    kTypeEncodingsC99Bool,
    /// v : void
    kTypeEncodingsVoid,
    /// * : char *
    kTypeEncodingsCString,
    /// @ : object/id - Objective-C Class,we need use this type to pasrse.
    kTypeEncodingsObject,
    /// # : Class
    kTypeEncodingsClass,
    /// : : SEL
    kTypeEncodingsSEL,
    /// {name=type...} : {CGSize=dd}...
    kTypeEncodingsStruct,
    /// [array type] : [int]
    kTypeEncodingsArray,
    /// (name=type...)
    kTypeEncodingsUnion,
    /// bnum
    kTypeEncodingsBits,
    /// ^type : int * = ^i...
    kTypeEncodingsPointType,
} kTypeEncodings;

typedef enum : unsigned {
    kPropertyTypeEncodingsNone = 1,
    /// R : readonly
    kPropertyTypeEncodingsReadonly = 1 << 1,
    /// C : copy
    kPropertyTypeEncodingsCopy     = 1 << 2,
    /// & : retain
    kPropertyTypeEncodingsRetain   = 1 << 3,
    /// N : nonatomic
    kPropertyTypeEncodingsNonatomic = 1 << 4,
    /// G<name> : a custom getter selector name,The name follows the G (for example, GcustomGetter,).
    kPropertyTypeEncodingsCustomGetter = 1 << 5,
    /// S<name> : a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
    kPropertyTypeEncodingsCustomSetter = 1 << 6,
    /// D : @dynamic
    kPropertyTypeEncodingsDynamic  = 1 << 7,
    /// W : weak
    kPropertyTypeEncodingsWeak     = 1 << 8,
    /// P : The property is eligible for garbage collection.
    kPropertyTypeEncodingsGarbageCollection = 1 << 9,
    /// t<encoding>
    kPropertyTypeEncodingsOldEndcoding = 1 << 10,
} kPropertyTypeEncodings;

NSArray * p_parseClassInfo_propertys(Class cls);
NSArray * p_parseClassInfo_ivars(Class cls);
static bool p_isCustomClass(Class cls);

static NSDictionary *nsClsMap = nil;
static bool p_isCustomClass(Class cls) {
    nsClsMap = @{@"NSString":@1,
                 @"NSMutableString":@1,
                 @"NSArray":@1,
                 @"NSMutableArray":@1,
                 @"NSDictionary":@1,
                 @"NSMutableDictionary":@1,
                 @"NSSet":@1,
                 @"NSMutableSet":@1,
                 @"NSData":@1,
                 @"NSMutableData":@1,
                 @"NSNumber":@1
                                      };
    if (!cls
        || nsClsMap[NSStringFromClass(cls)] != nil) {
        return false;
    }
    return true;
}


#pragma mark - Property Info

@interface IAPropertyInfo : NSObject {
    @public
    objc_property_t _property_t;
    const char *_name;
    kTypeEncodings _encodingType;
    bool _isObject;
    __nullable Class _objectCls;
    bool _isCustomCls;
    bool _isTypeArray;
    bool _isTypeSet;
    kPropertyTypeEncodings _propertyEncodingTypes;
    const char *_ivarName; // ivar name like: @property int age; _ivarName = "_age";
}

- (instancetype)initWithProperty_t:(const objc_property_t)p;

@end

@implementation IAPropertyInfo

kTypeEncodings p_parseTypeEncoding(Class *cls, const char *value) {
    kTypeEncodings type = kTypeEncodingsUnknownType;
    char n0 = value[0];
    switch (n0) {
        case 'c':
            type = kTypeEncodingsChar;
            break;
        case 's':
            type = kTypeEncodingsShort;
            break;
        case 'l':
            type = kTypeEncodingsLong;
            break;
        case 'q':
            type = kTypeEncodingsLongLong;
            break;
        case 'C':
            type = kTypeEncodingsUnsignedChar;
            break;
        case 'I':
            type = kTypeEncodingsUnsignedInt;
            break;
        case 'S':
            type = kTypeEncodingsUnsignedShort;
            break;
        case 'L':
            type = kTypeEncodingsUnsignedLong;
            break;
        case 'Q':
            type = kTypeEncodingsUnsignedLongLong;
            break;
        case 'f':
            type = kTypeEncodingsFloat;
            break;
        case 'd':
            type = kTypeEncodingsDouble;
            break;
        case 'B':
            type = kTypeEncodingsC99Bool;
            break;
        case 'v':
            type = kTypeEncodingsVoid;
            break;
        case '*':
            type = kTypeEncodingsCString;
            break;
        case '@':
        {
            type = kTypeEncodingsObject;
            // "@\"NSString\""
            if (strlen(value) > 3) {
                NSString *valueString = [NSString stringWithUTF8String:value];
                NSString *classString = [valueString substringWithRange:NSMakeRange(2, strlen(value) - 3)];
                *cls = NSClassFromString(classString);
            } else {
                NSLog(@"Error⚠️:The type encoding parse error with value:%s",value);
            }
        }
            break;
        case '#':
            type = kTypeEncodingsClass;
            break;
        case ':':
            type = kTypeEncodingsSEL;
            break;
        case '[':
            type = kTypeEncodingsArray;
            break;
        case '{':
            type = kTypeEncodingsStruct;
            break;
        case '(':
            type = kTypeEncodingsUnion;
            break;
        case 'b':
            type = kTypeEncodingsBits;
            break;
        case '^':
            type = kTypeEncodingsPointType;
            break;
        default:
            break;
    }
    return type;
}

- (instancetype)initWithProperty_t:(const objc_property_t)p {
    if (self = [super init]) {
        _property_t = p;
        _name = property_getName(p);
        _propertyEncodingTypes = kPropertyTypeEncodingsNone;
        _isCustomCls = false;
        
        unsigned int outCount = 0;
        objc_property_attribute_t *attribute_t = property_copyAttributeList(p, &outCount);
        for (unsigned int i = 0; i < outCount; ++i) {
            objc_property_attribute_t a = attribute_t[i];
            const char *name = a.name;
            const char *value = a.value;
            char n0 = name[0];
            switch (n0) {
                case 'T':
                {
                    Class objectCls = nil;
                    _encodingType = p_parseTypeEncoding(&objectCls, value);
                    if (objectCls) {
                        self->_isObject = true;
                        self->_objectCls = objectCls;
                    }
                    _isCustomCls = p_isCustomClass(_objectCls);
                    _isTypeArray = (_objectCls == [NSArray class] || _objectCls == [NSMutableArray class]);
                    _isTypeSet = (_objectCls == [NSSet class] || _objectCls == [NSMutableSet class]);
                }
                    break;
                case 'V':
                    _ivarName = name;
                    break;
                case 'R':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsReadonly;
                    break;
                case 'C':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsCopy;
                    break;
                case '&':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsRetain;
                    break;
                case 'N':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsNonatomic;
                    break;
                case 'G':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsCustomGetter;
                    break;
                case 'S':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsCustomSetter;
                    break;
                case 'D':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsDynamic;
                    break;
                case 'W':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsWeak;
                    break;
                case 'P':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsGarbageCollection;
                    break;
                case 't':
                    _propertyEncodingTypes |= kPropertyTypeEncodingsOldEndcoding;
                    break;
                default:
                    break;
            }
        }
    }
    return self;
}

@end

#pragma mark - Ivar Info


@interface IAIvarInfo : NSObject {
@public
    Ivar _ivar;
    const char *_name;
    const char * _Nullable _pname; // 这个是属性的名字，如果有属性那么会有这个值，否则就是NULL
    kTypeEncodings _encodingType;
    __nullable Class _objectCls;
    bool _isCustomCls;
    bool _isTypeArray;
    bool _isTypeSet;
    __nullable id _value; // 成员变量的值
}

- (instancetype)initWithIvar:(Ivar)ivar;

@end

@implementation IAIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    self = [super init];
    if (self) {
        _ivar = ivar;
        _name = ivar_getName(ivar);
        _encodingType = p_parseTypeEncoding(&_objectCls, ivar_getTypeEncoding(ivar));
        _isCustomCls = p_isCustomClass(_objectCls);
        _isTypeArray = (_objectCls == [NSArray class] || _objectCls == [NSMutableArray class]);
        _isTypeSet = (_objectCls == [NSSet class] || _objectCls == [NSMutableSet class]);
    }
    return self;
}

@end

NSArray * p_parseClassInfo_propertys(Class cls) {
    unsigned int outCount = 0;
    objc_property_t *property_t = class_copyPropertyList(cls, &outCount);
    NSMutableArray *propertys = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; ++i) {
        objc_property_t p = property_t[i];
        IAPropertyInfo *p_info = [[IAPropertyInfo alloc] initWithProperty_t:p];
        [propertys addObject:p_info];
    }
    return propertys.copy;
}

NSArray * p_parseClassInfo_ivars(Class cls) {
    unsigned int outCount = 0;
    Ivar *ivar = class_copyIvarList(cls, &outCount);
    NSMutableArray *ivars = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; ++i) {
        Ivar ivar_t = ivar[i];
        IAIvarInfo *ivar = [[IAIvarInfo alloc] initWithIvar:ivar_t];
        [ivars addObject:ivar];
    }
    return ivars.copy;
}

#pragma mark - Class Info

@interface IAClassInfo : NSObject {
@public
    Class _cls;
    Class _superCls;
    NSArray <IAPropertyInfo *>*_propertys;
    NSArray <IAIvarInfo *>*_ivars;
}

- (instancetype)initWithCls:(Class)cls;

@end

@implementation IAClassInfo

- (instancetype)initWithCls:(Class)cls {
    if (self = [super init]) {
        _cls = cls;
        _superCls = class_getSuperclass(cls);
        _propertys = p_parseClassInfo_propertys(cls);
        NSMutableDictionary *nameMap = [NSMutableDictionary dictionaryWithCapacity:_propertys.count];
        for (IAPropertyInfo *p in _propertys) {
            nameMap[[@"_" stringByAppendingString:[NSString stringWithUTF8String:p->_name]]] = [NSString stringWithUTF8String:p->_name];
        }
        _ivars = p_parseClassInfo_ivars(cls);
        for (IAIvarInfo *ivar in _ivars) {
            ivar->_pname = [nameMap[[NSString stringWithUTF8String:ivar->_name]] UTF8String];
        }
    }
    return self;
}

@end

#pragma mark - ParseMachine

@interface IAParseMachine : NSObject

@property (nonatomic, strong, readonly, class) IAParseMachine *sharedInstance;
@property (nonatomic, strong, readonly) NSMutableDictionary *clsMapCache;

@property (nonatomic, strong, readonly) dispatch_semaphore_t syncSign;


/**
 Set value to one from 'from'.
 
 @param from can be json, dictionary...
 @param one That one needs to be set values.
 */
- (void)parse:(id)from toTempOne:(id)one;

@end

@implementation IAParseMachine

static bool p_isEqual(const char *str1, const char *str2) {
    if (str1 == NULL
        || str2 == NULL) {
        return false;
    }
    if (strcmp(str1, str2) == 0) {
        return true;
    } else if (strcmp(str1, str2) < 0) {
        // _id, id
        size_t count = strlen(str1);
        if (count == 0) {
            return false;
        }
        char *cat0 = (char *)str1;
        cat0 += 1;
        if (strcmp(cat0, str2) == 0) {
            return true;
        }
        return false;
    } else {
        return false;
    }
}

+ (IAParseMachine *)sharedInstance {
    static IAParseMachine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance->_clsMapCache = [NSMutableDictionary dictionary];
        instance->_syncSign = dispatch_semaphore_create(1);
        
        extern NSNotificationName const UIApplicationDidReceiveMemoryWarningNotification;
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(didAppReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    });
    return instance;
}

- (void)didAppReceiveMemoryWarning:(NSNotification *)noti {
    [[IAParseMachine sharedInstance] clearAllCache];
}

- (void)parse:(id)from toTempOne:(id)one {
    NSDictionary *fromToDic = [self parseToDictionary:from];
    [self parseDictionary:fromToDic toTempOne:one];
}

- (NSDictionary *)parseToDictionary:(id)from {
    if ([from isKindOfClass:[NSDictionary class]]) {
        return from;
    } else if ([from isKindOfClass:[NSString class]]) {
        NSData *data = [from dataUsingEncoding:NSUTF8StringEncoding];
        return [self parseToDictionary:data];
    } else if ([from isKindOfClass:[NSData class]]) {
        id parseOne = [NSJSONSerialization JSONObjectWithData:from options:NSJSONReadingMutableLeaves error:nil];
        if ([parseOne isKindOfClass:[NSDictionary class]]) {
            return parseOne;
        }
        NSLog(@"Error-⚠️:The 'from' is kind of NSData, but the parseOne must be NSDictionary.");
    }
    NSLog(@"Error-⚠️:Can't parse 'from', you have to check the type is NSDictionary or NSString or NSData?");
    return nil;
}

- (void)parseDictionary:(NSDictionary *)dic toTempOne:(id)one {
    if (![dic isKindOfClass:[NSDictionary class]]) return;
    Class autoParseSuperCls = nil;
    Class cls = [one class];
    do {
        if (autoParseSuperCls) {
            cls = autoParseSuperCls;
        }
        IAClassInfo *clsInfo = [IAParseMachine.sharedInstance clsInfoWithCls:cls];
        if (!clsInfo) {
            clsInfo = [[IAClassInfo alloc] initWithCls:cls];
            if (![cls ia_notCacheClass]) {
                [IAParseMachine.sharedInstance setClassInfo:clsInfo forCls:cls];
            }
        }
        
        // set value for key
        NSArray *keys = [dic allKeys];
        NSDictionary *keyMap = [cls ia_mapKeysToModelKeys];
        if (clsInfo->_propertys.count == clsInfo->_ivars.count) {
            for (IAPropertyInfo *property in clsInfo->_propertys) {
                for (NSString *key in keys) {
                    NSString *setKey = keyMap[key];
                    if (!setKey) {
                        setKey = key;
                    }
                    if ([self setValueForKey:key setKey:setKey sourceDic:dic traverseProperty:property toTempOne:one]) {
                        break;
                    }
                }
            }
        } else {
            for (IAIvarInfo *ivar in clsInfo->_ivars) {
                for (NSString *key in keys) {
                    NSString *setKey = keyMap[key];
                    if (!setKey) {
                        setKey = key;
                    }
                    if ([self setValueForKey:key setKey:setKey sourceDic:dic traverseIvar:ivar toTempOne:one]) {
                        break;
                    }
                }
            }
        }
        
        autoParseSuperCls = clsInfo->_superCls;
        if (autoParseSuperCls == [NSObject class]
            || autoParseSuperCls == [NSProxy class]) {
            break;
        }
    } while ([cls ia_autoParseSuper] && autoParseSuperCls);
}

- (BOOL)setValueForKey:(NSString *)key
                setKey:(NSString *)setKey
             sourceDic:(NSDictionary *)dic
          traverseIvar:(IAIvarInfo *)ivar
             toTempOne:(id)one {
    if (p_isEqual(ivar->_name, setKey.UTF8String)) {
        if (ivar->_isCustomCls == true) {
            Class objectCls = ivar->_objectCls;
            id obj = [objectCls new];
            [self parseDictionary:dic[key] toTempOne:obj];
            [one setValue:obj forKey:setKey];
            return YES;
        } else if (ivar->_isTypeArray == true) {
            NSDictionary *clsMap = [[one class] ia_classInModelArrayForKeys];
            NSArray *valueArr = dic[key];
            if ([valueArr isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray arrayWithCapacity:valueArr.count];
                Class cls = clsMap[setKey];
                if (!cls) {
                    [one setValue:dic[key] forKey:setKey];
                    return YES;
                }
                for (id value in valueArr) {
                    id one = [cls new];
                    [self parse:value toTempOne:one];
                    [array addObject:one];
                }
                [one setValue:array.copy forKey:setKey];
                return YES;
            } else {
                NSLog(@"Error⚠️:The key %@ not 'Array' type in source dic:%@",setKey,dic);
                return YES;
            }
        } else if (ivar->_isTypeSet == true) {
            NSDictionary *clsMap = [[one class] ia_classInModelArrayForKeys];
            NSArray *valueArr = dic[key];
            if ([valueArr isKindOfClass:[NSArray class]]) {
                NSMutableSet *set = [NSMutableSet setWithCapacity:valueArr.count];
                Class cls = clsMap[setKey];
                if (!cls) {
                    [one setValue:dic[key] forKey:setKey];
                    return YES;
                }
                for (id value in valueArr) {
                    id one = [cls new];
                    [self parse:value toTempOne:one];
                    [set addObject:one];
                }
                [one setValue:set.copy forKey:setKey];
                return YES;
            } else {
                NSLog(@"Error⚠️:The key %@ not 'Set' type in source dic:%@",setKey,dic);
                return YES;
            }
        } else {
            [one setValue:dic[key] forKey:setKey];
            return YES;
        }
    }
    return NO;
}

- (BOOL)setValueForKey:(NSString *)key
                setKey:(NSString *)setKey
             sourceDic:(NSDictionary *)dic
      traverseProperty:(IAPropertyInfo *)property
             toTempOne:(id)one {
    if (!key
        || !setKey) {
        return NO;
    }
    if (strcmp(property->_name, setKey.UTF8String) == 0) {
        if (property->_isCustomCls == true) {
            Class objectCls = property->_objectCls;
            id obj = [objectCls new];
            [self parseDictionary:dic[key] toTempOne:obj];
            [one setValue:obj forKey:setKey];
            return YES;
        } else if (property->_isTypeArray) {
            NSDictionary *clsMap = [[one class] ia_classInModelArrayForKeys];
            NSArray *valueArr = dic[key];
            if ([valueArr isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray arrayWithCapacity:valueArr.count];
                Class cls = clsMap[setKey];
                if (!cls) {
                    [one setValue:dic[key] forKey:setKey];
                    return YES;
                }
                for (id value in valueArr) {
                    id one = [cls new];
                    [self parse:value toTempOne:one];
                    [array addObject:one];
                }
                [one setValue:array.copy forKey:setKey];
                return YES;
            } else {
                NSLog(@"Error⚠️:The key %@ not 'Array' type in source dic:%@",setKey,dic);
                return YES;
            }
        } else if (property->_isTypeSet) {
            NSDictionary *clsMap = [[one class] ia_classInModelArrayForKeys];
            NSArray *valueArr = dic[key];
            if ([valueArr isKindOfClass:[NSArray class]]) {
                NSMutableSet *set = [NSMutableSet setWithCapacity:valueArr.count];
                Class cls = clsMap[setKey];
                if (!cls) {
                    [one setValue:dic[key] forKey:setKey];
                    return YES;
                }
                for (id value in valueArr) {
                    id one = [cls new];
                    [self parse:value toTempOne:one];
                    [set addObject:one];
                }
                [one setValue:set.copy forKey:setKey];
                return YES;
            } else {
                NSLog(@"Error⚠️:The key %@ not 'Set' type in source dic:%@",setKey,dic);
                return YES;
            }
        } else {
            [one setValue:dic[key] forKey:setKey];
            return YES;
        }
    }
    return NO;
}

// transfer to NSString,NSArray,NSDictionary
- (id)parseToJSONModelWithObj:(id)target {
    if (!target
        || [target isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([target isKindOfClass:[NSString class]]
        || [target isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@",target];
    }
    if ([target isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:target encoding:NSUTF8StringEncoding];
    }
    if ([target isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:target]) {
            return target;
        } else {
            NSMutableDictionary *jsonDic = [NSMutableDictionary dictionary];
            [((NSDictionary *)target) enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                jsonDic[key] = [self parseToJSONModelWithObj:obj];
            }];
            return jsonDic.copy;
        }
    }
    if ([target isKindOfClass:[NSArray class]]) {
        id obj = ((NSArray *)target).firstObject;
        if (obj == nil
            || [obj isKindOfClass:[NSNull class]]) {
            return nil;
        }
        if ([NSJSONSerialization isValidJSONObject:target]) {
            return target;
        } else {
            NSMutableArray *jsonArr = [NSMutableArray array];
            [((NSArray *)target) enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [jsonArr addObject:[self parseToJSONModelWithObj:obj]];
            }];
            return jsonArr.copy;
        }
    }
    if ([target isKindOfClass:[NSSet class]]) {
        id obj = ((NSSet *)target).anyObject;
        if (obj == nil
            || [obj isKindOfClass:[NSNull class]]) {
            return nil;
        }
        if ([NSJSONSerialization isValidJSONObject:target]) {
            return target;
        } else {
            NSMutableArray *jsonArr = [NSMutableArray array];
            [((NSSet *)target) enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                [jsonArr addObject:[self parseToJSONModelWithObj:obj]];
            }];
            return jsonArr.copy;
        }
    }
    
    Class cls = [target class];
    if (p_isCustomClass(cls)) {
        NSMutableDictionary *jsonDic = [NSMutableDictionary dictionary];
        Class superCls = nil;
        do {
            if (superCls) {
                cls = superCls;
            }
            IAClassInfo *clsInfo = [IAParseMachine.sharedInstance clsInfoWithCls:cls];
            if (!clsInfo) {
                clsInfo = [[IAClassInfo alloc] initWithCls:cls];
                if (![cls ia_notCacheClass]) {
                    [IAParseMachine.sharedInstance setClassInfo:clsInfo forCls:cls];
                }
                
                if (superCls) {
                    // 正在调用父类的信息
                    for (IAIvarInfo *ivarInfo in clsInfo->_ivars) {
                        if (ivarInfo->_pname != NULL) {
                            [jsonDic setValue:[target valueForKey:[NSString stringWithUTF8String:ivarInfo->_pname]] forKey:[NSString stringWithUTF8String:ivarInfo->_pname]];
                        } else {
                            [jsonDic setValue:[target valueForKey:[NSString stringWithUTF8String:ivarInfo->_name]] forKey:[NSString stringWithUTF8String:ivarInfo->_name]];
                        }
                    }
                }
            }
            for (IAIvarInfo *ivarInfo in clsInfo->_ivars) {
                NSString *key = ivarInfo->_pname ? [NSString stringWithUTF8String:ivarInfo->_pname] : [NSString stringWithUTF8String:ivarInfo->_name];
                switch (ivarInfo->_encodingType) {
                    case kTypeEncodingsChar: {
                        char val = ((char (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:[NSString stringWithFormat:@"%c",val] forKey:key];
                        break;
                    }
                    case kTypeEncodingsInt: {
                        int val = ((int (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsShort: {
                        short val = ((short (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsLong: {
                        long val = ((long (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsLongLong: {
                        long long val = ((long long (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsUnsignedChar: {
                        unsigned char val = ((unsigned char (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsUnsignedInt: {
                        unsigned int val = ((unsigned int (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsUnsignedShort: {
                        unsigned short val = ((unsigned short (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsUnsignedLong: {
                        unsigned long val = ((unsigned long (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsUnsignedLongLong: {
                        unsigned long long val = ((unsigned long long (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsFloat: {
                        float val = ((float (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsDouble: {
                        double val = ((double (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsC99Bool: {
                        bool val = ((bool (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:@(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsVoid: {
                        [jsonDic setObject:[NSNull new] forKey:key];
                        break;
                    }
                    case kTypeEncodingsCString: {
                        char * val = ((char * (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:[NSString stringWithUTF8String:val] forKey:key];
                        break;
                    }
                    case kTypeEncodingsObject: {
                        id value = object_getIvar(target, ivarInfo->_ivar);
                        [jsonDic setObject:[self parseToJSONStringWithObj:value] forKey:key];
                        break;
                    }
                    case kTypeEncodingsClass: {
                        Class val = ((Class (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:NSStringFromClass(val) forKey:key];
                        break;
                    }
                    case kTypeEncodingsSEL: {
                        SEL val = ((SEL (*)(id, Ivar))object_getIvar)(target, ivarInfo->_ivar);
                        [jsonDic setObject:NSStringFromSelector(val) forKey:key];
                        break;
                    }
                    default:
                        break;
                }
            }
            superCls = clsInfo->_superCls;
        } while ([cls ia_autoParseSuper] && superCls);
        return [self parseToJSONModelWithObj:jsonDic.copy];
    }
    return nil;
}

- (NSString *)parseToJSONStringWithObj:(id)target {
    if (!target || [target isKindOfClass:[NSNull class]]) {
        return nil;
    }
    id jsonModel = [self parseToJSONModelWithObj:target];
    if ([jsonModel isKindOfClass:[NSString class]]) {
        return jsonModel;
    }
    if ([jsonModel isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:jsonModel encoding:NSUTF8StringEncoding];
    }
    if ([jsonModel isKindOfClass:[NSArray class]]
        || [jsonModel isKindOfClass:[NSDictionary class]]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonModel options:NSJSONWritingPrettyPrinted error:nil];
        return [self parseToJSONStringWithObj:data];
    }
    return nil;
}

#pragma mark cache

- (void)clearAllCache {
    dispatch_semaphore_wait(self.syncSign, DISPATCH_TIME_FOREVER);
    [self.clsMapCache removeAllObjects];
    dispatch_semaphore_signal(self.syncSign);
}

- (void)clearCacheForClass:(Class)cls {
    dispatch_semaphore_wait(self.syncSign, DISPATCH_TIME_FOREVER);
    [self.clsMapCache removeObjectForKey:NSStringFromClass(cls)];
    dispatch_semaphore_signal(self.syncSign);
}

- (IAClassInfo *)clsInfoWithCls:(Class)cls {
    dispatch_semaphore_wait(self.syncSign, DISPATCH_TIME_FOREVER);
    id obj = [self.clsMapCache objectForKey:NSStringFromClass(cls)];
    dispatch_semaphore_signal(self.syncSign);
    return obj;
}

- (void)setClassInfo:(IAClassInfo *)clsInfo forCls:(Class)cls {
    if (!cls) return;
    dispatch_semaphore_wait(self.syncSign, DISPATCH_TIME_FOREVER);
    [self.clsMapCache setObject:clsInfo forKey:NSStringFromClass(cls)];
    dispatch_semaphore_signal(self.syncSign);
}

@end


#pragma mark - Public

@implementation NSObject (IAParse)

+ (instancetype)ia_parseFrom:(id)from {
    id one = [self new];
    [[IAParseMachine sharedInstance] parse:from toTempOne:one];
    return one;
}

- (void)ia_parseForm:(id)from {
    [[IAParseMachine sharedInstance] parse:from toTempOne:self];
}

- (NSString *)ia_parseToJSONString {
    return [[IAParseMachine sharedInstance] parseToJSONStringWithObj:self];
}

- (id)ia_parseToJSONModel {
    return [[IAParseMachine sharedInstance] parseToJSONModelWithObj:self];
}

@end


@implementation NSObject (IAParseExtern)

+ (BOOL)ia_autoParseSuper {
    return YES;
}

+ (NSDictionary *)ia_mapKeysToModelKeys {
    return nil;
}

+ (NSDictionary *)ia_classInModelArrayForKeys {
    return nil;
}

+ (BOOL)ia_notCacheClass {
    return NO;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"ia====== <%@> can't parse with key:%@,value:%@, you should check type encoding",self.class,key,value);
}

@end
