//
//  Yodo1AntiIndulgedHelper.h
//  yodo1-anti-indulged-ios
//
//  Created by ZhouYuzhen on 2020/10/9.
//

#import <Foundation/Foundation.h>
#import "Yodo1AntiIndulged.h"

NS_ASSUME_NONNULL_BEGIN

#define Yodo1AntiIndulgedChannel @"AppStore"

@interface Yodo1AntiIndulgedHelper : NSObject

@property (nonatomic, assign) BOOL autoTimer; // 自动开启计时
@property (nonatomic, weak, readonly) id<Yodo1AntiIndulgedDelegate> delegate;
@property (nonatomic, copy, readonly) Yodo1AntiIndulgedSuccessful certSucdessfulCallback;
@property (nonatomic, copy, readonly) Yodo1AntiIndulgedFailure certFailureCallback;


+ (Yodo1AntiIndulgedHelper *)shared;

/// 初始化
- (void)init:(NSString *)appKey channel:(NSString *)channel regionCode:(NSString *)regionCode delegate: (id<Yodo1AntiIndulgedDelegate>)delegate;

/// 获取SDK版本
- (NSString *)getSdkVersion;

/// 开启计时, 如果当前正在计时中则会忽略
- (void)startTimer;
/// 停止计时，同时会上报时间
- (void)stopTimer;
/// 是否正在计时
- (BOOL)isTimer;

- (BOOL)isGuestUser;

- (BOOL)successful:(id _Nullable)data;
- (BOOL)failure:(NSError * _Nullable)error;

/// 验证玩家防沉迷信息
/// accountId 玩家账号ru
/// 如果 autoTimer == YES游客及未成年会自动开启计时
- (void)verifyCertificationInfo:(NSString *)accountId success:(Yodo1AntiIndulgedSuccessful)success failure:(Yodo1AntiIndulgedFailure)failure;

///是否已限制消费
- (void)verifyPurchase:(NSInteger)money success:(Yodo1AntiIndulgedSuccessful)success failure:(Yodo1AntiIndulgedFailure)failure;

///上报消费信息 - 支付信息&商品信息
- (void)reportProductReceipts:(NSArray<Yodo1AntiIndulgedProductReceipt *> *)receipts success:(Yodo1AntiIndulgedSuccessful)success failure:(Yodo1AntiIndulgedFailure)failure;

@end

NS_ASSUME_NONNULL_END
