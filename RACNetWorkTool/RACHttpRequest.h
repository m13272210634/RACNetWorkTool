//
//  RACHttpRequest.h
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACHttpParams.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
@class RACHttpResponse;
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RACHTTPRequestSerializer) {
   RACHTTPRequestSerializerHTTP  = 0,
   RACHTTPRequestSerializerJSON,
};

@interface RACHttpRequest : NSObject
/**
 请求参数
 */
@property(nonatomic , readonly ,strong)RACHttpParams   * requestParams;

@property(nonatomic,assign)RACHTTPRequestSerializer   requestSerializerType;

@property(nonatomic, strong)Class responseClass;

@property(nonatomic, strong)RACHttpResponse*response;


+ (instancetype)rac_RequestWithParams:(RACHttpParams*)params;

@end


@interface RACHttpRequest(RACHttpSerice)

// request 直接发起请求
- (RACSignal*)rac_RequestWithResponseClass:(Class)responseClass;

@end

NS_ASSUME_NONNULL_END
