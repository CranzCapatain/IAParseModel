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

#pragma mark - ParseMachine
@class IAClassInfo, IAPropertyInfo, IAVarInfo;
@interface IAParseMachine : NSObject

@property (nonatomic, strong, readonly, class) IAParseMachine *sharedInstance;

@end

@implementation IAParseMachine

+ (IAParseMachine *)sharedInstance {
    static IAParseMachine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

@end


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

#pragma mark - Class Info

@interface IAClassInfo : NSObject {
    Class _cls;
    Class _superCls;
    NSArray <IAPropertyInfo *>*_propertys;
    NSArray <IAVarInfo *>*_ivars;
}

- (instancetype)initWithCls:(Class)cls;

@end

@implementation IAClassInfo

- (instancetype)initWithCls:(Class)cls {
    if (self = [super init]) {
        _cls = cls;
        _superCls = class_getSuperclass(cls);
        _propertys = p_parseClassInfo_propertys(cls);
        _ivars = p_parseClassInfo_ivars(cls);
    }
    return self;
}

@end


#pragma mark - Property Info

@interface IAPropertyInfo : NSObject {
    objc_property_t _property_t;
    const char *_name;
    kTypeEncodings _encodingType;
    bool _isObject;
    __nullable Class _objectCls;
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
                NSLog(@"ia===== type encoding error with value:%s",value);
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
        
        unsigned int outCount = 0;
        objc_property_attribute_t *attribute_t = property_copyAttributeList(p, &outCount);
        for (unsigned int i = 0; i < outCount; ++i) {
            objc_property_attribute_t a = attribute_t[i];
            const char *name = a.name;
            const char *value = a.value;
            NSLog(@"ia====== property-name:%s, attribute-{name:%s,value:%s}",_name,name,value);
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
    Ivar _ivar;
    const char *_name;
    kTypeEncodings _encodingType;
    __nullable Class _objectCls;
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
    }
    return self;
}

@end

#warning 考虑下多线程的情况
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







#pragma mark - Public

@implementation NSObject (IAParse)

+ (instancetype)ia_parseFrom:(id)from {
    return [self new];
}

- (void)ia_parseForm:(id)from {
    
}

- (void)testParse:(Class)cls {
    
    IAClassInfo *info = [[IAClassInfo alloc] initWithCls:cls];
//    NSLog(@"%@",info);
}

@end
