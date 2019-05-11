//
//  TestModel.h
//  IAParseModel
//
//  Created by 金峰 on 2018/8/18.
//  Copyright © 2018年 IA.Alter.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubModel.h"
#import <UIKit/UIKit.h>
#import "TestBaseModel.h"

@interface TestModel : TestBaseModel

{
    SubModel *_sub;
//    int _ii;
}

/*
 name = T,value = {CGRect={CGPoint=dd}{CGSize=dd}}
 name = N,value =
 name = V,value = _rect
 */
@property (nonatomic, assign) CGRect rect;
//@property (nonatomic, assign) CGPoint p;
//@property (nonatomic, assign) CGSize size;
//@property (nonatomic, assign) UIOffset offset;
//@property (nonatomic, assign) UIEdgeInsets edges;
//@property (nonatomic, assign) CGAffineTransform a;
//@property (nonatomic, assign) CGVector v;

/*
 name = T,value = ^i
 name = N,value =
 name = V,value = _point
 */
@property (nonatomic, assign) int *point;

/**
 name = T,value = @"NSString"
 name = C,value =
 name = N,value =
 name = V,value = _name
 */
//@property (nonatomic, copy) NSString *name;

/**
 name = T,value = i
 name = V,value = _age
 */
//@property (atomic, assign) int age;

/**
 name = T,value = @"NSArray"
 name = W,value =
 name = N,value =
 name = V,value = _array
 */
@property (nonatomic, strong) NSArray *array; // SubModel


/**
 name = T,value = @"SubModel"
 name = &,value =
 name = N,value =
 name = G,value = myGetModel
 name = S,value = mySetIAModel:
 name = V,value = _model
 */
@property (nonatomic, strong, setter=mySetIAModel:,getter=myGetModel) SubModel *model;

/**
 name = T,value = @"NSDictionary"
 name = &,value =
 name = N,value =
 name = V,value = _dic
 */
@property (nonatomic, retain, readwrite) NSDictionary *dic;

/**
 name = T,value = @"NSNumber"
 name = R,value =
 name = N,value =
 name = V,value = _num
 */
//@property (nonatomic, strong, readonly) NSNumber *num;

@property (nonatomic, strong) NSDate *date;
@end
