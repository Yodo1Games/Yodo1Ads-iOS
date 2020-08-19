//
//  Yodo1AdConfigHelper.h
//
//  Created by yixian huang on 2017/8/10.
//
//

#ifndef InterstitialHelper_h
#define InterstitialHelper_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//Banner
FOUNDATION_EXPORT NSString* const kPlatform_BannerAdControl;
FOUNDATION_EXPORT NSString* const kPlatform_BannerAdConfig;
FOUNDATION_EXPORT NSString* const kPlatform_BannerAdMasterSwitch;
FOUNDATION_EXPORT NSString* const kPlatform_BannerAdSwitchingCycle;

//Interstitial
FOUNDATION_EXPORT NSString* const kPlatform_InterstitialAdControl;
FOUNDATION_EXPORT NSString* const kPlatform_InterstitialAdConfig;
FOUNDATION_EXPORT NSString* const kPlatform_InterstitialAdMasterSwitch;

//Video
FOUNDATION_EXPORT NSString* const kPlatform_VideoAdControl;
FOUNDATION_EXPORT NSString* const kPlatform_VideoAdConfig;
FOUNDATION_EXPORT NSString* const kPlatform_VideoAdMasterSwitch;

FOUNDATION_EXPORT NSString* const kRatio;
FOUNDATION_EXPORT NSString* const kMaxShowTimes;

FOUNDATION_EXPORT NSString* const kSensors_Switch;
FOUNDATION_EXPORT NSString* const kSensors_Switch_DebugMode;
FOUNDATION_EXPORT NSString* const kSensors_ServerUrl;

typedef NS_ENUM(NSUInteger, Yodo1ConfigType) {
    Yodo1ConfigTypeBanner,
    Yodo1ConfigTypeInterstitial,
    Yodo1ConfigTypeVideo
};

typedef NS_ENUM(NSUInteger,SDKInitType) {
    SDKInitTypeToutiao,
    SDKInitTypeMintegral,
    SDKInitTypeTapjoy,
    SDKInitTypeIronSource,
    SDKInitTypeInmobi,
    SDKInitTypeAdmob,
    SDKInitTypeMopub,
    SDKInitTypeUnityAds,
    SDKInitTypeOneWay,
    SDKInitTypeSmaato,
};

@interface Yodo1AdConfigHelper : NSObject

+ (instancetype)instance;

///在线参数是否开启有效
- (BOOL)isAdEableWithType:(Yodo1ConfigType)type;

///是否已经初始化完
- (BOOL)isUpdated;

///在线参数是否已经配置有数据
- (BOOL)isOnlineParamsEableWithType:(Yodo1ConfigType)type;

///根据平台定义的键（key）和类型去获取值(value)
- (NSString*)appIdWithPlatform:(NSString*)platformKey configType:(Yodo1ConfigType)type;

///根据广告平台和类型去获取广告平台的占有比值
- (NSString*)percentWithPlatform:(NSString*)platform configType:(Yodo1ConfigType)type;

///根据广告平台和类型获取最大限制播放次数
- (NSString *)showTimesWithPlatform:(NSString *)platform configType:(Yodo1ConfigType)type;

///获取权重数组
- (NSArray*)configWeightWithType:(Yodo1ConfigType)type;

- (NSArray *)placement_ids:(Yodo1ConfigType)type;

- (NSDictionary *)report_fields;

///和JSONObjectWithString 方法成对出现
+ (NSString*)stringWithJSONObject:(id)obj error:(NSError**)error;

///和stringWithJSONObject 方法成对出现
+ (id)JSONObjectWithString:(NSString*)str error:(NSError**)error;

- (void)setLogEnable:(BOOL)enable;

- (BOOL)adsLogEnbale;

- (void)setAdsLog:(NSString*)log;

- (void)cleanAdsLog;

- (NSString*)adsLog;

- (BOOL)isInitedWithInitType:(SDKInitType)type;

- (void)setInitedWithInitType:(SDKInitType)type
                     isInited:(BOOL)isInited;



/// return YES 同意收集数据,默认是收集数据
- (BOOL)isUserConsent;
/// consent is YES 是同意收集数据，NO 不同意收集数据
- (void)setUserConsent:(BOOL)consent;

/// consent is YES 是16岁以下，NO 默认是16岁以上
- (void)setTagForUnderAgeOfConsent:(BOOL)isBelowConsentAge;
/// return true 表示16岁以下
- (BOOL)isTagForUnderAgeOfConsent;

/// return true 表示用户选择不出售其个人信息
- (BOOL)isDoNotSell;
/// 如果用户选择不出售其个人信息，请将以下标记设置为true。
- (void)setDoNotSell:(BOOL)doNotSell;

- (NSDictionary *)sensorsConfig;

@end

NS_ASSUME_NONNULL_END

#endif /* InterstitialHelper_h */
