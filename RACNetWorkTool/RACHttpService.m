//
//  RACHttpService.m
//  ProjectModel
//
//  Created by 王纯杰 on 2019/7/16.
//  Copyright © 2019 Sharon Chou. All rights reserved.
//

#import "RACHttpService.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <YYModel/YYModel.h>
#import "RACResponseModel.h"
@implementation RACHttpService

static id _service = nil;

+(instancetype)shareService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _service = [[self alloc]init];
        [_service _configHTTPService];
    });
    return _service;
}

- (void)_configHTTPService{
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
#if DEBUG
    responseSerializer.removesKeysWithNullValues = NO;
#else
    responseSerializer.removesKeysWithNullValues = YES;
#endif
    responseSerializer.readingOptions = NSJSONReadingAllowFragments;
    /// config
    self.responseSerializer = responseSerializer;

    /// 安全策略
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO
    //主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    securityPolicy.validatesDomainName = NO;
    
    self.securityPolicy = securityPolicy;
    /// 支持解析
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                      @"text/json",
                                                      @"text/javascript",
                                                      @"text/html",
                                                      @"text/plain",
                                                      @"text/html; charset=UTF-8",
                                                      nil];
    /// 开启网络监测
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if (status == AFNetworkReachabilityStatusUnknown) {

            NSLog(@"--- 未知网络 ---");
        }else if (status == AFNetworkReachabilityStatusNotReachable) {
    
            NSLog(@"--- 无网络 ---");
        }else{
            NSLog(@"--- 有网络 ---");
        }
    }];
    [self.reachabilityManager startMonitoring];
}


- (void)_configureRequestSerializer:(RACHttpRequest*)request
{
    if (request.requestSerializerType == RACHTTPRequestSerializerHTTP) {
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
    }else if (request.requestSerializerType == RACHTTPRequestSerializerJSON){
        self.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    AFHTTPRequestSerializer *requestSerializer = self.requestSerializer;
    [requestSerializer willChangeValueForKey:@"timeoutInterval"];
    requestSerializer.timeoutInterval = 50;
    [requestSerializer didChangeValueForKey:@"timeoutInterval"];
}

- (RACSignal*)rac_requestMethod:(RACHttpParams *)params responseClass:(Class)responseClass
{
    RACHttpRequest * request= [RACHttpRequest rac_RequestWithParams:params];
    return [self rac_request:request responseClass:responseClass];
}


/**
 网络请求

 @param requset 自定义 RACHttpRequest
 @param responseClass 期望响应的结果
 @return 完成回调信号
 */
- (RACSignal*)rac_request:(RACHttpRequest *)requset responseClass:(Class)responseClass
{
    if (!requset) [RACSignal error:[NSError errorWithDomain:RACHttpServiceDomainKey code:0 userInfo:nil]];
    
    [self _configureRequestSerializer:requset];
    
    @weakify(self);
    return [[[self rac_requestWith:requset.requestParams.urlPath params:requset.requestParams.params method:requset.requestParams.method]reduceEach:^RACStream*(NSURLResponse * response, NSDictionary* responseObject){
        @strongify(self);
        return [[self rac_parsedResponseOfClass:responseClass fromJSON:responseObject]
                map:^id(id value) {
                    RACHttpResponse * response = [[RACHttpResponse alloc]initWithResponseObject:responseObject parsedResult:value];
                    return response;
                }];
    }]concat];
}


- (void)rac_request:(NSArray<RACHttpRequest *>*)requsetArray completeBlock:(void(^)(NSArray <RACHttpRequest *> * obj,NSError * error))complete
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block NSError * _error = nil;
    for (RACHttpRequest * rq in requsetArray) {
        [self _configureRequestSerializer:rq];
        @weakify(self);
        dispatch_group_enter(group);
        dispatch_group_async(group, queue, ^{
            [[[[self rac_requestWith:rq.requestParams.urlPath params:rq.requestParams.params method:rq.requestParams.method]reduceEach:^RACStream*(NSURLResponse * response, NSDictionary* responseObject){
                @strongify(self)
                return [[self rac_parsedResponseOfClass:rq.responseClass fromJSON:responseObject] map:^id(id value) {
                    RACHttpResponse * response = [[RACHttpResponse alloc]initWithResponseObject:responseObject parsedResult:value];
                    return response;
                }];
            }]concat] subscribeNext:^(id x) {
                rq.response = x;
                dispatch_group_leave(group);
            } error:^(NSError *error) {
                _error = error;
                dispatch_group_leave(group);
            } completed:^{
            }];
        });
    }

    dispatch_group_notify(group, queue, ^{
        complete(requsetArray,_error);
    });
//    
}



- (RACSignal*)rac_requestWith:(NSString*)path params:(id)params method:(NSString*)method
{
    @weakify(self);
    RACSignal * signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        NSError * serializatiionError = nil;
        NSMutableURLRequest * request = [self.requestSerializer requestWithMethod:method URLString:path parameters:params error:&serializatiionError];
        
        //判断请求是否正确
        if (serializatiionError) {
            dispatch_async(self.completionQueue, ^{
                [subscriber sendError:serializatiionError];
            });
            return [RACDisposable disposableWithBlock:^{}];
        }
        
        __block NSURLSessionTask * task = nil;
        task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            
            if (error) {
                NSError * parsError = [self rac_errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
                [self HTTPRequestLog:task body:params error:parsError];
                [subscriber sendError:parsError];
            }else{
                NSInteger statusCode = [responseObject[RACHttpResponseCodeKey] integerValue];
                if (statusCode == RACHttpResponseSuccessCode) {//请求成功
                    [self HTTPRequestLog:task body:params error:nil];
                    [subscriber sendNext:RACTuplePack(response,responseObject)];
                    [subscriber sendCompleted];
                }else{
                    if (statusCode == 0) {
                        
                    }else{
                        NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                        userInfo[RACHTTPServiceErrorHTTPStatusCodeKey] = @(statusCode);
                        NSString * msgTips = responseObject[RACHttpResponseMsgKey];
                        msgTips = StringIsNotEmpty(msgTips)?msgTips:@"服务器出错了，请稍后重试~";
                        userInfo[RACHTTPServiceErrorMessagesKey] = msgTips;
                        if (task.currentRequest.URL != nil) {
                            userInfo[RACHTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
                            
                        }
                        if (task.error != nil) {
                            userInfo[NSUnderlyingErrorKey] = task.error;
                        }
                        NSError * requestError = [NSError errorWithDomain:RACHttpServiceDomainKey code:statusCode userInfo:userInfo];
                        [self HTTPRequestLog:task body:params error:requestError];
                        [subscriber sendError:error];
                    }
                }
                
            }
        }];
        [task resume];
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    return [[signal replayLazily]setNameWithFormat:@"%@,%@,%@",path,params,method];
}


/// 解析数据
- (RACSignal *)rac_parsedResponseOfClass:(Class)resultClass fromJSON:(NSDictionary *)responseObject {
    /// 这里主要解析的是 data:对应的数据
    responseObject = responseObject[RACHttpResponseDataKey];

    RACResponseModel * responseModel = [[RACResponseModel alloc]init];
    responseModel.code = [responseObject[RACHttpResponseCodeKey] integerValue];
    responseModel.msg = responseObject[RACHttpResponseMsgKey];
    
    return  [RACSignal createSignal:^ id (id<RACSubscriber> subscriber) {
        /// 解析字典
        void (^parseJSONDictionary)(NSDictionary *) = ^(NSDictionary *JSONDictionary) {
            if (resultClass == nil) {
                responseModel.obj = JSONDictionary;
                [subscriber sendNext:responseModel];
                return;
            }
            /// 这里继续取出数据 data{"list":[]}
            NSArray * JSONArray = JSONDictionary[RACHttpResponseListKey];
            if ([JSONArray isKindOfClass:[NSArray class]]) {
                /// 字典数组 转对应的模型
                NSArray *parsedObjects = [NSArray yy_modelArrayWithClass:resultClass.class json:JSONArray];
                responseModel.obj = parsedObjects;
                [subscriber sendNext:responseModel];
                
            }else{
                /// 字典转模型
                id  parsedObject = [resultClass yy_modelWithDictionary:JSONDictionary];
                if (parsedObject == nil) {
                    // Don't treat "no class found" errors as real parsing failures.
                    // In theory, this makes parsing code forward-compatible with
                    // API additions.
                    // 模型解析失败
                    NSError *error = [NSError errorWithDomain:@"数据类型异常" code:2222 userInfo:@{}];
                    [subscriber sendError:error];
                    return;
                }
                responseModel.obj = parsedObject;
                [subscriber sendNext:responseModel];
            }
        };
        
        if ([responseObject isKindOfClass:NSArray.class]) {
            
            if (resultClass == nil) {
                responseModel.obj = responseObject;
                [subscriber sendNext:responseModel];
            }else{
                /// 数组 保证数组里面装的是同一种 NSDcitionary
                for (NSDictionary *JSONDictionary in responseObject) {
                    if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
                        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Invalid JSON array element: %@", @""), JSONDictionary];
                        [subscriber sendError:[self parsingErrorWithFailureReason:failureReason]];
                        return nil;
                    }
                }
                /// 字典数组 转对应的模型
                NSArray *parsedObjects = [NSArray yy_modelArrayWithClass:resultClass.class json:responseObject];
                responseModel.obj = parsedObjects;

                [subscriber sendNext:responseModel];
            }
            [subscriber sendCompleted];
        } else if ([responseObject isKindOfClass:NSDictionary.class]) {
            /// 解析字典
            parseJSONDictionary(responseObject);
            [subscriber sendCompleted];
        } else if (responseObject == nil || [responseObject isKindOfClass:[NSNull class]]) {
            [subscriber sendCompleted];
        } else {
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Response wasn't an array or dictionary (%@): %@", @""), [responseObject class], responseObject];
            [subscriber sendError:[self parsingErrorWithFailureReason:failureReason]];
        }
        return nil;
    }];
    /// 解析
    
}

#pragma mark - Upload
- (RACSignal *)rac_upload:(RACHttpRequest *)request responseClass:(Class)responseClass fileDatas:(NSArray<NSData*>*)fileDatas name:(NSString*)name minType:(NSString*)mineType{
    /// request 必须的有值
    if (!request) return [RACSignal error:[NSError errorWithDomain:RACHttpServiceDomainKey code:-1 userInfo:nil]];
    /// 断言
    NSAssert(StringIsNotEmpty(name), @"name is empty: %@", name);
    
    @weakify(self);
    
    /// 覆盖manager 请求序列化
    self.requestSerializer = [self _requestSerializerWithRequest:request];
    
    /// 发起请求
    /// concat:按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号。 这里传进去的参数，不是parameters而是之前通过
    /// urlParametersWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters;穿进去的参数
    return [[[self enqueueUploadRequestWithPath:request.requestParams.urlPath parameters:request.requestParams.params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSInteger count = fileDatas.count;
        for (int i = 0; i< count; i++) {
            /// 取出fileData
            NSData *fileData = fileDatas[i];
            
            /// 断言
            NSAssert([fileData isKindOfClass:NSData.class], @"fileData is not an NSData class: %@", fileData);
            
            // 在网络开发中，上传文件时，是文件不允许被覆盖，文件重名
            // 要解决此问题，
            // 可以在上传时使用当前的系统事件作为文件名
            
            static NSDateFormatter *formatter = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                formatter = [[NSDateFormatter alloc] init];
            });
            // 设置时间格式
            [formatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString  stringWithFormat:@"senba_empty_%@_%zd.jpg", dateString , i];
            [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:StringIsNotEmpty(mineType)?mineType:@"application/octet-stream"];
        }
    }]
             reduceEach:^RACStream *(NSURLResponse *response, NSDictionary * responseObject){
                 @strongify(self);
                 /// 请求成功 这里解析数据
                 return [[self rac_parsedResponseOfClass:responseClass fromJSON:responseObject]
                         map:^(id parsedResult) {
                             RACHttpResponse *parsedResponse = [[RACHttpResponse alloc] initWithResponseObject:responseObject parsedResult:parsedResult];
                             NSAssert(parsedResponse != nil, @"Could not create MHHTTPResponse with response %@ and parsedResult %@", response, parsedResult);
                             return parsedResponse;
                         }];
             }]
            concat];;
}


- (RACSignal *)enqueueUploadRequestWithPath:(NSString *)path parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block{
    @weakify(self);
    /// 创建信号
    RACSignal *signal = [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        /// 获取request
        NSError *serializationError = nil;
        
        NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
        if (serializationError) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                [subscriber sendError:serializationError];
            });
#pragma clang diagnostic pop
            
            return [RACDisposable disposableWithBlock:^{
            }];
        }
        
        __block NSURLSessionDataTask *task = [self uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
            if (error) {
                NSError *parseError = [self rac_errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
                [self HTTPRequestLog:task body:parameters error:parseError];
                [subscriber sendError:parseError];
            } else {
                
                /// 断言
                NSAssert([responseObject isKindOfClass:NSDictionary.class], @"responseObject is not an NSDictionary: %@", responseObject);
                
                /// 在这里判断数据是否正确
                /// 判断
                NSInteger statusCode = [responseObject[RACHttpResponseCodeKey] integerValue];
                
                if (statusCode == RACHttpResponseSuccessCode) {
                    /// 打包成元祖 回调数据
                    [subscriber sendNext:RACTuplePack(response , responseObject)];
                    [subscriber sendCompleted];
                }else{
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[RACHttpResponseCodeKey] = @(statusCode);
                        NSString *msgTips = responseObject[RACHttpResponseMsgKey];
#if defined(DEBUG)||defined(_DEBUG)
                        msgTips = StringIsNotEmpty(msgTips)?[NSString stringWithFormat:@"%@(%zd)",msgTips,statusCode]:[NSString stringWithFormat:@"服务器出错了，请稍后重试(%zd)~",statusCode];                 /// 调试模式
#else
                        msgTips = MHStringIsNotEmpty(msgTips)?msgTips:@"服务器出错了，请稍后重试~";  /// 发布模式
#endif
                        userInfo[RACHTTPServiceErrorMessagesKey] = msgTips;
                        if (task.currentRequest.URL != nil) userInfo[RACHTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
                        if (task.error != nil) userInfo[NSUnderlyingErrorKey] = task.error;
                        [subscriber sendError:[NSError errorWithDomain:RACHttpServiceDomainKey code:statusCode userInfo:userInfo]];
                    }

            }
        }];
        
        [task resume];
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
        
    }];
    /// replayLazily:replayLazily会在第一次订阅的时候才订阅sourceSignal
    /// 会提供所有的值给订阅者 replayLazily还是冷信号 避免了冷信号的副作用
    return [[signal
             replayLazily]
            setNameWithFormat:@"-enqueueUploadRequestWithPath: %@ parameters: %@", path, parameters];
}

- (NSError *)parsingErrorWithFailureReason:(NSString *)localizedFailureReason {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Could not parse the service response.", @"");
    if (localizedFailureReason != nil) userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason;
    return [NSError errorWithDomain:RACHttpServiceDomainKey code:RACHttpServiceErrorJSONFailed userInfo:userInfo];
}


- (NSError *)rac_errorFromRequestWithTask:(NSURLSessionTask *)task httpResponse:(NSHTTPURLResponse *)httpResponse responseObject:(NSDictionary *)responseObject error:(NSError *)error {
    /// 不一定有值，则HttpCode = 0;
    NSInteger HTTPCode = httpResponse.statusCode;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    /// default errorCode is MHHTTPServiceErrorConnectionFailed，意味着连接不上服务器
    NSInteger errorCode = RACHttpServiceErrorServiceFailed;
    NSString *errorDesc = @"服务器出错了，请稍后重试~";
    /// 其实这里需要处理后台数据错误，一般包在 responseObject
    /// HttpCode错误码解析 https://www.guhei.net/post/jb1153
    /// 1xx : 请求消息 [100  102]
    /// 2xx : 请求成功 [200  206]
    /// 3xx : 请求重定向[300  307]
    /// 4xx : 请求错误  [400  417] 、[422 426] 、449、451
    /// 5xx 、600: 服务器错误 [500 510] 、600
    NSInteger httpFirstCode = HTTPCode/100;
    if (httpFirstCode>0) {
        if (httpFirstCode==4) {
            /// 请求出错了，请稍后重试
            if (HTTPCode == 408) {
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = @"请求超时，请稍后再试(408)~"; /// 调试模式
#else
                errorDesc = @"请求超时，请稍后再试~";      /// 发布模式
#endif
            }else{
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = [NSString stringWithFormat:@"请求出错了，请稍后重试(%zd)~",HTTPCode];                   /// 调试模式
#else
                errorDesc = @"请求出错了，请稍后重试~";      /// 发布模式
#endif
            }
        }else if (httpFirstCode == 5 || httpFirstCode == 6){
            /// 服务器出错了，请稍后重试
#if defined(DEBUG)||defined(_DEBUG)
            errorDesc = [NSString stringWithFormat:@"服务器出错了，请稍后重试(%zd)~",HTTPCode];                      /// 调试模式
#else
            errorDesc = @"服务器出错了，请稍后重试~";       /// 发布模式
#endif
            
        }else if (!self.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    }else{
        if (!self.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    }
    switch (HTTPCode) {
        case 400:{
            errorCode = RACHttpServiceErrorBadRequest;           /// 请求失败
            break;
        }
        case 403:{
            errorCode = RACHttpServiceForBiddenRequest;     /// 服务器拒绝请求
            break;
        }
        case 422:{
            errorCode = RACHttpServiceErrorRequestFailed; /// 请求出错
            break;
        }
        default:
            /// 从error中解析
            if ([error.domain isEqual:NSURLErrorDomain]) {
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = [NSString stringWithFormat:@"请求出错了，请稍后重试(%zd)~",error.code];                   /// 调试模式
#else
                errorDesc = @"请求出错了，请稍后重试~";        /// 发布模式
#endif
                switch (error.code) {
                    case NSURLErrorSecureConnectionFailed:
                    case NSURLErrorServerCertificateHasBadDate:
                    case NSURLErrorServerCertificateHasUnknownRoot:
                    case NSURLErrorServerCertificateUntrusted:
                    case NSURLErrorServerCertificateNotYetValid:
                    case NSURLErrorClientCertificateRejected:
                    case NSURLErrorClientCertificateRequired:
                        errorCode = RACHttpServiceErrorConnectFailed; /// 建立安全连接出错了
                        break;
                    case NSURLErrorTimedOut:{
#if defined(DEBUG)||defined(_DEBUG)
                        errorDesc = @"请求超时，请稍后再试(-1001)~"; /// 调试模式
#else
                        errorDesc = @"请求超时，请稍后再试~";        /// 发布模式
#endif
                        break;
                    }
                    case NSURLErrorNotConnectedToInternet:{
#if defined(DEBUG)||defined(_DEBUG)
                        errorDesc = @"网络开小差了，请稍后重试(-1009)~"; /// 调试模式
#else
                        errorDesc = @"网络开小差了，请稍后重试~";        /// 发布模式
#endif
                        break;
                    }
                }
            }
    }
    userInfo[RACHTTPServiceErrorHTTPStatusCodeKey] = @(HTTPCode);
    userInfo[RACHTTPServiceErrorDescriptionKey] = errorDesc;
    if (task.currentRequest.URL != nil) userInfo[RACHTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
    if (task.error != nil) userInfo[NSUnderlyingErrorKey] = task.error;
    return [NSError errorWithDomain:RACHttpServiceDomainKey code:errorCode userInfo:userInfo];
}


#pragma mark - 打印请求日志
- (void)HTTPRequestLog:(NSURLSessionTask *)task body:params error:(NSError *)error {
    NSLog(@">>>>>>>>>>>>>>>>>>>>>👇 REQUEST FINISH 👇>>>>>>>>>>>>>>>>>>>>>>>>>>");
    NSLog(@"Request%@=======>:%@", error?@"失败":@"成功", task.currentRequest.URL.absoluteString);
    NSLog(@"requestBody======>:%@", params);
    NSLog(@"requstHeader=====>:%@", task.currentRequest.allHTTPHeaderFields);
    NSLog(@"response=========>:%@", task.response);
    NSLog(@"error============>:%@", error);
    NSLog(@"<<<<<<<<<<<<<<<<<<<<<👆 REQUEST FINISH 👆<<<<<<<<<<<<<<<<<<<<<<<<<<");
}

/// 序列化
- (AFHTTPRequestSerializer *)_requestSerializerWithRequest:(RACHttpRequest *) request{
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    return requestSerializer;
}

@end
