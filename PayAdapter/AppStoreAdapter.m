//
//  AppStoreAdapter.m
//
//  Created by yodo1 on 14-5-19.
//  Copyright (c) 2014年 yodo1. All rights reserved.
//

#import "AppStoreAdapter.h"
#import <StoreKit/StoreKit.h>
#import "UCSNS.h"
#import "PaymentProduct.h"
#import "AppStoreProduct.h"
#import "Yodo1Commons.h"
#import "SubscriptionInfo.h"
#import "Yodo1AnalyticsManager.h"

#define APPSTORE_REQUEST_LIST @"appstore_request_list"
#define VERIFYING_REQUEST_LIST @"verifing_request_list"

#define SUCCESS_PAYMENT_ERROR_CODE          0      //苹果收据验证成功
#define VERIFYING_PAYMENT_ERROR_CODE        20     //苹果收据验证失败
#define SYNCHRONIZATION_GAME_ERROR_CODE     23     //同步游戏服务器失败

NSString *const ucBuyItemError = @"ucBuyItemError";
NSString *const ucBuyItemOK = @"ucBuyItemOK";

@interface AppStoreAdapter()<SKPaymentTransactionObserver,SKProductsRequestDelegate,SKRequestDelegate>
{
    NSMutableDictionary*   dictProducts;
    BOOL isRequesting;
}

@property (nonatomic,copy) NSString* extra;
@property (nonatomic,copy) NSString* orderId;
@property (nonatomic,retain) NSMutableArray* channelProductIdArray;
@property (nonatomic,retain) NSMutableArray* uniformProductIdArray;
@property (nonatomic,retain) NSMutableArray* productsInfoIdArray;
@property (nonatomic,retain) NSArray* products;
@property (nonatomic,copy) NSString* transactionReceipt;
@property (nonatomic,copy) NSString* transactionIdentifier;
@property (nonatomic,copy) NSString* currentUniformProductId;
@property (nonatomic,copy) NSString* price;
@property (nonatomic,retain) NSMutableArray* lossOrderIdArray; //查询漏单的产品ID
@property (nonatomic, retain) SKPayment* addedStorePayment;//promot Appstore Buy
/*
 更新产品信息
 */
- (void) updateProductInfo;

/*
 判断是否可以购买
 */
- (BOOL)paymentsAllowed;

/*
 请求所有产品信息
 */
- (void)requestProducts:(NSArray*)productIds;

/*
 获取产品信息根据产品ID
 */
- (SKProduct*)productInfoWithProductId:(NSString*)productId;

/*
 请求产品购买根据产品id
 */
- (void)requestPaymentWithProduct:(AppStoreProduct*)product;

/*
 格式化产品价格
 */
- (NSString*)productPrice:(SKProduct*)product;

//返回显示价格
- (NSString *)diplayPrice:(SKProduct *)product;

/*获取货币种类*/
- (NSString*)currencyCode:(NSLocale*)priceLocale;

//根据产品对象获取订阅周期
- (NSString*)periodUnitWithProduct:(SKProduct*)product;

- (AppStoreProduct*)productWithChannelProductId:(NSString*)channelProductId;

- (void)checkProductInfoWithChannelProductId:(NSString*)channelProductId
                             bRestorePayment:(BOOL)bRestorePayment;

@end

@implementation AppStoreAdapter
@synthesize channelProductIdArray = _channelProductIdArray;
@synthesize uniformProductIdArray = _uniformProductIdArray;
@synthesize productsInfoIdArray = _productsInfoIdArray;
@synthesize restoreProductIdArray = _restoreProductIdArray;
@synthesize productIdDic = _productIdDic;
@synthesize products = _products;
@synthesize currentUniformProductId;
@synthesize lossOrderIdArray = _lossOrderIdArray;
@synthesize addedStorePayment = _addedStorePayment;

+ (LoginType)platformType
{
    return LoginTypeAppStore;
}

+ (void)load
{
    if(NSClassFromString(@"AppStoreAdapter") != nil) {
        [[Yodo1Registry sharedRegistry] registerClass:self withRegistryType:@"platformType"];
    }
}

- (void)dealloc
{
    if (dictProducts) {
        dictProducts = nil;
        [dictProducts release];
    }
    if (_products) {
        _products = nil;
        [_products release];
    }
    if (_productIdDic) {
        _productIdDic = nil;
        [_productIdDic release];
    }
    if (_channelProductIdArray) {
        _channelProductIdArray = nil;
        [_channelProductIdArray release];
    }
    if (_uniformProductIdArray) {
        _uniformProductIdArray = nil;
        [_uniformProductIdArray release];
    }
    if (_productsInfoIdArray) {
        _productsInfoIdArray = nil;
        [_productsInfoIdArray release];
    }
    
    if (_restoreProductIdArray) {
        _restoreProductIdArray = nil;
        [_restoreProductIdArray release];
    }
    if (_lossOrderIdArray) {
        _lossOrderIdArray = nil;
        [_lossOrderIdArray release];
    }
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [super dealloc];
}

- (id)initWithType:(LoginType)type orientation:(UIInterfaceOrientation)orientation
{
    //初始化
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        dictProducts = [[NSMutableDictionary alloc] init];
        _channelProductIdArray = [[NSMutableArray alloc] initWithCapacity:5];
        _uniformProductIdArray = [[NSMutableArray alloc] initWithCapacity:5];
        _productsInfoIdArray = [[NSMutableArray alloc] initWithCapacity:5];
        _restoreProductIdArray = [[NSMutableArray alloc] initWithCapacity:5];
        _lossOrderIdArray = [[NSMutableArray alloc] initWithCapacity:5];
        
        NSString  *path=[[NSBundle mainBundle] pathForResource:@"Yodo1KeyConfig.bundle/Yodo1ProductInfo" ofType:@"plist"];
        _productIdDic =[NSMutableDictionary dictionaryWithContentsOfFile:path];
        NSAssert([_productIdDic count] > 0, @"Yodo1ProductInfo.plist 没有配置产品ID!");
        if(_productIdDic != nil){
            for (id key in _productIdDic){
                NSDictionary* pay = [_productIdDic objectForKey:key];
                [dictProducts setObject:[[[AppStoreProduct alloc] initWithDict:pay productId:key] autorelease] forKey:key];
                [_channelProductIdArray addObject:[pay objectForKey:PRODUCT_ID]];
                [_uniformProductIdArray addObject:key];
            }
            if (_channelProductIdArray.count > 0) {
                [self requestProducts:_channelProductIdArray];
            }
        }
    }
    return self;
}


- (NSString *)localizedStringForKeyWithBundleName:(NSString *)bundleName
                                              key:(NSString *)key
                                      withDefault:(NSString *)defaultString
{
    if (bundleName==nil) {
        return nil;
    }
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:bundleName ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *language = [NSBundle mainBundle].preferredLocalizations.firstObject;
        if ([[bundle localizations] containsObject:language]) {
            bundlePath = [bundle pathForResource:language ofType:@"lproj"];
        } else {
            language = [self language];
            if ([[bundle localizations] containsObject:language]) {
                bundlePath = [bundle pathForResource:language ofType:@"lproj"];
            }else{
                language = @"en";//默认英文
                NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
                if ([[infoDictionary allKeys] containsObject:@"CFBundleDevelopmentRegion"]) {
                    language = [infoDictionary objectForKey:@"CFBundleDevelopmentRegion"];
                }
                if ([language isEqualToString:@"zh_CN"]) {
                    language = @"zh-Hans";//中文
                }
                bundlePath = [bundle pathForResource:language ofType:@"lproj"];
            }
        }
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
    }
    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

- (NSString *)language {
    NSString* lang = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSArray * langArrayWord = [lang componentsSeparatedByString:@"-"];
    NSString* langString = [langArrayWord objectAtIndex:0];
    if (langArrayWord.count >= 3) {
        langString = [NSString stringWithFormat:@"%@-%@",
                      [langArrayWord objectAtIndex:0],
                      [langArrayWord objectAtIndex:1]];
    }
    return langString;
}

- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString {
    return [self localizedStringForKeyWithBundleName:@"Yodo1SDKStrings" key:key withDefault:defaultString];
}

-(void)updateProductInfo
{
    for (id key in self.uniformProductIdArray) {
        AppStoreProduct* product = [dictProducts objectForKey:key];
        SKProduct* skProduct = [self productInfoWithProductId:product.channelProductId];
        if (skProduct) {
            product.productName = skProduct.localizedTitle;
            product.channelProductId = skProduct.productIdentifier;
            product.productPrice = [skProduct.price stringValue];
            product.productDescription = skProduct.localizedDescription;
            product.currency = [self currencyCode:skProduct.priceLocale];
            product.priceDisplay = [self diplayPrice:skProduct];
            product.periodUnit = [self periodUnitWithProduct:skProduct];
        }
    }
}

- (NSString*)periodUnitWithProduct:(SKProduct*)product
{
    if (@available(iOS 11.2, *)) {
        
        NSString* unit = @"";
        int numberOfUnits = (int)product.subscriptionPeriod.numberOfUnits;
        switch (product.subscriptionPeriod.unit)
        {
            case SKProductPeriodUnitDay:
            {
                if (numberOfUnits == 7) {
                    unit = [self localizedStringForKey:@"SubscriptionWeek" withDefault:@"每周"];
                }else if (numberOfUnits == 30){
                    unit = [self localizedStringForKey:@"SubscriptionMonth" withDefault:@"每月"];
                } else {
                    unit = [NSString stringWithFormat:[self localizedStringForKey:@"SubscriptionDay" withDefault:@"每%d天"],numberOfUnits];
                }
            }
                break;
            case SKProductPeriodUnitWeek:
            {
                if (numberOfUnits == 1) {
                    unit = [self localizedStringForKey:@"SubscriptionWeek" withDefault:@"每周"];
                } else {
                    unit = [NSString stringWithFormat:[self localizedStringForKey:@"SubscriptionWeeks" withDefault:@"每%d周"],numberOfUnits];
                }
            }
                break;
            case SKProductPeriodUnitMonth:
            {
                if (numberOfUnits == 1) {
                    unit = [self localizedStringForKey:@"SubscriptionMonth" withDefault:@"每月"];
                } else {
                    unit = [NSString stringWithFormat:[self localizedStringForKey:@"SubscriptionMonths" withDefault:@"每%d个月"],numberOfUnits];
                }
            }
                break;
            case SKProductPeriodUnitYear:
            {
                if (numberOfUnits == 1) {
                    unit = [self localizedStringForKey:@"SubscriptionYear" withDefault:@"每年"];
                } else {
                    unit = [NSString stringWithFormat:[self localizedStringForKey:@"SubscriptionYears" withDefault:@"每%d年"],numberOfUnits];
                }
            }
                break;
        }
        return unit;
    } else {
        return @"";
    }
    return @"";
}

- (void)requestUpdateProductInfo
{
    if (self.channelProductIdArray.count > 0) {
        [self requestProducts:self.channelProductIdArray];
    }
}

- (void)login:(LoginUCenterCompletionBlock)block
{
}

- (void)loginOut
{
    if([UCenterManager sharedInstance].loginOutCompletionBlock){
        [UCenterManager sharedInstance].loginOutCompletionBlock();
    }
}

- (BOOL)isLogined
{
    return YES;
}

- (void)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
{
    [UCSNS handleOpenUrl:url];
}

#pragma mark- paymentWithProductId

- (void)paymentWithProductId:(NSString *)uniformProductId
{
    if (![[dictProducts allKeys] containsObject:uniformProductId]) {
        assert("Key is not config...");
    }
    
    self.currentUniformProductId = uniformProductId;
    
    AppStoreProduct* product = [dictProducts objectForKey:uniformProductId];
    PaymentProduct* paymentProduct = [[PaymentProduct alloc] init];
    paymentProduct.uniformProductId = product.uniformProductId;
    paymentProduct.channelProductId = product.channelProductId;
    paymentProduct.price = product.productPrice;
    paymentProduct.currency = product.currency;
    paymentProduct.productType = [NSString stringWithFormat:@"%d", (int)product.productType];
    paymentProduct.periodUnit = product.periodUnit;
    
    if (![UCenterManager sharedInstance].gameUserId) {
        paymentProduct.gameUserId = [Yodo1Commons idfvString];
    }else{
        paymentProduct.gameUserId = [UCenterManager sharedInstance].gameUserId;
    }
    
    if (![UCenterManager sharedInstance].gameNickname) {
        paymentProduct.gameNickname = [Yodo1Commons idfvString];
    }else{
        paymentProduct.gameNickname = [UCenterManager sharedInstance].gameNickname;
    }
    
    paymentProduct.ucuid = [UCenterManager sharedInstance].yodo1UCUid;
    paymentProduct.channelId = [UCenterManager sharedInstance].channelId;
    paymentProduct.gameRegionCode = [UCenterManager sharedInstance].gameRegionCode;
    paymentProduct.extra = [UCenterManager sharedInstance].extra;
    
    NSArray *preSaveProductListInfo = [self loadPaymentProducts:APPSTORE_REQUEST_LIST];
    NSMutableArray *productListInfo = [[NSMutableArray alloc] initWithArray:preSaveProductListInfo];
    [productListInfo addObject:paymentProduct];
    [self savePaymentProducts:productListInfo key:APPSTORE_REQUEST_LIST];
    
    [paymentProduct release];
    
    
    if([paymentProduct.productType intValue] == Auto_Subscription){
        NSString* mes = [self localizedStringForKey:@"SubscriptionAlertMessage"
                                        withDefault:@"确认启用后，您的iTunes账户将支付 %@ %@ 。%@自动续订此服务时您的iTunes账户也会支付相同费用。系统在订阅有效期结束前24小时会自动为您续订并扣费，除非您在有效期结束前取消服务。若需取消订阅，可前往设备设置-iTunes与App Store-查看Apple ID-订阅，管理或取消已经启用的服务。"];
        NSString* message = [NSString stringWithFormat:mes,paymentProduct.price,paymentProduct.currency,paymentProduct.periodUnit];
        
        NSString* title = [self localizedStringForKey:@"SubscriptionAlertTitle" withDefault:@"确认启用订阅服务"];
        NSString* cancelTitle = [self localizedStringForKey:@"SubscriptionAlertCancel" withDefault:@"取消"];
        NSString* okTitle = [self localizedStringForKey:@"SubscriptionAlertOK" withDefault:@"启用"];
        NSString* privateTitle = [self localizedStringForKey:@"SubscriptionAlertPrivate" withDefault:@"隐私协议"];
        NSString* serviceTitle = [self localizedStringForKey:@"SubscriptionAlertService" withDefault:@"服务条款"];
        
        if([[[UIDevice currentDevice]systemVersion] floatValue] < 8.0){
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:privateTitle,serviceTitle,okTitle, nil];
            [alert show];
        }else{
            UIAlertControllerStyle uiAlertControllerStyle = UIAlertControllerStyleActionSheet;
            if([Yodo1Commons isIpad] == YES){
                NSLog(@"IS pad");
                uiAlertControllerStyle = UIAlertControllerStyleAlert;
            }
            
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:uiAlertControllerStyle];
            
            NSString* privacyPolicyUrl = [self localizedStringForKey:@"SubscriptionPrivacyPolicyURL"
                                                         withDefault:@"https://www.yodo1.com/cn/privacy_policy"];
            NSString* termsServiceUrl = [self localizedStringForKey:@"SubscriptionTermsServiceURL"
                                                        withDefault:@"https://www.yodo1.com/cn/user_agreement"];
            
            UIAlertAction *privateAction = [UIAlertAction actionWithTitle:privateTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:privacyPolicyUrl]];
            }];
            UIAlertAction *serviceAction = [UIAlertAction actionWithTitle:serviceTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:termsServiceUrl]];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId,PaymentCannel,@"购买取消",self.extra);
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self requestPaymentWithProduct:product];
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:serviceAction];
            [alertController addAction:privateAction];
            [alertController addAction:cancelAction];
            
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
        }
    }else{
        [self requestPaymentWithProduct:product];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString* privacyPolicyUrl = [self localizedStringForKey:@"SubscriptionPrivacyPolicyURL"
                                                 withDefault:@"https://www.yodo1.com/cn/privacy_policy"];
    NSString* termsServiceUrl = [self localizedStringForKey:@"SubscriptionTermsServiceURL"
                                                withDefault:@"https://www.yodo1.com/cn/user_agreement"];
    switch (buttonIndex) {
        case 1:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:privacyPolicyUrl]];
            break;
        case 2:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:termsServiceUrl]];
            break;
        case 3:
            [self requestPaymentWithProduct:[dictProducts objectForKey:self.currentUniformProductId]];
            break;
        default:
            [UCenterManager sharedInstance].paymentCompletionBlock(self.currentUniformProductId,PaymentCannel,@"购买取消",self.extra);
            break;
    }
}

- (void)querySubscriptions:(BOOL)excludeOldTransactions{
    NSMutableArray* result = [[NSMutableArray alloc] init];
    
    NSString* gameUserId = nil;
    if (![UCenterManager sharedInstance].gameUserId) {
        gameUserId = [Yodo1Commons idfvString];
    }else{
        gameUserId = [UCenterManager sharedInstance].gameUserId;
    }
    
    [[Yodo1OGPayment sharedInstance] querySubscriptionsWithAppkey:[UCenterManager sharedInstance].appKey
                                                        channelId:[UCenterManager sharedInstance].channelId
                                           excludeOldTransactions:excludeOldTransactions
                                                  completionBlock:^(BOOL success, Yodo1OGPaymentError* error, NSString *response){
        if (success) {
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            if(responseDic){
                NSDictionary* extra =[responseDic objectForKey:@"extra"];
                NSArray* latest_receipt_infos =[extra objectForKey:@"latest_receipt_info"];
                NSTimeInterval serverTime = [[responseDic objectForKey:@"timestamp"] doubleValue];
                
                for (int i = 0; i < [latest_receipt_infos count]; i++) {
                    NSDictionary* latest_receipt_info =[latest_receipt_infos objectAtIndex:i];
                    NSTimeInterval expires_date_ms = [[latest_receipt_info objectForKey:@"expires_date_ms"] doubleValue];
                    if(expires_date_ms == 0){
                        continue;
                    }
                    NSTimeInterval purchase_date_ms = [[latest_receipt_info objectForKey:@"purchase_date_ms"] doubleValue];
                    NSString* channelProductId = [latest_receipt_info objectForKey:@"product_id"];
                    NSString* uniformProductId = [[self productWithChannelProductId:channelProductId] uniformProductId];
                    SubscriptionInfo* info = [[SubscriptionInfo alloc] initWithUniformProductId:uniformProductId channelProductId:channelProductId expires:expires_date_ms purchaseDate:purchase_date_ms];
                    [result addObject:info];
                }
                
                if([UCenterManager sharedInstance].querySubscriptionBlock){
                    [UCenterManager sharedInstance].querySubscriptionBlock(result, serverTime, YES, nil);
                }
            }
        }else{
            if([UCenterManager sharedInstance].querySubscriptionBlock){
                [UCenterManager sharedInstance].querySubscriptionBlock(result, -1, NO, response);
            }
        }
    }];
}

- (void)queryLossOrder
{
    [self.lossOrderIdArray removeAllObjects];
    NSDictionary *preVerifyingProductListInfo = [self loadPaymentProducts:VERIFYING_REQUEST_LIST];
    
    if (preVerifyingProductListInfo && [preVerifyingProductListInfo count] >0) {
        
        __block NSMutableDictionary* lossOrder = [[NSMutableDictionary alloc] init];
        __block int lossOrderCount = 0;
        __block int lossOrderReceiveCount = 0;
        
        NSString* gameUserId = nil;
        if (![UCenterManager sharedInstance].gameUserId) {
            gameUserId = [Yodo1Commons idfvString];
        }else{
            gameUserId = [UCenterManager sharedInstance].gameUserId;
        }
        
        for (id key in preVerifyingProductListInfo) {
            PaymentProduct* paymentProduct = [preVerifyingProductListInfo objectForKey:key];//遍历所有的产品ID
            if (![paymentProduct.gameUserId isEqualToString:gameUserId])
                continue;
            
            lossOrderCount++;
            [[Yodo1OGPayment sharedInstance] verifyAppStoreIAPOrder:paymentProduct.gameUserId
                                                           nickname:paymentProduct.gameNickname
                                                              ucuid:paymentProduct.ucuid
                                                           deviceid:[Yodo1Commons idfvString]
                                                            orderId:paymentProduct.transactionIdentifier
                                                           itemCode:paymentProduct.channelProductId
                                                             amount:paymentProduct.price
                                                       currencyCode:paymentProduct.currency
                                                         trxReceipt:paymentProduct.trxReceipt
                                                              extra:paymentProduct.extra
                                                             appkey:[UCenterManager sharedInstance].appKey
                                                          channelId:paymentProduct.channelId
                                                     gameRegionCode:paymentProduct.gameRegionCode
                                                        productType:paymentProduct.productType
                                                    completionBlock:^(BOOL success, Yodo1OGPaymentError *error, NSString *response){
                NSLog(@"response:%@",response);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        if (response) {
                            NSDictionary* dic = (NSDictionary*)[Yodo1Commons JSONObjectWithString:response error:nil];
                            NSString* stOrderId = [dic objectForKey:ORDER_ID];//苹果订单id
                            NSString* itemCode = [dic objectForKey:@"item_code"];
                            if (stOrderId) {
                                [lossOrder setObject:itemCode forKey:stOrderId];
                            }
                            NSLog(@"验证成功orderid:%@",stOrderId);
                        }
                    } else {
                        NSDictionary* dic = (NSDictionary*)[Yodo1Commons JSONObjectWithString:response error:nil];
                        NSString* stOrderId = [dic objectForKey:ORDER_ID];//苹果订单id
                        
                        if ([error errorCode] == VERIFYING_PAYMENT_ERROR_CODE) {
                            [self removeVerifyingRequestWithTransactionIdentifier:stOrderId];
                            NSLog(@"苹果收据验证失败OrderId:%@",stOrderId);
                        }
                    }
                    
                    lossOrderReceiveCount++;
                    if (lossOrderReceiveCount==lossOrderCount) {
                        
                        if ([UCenterManager sharedInstance].lossOrderCompletionBlock) {
                            NSArray* orderIds = [lossOrder allKeys];
                            if ([orderIds count] > 0) {
                                for (int i = 0; i < orderIds.count; i++) {
                                    NSString* key = [orderIds objectAtIndex:i];
                                    if (![self removeVerifyingRequestWithTransactionIdentifier:key]) {
                                        [lossOrder removeObjectForKey:key];
                                    }
                                }
                            }
                            NSArray* tempItemCode = [NSArray arrayWithArray:[lossOrder allValues]];
                            for (NSString* itemCode in tempItemCode) {
                                [self checkProductInfoWithChannelProductId:itemCode bRestorePayment:NO];
                            }
                            [UCenterManager sharedInstance].lossOrderCompletionBlock(self.lossOrderIdArray,success,LossOrderTypeLossOrder,@"");
                            [lossOrder release];
                        }
                        
                    }
                });
                
            }];
        }
    }else{
        if ([UCenterManager sharedInstance].lossOrderCompletionBlock) {
            [UCenterManager sharedInstance].lossOrderCompletionBlock(nil,NO,LossOrderTypeLossOrder,@"没有漏单");
        }
    }
}

- (void)productInfoWithProductId:(NSString *)uniformProductId
                        callback:(ProductInfoCompletionBlock)callback
{
    AppStoreProduct* product = [dictProducts objectForKey:uniformProductId];
    ProductInfo* productInfo = [[[ProductInfo alloc]init]autorelease];
    productInfo.uniformProductId = product.uniformProductId;
    productInfo.channelProductId = product.channelProductId;
    productInfo.productName = product.productName;
    productInfo.productDescription = product.productDescription;
    productInfo.productType = product.productType;
    productInfo.currency = product.currency;
    
    SKProduct* skProduct = [self productInfoWithProductId:product.channelProductId];
    if (skProduct) {
        productInfo.productPrice = [skProduct.price stringValue];
        productInfo.currency = [self currencyCode:skProduct.priceLocale];
        productInfo.priceDisplay = [self diplayPrice:skProduct];
        productInfo.periodUnit = [self periodUnitWithProduct:skProduct];
    }else{
        productInfo.productPrice = product.productPrice;
        productInfo.priceDisplay = product.priceDisplay;
        
        if(_channelProductIdArray.count>0){
            [self requestProducts:_channelProductIdArray];
        }
    }
    callback(uniformProductId,productInfo);
}

- (void)productsInfo:(ProductsInfoCompletionBlock)callback
{
    if (callback) {
        if ([_productsInfoIdArray count] > 0 ) {
            [_productsInfoIdArray removeAllObjects];
        }
        BOOL hasError = NO;
        NSArray* allAppStoreProduct = [dictProducts allValues];
        for (AppStoreProduct *productInfo in allAppStoreProduct) {
            NSMutableDictionary* dict = [NSMutableDictionary dictionary];
            [dict setObject:productInfo.uniformProductId == nil?@"":productInfo.uniformProductId forKey:@"productId"];
            [dict setObject:productInfo.channelProductId == nil?@"":productInfo.channelProductId forKey:@"marketId"];
            [dict setObject:productInfo.productName == nil?@"":productInfo.productName forKey:@"productName"];
            
            SKProduct* skProduct = [self productInfoWithProductId:productInfo.channelProductId];
            NSString* price = nil;
            if (skProduct) {
                price = [skProduct.price stringValue];
                productInfo.currency = [self currencyCode:skProduct.priceLocale];
                productInfo.priceDisplay = [self diplayPrice:skProduct];
                productInfo.periodUnit = [self periodUnitWithProduct:skProduct];
            }else{
                price = productInfo.productPrice;
                hasError = YES;
            }
            
            [dict setObject:productInfo.priceDisplay == nil?@"":productInfo.priceDisplay forKey:@"priceDisplay"];
            [dict setObject:price == nil?@"":price forKey:@"price"];
            [dict setObject:productInfo.productDescription == nil?@"":productInfo.productDescription forKey:@"description"];
            [dict setObject:[NSNumber numberWithInt:productInfo.productType] forKey:@"ProductType"];
            [dict setObject:productInfo.currency == nil?@"":productInfo.currency forKey:@"currency"];
            [dict setObject:[NSNumber numberWithInt:0] forKey:@"coin"];
            
            [_productsInfoIdArray addObject:dict];
        }
        
        if(hasError && _channelProductIdArray.count>0){
            [self requestProducts:_channelProductIdArray];
        }
        callback(_productsInfoIdArray);
    }else{
        NSLog(@"not set productsInfo callback!");
    }
}

#pragma mark - 保存购买，防止苹果漏单 PaymentProduct

- (void)savePaymentProducts:(id)productsObject key:(NSString *)key
{
    if (productsObject == nil) {
        NSLog(@"[ Yodo1 ] 保存数据为nil");
        return;
    }
    NSData *yodo1PaymentProductData = nil;
    NSError *error = nil;
    if (@available(iOS 11.0, *)) {
        yodo1PaymentProductData = [NSKeyedArchiver archivedDataWithRootObject:productsObject requiringSecureCoding:YES error:&error];
        if (error){
            NSLog(@"[ Yodo1 ] 保存数据error:%@",error);
        }
        
    } else {
        yodo1PaymentProductData = [NSKeyedArchiver archivedDataWithRootObject:productsObject];
    }
    if (yodo1PaymentProductData) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:yodo1PaymentProductData forKey:key];
        [defaults synchronize];
    }else{
        NSLog(@"[ Yodo1 ] 保存数据为nil");
    }
}

- (id)loadPaymentProducts:(NSString *)key
{
    NSError *error = nil;
    id content = nil;
    NSData* yodo1PaymentProductData  = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (yodo1PaymentProductData == nil) {
        return nil;
    }
    NSSet* sets = [NSSet setWithArray:@[NSArray.class,NSDictionary.class,PaymentProduct.class]];
    if (@available(iOS 11.0, *)) {
        content = [NSKeyedUnarchiver unarchivedObjectOfClasses:sets fromData:yodo1PaymentProductData error:&error];
        if (error) {
            NSLog(@"[ Yodo1 ] load数据error:%@",error);
        }
    } else {
        content = [NSKeyedUnarchiver unarchiveObjectWithData:yodo1PaymentProductData];
    }
    return content;
}

- (BOOL)removeVerifyingRequestWithTransactionIdentifier:(NSString*)transactionIdentifier
{
    NSDictionary *preVerifyingProductListInfo = [self loadPaymentProducts:VERIFYING_REQUEST_LIST];
    NSMutableDictionary *verifyingProductListInfo = [[NSMutableDictionary alloc] initWithDictionary:preVerifyingProductListInfo];
    if([[verifyingProductListInfo allKeys]containsObject:transactionIdentifier]){
        [verifyingProductListInfo removeObjectForKey:transactionIdentifier];
        [self savePaymentProducts:verifyingProductListInfo key:VERIFYING_REQUEST_LIST];
        return YES;
    }
    return NO;
}

- (BOOL)paymentsAllowed
{
    return [SKPaymentQueue canMakePayments];
}

#pragma mark - appstore request product

- (void)requestProducts:(NSArray *)productIds
{
    isRequesting = YES;
    NSSet *productIds_ = [NSSet setWithArray:productIds];
    SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:productIds_];
    request.delegate = self;
    [request start];
}

- (SKProduct*)productInfoWithProductId:(NSString *)productId
{
    if ([self.products count] > 0) {
        for(SKProduct *product in self.products) {
            if ([productId isEqualToString:product.productIdentifier]) {
                return product;
            }
        }
    }
    return nil;
}

- (void)requestPaymentWithProduct:(AppStoreProduct*)product
{
    SKProduct *productItem = [self productInfoWithProductId:product.channelProductId];
    if (productItem) {
        SKPayment *payment = [SKPayment paymentWithProduct:productItem];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else{
        //重新去请求产品信息
        if (_channelProductIdArray.count > 0 && !isRequesting) {
            [self requestProducts:_channelProductIdArray];
        }
        NSString* info = [self localizedStringForKey:ucBuyItemError withDefault:@"购买的产品无效，请稍候重试！"];
        NSString* ok =  [self localizedStringForKey:ucBuyItemOK withDefault:@"确定"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:info
                                                       delegate:nil
                                              cancelButtonTitle:ok
                                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        if ([UCenterManager sharedInstance].paymentCompletionBlock) {
            [UCenterManager sharedInstance].paymentCompletionBlock(product.uniformProductId,PaymentFail,@"购买的产品无效，请稍候重试！",self.extra);
        }
    }
}

- (void)restorePayment
{
    [self.restoreProductIdArray removeAllObjects];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (NSString *)diplayPrice:(SKProduct *)product
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
    return formattedPrice;
}

- (NSString *)productPrice:(SKProduct *)product
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    [numberFormatter setCurrencySymbol:@""];
    NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
    return formattedPrice;
}

- (NSString *)currencyCode:(NSLocale *)priceLocale
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setCurrencySymbol:@""];
    if (priceLocale) {
        [numberFormatter setLocale:priceLocale];
    }
    return [numberFormatter currencyCode];
}

- (AppStoreProduct*)productWithChannelProductId:(NSString*)channelProductId
{
    NSArray* allAppStoreProduct = [dictProducts allValues];
    for (AppStoreProduct *productInfo in allAppStoreProduct) {
        if ([productInfo.channelProductId isEqualToString:channelProductId]) {
            return productInfo;
        }
    }
    return nil;
}

- (void)checkProductInfoWithChannelProductId:(NSString*)channelProductId
                             bRestorePayment:(BOOL)bRestorePayment
{
    if (channelProductId == nil) {
        return;
    }
    AppStoreProduct *productInfo = [self productWithChannelProductId:channelProductId];
    if (productInfo) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:productInfo.uniformProductId == nil?@"":productInfo.uniformProductId forKey:@"productId"];
        [dict setObject:productInfo.channelProductId == nil?@"":productInfo.channelProductId forKey:@"marketId"];
        [dict setObject:productInfo.productName == nil?@"":productInfo.productName forKey:@"productName"];
        
        SKProduct* skProduct = [self productInfoWithProductId:productInfo.channelProductId];
        NSString* price = nil;
        if (skProduct) {
            price = [self productPrice:skProduct];
        }else{
            price = productInfo.productPrice;
        }
        
        NSString* priceDisplay = [NSString stringWithFormat:@"%@ %@",price,productInfo.currency];
        [dict setObject:priceDisplay == nil?@"":priceDisplay forKey:@"priceDisplay"];
        [dict setObject:price == nil?@"":price forKey:@"price"];
        [dict setObject:productInfo.productDescription == nil?@"":productInfo.productDescription forKey:@"description"];
        [dict setObject:[NSNumber numberWithInt:productInfo.productType] forKey:@"ProductType"];
        [dict setObject:productInfo.currency == nil?@"":productInfo.currency forKey:@"currency"];
        [dict setObject:[NSNumber numberWithInt:0] forKey:@"coin"];
        [dict setObject:productInfo.periodUnit == nil?@"":[self periodUnitWithProduct:skProduct] forKey:@"periodUnit"];
        
        if (bRestorePayment) {
            [self.restoreProductIdArray addObject:dict];
        }else{
            [self.lossOrderIdArray addObject:dict];
        }
    }
}

#pragma mark - removeAppstoreRequestListWithProductId 保存成功信息，删除苹果支付请求信息

- (PaymentProduct*)removeAppstoreRequestListWithProductId:(NSString*)productId withUserId:(NSString*)gameUserId isSaveVerifyList:(SKPaymentTransaction *)transaction
{
    NSArray *preSaveProductListInfo = [self loadPaymentProducts:APPSTORE_REQUEST_LIST];
    
    if (preSaveProductListInfo == nil)
    {
        assert("APPSTORE_REQUEST_LIST is empty...");
        return nil;
    }
    
    NSMutableArray *appstoreProductListInfo = [[NSMutableArray alloc] initWithArray:preSaveProductListInfo];
    
    for (int i=0; i<appstoreProductListInfo.count; i++)
    {
        PaymentProduct* yodo1PaymentAppstoreProduct = [appstoreProductListInfo objectAtIndex:i];
        if ([yodo1PaymentAppstoreProduct.channelProductId compare:productId] == NSOrderedSame &&
            (gameUserId == nil || [yodo1PaymentAppstoreProduct.gameUserId compare:gameUserId] == NSOrderedSame))
        {
            if (transaction) {
                //保存购买，防止验证失败漏单
                NSString *trxReceipt =[[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]] base64EncodedStringWithOptions:0];
                
                yodo1PaymentAppstoreProduct.trxReceipt = trxReceipt;
                yodo1PaymentAppstoreProduct.transactionIdentifier = transaction.transactionIdentifier;
                
                NSDictionary *preVerifyingProductListInfo = [self loadPaymentProducts:VERIFYING_REQUEST_LIST];
                NSMutableDictionary *verifyingProductListInfo = [[NSMutableDictionary alloc] initWithDictionary:preVerifyingProductListInfo];
                [verifyingProductListInfo setObject:yodo1PaymentAppstoreProduct forKey:yodo1PaymentAppstoreProduct.transactionIdentifier];
                [self savePaymentProducts:verifyingProductListInfo key:VERIFYING_REQUEST_LIST];
            }
            //删除保存的苹果支付请求
            [appstoreProductListInfo removeObject:yodo1PaymentAppstoreProduct];
            
            [self savePaymentProducts:appstoreProductListInfo key:APPSTORE_REQUEST_LIST];
            [appstoreProductListInfo release];
            
            return yodo1PaymentAppstoreProduct;
        }
    }
    return nil;
}

#pragma mark- completeTransaction交易完成
/*
 交易完成
 */
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0) {
        [UCenterManager sharedInstance].paymentCompletionBlock(self.currentUniformProductId,PaymentSuccess,@"支付成功",[UCenterManager sharedInstance].extra);
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    } else {
        // 移除防止苹果漏单的购买记录
        NSString* gameUserId = nil;
        if (![UCenterManager sharedInstance].gameUserId) {
            gameUserId = [Yodo1Commons idfvString];
        }else{
            gameUserId = [UCenterManager sharedInstance].gameUserId;
        }
        
        PaymentProduct* paymentProduct = [self removeAppstoreRequestListWithProductId:transaction.payment.productIdentifier
                                                                           withUserId:gameUserId
                                                                     isSaveVerifyList:transaction];
        if (paymentProduct == nil) {
            NSLog(@"没有主动点击购买");
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            return;
        }
        [self productInfoWithProductId:paymentProduct.uniformProductId
                              callback:^(NSString *uniformProductId, ProductInfo *productInfo) {
            //AppsFlyer 数据统计
            [[Yodo1AnalyticsManager sharedInstance]validateAndTrackInAppPurchase:transaction.payment.productIdentifier
                                                                           price:productInfo.productPrice
                                                                        currency:productInfo.currency
                                                                   transactionId:transaction.transactionIdentifier];
            
            //Swrve 统计
            SKProduct* sk = [self productInfoWithProductId:productInfo.channelProductId];
            [[Yodo1AnalyticsManager sharedInstance]swrveTransactionProcessed:transaction
                                                               productBought:sk];
        }];
        if ([UCenterManager sharedInstance].validatePaymentBlock) {
            NSDictionary* extra = @{@"productIdentifier":paymentProduct.channelProductId,
                                    @"transactionIdentifier":paymentProduct.transactionIdentifier,
                                    @"transactionReceipt":paymentProduct.trxReceipt};
            NSString* extraSt = [Yodo1Commons stringWithJSONObject:extra error:nil];
            [UCenterManager sharedInstance].validatePaymentBlock(paymentProduct.uniformProductId,extraSt);
        }
        if ([UCenterManager sharedInstance].paymentCompletionBlock && paymentProduct) {
            
            if (paymentProduct.gameUserId == nil) {
                NSLog(@"gameUserId is not nil...");
                return;
            }
            [[Yodo1OGPayment sharedInstance] verifyAppStoreIAPOrder:paymentProduct.gameUserId
                                                           nickname:paymentProduct.gameNickname
                                                              ucuid:paymentProduct.ucuid
                                                           deviceid:[Yodo1Commons idfvString]
                                                            orderId:transaction.transactionIdentifier
                                                           itemCode:transaction.payment.productIdentifier
                                                             amount:paymentProduct.price
                                                       currencyCode:paymentProduct.currency
                                                         trxReceipt:paymentProduct.trxReceipt
                                                              extra:paymentProduct.extra
                                                             appkey:[UCenterManager sharedInstance].appKey
                                                          channelId:paymentProduct.channelId
                                                     gameRegionCode:paymentProduct.gameRegionCode
                                                        productType:paymentProduct.productType
                                                    completionBlock:^(BOOL success, Yodo1OGPaymentError *error, NSString *response) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        if ([self removeVerifyingRequestWithTransactionIdentifier:paymentProduct.transactionIdentifier]) {
                            [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId,PaymentSuccess,response,[UCenterManager sharedInstance].extra);
                        }else{
                            [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId,PaymentFail,response,[UCenterManager sharedInstance].extra);
                        }
                    }else{
                        [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId, PaymentValidationFail,response,[UCenterManager sharedInstance].extra);
                        if ([error errorCode] == VERIFYING_PAYMENT_ERROR_CODE) {
                            [self removeVerifyingRequestWithTransactionIdentifier:paymentProduct.transactionIdentifier];
                        }
                    }
                });
            }];
            
        }
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
}

/*
 恢复购买
 */
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    if (self.restoreProductIdArray) {
        [self checkProductInfoWithChannelProductId:transaction.payment.productIdentifier bRestorePayment:YES];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

#pragma mark- completeTransaction交易失败
/*
 交易失败
 */
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    // 移除防止苹果漏单的购买记录
    NSString* gameUserId = nil;
    if (![UCenterManager sharedInstance].gameUserId) {
        gameUserId = [Yodo1Commons idfvString];
    }else{
        gameUserId = [UCenterManager sharedInstance].gameUserId;
    }
    
    PaymentProduct* paymentProduct = [self removeAppstoreRequestListWithProductId:transaction.payment.productIdentifier withUserId:gameUserId isSaveVerifyList:nil];
    
    if ([UCenterManager sharedInstance].paymentCompletionBlock && gameUserId && paymentProduct) {
        if (transaction.error.code == SKErrorPaymentCancelled)
            [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId,PaymentCannel,@"购买取消",self.extra);
        else
            [UCenterManager sharedInstance].paymentCompletionBlock(paymentProduct.uniformProductId,PaymentFail,@"购买失败",self.extra);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

#pragma SKProductsRequestDelegate delegate

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    isRequesting = NO;
    self.products = response.products;
    NSArray *invalid = response.invalidProductIdentifiers;
    
    for (NSString *invalidPID in invalid) {
#ifdef DEBUG
        NSLog(@"[ Yodo1 ]:%@ is invalid", invalidPID);
#endif
        
    }
    for(SKProduct *product in self.products) {
#ifdef DEBUG
        NSLog(@"[ Yodo1 ] ID:%@: Title:%@ (%@) - %@ %@", product.productIdentifier,
              product.localizedTitle, product.localizedDescription, [self productPrice:product],[self currencyCode:product.priceLocale]);
        
#endif
    }
    
}

#pragma SKPaymentTransactionObserver delegate

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    
    for (SKPaymentTransaction *transaction in transactions) {
        if (transaction == nil) {
            continue;
        }
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
            {
                NSLog(@"Transaction started!");
            }
                break;
                
            case SKPaymentTransactionStatePurchased:
            {
#ifdef DEBUG
                NSLog(@"Transaction successful!");
                NSLog(@"订单号:transactionIdentifier:%@",transaction.transactionIdentifier);
#endif
                [self completeTransaction:transaction];
                
            }
                break;
                
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"Transaction failed!");
                [self failedTransaction:transaction];
            }
                break;
            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"Transaction restored!");
                [self restoreTransaction:transaction];
            }
                break;
            case SKPaymentTransactionStateDeferred:
            {
                NSLog(@"Transaction Deferred!");
                break;
            }
            default: {
                
            }
                break;
        }
    }
    
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if ([UCenterManager sharedInstance].lossOrderCompletionBlock) {
        [UCenterManager sharedInstance].lossOrderCompletionBlock(self.restoreProductIdArray,YES,LossOrderTypeRestore,@"恢复购买成功");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if ([UCenterManager sharedInstance].lossOrderCompletionBlock)
    {
        if (error.code == SKErrorPaymentCancelled)
            [UCenterManager sharedInstance].lossOrderCompletionBlock(nil,NO,LossOrderTypeRestore,@"取消恢复购买");
        else
            [UCenterManager sharedInstance].lossOrderCompletionBlock(nil,NO,LossOrderTypeRestore,@"恢复购买失败");
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product{
    self.addedStorePayment = payment;
    
    //defer
    return NO;
}

- (AppStoreProduct*)GetPromotionProduct{
    if (self.addedStorePayment) {
        NSString* uniformProductId = [[self productWithChannelProductId:self.addedStorePayment.productIdentifier] uniformProductId];
        AppStoreProduct* product = [dictProducts objectForKey:uniformProductId];
        return product;
    }
    
    return nil;
}

- (void) CancelPromotion{
    self.addedStorePayment = nil;
}

- (void)ReadyToContinuePurchaseFromPromot{
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        if(self.addedStorePayment){
            NSString* uniformProductId = [[self productWithChannelProductId:self.addedStorePayment.productIdentifier] uniformProductId];
            {
                self.currentUniformProductId = uniformProductId;
                
                AppStoreProduct* product = [dictProducts objectForKey:uniformProductId];
                PaymentProduct* paymentProduct = [[PaymentProduct alloc] init];
                paymentProduct.uniformProductId = product.uniformProductId;
                paymentProduct.channelProductId = product.channelProductId;
                paymentProduct.price = product.productPrice;
                paymentProduct.currency = product.currency;
                paymentProduct.productType = [NSString stringWithFormat:@"%d", (int)product.productType];
                
                if (![UCenterManager sharedInstance].gameUserId) {
                    paymentProduct.gameUserId = [Yodo1Commons idfvString];
                }else{
                    paymentProduct.gameUserId = [UCenterManager sharedInstance].gameUserId;
                }
                
                if (![UCenterManager sharedInstance].gameNickname) {
                    paymentProduct.gameNickname = [Yodo1Commons idfvString];
                }else{
                    paymentProduct.gameNickname = [UCenterManager sharedInstance].gameNickname;
                }
                
                paymentProduct.ucuid = [UCenterManager sharedInstance].yodo1UCUid;
                paymentProduct.channelId = [UCenterManager sharedInstance].channelId;
                paymentProduct.gameRegionCode = [UCenterManager sharedInstance].gameRegionCode;
                paymentProduct.extra = [UCenterManager sharedInstance].extra;
                
                NSArray *preSaveProductListInfo = [self loadPaymentProducts:APPSTORE_REQUEST_LIST];
                NSMutableArray *productListInfo = [[NSMutableArray alloc] initWithArray:preSaveProductListInfo];
                [productListInfo addObject:paymentProduct];
                [self savePaymentProducts:productListInfo key:APPSTORE_REQUEST_LIST];
                
                [paymentProduct release];
            }
            
            [[SKPaymentQueue defaultQueue] addPayment:self.addedStorePayment];
        }
    }
#endif
}

#pragma SKRequest delegate

- (void)requestDidFinish:(SKRequest *)request
{
    if (self.products && self.products.count >0) {
        [self updateProductInfo];
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    
}



- (void)fetchStorePromotionOrder{
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        [[SKProductStorePromotionController defaultController] fetchStorePromotionOrderWithCompletionHandler:^(NSArray<SKProduct *> * _Nonnull storePromotionOrder, NSError * _Nullable error) {
            if([UCenterManager sharedInstance].fetchStorePromotionOrderCompletionBlock){
                NSMutableArray<NSString*>* uniformProductIDs = [[NSMutableArray alloc] init];
                for (int i = 0; i < [storePromotionOrder count]; i++) {
                    NSString* productID = [[storePromotionOrder objectAtIndex:i] productIdentifier];
                    NSString* uniformProductID = [[self productWithChannelProductId:productID] uniformProductId];
                    [uniformProductIDs addObject:uniformProductID];
                }
                
                [UCenterManager sharedInstance].fetchStorePromotionOrderCompletionBlock(uniformProductIDs, error == nil, [error description]);
            }
        }];
    } else {
        // Fallback on earlier versions
    }
#endif
}

- (void)fetchStorePromotionVisibilityForProduct:(NSString*)uniformProductId {
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        NSString* productID = [[dictProducts objectForKey:uniformProductId] channelProductId];
        [[SKProductStorePromotionController defaultController] fetchStorePromotionVisibilityForProduct:[self productInfoWithProductId:productID] completionHandler:^(SKProductStorePromotionVisibility storePromotionVisibility, NSError * _Nullable error) {
            if([UCenterManager sharedInstance].fetchStorePromotionVisibilityCompletionBlock){
                Yodo1PromotionVisibility result = Default;
                switch (storePromotionVisibility) {
                    case SKProductStorePromotionVisibilityShow:
                        result = Visible;
                        break;
                    case SKProductStorePromotionVisibilityHide:
                        result = Hide;
                        break;
                    default:
                        break;
                }
                [UCenterManager sharedInstance].fetchStorePromotionVisibilityCompletionBlock(result, error == nil, [error description]);
            }
        }];
    } else {
        // Fallback on earlier versions
    }
#endif
}

- (void)updateStorePromotionOrder:(NSArray<NSString *> *)uniformProductIdArray{
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        NSMutableArray<SKProduct *> *productsArray = [[NSMutableArray alloc] init];
        for (NSString* uniformProductId in uniformProductIdArray) {
            NSString* productID = [[dictProducts objectForKey:uniformProductId] channelProductId];
            [productsArray addObject:[self productInfoWithProductId:productID]];
        }
        [[SKProductStorePromotionController defaultController] updateStorePromotionOrder:productsArray completionHandler:^(NSError * _Nullable error) {
            [UCenterManager sharedInstance].updateStorePromotionOrderCompletionBlock(error == nil, [error description]);
        }];
    } else {
        // Fallback on earlier versions
    }
#endif
}

- (void)updateStorePromotionVisibility:(BOOL)visibility Product:(NSString*)uniformProductId{
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        SKProduct* product = [self productInfoWithProductId:[[dictProducts objectForKey:uniformProductId] channelProductId]];
        [[SKProductStorePromotionController defaultController] updateStorePromotionVisibility:visibility ? SKProductStorePromotionVisibilityShow : SKProductStorePromotionVisibilityHide forProduct:product completionHandler:^(NSError * _Nullable error) {
            [UCenterManager sharedInstance].updateStorePromotionVisibilityCompletionBlock(error == nil, [error description]);
        }];
    } else {
        // Fallback on earlier versions
    }
#endif
}

@end
