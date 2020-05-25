//
//  RACHttpResponse.m
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/31.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "RACHttpResponse.h"
#import "RACHttpConstKey.h"
@interface RACHttpResponse ()

/// The parsed MHObject object corresponding to the API response.
/// The developer need care this data
@property (nonatomic, readwrite, strong) id parsedResult;
/// 自己服务器返回的状态码
@property (nonatomic, readwrite, assign) JNHTTPResponseCode code;
/// 自己服务器返回的信息
@property (nonatomic, readwrite, copy) NSString *msg;

@end

@implementation RACHttpResponse

- (instancetype)initWithResponseObject:(id)responseObject parsedResult:(id)parsedResult
{
    self = [super init];
    if (self) {
        self.parsedResult = parsedResult ?:NSNull.null;
        self.code = [responseObject[RACHttpResponseCodeKey] integerValue];
        self.msg = responseObject[RACHttpResponseMsgKey];
    }
    return self;
}
@end
