//
//  RACHttpConstKey.h
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const RACHttpServiceDomainKey;

//服务器连接失败
extern NSInteger const RACHttpServiceErrorServiceFailed;

//请求失败
extern NSInteger const RACHttpServiceErrorRequestFailed;

//连接失败
extern NSInteger const RACHttpServiceErrorConnectFailed;

//请求出错
extern NSInteger const RACHttpServiceErrorBadRequest;

//解析错误
extern NSInteger const RACHttpServiceErrorJSONFailed;

//服务器拒绝请求
extern NSInteger const  RACHttpServiceForBiddenRequest;

//URL
extern NSString * const RACHTTPServiceErrorRequestURLKey;
//状态码
extern NSString * const RACHTTPServiceErrorHTTPStatusCodeKey;
//描述
extern NSString * const RACHTTPServiceErrorDescriptionKey ;
//信息
extern NSString * const RACHTTPServiceErrorMessagesKey;


/* 响应key   */
extern NSString * const RACHttpResponseCodeKey;

extern NSString * const RACHttpResponseMsgKey;

extern NSString * const RACHttpResponseDataKey;

extern NSString * const RACHttpResponseListKey;

extern NSInteger  const RACHttpResponseSuccessCode;


NS_ASSUME_NONNULL_END
