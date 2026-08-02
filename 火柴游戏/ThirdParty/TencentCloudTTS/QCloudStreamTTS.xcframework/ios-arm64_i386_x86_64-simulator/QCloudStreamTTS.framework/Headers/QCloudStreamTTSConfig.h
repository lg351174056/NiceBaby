//
//  QCloudStreamTTSConfig.h
//  QCloudStreamTTS
//
//  Created by tbolp on 2024/10/15.
//

#import <Foundation/Foundation.h>
#import <QCloudStreamTTS/QCloudStreamTTSController.h>
#import <QCloudStreamTTS/QCloudStreamTTSListener.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString* const kVoiceType;
FOUNDATION_EXPORT NSString* const kVolume;
FOUNDATION_EXPORT NSString* const kSpeed;
FOUNDATION_EXPORT NSString* const kSampleRate;
FOUNDATION_EXPORT NSString* const kCodec;
FOUNDATION_EXPORT NSString* const kEnableSubtitle;
FOUNDATION_EXPORT NSString* const kEmotionCategory;
FOUNDATION_EXPORT NSString* const kEmotionIntensity;
FOUNDATION_EXPORT NSString* const kSegmentRate;
FOUNDATION_EXPORT NSString* const kFastVoiceType;


@interface QCloudStreamTTSConfig : NSObject

@property (nonnull) NSString* appID; // 腾讯云 appid
@property (nonnull) NSString* secretID; // 腾讯云 secretID
@property (nonnull) NSString* secretKey; // 腾讯云 secretKey
@property (nonnull) NSString* token; // 临时token,不为空字符时生效,使用临时token时,secretId,secretKey需为临时密钥
@property int connectTimeout; // 大于0生效,单位为ms,默认为0

/*
 * 设置传入后台的api的参数,参数可参考文档https://cloud.tencent.com/document/product/1073/108595 说明
 * @param key 参数名称
 * @param value 参数值,参数值为nil会删除已设置的key
 */
- (QCloudStreamTTSConfig*)setApiParam:(nonnull NSString*)key value:(nullable NSString*)value;
- (QCloudStreamTTSConfig*)setApiParam:(nonnull NSString*)key ivalue:(NSInteger)value;
- (QCloudStreamTTSConfig*)setApiParam:(nonnull NSString*)key fvalue:(float)value;
- (QCloudStreamTTSConfig*)setApiParam:(nonnull NSString*)key bvalue:(BOOL)value;

/*
 * 创建流式语音合成控制器
 * @param listener 用于回调合成任务的接口及中间信息
 */
- (id<QCloudStreamTTSController>)build:(id<QCloudStreamTTSListener>)listener;

@end

NS_ASSUME_NONNULL_END
