//
//  RACHttpService.h
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "RACHttpRequest.h"
#import "RACHttpConstKey.h"
#import "RACHttpResponse.h"
#import <YYModel/YYModel.h>
// 是否为空对象
#define ObjectIsNil(__object)  ((nil == __object) || [__object isKindOfClass:[NSNull class]])

// 字符串为空
#define StringIsEmpty(__string) ((__string.length == 0) || ObjectIsNil(__string))

// 字符串不为空
#define StringIsNotEmpty(__string)  (!StringIsEmpty(__string))

NS_ASSUME_NONNULL_BEGIN

@interface RACHttpService : AFHTTPSessionManager

+ (instancetype)shareService;

- (RACSignal*)rac_request:(RACHttpRequest *)requset responseClass:(Class)responseClass;

- (RACSignal*)rac_requestMethod:(RACHttpParams *)params responseClass:(Class)responseClass;


- (void)rac_request:(NSArray<RACHttpRequest *>*)requsetArray completeBlock:(void(^)(NSArray<RACHttpRequest *> * obj,NSError * error))complete;

//- (RACSignal*)rac_upload:(RACHttpRequest *)requset responseClass:(Class)responseClass fileDatas:(NSArray<NSData*>*)fileDatas name:(NSString*)name minType:(NSString*)mineType;

@end

NS_ASSUME_NONNULL_END
