//
//  BlueToothCentral.h
//  coin
//
//  Created by Kanishk Parashar on 8/10/13.
//  Copyright (c) 2013 Coin Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCNCoinBLEServiceUUID @"3870cd80-fc9c-11e1-a21f-0800200c9a66"
#define kCNCoinBLEWriteCharacteristicUUID @"E788D73B-E793-4D9E-A608-2F2BAFC59A00"
#define kCNCoinBLEReadCharacteristicUUID @"4585C102-7784-40B4-88E1-3CB5C4FD37A3"

@class CBCharacteristic;
@class CBPeripheral;

@protocol CNBluetoothCentralDelegate;

@interface CNBluetoothCentral : NSObject

@property (nonatomic, weak) id<CNBluetoothCentralDelegate> delegate;

+ (CNBluetoothCentral *)sharedBluetoothCentral;

- (BOOL)startCentral;
- (BOOL)sendDataWithoutResponse:(NSString *) dataStr;
- (void)cleanup;
- (BOOL)isConnected;

@end

@protocol CNBluetoothCentralDelegate <NSObject>

@required

- (void)scanStarted;

- (void)centralDidNotStart:(NSString *)errorString;

- (void)centralConnectedwithPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error;

- (void)centralDisconnectwithPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error;

- (void)centralReadCharacteristic:(CBCharacteristic *)characteristic withPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error;

- (void)centralWroteCharacteristic:(CBCharacteristic *)characteristic withPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error;

@end
