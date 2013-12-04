//
//  BlueToothCentral.m
//  coin
//
//  Created by Kanishk Parashar on 8/10/13.
//  Copyright (c) 2013 Coin Inc. All rights reserved.
//

#import "CNBluetoothCentral.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CNBluetoothCentral () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, strong) NSMutableData *data;

@end

@implementation CNBluetoothCentral

+ (CNBluetoothCentral *)sharedBluetoothCentral
{
    static CNBluetoothCentral *_sharedBlueToothCentral = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBlueToothCentral = [[CNBluetoothCentral alloc] init];
    });

    return _sharedBlueToothCentral;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableData alloc] init];
    }

    return self;
}

- (BOOL)startCentral
{
    NSLog(@"Start BLE");
    if (self.centralManager == nil)
    {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        return YES;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(centralDidNotStart:)])
    {
        [self.delegate centralDidNotStart:@"Already in use"];
    }
    return NO;
}

- (BOOL)isConnected {
    
    if (self.discoveredPeripheral.state == CBPeripheralStateConnected)
    {
        return YES;
    } else {
        return NO;
    }

}

/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanStarted)])
    {
        [self.delegate scanStarted];
    }
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kCNCoinBLEServiceUUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];

    NSLog(@"Scanning started");
}

#pragma mark - CBCenteralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralDidNotStart:)])
        {
            NSString *error = @"";

            switch (central.state)
            {
                case CBCentralManagerStateUnknown:
                    error = @"Bluetooth in unknown state.  Please try again.";
                    break;
                case CBCentralManagerStateResetting:
                    error = @"Bluetooth is resetting.  Please try again.";
                    break;
                case CBCentralManagerStateUnsupported:
                    error = @"Bluetooth is not supported on this device.";
                    break;
                case CBCentralManagerStateUnauthorized:
                    error = @"Bluetooth is not authorized on this device.";
                    break;
                case CBCentralManagerStatePoweredOff:
                    error = @"Bluetooth is not powered on this device.  Please turn on bluetooth from the settings app.";
                    break;
                default:
                    break;
            }

            [self.delegate centralDidNotStart:error];
        }

        return;
    }

    // TODO think about breaking apart scanning for peripherals from the state update
    [self scan];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
//    // Reject any where the value is above reasonable range
//    if (RSSI.integerValue > -15)
//    {
//        return;
//    }
//
//    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
//    if (RSSI.integerValue < -35)
//    {
//        return;
//    }

    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);

    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral)
    {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        self.discoveredPeripheral.delegate = self;

        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);

        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];

    if (self.delegate && [self.delegate respondsToSelector:@selector(centralDidNotStart:)])
    {
        [self.delegate centralDidNotStart:@"Failed to connect to Coin."];
    }
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");

    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");

    // Clear the data that we may already have
    [self.data setLength:0];

    // Make sure we get the discovery callbacks
    peripheral.delegate = self;

    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kCNCoinBLEServiceUUID]]];
}

/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;

    if (self.delegate && [self.delegate respondsToSelector:@selector(centralDisconnectwithPeripheral:withError:)])
    {
        [self.delegate centralDisconnectwithPeripheral:peripheral withError:error];
    }

    self.centralManager = nil;
}

/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"discovered services:%@",peripheral.services);
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];

        if (self.delegate && [self.delegate respondsToSelector:@selector(centralDidNotStart:)])
        {
            [self.delegate centralDidNotStart:@"Error discovering Services.  Please try again."];
        }
        return;
    }

    // Discover the characteristic we want...

    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
    {
        NSLog(@"looking through peripheral.services");
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{

    NSLog(@"Did discover characteristics %@ for service %@", service.characteristics, kCNCoinBLEServiceUUID);
    // Deal with errors (if any)
    if (error)
    {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];

        if (self.delegate && [self.delegate respondsToSelector:@selector(centralConnectedwithPeripheral:withError:)])
        {
            [self.delegate centralConnectedwithPeripheral:peripheral withError:error];
        }
        return;
    }

    for (CBCharacteristic *characteristic in service.characteristics){

        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCNCoinBLEWriteCharacteristicUUID]])
        {
            NSLog(@"Found our write characteristic");
            if (self.delegate && [self.delegate respondsToSelector:@selector(centralConnectedwithPeripheral:withError:)])
            {
                [self.delegate centralConnectedwithPeripheral:peripheral withError:error];
                NSLog(@"connected callback");
            }
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCNCoinBLEReadCharacteristicUUID]]) {
            NSLog(@"Found our read characteristic");
            
            [self.discoveredPeripheral setNotifyValue:YES forCharacteristic:characteristic];
            
        }
    }

    // Once this is complete, we just need to send/receive data
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error writing value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        [self cleanup];
        return;
    }

    if ([self.delegate respondsToSelector:@selector(centralWroteCharacteristic:withPeripheral:withError:)])
    {
        [self.delegate centralWroteCharacteristic:characteristic withPeripheral:self.discoveredPeripheral withError:nil];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(centralReadCharacteristic:withPeripheral:withError:)])
    {
        [self.delegate centralReadCharacteristic:characteristic withPeripheral:self.discoveredPeripheral withError:nil];
    }
    
    
    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    
}

- (void)cleanup
{
    NSLog(@"cleanup BLE");
    [self.centralManager stopScan];

    if (self.discoveredPeripheral.state == CBPeripheralStateConnected)
    {
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }

    //self.centralManager = nil;
}

- (BOOL)sendDataWithoutResponse:(NSString *)dataStr
{
    CBCharacteristic *tmpCharacteristic;

    for (CBService *service in self.discoveredPeripheral.services)
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            // And check if it's the right one
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCNCoinBLEWriteCharacteristicUUID]])
            {

                tmpCharacteristic = characteristic;
                break;
            }
        }
    }

    if (tmpCharacteristic == nil)
    {
        return NO;
    }


    //Cut and send in 20 character size
    NSString *tmpStr;
    int x = 0;

    for (x = 0; x + 20 < [dataStr length]; x = x + 20)
    {
        tmpStr = [dataStr substringWithRange:NSMakeRange(x, 20)];

        if ([tmpCharacteristic.UUID isEqual:[CBUUID UUIDWithString:kCNCoinBLEWriteCharacteristicUUID]])
        {
            [self.discoveredPeripheral writeValue:[tmpStr dataUsingEncoding:NSUTF8StringEncoding]
                                forCharacteristic:tmpCharacteristic
                                             type:CBCharacteristicWriteWithResponse];
        }
    }

    [self.discoveredPeripheral writeValue:[[dataStr substringWithRange:NSMakeRange(x, [dataStr length] - x)] dataUsingEncoding:NSUTF8StringEncoding]
                        forCharacteristic:tmpCharacteristic
                                     type:CBCharacteristicWriteWithResponse];


    //Inform the delegate that data is sent
    if (self.delegate && [self.delegate respondsToSelector:@selector(centralWroteCharacteristic:withPeripheral:withError:)])
    {
        [self.delegate centralWroteCharacteristic:tmpCharacteristic withPeripheral:self.discoveredPeripheral withError:nil];
    }
    
    return YES;
}

@end
