//
//  Yodo1AnalyticsManager.m
//  foundationsample
//
//  Created by hyx on 14-10-14.
//  Copyright (c) 2014年 yodo1. All rights reserved.
//

#import "Yodo1AnalyticsManager.h"
#import "Yodo1Registry.h"
#import "AnalyticsAdapter.h"
#import "Yodo1Commons.h"
#import "Yodo1ClassWrapper.h"
#import "Yodo1UnityTool.h"
#import "Yd1OnlineParameter.h"

@implementation AnalyticsInitConfig


@end

@interface Yodo1AnalyticsManager ()
{
    BOOL bUmengOpen;
    BOOL bTalkingDataOpen;
    BOOL bGameAnalyticsOpen;
    BOOL bAppsFlyerOpen;
    BOOL bSwrveOpen;
}

@property (nonatomic, strong) NSMutableDictionary* analyticsDict;
@property (nonatomic, strong) NSMutableDictionary* trackPropertys;

- (NSString*)talkingDataDeviceId;

///获取一个随机整数范围在[from,to]
- (int)randomNumber:(int)from to:(int)to;

@end

@implementation Yodo1AnalyticsManager

+ (Yodo1AnalyticsManager *)sharedInstance
{
    static Yodo1AnalyticsManager* _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Yodo1AnalyticsManager alloc]init];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _analyticsDict = [[NSMutableDictionary alloc] init];
        _trackPropertys = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (int)randomNumber:(int)from to:(int)to {
    return (int)(from + (arc4random() % (to - from + 1)));
}

- (BOOL)isAppsFlyerInstalled {
    return YES;
    // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // BOOL isInstalled = [defaults boolForKey:@"YODO1_APPSFLYER"];
    // if (!isInstalled) {
    //     NSInteger tempRandom = [self randomNumber:0 to:100];
    //     [defaults setInteger:tempRandom forKey:@"YODO1_APPSFLYER_RANDOM"];
    //     [defaults setBool:YES forKey:@"YODO1_APPSFLYER"];
    //     [defaults synchronize];
    // }
    // BOOL appsFlyerInstalled = NO;
    // NSInteger random = [defaults integerForKey:@"YODO1_APPSFLYER_RANDOM"];
    
    // NSString* randomAppsFlyer = [Yodo1OnlineParameter stringParams:@"AppsFlyerRandom" defaultValue:@"0"];
    // NSInteger onlineNums = [randomAppsFlyer integerValue];
    
    // if (random > 0 && random <= onlineNums) { //randomAppsFlyer 为0的时候关闭
    //     appsFlyerInstalled = YES;
    // }
    // return appsFlyerInstalled;
}

- (void)initializeAnalyticsWithConfig:(AnalyticsInitConfig*)initConfig  
{
    NSString* umengEvent = [Yd1OnlineParameter.shared stringConfigWithKey:@"Platform_Analytics_SwitchUmeng" defaultValue:@"on"];
    if ([umengEvent isEqualToString:@"off"]) {//默认是开着
        bUmengOpen = NO;
    }else{
        bUmengOpen = YES;
    }
    
    NSString* talkingDataEvent = [Yd1OnlineParameter.shared stringConfigWithKey:@"Platform_Analytics_SwitchTalkingData" defaultValue:@"on"];
    if ([talkingDataEvent isEqualToString:@"off"]) {//默认是开着
        bTalkingDataOpen = NO;
    }else{
        bTalkingDataOpen = YES;
    }
    
    NSString* gameAnalyticsEvent = [Yd1OnlineParameter.shared stringConfigWithKey:@"Platform_Analytics_SwitchGameAnalytics" defaultValue:@"on"];
    if ([gameAnalyticsEvent isEqualToString:@"off"]) {//默认是开着
        bGameAnalyticsOpen = NO;
    }else{
        bGameAnalyticsOpen = YES;
    }
    
    NSString* appsFlyerEvent = [Yd1OnlineParameter.shared stringConfigWithKey:@"Platform_Analytics_SwitchAppsFlyer" defaultValue:@"on"];
    if ([appsFlyerEvent isEqualToString:@"off"]) {//默认是开着
        bAppsFlyerOpen = NO;
    }else{
        bAppsFlyerOpen = YES;
    }
    
    NSString* switchEvent = [Yd1OnlineParameter.shared stringConfigWithKey:@"Platform_Analytics_SwitchSwrve" defaultValue:@"on"];
    if ([switchEvent isEqualToString:@"off"]) {//默认是开着
        bSwrveOpen = NO;
    }else{
        bSwrveOpen = YES;
    }
    
    NSDictionary* dic = [[Yodo1Registry sharedRegistry] getClassesStatusType:@"analyticsType"
                                                              replacedString:@"AnalyticsAdapter"
                                                               replaceString:@"AnalyticsType"];
    if (dic) {
        NSArray* keyArr = [dic allKeys];
        //优先初始化Swrve
        BOOL isHaveSwrve = false;
        for (id key1 in keyArr) {
            if (bSwrveOpen && [key1 integerValue] == AnalyticsTypeSwrve) {
                Class adapter = [[[Yodo1Registry sharedRegistry] adapterClassFor:[key1 integerValue] classType:@"analyticsType"] theYodo1Class];
                AnalyticsAdapter* advideoAdapter = [[adapter alloc] initWithAnalytics:initConfig];
                NSNumber* adVideoOrder = [NSNumber numberWithInt:[key1 intValue]];
                [self.analyticsDict setObject:advideoAdapter forKey:adVideoOrder];
                isHaveSwrve = true;
            }
        }
        
        for (id key in keyArr) {
            if (!bTalkingDataOpen && [key integerValue] == AnalyticsTypeTalkingData) {
                continue;
            }
            if (!bGameAnalyticsOpen && [key integerValue] == AnalyticsTypeGameAnalytics) {
                continue;
            }
            if (!bUmengOpen && [key integerValue] == AnalyticsTypeUmeng) {
                continue;
            }
            if (!bAppsFlyerOpen && [key integerValue] == AnalyticsTypeAppsFlyer) {
                continue;
            }
            if (!bSwrveOpen && [key integerValue] == AnalyticsTypeSwrve) {
                continue;
            }
            //跳过Swrve
            if (isHaveSwrve && [key integerValue] == AnalyticsTypeSwrve) {
                continue;
            }
            
            Class adapter = [[[Yodo1Registry sharedRegistry] adapterClassFor:[key integerValue] classType:@"analyticsType"] theYodo1Class];
            AnalyticsAdapter* advideoAdapter = [[adapter alloc] initWithAnalytics:initConfig];
            NSNumber* adVideoOrder = [NSNumber numberWithInt:[key intValue]];
            [self.analyticsDict setObject:advideoAdapter forKey:adVideoOrder];
        }
    }
}

- (void)eventAnalytics:(NSString *)eventName
             eventData:(NSDictionary *)eventData

{
    if (eventName == nil) {
        NSAssert(eventName != nil, @"eventName cannot nil!");
    }
    
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter eventWithAnalyticsEventName:eventName eventData:eventData];
    }
}

- (void)eventAdAnalyticsWithName:(NSString *)eventName 
                       eventData:(NSDictionary *)eventData
{
    if (eventName == nil) {
        NSAssert(eventName != nil, @"eventName cannot nil!");
    }
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeAppsFlyer){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter eventAdAnalyticsWithName:eventName eventData:eventData];
            break;
        }
    }
}

- (void)startLevelAnalytics:(NSString*)level
{
    if (!level) {
        return;
    }
    
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter startLevelAnalytics:level];
    }
}

- (void)finishLevelAnalytics:(NSString*)level
{
    if (!level) {
        return;
    }
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter finishLevelAnalytics:level];
    }
}

- (void)failLevelAnalytics:(NSString*)level failedCause:(NSString*)cause
{
    if (!level) {
        return;
    }
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter failLevelAnalytics:level failedCause:cause];
    }
}

- (void)userLevelIdAnalytics:(int)level
{
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter userLevelIdAnalytics:level];
    }
}

- (void)chargeRequstAnalytics:(NSString*)orderId
                        iapId:(NSString*)iapId
               currencyAmount:(double)currencyAmount
                 currencyType:(NSString *)currencyType
        virtualCurrencyAmount:(double)virtualCurrencyAmount
                  paymentType:(NSString *)paymentType
{
    if (currencyAmount < 0 ) {
        currencyAmount = 0;
    }
    
    if (virtualCurrencyAmount < 0) {
        virtualCurrencyAmount = 0;
    }
    
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter chargeRequstAnalytics:orderId
                                 iapId:iapId
                        currencyAmount:currencyAmount
                          currencyType:currencyType
                 virtualCurrencyAmount:virtualCurrencyAmount
                           paymentType:paymentType
         ];
    }
}

- (void)chargeSuccessAnalytics:(NSString *)orderId source:(int)source;
{
    
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter chargeSuccessAnalytics:orderId source:source];
    }
}


- (void)rewardAnalytics:(double)virtualCurrencyAmount reason:(NSString *)reason source:(int)source;
{
    if (virtualCurrencyAmount < 0) {
        virtualCurrencyAmount = 0;
    }
    
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter rewardAnalytics:virtualCurrencyAmount reason:reason source:source];
    }
}

- (void)purchaseAnalytics:(NSString *)item itemNumber:(int)number priceInVirtualCurrency:(double)price
{
    if (number < 0) {
        number = 0;
    }
    if (price < 0) {
        price = 0;
    }
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter purchaseAnalytics:item itemNumber:number priceInVirtualCurrency:price];
    }
}


- (void)useAnalytics:(NSString *)item amount:(int)amount price:(double)price;
{
    if (amount < 0) {
        amount = 0;
    }
    if (price < 0) {
        price = 0;
    }
    for (id key in [self.analyticsDict allKeys]) {
        AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
        [adapter useAnalytics:item amount:amount price:price];
    }
}

- (NSString*)talkingDataDeviceId
{
    NSString* deviceId = nil;
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeTalkingData){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            deviceId = [adapter talkingDataDeviceId];
            break;
        }
    }
    return deviceId;
}

- (void)track:(NSString *)eventName
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter track:eventName];
            break;
        }
    }
}

-(void)saveTrackWithEventName:(NSString *)eventName
                  propertyKey:(NSString *)propertyKey
                propertyValue:(NSString *)propertyValue
{
    if (eventName == nil || propertyKey == nil || propertyValue == nil) {
        return;
    }
    NSMutableDictionary * propertys = [NSMutableDictionary dictionaryWithCapacity:5];
    if ([[self.trackPropertys allKeys]containsObject:eventName]) {
        NSDictionary* property = [self.trackPropertys objectForKey:eventName];
        [propertys addEntriesFromDictionary:property];
        if (![[propertys allKeys]containsObject:propertyKey]) {
            [propertys setObject:propertyValue forKey:propertyKey];
        }
    }else{
        [propertys setObject:propertyValue forKey:propertyKey];
    }
    
    [self.trackPropertys setObject:propertys forKey:eventName];
}

- (void)saveTrackWithEventName:(NSString *)eventName
                   propertyKey:(NSString *)propertyKey
              propertyIntValue:(int)propertyValue
{
    if (eventName == nil || propertyKey == nil) {
        return;
    }
    NSMutableDictionary * propertys = [NSMutableDictionary dictionaryWithCapacity:5];
    if ([[self.trackPropertys allKeys]containsObject:eventName]) {
        NSDictionary* property = [self.trackPropertys objectForKey:eventName];
        [propertys addEntriesFromDictionary:property];
        if (![[propertys allKeys]containsObject:propertyKey]) {
            [propertys setObject:[NSNumber numberWithInt:propertyValue] forKey:propertyKey];
        }
    }else{
        [propertys setObject:[NSNumber numberWithInt:propertyValue] forKey:propertyKey];
    }
    
    [self.trackPropertys setObject:propertys forKey:eventName];
}

- (void)saveTrackWithEventName:(NSString *)eventName
                   propertyKey:(NSString *)propertyKey
            propertyFloatValue:(float)propertyValue
{
    if (eventName == nil || propertyKey == nil) {
        return;
    }
    NSMutableDictionary * propertys = [NSMutableDictionary dictionaryWithCapacity:5];
    if ([[self.trackPropertys allKeys]containsObject:eventName]) {
        NSDictionary* property = [self.trackPropertys objectForKey:eventName];
        [propertys addEntriesFromDictionary:property];
        if (![[propertys allKeys]containsObject:propertyKey]) {
            [propertys setObject:[NSNumber numberWithFloat:propertyValue] forKey:propertyKey];
        }
    }else{
        [propertys setObject:[NSNumber numberWithFloat:propertyValue] forKey:propertyKey];
    }
    
    [self.trackPropertys setObject:propertys forKey:eventName];
}


- (void)saveTrackWithEventName:(NSString *)eventName
                   propertyKey:(NSString *)propertyKey
           propertyDoubleValue:(double)propertyValue
{
    if (eventName == nil || propertyKey == nil) {
        return;
    }
    NSMutableDictionary * propertys = [NSMutableDictionary dictionaryWithCapacity:5];
    if ([[self.trackPropertys allKeys]containsObject:eventName]) {
        NSDictionary* property = [self.trackPropertys objectForKey:eventName];
        [propertys addEntriesFromDictionary:property];
        if (![[propertys allKeys]containsObject:propertyKey]) {
            [propertys setObject:[NSNumber numberWithDouble:propertyValue] forKey:propertyKey];
        }
    }else{
        [propertys setObject:[NSNumber numberWithDouble:propertyValue] forKey:propertyKey];
    }
    
    [self.trackPropertys setObject:propertys forKey:eventName];
}

-(void)submitTrackWithEventName:(NSString *)eventName
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            if ([[self.trackPropertys allKeys]containsObject:eventName]) {
                NSDictionary* property = [self.trackPropertys objectForKey:eventName];
                [adapter track:eventName property:property];
                //remove submit property
                [self.trackPropertys removeObjectForKey:eventName];
            }
            break;
        }
    }
}

- (void)registerSuperProperty:(NSDictionary *)property
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter registerSuperProperty:property];
            break;
        }
    }
}

- (void)unregisterSuperProperty:(NSString *)propertyName
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter unregisterSuperProperty:propertyName];
            break;
        }
    }
}

- (NSString *)getSuperProperty:(NSString *)propertyName
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            return [adapter getSuperProperty:propertyName];
        }
    }
    return nil;
}


- (NSDictionary *)getSuperProperties
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            return [adapter getSuperProperties];
        }
    }
    return nil;
}

- (void)clearSuperProperties
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeUmeng){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter clearSuperProperties];
            break;
        }
    }
}

- (void)setGACustomDimension01:(NSString*)dimension01
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeGameAnalytics){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter setGACustomDimension01:dimension01];
            break;
        }
    }
}

- (void)setGACustomDimension02:(NSString*)dimension02
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeGameAnalytics){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter setGACustomDimension02:dimension02];
            break;
        }
    }
}

- (void)setGACustomDimension03:(NSString*)dimension03
{
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeGameAnalytics){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter setGACustomDimension03:dimension03];
            break;
        }
    }
}

- (void)validateAndTrackInAppPurchase:(NSString*)productIdentifier
                                price:(NSString*)price
                             currency:(NSString*)currency
                        transactionId:(NSString*)transactionId {
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeAppsFlyer){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter validateAndTrackInAppPurchase:productIdentifier
                                             price:price
                                          currency:currency
                                     transactionId:transactionId];
            break;
        }
    }
}

- (void)swrveEventAnalyticsWithName:(NSString *)eventName
                          eventData:(NSDictionary *)eventData {
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeSwrve){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter swrveEventAnalyticsWithName:eventName eventData:eventData];
            break;
        }
    }
}

- (void)swrveUserUpdate:(NSDictionary *)eventData {
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeSwrve){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter swrveUserUpdate:eventData];
            break;
        }
    }
}

- (void)swrveTransactionProcessed:(SKPaymentTransaction*) transaction
                    productBought:(SKProduct*) product {
    for (id key in [self.analyticsDict allKeys]) {
        if ([key integerValue]==AnalyticsTypeSwrve){
            AnalyticsAdapter* adapter = [self.analyticsDict objectForKey:key];
            [adapter swrveTransactionProcessed:transaction productBought:product];
            break;
        }
    }
}

- (void)dealloc
{
    self.analyticsDict = nil;
    self.trackPropertys = nil;
}



#ifdef __cplusplus

extern "C" {
    
    char* UnityGetTalkingDataDeviceId()
    {
        const char* deviceId = [[Yodo1AnalyticsManager sharedInstance]talkingDataDeviceId].UTF8String;
        return Yodo1MakeStringCopy(deviceId);
    }
    /** 自定义事件,数量统计.
     友盟：使用前，请先到友盟App管理后台的设置->编辑自定义事件
     中添加相应的事件ID，然后在工程中传入相应的事件ID
     TalkingData:
     同道：
     */
    void UnityEventWithJson(const char* eventId, const char* jsonData)
    {
        NSString* eventData = Yodo1CreateNSString(jsonData);
        NSDictionary *eventDataDic = [Yodo1Commons JSONObjectWithString:eventData error:nil];
        [[Yodo1AnalyticsManager sharedInstance]eventAnalytics:Yodo1CreateNSString(eventId)
                                                    eventData:eventDataDic];
    }
    
    void UnityStartLevelAnalytics(const char* level)
    {
        [[Yodo1AnalyticsManager sharedInstance]startLevelAnalytics:Yodo1CreateNSString(level)];
    }
    
    void UnityFinishLevelAnalytics(const char* level)
    {
        [[Yodo1AnalyticsManager sharedInstance]finishLevelAnalytics:Yodo1CreateNSString(level)];
    }
    
    void UnityFailLevelAnalytics(const char* level,const char* cause)
    {
        [[Yodo1AnalyticsManager sharedInstance]failLevelAnalytics:Yodo1CreateNSString(level)
                                                      failedCause:Yodo1CreateNSString(cause)];
    }
    
    void UnityUserLevelIdAnalytics(int level)
    {
        [[Yodo1AnalyticsManager sharedInstance]userLevelIdAnalytics:level];
    }
    
    void UnityChargeRequstAnalytics(const char* orderId,
                                    const char* iapId,
                                    double currencyAmount,
                                    const char* currencyType,
                                    double virtualCurrencyAmount,
                                    const char* paymentType)
    {
        [[Yodo1AnalyticsManager sharedInstance]chargeRequstAnalytics:Yodo1CreateNSString(orderId)
                                                               iapId:Yodo1CreateNSString(iapId)
                                                      currencyAmount:currencyAmount
                                                        currencyType:Yodo1CreateNSString(currencyType)
                                               virtualCurrencyAmount:virtualCurrencyAmount
                                                         paymentType:Yodo1CreateNSString(paymentType)];
    }
    
    void UnityChargeSuccessAnalytics(const char* orderId,int source)
    {
        [[Yodo1AnalyticsManager sharedInstance]chargeSuccessAnalytics:Yodo1CreateNSString(orderId) source:source];
    }
    
    void UnityRewardAnalytics(double virtualCurrencyAmount,const char* reason ,int source)
    {
        [[Yodo1AnalyticsManager sharedInstance]rewardAnalytics:virtualCurrencyAmount
                                                        reason:Yodo1CreateNSString(reason)
                                                        source:source];
    }
    
    void UnityPurchaseAnalytics(const char* item,int number,double price)
    {
        [[Yodo1AnalyticsManager sharedInstance]purchaseAnalytics:Yodo1CreateNSString(item)
                                                      itemNumber:number
                                          priceInVirtualCurrency:price];
    }
    
    void UnityUseAnalytics(const char* item,int amount,double price)
    {
        [[Yodo1AnalyticsManager sharedInstance]useAnalytics:Yodo1CreateNSString(item)
                                                     amount:amount
                                                      price:price];
        
    }
    
#pragma mark - DplusMobClick
    void UnityTrack(const char* eventName)
    {
        [[Yodo1AnalyticsManager sharedInstance]track:Yodo1CreateNSString(eventName)];
    }
    
    void UnitySaveTrackWithEventName(const char* eventName,const char* propertyKey,const char* propertyValue)
    {
        if(eventName == NULL || propertyKey == NULL || propertyValue == NULL)return;
        [[Yodo1AnalyticsManager sharedInstance]saveTrackWithEventName:Yodo1CreateNSString(eventName)
                                                          propertyKey:Yodo1CreateNSString(propertyKey)
                                                        propertyValue:Yodo1CreateNSString(propertyValue)];
    }
    
    void UnitySaveTrackWithEventNameIntValue(const char* eventName,const char* propertyKey,const char* propertyValue)
    {
        if(eventName == NULL || propertyKey == NULL)return;
        [[Yodo1AnalyticsManager sharedInstance]saveTrackWithEventName:Yodo1CreateNSString(eventName)
                                                          propertyKey:Yodo1CreateNSString(propertyKey)
                                                     propertyIntValue:[Yodo1CreateNSString(propertyValue) intValue]];
    }
    
    void UnitySaveTrackWithEventNameFloatValue(const char* eventName,const char* propertyKey,const char* propertyValue)
    {
        if(eventName == NULL || propertyKey == NULL)return;
        [[Yodo1AnalyticsManager sharedInstance]saveTrackWithEventName:Yodo1CreateNSString(eventName)
                                                          propertyKey:Yodo1CreateNSString(propertyKey)
                                                   propertyFloatValue:[Yodo1CreateNSString(propertyValue) floatValue]];
    }
    
    void UnitySaveTrackWithEventNameDoubleValue(const char* eventName,const char* propertyKey,const char* propertyValue)
    {
        if(eventName == NULL || propertyKey == NULL)return;
        [[Yodo1AnalyticsManager sharedInstance]saveTrackWithEventName:Yodo1CreateNSString(eventName)
                                                          propertyKey:Yodo1CreateNSString(propertyKey)
                                                  propertyDoubleValue:[Yodo1CreateNSString(propertyValue) doubleValue]];
    }
    
    void UnitySubmitTrack(const char* eventName)
    {
        if(eventName == NULL)return;
        [[Yodo1AnalyticsManager sharedInstance] submitTrackWithEventName:Yodo1CreateNSString(eventName)];
    }
    
    void UnityRegisterSuperProperty(const char* propertyJson)
    {
        NSString* properties = Yodo1CreateNSString(propertyJson);
        NSDictionary* dic = [Yodo1Commons JSONObjectWithString:properties error:nil];
        if([dic count] > 0){
            [[Yodo1AnalyticsManager sharedInstance]registerSuperProperty:dic];
        }
    }
    
    void UnityUnregisterSuperProperty(const char* propertyName)
    {
        [[Yodo1AnalyticsManager sharedInstance]unregisterSuperProperty:Yodo1CreateNSString(propertyName)];
    }
    
    //返回单个值
    char* UnityGetSuperProperty(const char* propertyName)
    {
        NSString* properties = [[Yodo1AnalyticsManager sharedInstance]getSuperProperty:Yodo1CreateNSString(propertyName)];
        if(properties){
            return Yodo1MakeStringCopy(properties.UTF8String);
        }
        return NULL;
    }
    
    //返回json字符串，那边解析为词典
    char* UnityGetSuperProperties()
    {
        NSDictionary* dic = [[Yodo1AnalyticsManager sharedInstance]getSuperProperties];
        if([dic count] > 0){
            NSString* properties = [Yodo1Commons stringWithJSONObject:dic error:nil];
            return Yodo1MakeStringCopy(properties.UTF8String);
        }
        return NULL;
    }
    
    void UnityClearSuperProperties()
    {
        [[Yodo1AnalyticsManager sharedInstance]clearSuperProperties];
    }
    
#pragma mark - GameAnalytics
    void UnitySetGACustomDimension01(const char* dimension01)
    {
        NSString* dimension =  Yodo1CreateNSString(dimension01);
        [[Yodo1AnalyticsManager sharedInstance]setGACustomDimension01:dimension];
    }
    
    void UnitySetGACustomDimension02(const char* dimension02)
    {
        NSString* dimension =  Yodo1CreateNSString(dimension02);
        [[Yodo1AnalyticsManager sharedInstance]setGACustomDimension02:dimension];
    }
    
    void UnitySetGACustomDimension03(const char* dimension03)
    {
        NSString* dimension =  Yodo1CreateNSString(dimension03);
        [[Yodo1AnalyticsManager sharedInstance]setGACustomDimension03:dimension];
    }
    
     #pragma mark - AppsFlyer
    // AppsFlyer
    void UnityValidateAndTrackInAppPurchase(const char*productIdentifier,
                                            const char*price,
                                            const char*currency,
                                            const char*transactionId){
        [[Yodo1AnalyticsManager sharedInstance]validateAndTrackInAppPurchase:Yodo1CreateNSString(productIdentifier)
                                                                       price:Yodo1CreateNSString(price)
                                                                    currency:Yodo1CreateNSString(currency)
                                                               transactionId:Yodo1CreateNSString(transactionId)];
    }
    // AppsFlyer Event
    void UnityEventAdAnalyticsWithName(const char*eventName, const char* jsonData) {
        NSString* m_EventName = Yodo1CreateNSString(eventName);
        NSString* eventData = Yodo1CreateNSString(jsonData);
        NSDictionary *eventDataDic = [Yodo1Commons JSONObjectWithString:eventData error:nil];
        [[Yodo1AnalyticsManager sharedInstance]eventAdAnalyticsWithName:m_EventName eventData:eventDataDic];
    }
    
     #pragma mark - Swrve
    //Swrve event
    void UnitySwrveEventAnalyticsWithName(const char*eventName, const char* jsonData) {
        NSString* m_EventName = Yodo1CreateNSString(eventName);
        NSString* eventData = Yodo1CreateNSString(jsonData);
        NSError *error = nil;
        NSDictionary *eventDataDic = [Yodo1Commons JSONObjectWithString:eventData error:&error];
        if(error){
            NSLog(@"Swrve Event error:%@",error.localizedDescription);
        }
        [[Yodo1AnalyticsManager sharedInstance]swrveEventAnalyticsWithName:m_EventName
                                                                 eventData:eventDataDic];
    }
    
    void UnitySwrveUserUpdate(const char* jsonData) {
        NSString* eventData = Yodo1CreateNSString(jsonData);
        NSError *error = nil;
        NSDictionary *eventDataDic = [Yodo1Commons JSONObjectWithString:eventData error:&error];
        if(error){
            NSLog(@"Swrve UserUpdate error:%@",error.localizedDescription);
        }
        [[Yodo1AnalyticsManager sharedInstance]swrveUserUpdate:eventDataDic];
    }

    void UnitySwrveTransactionProcessed(const char* jsonData) {
 
    }
}
#endif

@end
