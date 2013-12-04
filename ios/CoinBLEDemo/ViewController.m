//
//  ViewController.m
//  CoinBLEDemo
//
//  Created by Guilherme J de Paula on 10/28/13.
//  Copyright (c) 2013 Coin, Inc. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "CNBluetoothCentral.h"

@interface ViewController () <CNBluetoothCentralDelegate>


@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UILabel *receiveTextLbl;
@property (weak, nonatomic) IBOutlet UILabel *statusLbl;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
- (IBAction)sendToBLE:(id)sender;
- (IBAction)toggleBLE:(id)sender;

@end

@implementation ViewController




- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[CNBluetoothCentral sharedBluetoothCentral] setDelegate:self];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[CNBluetoothCentral sharedBluetoothCentral] cleanup];
    [[CNBluetoothCentral sharedBluetoothCentral] setDelegate:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark CNBlueToothCentralDelegate


- (void)scanStarted {
    
    self.statusLbl.text = @"Status: Scanning";

}

- (void)centralDidNotStart:(NSString *)errorString {
    //UIAlert to warn about this error
    self.statusLbl.text = [NSString stringWithFormat:@"Status: Error - %@", errorString];

    
}

- (void)centralConnectedwithPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    
    //Alert user that peripheral connected successfully
    self.statusLbl.text = @"Status: Connected";

}

- (void)centralDisconnectwithPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    
    //UIAlert the user that the peripheral d/c
    self.statusLbl.text = @"Status: Disconnected";
    [self.connectBtn setTitle:@"Connect" forState:UIControlStateNormal];
    
}

- (void)centralReadCharacteristic:(CBCharacteristic *)characteristic withPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    
    NSUInteger i;
    NSString *str;
    
    //Append the received string into the bottom text view
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];    
    // Show it on log
    NSLog(@"%@", temp);
    // Skip all the NULL characters and take the first real character
    for (i = 0 ; i < temp.length ; i++)
    {
        if ([temp characterAtIndex:i] != '\0')
        {
            // Build new single-character string
            str = [NSString stringWithFormat:@"%C", [temp characterAtIndex:i]];
            break;
        }
    }
    // Display the single-character string
    self.receiveTextLbl.text = [NSString stringWithFormat:@"%@", str];
    // Reset used variables
    temp = (NSString *)@"";
    str = (NSString *)@"";
    
    // ************************************************ //
    // Tests with stringByReplacingOccurrencesOfString, //
    // NSMutableString, concatenation, setText, length, //
    // stringByAppendingString, etc, etc.               //
    // ************************************************ //
    
//    static int len;
//    NSMutableString *str;
//    NSString *str=[[NSString alloc]initWithString:@""];
    
//    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];

//    self.receiveTextLbl.text = [NSString stringWithFormat:@"%@%@", self.receiveTextLbl.text, temp];

//    len = temp.length;

//    self.receiveTextLbl.text = [self.receiveTextLbl.text stringByAppendingString:str];

//    str = (NSMutableString *)temp;
    
//    self.receiveTextLbl.text = [self.receiveTextLbl.text stringByAppendingString: msg];
    
//    [self.receiveTextLbl setText:temp];
 
}

- (void)centralWroteCharacteristic:(CBCharacteristic *)characteristic withPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    
    //UIAlert confirm to user that BLE send was successful (optional)
    
}

- (IBAction)sendToBLE:(id)sender {
    
    NSUInteger i;
    NSString *str;
    NSString *temp;
    
    if (([[CNBluetoothCentral sharedBluetoothCentral] isConnected]) &&
        (self.sendTextField.text.length != 0)){
    
        // Get the string entered by the user
        temp = self.sendTextField.text;
        // Skip all the NULL characters and extract the first real character
        for (i = 0 ; i < temp.length ; i++)
        {
            if ([temp characterAtIndex:i] != '\0')
            {
                // Build new single-character string
                str = [NSString stringWithFormat:@"%C", [temp characterAtIndex:i]];
                break;
            }
        }
        // Send the single-character string
        [[CNBluetoothCentral sharedBluetoothCentral] sendDataWithoutResponse:str];
        // Reset used variables
        temp = (NSString *)@"";
        str = (NSString *)@"";

    } else {
        //UIAlert user that we are not connected or no characters were entered
    }
    
}

- (IBAction)toggleBLE:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    if ([[btn currentTitle] isEqualToString:@"Connect"]) {
        
        [[CNBluetoothCentral sharedBluetoothCentral] startCentral];
        [btn setTitle:@"Disconnect" forState:UIControlStateNormal];
        
    } else {
        
        [[CNBluetoothCentral sharedBluetoothCentral] cleanup];
        [btn setTitle:@"Connect" forState:UIControlStateNormal];
        self.statusLbl.text = @"Status: Disconnected";
    }
        
}
- (IBAction)clearReceive:(id)sender {
    
    self.receiveTextLbl.text = @"";
}
@end
