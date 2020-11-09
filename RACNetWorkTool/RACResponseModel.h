//
//  RACResponseModel.h
//  ProjectModel
//
//  Created by 王纯杰 on 2020/11/9.
//  Copyright © 2020 Sharon Chou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RACResponseModel : NSObject

@property(nonatomic, strong)NSString*msg;
@property(nonatomic, assign)NSInteger  code;
@property(nonatomic, strong)id obj;

@end

NS_ASSUME_NONNULL_END
