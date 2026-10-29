#import "CallEngine.h"
#import <CommonCrypto/CommonHMAC.h>
#import <zlib.h>
@import TXLiteAVSDK_TRTC;

@interface CallEngine () <TRTCCloudDelegate>
@property (nonatomic, strong) TRTCCloud *cloud;
@end

@implementation CallEngine

+ (instancetype)shared {
    static CallEngine *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [CallEngine new]; });
    return inst;
}

- (instancetype)init {
    if (self = [super init]) {
        _cloud = [TRTCCloud sharedInstance];
        _cloud.delegate = self;
    }
    return self;
}

#pragma mark - UserSig (توليد محلي للمفتاح — مناسب لتطبيق خاص بالأصدقاء)

static NSString *GenUserSig(uint32_t sdkAppId, NSString *secretKey, NSString *userId, long expire) {
    long now = (long)[[NSDate date] timeIntervalSince1970];
    NSString *content = [NSString stringWithFormat:
        @"TLS.identifier:%@\nTLS.sdkappid:%u\nTLS.time:%ld\nTLS.expire:%ld\n",
        userId, sdkAppId, now, expire];

    NSData *keyData = [secretKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *msgData = [content dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char mac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, msgData.bytes, msgData.length, mac);
    NSString *sig = [[NSData dataWithBytes:mac length:sizeof(mac)] base64EncodedStringWithOptions:0];

    NSDictionary *obj = @{
        @"TLS.ver": @"2.0",
        @"TLS.identifier": userId,
        @"TLS.sdkappid": @(sdkAppId),
        @"TLS.expire": @(expire),
        @"TLS.time": @(now),
        @"TLS.sig": sig,
    };
    NSData *json = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    if (!json) return @"";

    uLongf destLen = compressBound((uLong)json.length);
    NSMutableData *out = [NSMutableData dataWithLength:destLen];
    if (compress((Bytef *)out.mutableBytes, &destLen, (const Bytef *)json.bytes, (uLong)json.length) != Z_OK) {
        return @"";
    }
    out.length = destLen;

    NSString *b64 = [out base64EncodedStringWithOptions:0];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"+" withString:@"*"];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"=" withString:@"_"];
    return b64;
}

#pragma mark - Room

- (void)enterWithSdkAppId:(uint32_t)sdkAppId
                secretKey:(NSString *)secretKey
                   userId:(NSString *)userId
                     room:(NSString *)room {
    TRTCParams *p = [TRTCParams new];
    p.sdkAppId = sdkAppId;
    p.userId = userId;
    p.userSig = GenUserSig(sdkAppId, secretKey, userId, 7 * 24 * 3600);
    p.strRoomId = room;
    p.role = TRTCRoleAnchor;
    [self.cloud enterRoom:p appScene:TRTCAppSceneVideoCall];
    [self.cloud startLocalAudio:TRTCAudioQualitySpeech];
}

- (void)exitRoom {
    [self.cloud stopScreenCapture];
    [self.cloud stopLocalAudio];
    [self.cloud exitRoom];
}

- (void)setMuted:(BOOL)muted {
    [self.cloud muteLocalAudio:muted];
}

#pragma mark - Screen share

- (void)startScreenShare:(NSInteger)quality {
    TRTCVideoEncParam *enc = [TRTCVideoEncParam new];
    switch (quality) {
        case 0:
            enc.videoResolution = TRTCVideoResolution_1280_720;
            enc.videoFps = 30;
            enc.videoBitrate = 4000;
            break;
        case 2:
            enc.videoResolution = TRTCVideoResolution_1920_1080;
            enc.videoFps = 15;
            enc.videoBitrate = 6000;
            break;
        default:
            enc.videoResolution = TRTCVideoResolution_1920_1080;
            enc.videoFps = 30;
            enc.videoBitrate = 8000;
            break;
    }
    enc.enableAdjustRes = NO;
    // appGroup = nil لأن الحساب المجاني ما يدعم App Groups
    [self.cloud startScreenCaptureByReplaykit:enc appGroup:nil];
}

- (void)stopScreenShare {
    [self.cloud stopScreenCapture];
}

#pragma mark - Remote video

- (void)showRemote:(NSString *)userId isSub:(BOOL)isSub inView:(UIView *)view {
    TRTCVideoStreamType t = isSub ? TRTCVideoStreamTypeSub : TRTCVideoStreamTypeBig;
    TRTCRenderParams *rp = [TRTCRenderParams new];
    rp.fillMode = TRTCVideoFillMode_Fit;
    [self.cloud setRemoteRenderParams:userId streamType:t params:rp];
    [self.cloud startRemoteView:userId streamType:t view:view];
}

- (void)hideRemote:(NSString *)userId isSub:(BOOL)isSub {
    TRTCVideoStreamType t = isSub ? TRTCVideoStreamTypeSub : TRTCVideoStreamTypeBig;
    [self.cloud stopRemoteView:userId streamType:t];
}

#pragma mark - TRTCCloudDelegate

- (void)onEnterRoom:(NSInteger)result {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onEntered) self.onEntered(result); });
}

- (void)onRemoteUserEnterRoom:(NSString *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onUserJoined) self.onUserJoined(userId); });
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onUserLeft) self.onUserLeft(userId); });
}

- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onVideo) self.onVideo(userId, NO, available); });
}

- (void)onUserSubStreamAvailable:(NSString *)userId available:(BOOL)available {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onVideo) self.onVideo(userId, YES, available); });
}

- (void)onScreenCaptureStarted {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onScreenState) self.onScreenState(YES); });
}

- (void)onScreenCaptureStopped:(int)reason {
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onScreenState) self.onScreenState(NO); });
}

- (void)onError:(TXLiteAVError)errCode errMsg:(nullable NSString *)errMsg extInfo:(nullable NSDictionary *)extInfo {
    NSString *m = [NSString stringWithFormat:@"خطأ %d: %@", (int)errCode, errMsg ?: @""];
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.onError) self.onError(m); });
}

@end
