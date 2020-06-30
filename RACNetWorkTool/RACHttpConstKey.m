//
//  RACHttpConstKey.m
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "RACHttpConstKey.h"


NSString * const RACHttpServiceDomainKey = @"RACHttpServiceDomainKey";

NSInteger const RACHttpServiceErrorServiceFailed = 668;

NSInteger const RACHttpServiceErrorRequestFailed = 672;

NSInteger const RACHttpServiceErrorConnectFailed = 673;

NSInteger const RACHttpServiceErrorBadRequest = 670;

NSInteger const RACHttpServiceErrorJSONFailed = 669;

NSInteger const RACHttpServiceForBiddenRequest = 671;



NSString * const RACHTTPServiceErrorRequestURLKey = @"RACHTTPServiceErrorRequestURLKey";

NSString * const RACHTTPServiceErrorHTTPStatusCodeKey = @"RACHTTPServiceErrorHTTPStatusCodeKey";

NSString * const RACHTTPServiceErrorDescriptionKey = @"RACHTTPServiceErrorDescriptionKey";

NSString * const RACHTTPServiceErrorMessagesKey =
    @"RACHTTPServiceErrorMessagesKey";



/* 响应key   */
NSString * const RACHttpResponseCodeKey = @"code";

NSString * const RACHttpResponseMsgKey = @"msg";

NSString * const RACHttpResponseDataKey = @"data";

NSString * const RACHttpResponseListKey = @"rows";

NSInteger  const RACHttpResponseSuccessCode = 0;
