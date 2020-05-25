//
//  RACHttpParams.m
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "RACHttpParams.h"
#import <objc/runtime.h>

static RACExtersionParams * _params;
@implementation RACExtersionParams

//+ (instancetype)extersionParams
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _params = [[self alloc]init];
//    });
//    return _params;
//}

- (NSString *)ver{
    static NSString *version = nil;
    if (version == nil) version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    return (version.length>0)?version:@"1";
}

- (NSString *)token {
    return @"1";
}

- (NSString *)deviceid {
    return @"1";
}

- (NSString *)platform{
    return @"iOS";
}

- (NSString *)channel{
    return @"AppStore";
}

- (NSString *)t {
    return [NSString stringWithFormat:@"%.f", [NSDate date].timeIntervalSince1970];
}

@end


@implementation RACHttpParamsBody
@end


@implementation RACHttpParams

+(instancetype)rac_httpParamsWithMethod:(NSString *)method path:(NSString *)path parameters:(RACHttpParamsBody *)body
{
    return [[self alloc]initHttpParamsWithMethod:method path:path parameters:body];
}

- (instancetype)initHttpParamsWithMethod:(NSString *)method path:(NSString *)path parameters:(RACHttpParamsBody *)body
{
    self = [super init];
    if (self) {
        _method             = method;
        _body               = body;
        _urlPath            = path;
        _extersionParmas    = [[RACExtersionParams alloc]init];
    }return self;
}

- (NSDictionary*)params{
    NSDictionary * exterParams =  [self dicFromObject:_extersionParmas];
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]initWithDictionary:exterParams];
    [dic addEntriesFromDictionary:[self dicFromObject:_body]];
    return dic;
}

//model转化为字典
- (NSDictionary *)dicFromObject:(NSObject *)object {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    Class cls = [object class];
    while (cls) {
        NSDictionary *tempDic = [self modelToDicWithClass:cls object:object];
        [dic setValuesForKeysWithDictionary:tempDic];
        cls = class_getSuperclass(cls);
        if ([cls isKindOfClass:RACHttpParamsBody.class] || [object isKindOfClass:RACHttpParamsBody.class]|| [cls isKindOfClass:RACExtersionParams.class] ||  [object isKindOfClass:RACExtersionParams.class]) {
            break;
        }
    }
    return dic;
}

- (NSDictionary*)modelToDicWithClass:(Class)cls object:(NSObject*)obj{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList(cls, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = propertyList[i];
        const char *cName = property_getName(property);
        NSString *name = [NSString stringWithUTF8String:cName];
        NSObject *value = [obj valueForKey:name];//valueForKey返回的数字和字符串都是对象
        
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            [dic setObject:value forKey:name];
        } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            //字典或字典
            [dic setObject:[self arrayOrDicWithObject:(NSArray*)value] forKey:name];
            
        } else if (value == nil|| value == NULL) {
            //null
            //[dic setObject:[NSNull null] forKey:name];
        } else {
            //model
            [dic setObject:[self dicFromObject:value] forKey:name];
        }
    }
    
    return [dic copy];
}

//将可能存在model数组转化为普通数组
- (id)arrayOrDicWithObject:(id)origin {
    if ([origin isKindOfClass:[NSArray class]]) {
        //数组
        NSMutableArray *array = [NSMutableArray array];
        for (NSObject *object in origin) {
            if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]) {
                //string , bool, int ,NSinteger
                [array addObject:object];
                
            } else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
                //数组或字典
                [array addObject:[self arrayOrDicWithObject:(NSArray *)object]];
                
            } else {
                //model
                [array addObject:[self dicFromObject:object]];
            }
        }
        
        return [array copy];
        
    } else if ([origin isKindOfClass:[NSDictionary class]]) {
        //字典
        NSDictionary *originDic = (NSDictionary *)origin;
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSString *key in originDic.allKeys) {
            id object = [originDic objectForKey:key];
            
            if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]) {
                //string , bool, int ,NSinteger
                [dic setObject:object forKey:key];
                
            } else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
                //数组或字典
                [dic setObject:[self arrayOrDicWithObject:object] forKey:key];
                
            } else {
                //model
                [dic setObject:[self dicFromObject:object] forKey:key];
            }
        }
        
        return [dic copy];
    }
    
    return [NSNull null];
}

@end
