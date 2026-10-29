#import "SampleHandler.h"
@import TXLiteAVSDK_ReplayKitExt;

// بدون App Group (الحساب المجاني ما يدعمه). تينسنت تسمح بـ nil مع ثبات أقل شوي.
@interface SampleHandler () <TXReplayKitExtDelegate>
@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *, NSObject *> *)setupInfo {
    [[TXReplayKitExt sharedInstance] setupWithAppGroup:nil delegate:self];
}

- (void)broadcastPaused {
}

- (void)broadcastResumed {
}

- (void)broadcastFinished {
}

#pragma mark - TXReplayKitExtDelegate

- (void)broadcastFinished:(TXReplayKitExt *)broadcast reason:(TXReplayKitExtReason)reason {
    NSString *tip = @"";
    switch (reason) {
        case TXReplayKitExtReasonRequestedByMain:
            tip = @"انتهى البث";
            break;
        case TXReplayKitExtReasonDisconnected:
            tip = @"انقطع الاتصال بالتطبيق";
            break;
        case TXReplayKitExtReasonVersionMismatch:
            tip = @"خطأ في نسخة المكتبة";
            break;
    }
    NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                         code:0
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: tip}];
    [self finishBroadcastWithError:error];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            [[TXReplayKitExt sharedInstance] sendVideoSampleBuffer:sampleBuffer];
            break;
        default:
            break;
    }
}

@end
