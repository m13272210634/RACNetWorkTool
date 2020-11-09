//
//  RACHttpParams.h
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RACExtersionParams : NSObject

/// 类方法
+ (instancetype)extersionParams;

/// 用户token，默认空字符串
@property (nonatomic, readonly, copy) NSString *token;

/// 设备编号，自行生成
@property (nonatomic, readonly, copy) NSString *deviceid;

/// app版本号
@property (nonatomic, readonly, copy) NSString *ver;

/// 平台 pc,wap,android,iOS
@property (nonatomic, readonly, copy) NSString *platform;

/// 渠道 AppStore
@property (nonatomic, strong) NSString *channel;

/// 时间戳
@property (nonatomic, strong) NSString *t;

@end


@interface RACHttpParamsBody : NSObject

@end


@interface RACHttpParams : NSObject

@property(nonatomic,strong)NSString   * urlPath;//链接

@property(nonatomic,strong)NSString   * method;//方法

//@property(nonatomic,strong)NSDictionary   * params;

@property(nonatomic,strong)RACHttpParamsBody   * body;//请求参数

@property(nonatomic,strong)RACExtersionParams   * extersionParmas;//扩展参数

+(instancetype)rac_httpParamsWithMethod:(NSString *)method path:(NSString *)path parameters:(RACHttpParamsBody *)body;

- (NSDictionary*)params;

@end


NS_ASSUME_NONNULL_END
