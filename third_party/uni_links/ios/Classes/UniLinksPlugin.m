#import "UniLinksPlugin.h"

static NSString *const kMessagesChannel = @"uni_links/messages";
static NSString *const kEventsChannel = @"uni_links/events";

@interface UniLinksPlugin () <FlutterStreamHandler>
@property(nonatomic, copy) NSString *initialLink;
@property(nonatomic, copy) NSString *latestLink;
@end

@implementation UniLinksPlugin {
  FlutterEventSink _eventSink;
}

static id _instance;

+ (UniLinksPlugin *)sharedInstance {
  if (_instance == nil) {
    _instance = [[UniLinksPlugin alloc] init];
  }
  return _instance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  UniLinksPlugin *instance = [UniLinksPlugin sharedInstance];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kMessagesChannel
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];

  FlutterEventChannel *chargingChannel =
      [FlutterEventChannel eventChannelWithName:kEventsChannel
                                binaryMessenger:[registrar messenger]];
  [chargingChannel setStreamHandler:instance];

  [registrar addApplicationDelegate:instance];
#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
  [registrar addSceneDelegate:instance];
#endif
}

- (void)setLatestLink:(NSString *)latestLink {
  static NSString *key = @"latestLink";

  [self willChangeValueForKey:key];
  _latestLink = [latestLink copy];
  [self didChangeValueForKey:key];

  if (_eventSink) _eventSink(_latestLink);
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSURL *url = (NSURL *)launchOptions[UIApplicationLaunchOptionsURLKey];
  self.initialLink = [url absoluteString];
  self.latestLink = self.initialLink;
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  self.latestLink = [url absoluteString];
  return YES;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    self.latestLink = [userActivity.webpageURL absoluteString];
    if (!_eventSink) {
      self.initialLink = self.latestLink;
    }
    return YES;
  }
  return NO;
}

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
- (BOOL)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  for (NSUserActivity *activity in connectionOptions.userActivities) {
    if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] &&
        activity.webpageURL != nil) {
      self.initialLink = activity.webpageURL.absoluteString;
      self.latestLink = self.initialLink;
      return YES;
    }
  }
  NSURL *url = connectionOptions.URLContexts.anyObject.URL;
  if (url == nil) return NO;
  self.initialLink = url.absoluteString;
  self.latestLink = self.initialLink;
  return YES;
}

- (BOOL)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
  if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] ||
      userActivity.webpageURL == nil) return NO;
  if (!_eventSink) self.initialLink = userActivity.webpageURL.absoluteString;
  self.latestLink = userActivity.webpageURL.absoluteString;
  return YES;
}

- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
  NSURL *url = URLContexts.anyObject.URL;
  if (url == nil) return NO;
  if (!_eventSink) self.initialLink = url.absoluteString;
  self.latestLink = url.absoluteString;
  return YES;
}
#endif

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getInitialLink" isEqualToString:call.method]) {
    result(self.initialLink);
    // } else if ([@"getLatestLink" isEqualToString:call.method]) {
    //     result(self.latestLink);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)eventSink {
  _eventSink = eventSink;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

@end
