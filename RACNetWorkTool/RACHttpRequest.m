//
//  RACHttpRequest.m
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "RACHttpRequest.h"
#import "RACHttpService.h"

@interface RACHttpRequest ()

@property(nonatomic , readwrite ,strong)RACHttpParams   * requestParams;

@end

@implementation RACHttpRequest

+ (instancetype)rac_RequestWithParams:(RACHttpParams*)params
{
    return [[self alloc]initRequestWithParams:params];
}

- (instancetype)initRequestWithParams:(RACHttpParams*)params
{
    self = [super init];
    if (self) {
        self.requestParams = params;
        _requestSerializerType = RACHTTPRequestSerializerHTTP;
    }return self;
}
@end

//request发起请求
@implementation RACHttpRequest(RACHttpSerice)

- (RACSignal*)rac_RequestWithResponseClass:(Class)responseClass
{
    return [[RACHttpService shareService]rac_request:self responseClass:responseClass];
}

@end


