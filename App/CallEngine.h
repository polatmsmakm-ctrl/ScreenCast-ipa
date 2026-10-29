#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// غلاف بسيط فوق TRTC: دخول غرفة، مكالمة صوتية جماعية، بث الشاشة، واستقبال بث الآخرين.
@interface CallEngine : NSObject

@property (class, nonatomic, readonly, strong) CallEngine *shared;

@property (nonatomic, copy, nullable) void (^onEntered)(NSInteger result);
@property (nonatomic, copy, nullable) void (^onUserJoined)(NSString *userId);
@property (nonatomic, copy, nullable) void (^onUserLeft)(NSString *userId);
/// isSub = true يعني بث شاشة (مسار فرعي)، false = المسار الرئيسي
@property (nonatomic, copy, nullable) void (^onVideo)(NSString *userId, BOOL isSub, BOOL available);
@property (nonatomic, copy, nullable) void (^onScreenState)(BOOL on);
@property (nonatomic, copy, nullable) void (^onError)(NSString *message);
/// userId -> مستوى الصوت (0-100). صوتك أنت بالمفتاح "__me"
@property (nonatomic, copy, nullable) void (^onVolume)(NSDictionary<NSString *, NSNumber *> *volumes);

- (void)enterWithSdkAppId:(uint32_t)sdkAppId
                secretKey:(NSString *)secretKey
                   userId:(NSString *)userId
                     room:(NSString *)room;
- (void)exitRoom;
- (void)setMuted:(BOOL)muted;
- (void)setSpeaker:(BOOL)speaker;
/// كتم صوت صديق عندك أنت فقط
- (void)muteRemote:(NSString *)userId mute:(BOOL)mute;
/// كتم/تشغيل صوت الايباد اللي ينبث مع الشاشة
- (void)setScreenSoundMuted:(BOOL)muted;

/// quality: 0 = 720p سلس، 1 = 1080p أقصى جودة، 2 = 1080p نص واضح (إطارات أقل)
- (void)startScreenShare:(NSInteger)quality;
- (void)stopScreenShare;

- (void)showRemote:(NSString *)userId isSub:(BOOL)isSub inView:(UIView *)view;
- (void)hideRemote:(NSString *)userId isSub:(BOOL)isSub;

@end

NS_ASSUME_NONNULL_END
