//
//  BTC2PeripheralDelegate.m
//  BTC2
//
//  Created by Joakim Fernstad on 5/17/13.
//  Copyright (c) 2013 Joakim Fernstad. All rights reserved.
//

#import "BTC2PeripheralDelegate.h"
#import "BTC2UUIDs.h"

@interface BTC2PeripheralDelegate ()
@property (nonatomic, readwrite, strong) CBPeripheralManager* peripheralManager;
@property (nonatomic, strong) CBMutableService* walletService;
@property (nonatomic, assign) BOOL shouldAdvertise;
@end

@implementation BTC2PeripheralDelegate
@synthesize peripheralManager;
@synthesize deviceName;
@synthesize walletService = m_walletService;
@synthesize shouldAdvertise;

-(id)init{
    if ((self = [super init])) {
        self.deviceName = @"NoName";
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        self.shouldAdvertise = NO;
        [self.peripheralManager addService:self.walletService];
    }
    return self;
}

-(void)cleanup{
    if (self.peripheralManager.isAdvertising) {
        [self.peripheralManager stopAdvertising];
        [self.peripheralManager removeAllServices];
    }
}

-(void)startAdvertising{

    NSDictionary* adDict = nil;
    self.shouldAdvertise = YES;
    
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        adDict = @{CBAdvertisementDataServiceUUIDsKey: BTC2WalletServiceUUID,
                   CBAdvertisementDataLocalNameKey: self.deviceName};
        
        [self.peripheralManager startAdvertising:adDict];
    }
}

-(void)stopAdvertising{
    self.shouldAdvertise = NO;
    if (self.peripheralManager.isAdvertising) {
        [self.peripheralManager stopAdvertising];
    }
}

-(CBMutableService*)walletService{

    CBMutableService* service = nil;
    CBMutableCharacteristic* walletCharacteristic = nil;
    
    if (!m_walletService) {
        
        NSData* fakeData = [@"SomeFakeData" dataUsingEncoding:NSUTF8StringEncoding];
        walletCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:BTC2WalletCharUUID]
                                                                  properties:CBCharacteristicPropertyRead
                                                                       value:fakeData
                                                                 permissions:CBAttributePermissionsReadable];

        
        service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:BTC2WalletServiceUUID]
                                                 primary:YES];
        
        service.characteristics = @[walletCharacteristic];
        
        m_walletService = service;
    }
    
    return m_walletService;
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerDidUpdateState state: %d", peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"Powered ON. Start advertising");
            if (self.shouldAdvertise) {
                [self startAdvertising];
            }
            break;
            
        default:
            break;
    }

}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"peripheralManagerDidStartAdvertising");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    NSLog(@"didAddService");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"didSubscribeToCharacteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"didUnsubscribeFromCharacteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

@end