//
//  react_native_linea.m
//  react-native-linea
//
//  Created by Angelo on 30-12-16.
//  Copyright © 2016 Angelo. All rights reserved.
//

#import "RCTLinea.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTEventEmitter.h>

@implementation RCTLinea

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

#pragma mark Events
- (NSArray<NSString *> *)supportedEvents {
    return @[
                @"connectionState",
                @"rfcardInfo",
                @"debug",
                @"magneticInfo",
                @"barcodeInfo"
            ];
}

- (void)sendConnectionState:(NSString *)state {
    [self sendEventWithName:@"connectionState" body:state];
}

- (void)sendRfCardInfo:(NSString *)data {
    [self sendEventWithName:@"rfcardInfo" body:data];
}

- (void)sendDebug:(NSString *)debug {
    // [self sendEventWithName:@"debug" body:debug];
}
- (void)sendMagneticInfo:(NSString *)data {
    [self sendEventWithName:@"magneticInfo" body:data];
}

- (void)sendBarcodeInfo:(NSString *)data {
    [self sendEventWithName:@"barcodeInfo" body:data];
}

#pragma mark React Native Constants
- (NSDictionary *)constantsToExport
{
    return @{
             @"BUTTON_ENABLED": @(BUTTON_ENABLED),
             @"BUTTON_DISABLED": @(BUTTON_DISABLED),
             @"MODE_MULTI_SCAN": @(MODE_MULTI_SCAN),
             @"MODE_SINGLE_SCAN": @(MODE_SINGLE_SCAN),
             @"MODE_MOTION_DETECT": @(MODE_MOTION_DETECT),
             @"MODE_SINGLE_SCAN_RELEASE": @(MODE_SINGLE_SCAN_RELEASE),
             @"MODE_MULTI_SCAN_NO_DUPLICATES": @(MODE_MULTI_SCAN_NO_DUPLICATES)
            };
}

#pragma mark React Native Methods

RCT_EXPORT_METHOD(initializeScanner) {
    linea = [DTDevices sharedDevice];
    [linea setDelegate:self];
    [linea connect];
    [linea setPassThroughSync:FALSE error:nil];
    rfidOn = YES;
    [self sendDebug:[[NSProcessInfo processInfo] globallyUniqueString]];
}
RCT_EXPORT_METHOD(disconnect) {
  [linea disconnect];
}

RCT_EXPORT_METHOD(barcodeStartScan) {
    [linea barcodeStartScan:nil];
}

RCT_EXPORT_METHOD(barcodeStopScan) {
    [linea barcodeStopScan:nil];
}

RCT_REMAP_METHOD(isPresent, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  BOOL present = [self isBarcodeScannerPresent];
  //RCTLogInfo(@"Checks if accessory is present %@", present);
  resolve([NSNumber numberWithBool:present]);
}

RCT_REMAP_METHOD(getCharging, resolverCharging:(RCTPromiseResolveBlock)resolve rejecterCharging:(RCTPromiseRejectBlock)reject) {
  BOOL isCharging;
  [linea getCharging:&isCharging error:nil];
  //RCTLogInfo(@"Charging is %@", isCharging);
  resolve([NSNumber numberWithBool:isCharging]);
}

RCT_REMAP_METHOD(setCharging, isEnabled:(BOOL)enabled resolverSetCharging:(RCTPromiseResolveBlock)resolve rejecterSetCharging:(RCTPromiseRejectBlock)reject) {
  NSError* error = nil;
  BOOL result = [linea setCharging:enabled error:&error];
  if (result) {
    resolve([NSNumber numberWithBool:result]);
  } else {
    NSString *errorDescription = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    //RCTLogInfo(@"Set charging fail %@", errorDescription);
    reject(@"no_charging", errorDescription, error);
  }
}

RCT_EXPORT_METHOD(getBatteryInfo:(RCTResponseSenderBlock)callback) {
  int capacity = 100;
  DTBatteryInfo *info = [linea getConnectedDeviceBatteryInfo:DEVICE_TYPE_LINEA error:nil];
  if (info) {
    capacity = info.capacity;
  } else {
    capacity = -1;
  }
  callback(@[[NSNull null], [NSNumber numberWithInt:(capacity)]]);
}

RCT_EXPORT_METHOD(scanRfId) {
    [linea connect];

    int methods = CARD_SUPPORT_TYPE_A + CARD_SUPPORT_TYPE_B + CARD_SUPPORT_FELICA + CARD_SUPPORT_NFC + CARD_SUPPORT_JEWEL + CARD_SUPPORT_ISO15 + CARD_SUPPORT_STSRI + CARD_SUPPORT_PICOPASS_ISO14 + CARD_SUPPORT_PICOPASS_ISO15;
    [linea rfInit:methods error:nil];
}

RCT_EXPORT_METHOD(setBarcodeScanMode:(int) mode) {
    [linea barcodeSetScanMode:mode error:nil];
}

RCT_EXPORT_METHOD(setBarcodeScanBeep:(BOOL) enabled) {
   int beep[] = {2730,150,65000,20,2730,150};
  if (enabled) {
    [linea barcodeSetScanBeep:enabled volume:100 beepData:beep length:sizeof(beep) error:nil];
    [linea playSound:100 beepData:beep length:sizeof(beep) error:nil];
  } else {
    [linea barcodeSetScanBeep:enabled volume:0 beepData:nil length:0 error:nil];
  }
}

RCT_EXPORT_METHOD(setBarcodeScanButtonMode:(int) mode) {
    [linea barcodeSetScanButtonMode:mode error:nil];
}

RCT_EXPORT_METHOD(playSound:(int) volume beepData:(NSArray *) beepData) {
    int count = [beepData count];
    int finalData[count];
    for (int i = 0; i < count; ++i) {
        finalData[i] = [beepData[i] integerValue];
    }
    
    [linea playSound:volume beepData:finalData length:sizeof(finalData) error:nil];
}

#pragma mark - Tools

//==============================================================================


- (BOOL)isBarcodeScannerPresent
{
    return [linea isPresent:DEVICE_TYPE_LINEA];
}

//==============================================================================


- (NSString *)connectedDeviceName
{
  return [linea deviceName];
}

#pragma mark DTDevices delegates

- (void)rfCardDetected:(int)cardIndex info:(DTRFCardInfo *)info {
    NSData *uidData = [info UID];
    NSString *string = [uidData base64EncodedStringWithOptions:nil];

    [self sendRfCardInfo:string];
}

- (void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3 {
    if (track1 != nil && ![track1 isEqualToString:@""]) {
        [self sendMagneticInfo:track1];
    }
    else if (track2 != nil && ![track2 isEqualToString:@""]) {
        [self sendMagneticInfo:track2];
    }
    else if (track3 != nil && ![track3 isEqualToString:@""]) {
        [self sendMagneticInfo:track3];
    }
    else {
        [self sendDebug:@"ALL TRACKS ARE EMPTY"];
    }
}

- (void)connectionState:(int)state {

    switch (state) {
        case CONN_CONNECTED:
            isConnected = YES;
            [self sendConnectionState:@"connected"];
            break;
        case CONN_CONNECTING:
            isConnected = NO;
            [self sendConnectionState:@"connecting"];
            break;
        case CONN_DISCONNECTED:
            isConnected = NO;
            [self sendConnectionState:@"disconnected"];
            break;
    }
}

-(void)barcodeData:(NSString *)barcode type:(int) type {
    [self sendBarcodeInfo:barcode];
}
- (void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
  [self sendBarcodeInfo:barcode];
}

@end
