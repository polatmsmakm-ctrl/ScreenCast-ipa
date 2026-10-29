#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// غلاف بسيط فوق TRTC: دخول غرفة، مكالمة صوتية جماعية، بث الشاشة، واستقبال بث الآخرين.
@interface CallEngine : NSObject

+ (instancetype)shared;

@property (nonatomic, copy, nullable) void (^onEntered)(NSInteger result);
@property (nonatomic, copy, nullable) void (^onUserJoined)(NSString *userId);
@property (nonatomic, copy, nullable) void (^onUserLeft)(NSString *userId);
/// isSub = true يعني بث شاشة (مسار فرعي)، false = المسار الرئيسي
@property (nonatomic, copy, nullable) void (^onVideo)(NSString *userId, BOOL isSub, BOOL available);
@property (nonatomic, copy, nullable) void (^onScreenState)(BOOL on);
@property (nonatomic, copy, nullable) void (^onError)(NSString *message);

- (void)enterWithSdkAppId:(uint32_t)sdkAppId
                secretKey:(NSString *)secretKey
                   userId:(NSString *)userId
                     room:(NSString *)room;
- (void)exitRoom;
- (void)setMuted:(BOOL)muted;

/// quality: 0 = 720p سلس، 1 = 1080p عالي، 2 = 1080p نص واضح (إطارات أقل، جودة أعلى)
- (void)startScreenShare:(NSInteger)quality;
- (void)stopScreenShare;

- (void)showRemote:(NSString *)userId isSub:(BOOL)isSub inView:(UIView *)view;
- (void)hideRemote:(NSString *)userId isSub:(BOOL)isSub;

@end

NS_ASSUME_NONNULL_END
