//
//  BTC2CentralDelegate.m
//  BTC2
//
//  Created by Joakim Fernstad on 5/17/13.
//  Copyright (c) 2013 Joakim Fernstad. All rights reserved.
//

#import "BTC2CentralDelegate.h"
#import "BTC2UUIDs.h"

#define CONNECTION_TIMEOUT 10       // TODO: parametrize

@interface BTC2CentralDelegate ()
@property (nonatomic, readwrite, strong) CBCentralManager* centralManager;
@property (nonatomic, strong) CBPeripheral* connectedPeripheral;
@property (nonatomic, assign) BOOL shouldScan;
@property (nonatomic, strong) NSTimer* connectionTimeout; // Allow x seconds to connect, then stop
-(void)connectionDidTimeout:(NSTimer*)timer;
-(void)disconnectPeripheral;
-(void)scanForPeripherals;
-(void)startConnectionTimer;
-(void)stopConnectionTimer;
@end

@implementation BTC2CentralDelegate
@synthesize centralManager;
@synthesize shouldScan;

-(id)init{
    if ((self = [super init])) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.shouldScan = NO;
    }
    return self;
}

-(void)cleanup{
    NSLog(@" Cleanup: STOPPING SCAN");

    self.shouldScan = NO;
    
    [self disconnectPeripheral];
    [self.centralManager stopScan];
}

-(void)startScan{
    if (self.centralManager.state == CBCentralManagerStateUnknown) {
        self.shouldScan = YES;
    }else{
        [self scanForPeripherals];
    }
}

-(void)startConnectionTimer{

    [self stopConnectionTimer];
    self.connectionTimeout = [NSTimer timerWithTimeInterval:CONNECTION_TIMEOUT
                                                     target:self
                                                   selector:@selector(connectionDidTimeout:)
                                                   userInfo:nil
                                                    repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:self.connectionTimeout forMode:NSDefaultRunLoopMode];
}

-(void)stopConnectionTimer{
    if (self.connectionTimeout.isValid) {
        [self.connectionTimeout invalidate];
    }
}

-(void)scanForPeripherals{
    NSLog(@"Start scanning for peripherals");
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BTC2WalletServiceUUID]] options:nil];
}


-(void)disconnectPeripheral{
    if (self.connectedPeripheral) {
        NSLog(@"Disconnecting peripheral: %@", self.connectedPeripheral.name);
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        [self stopConnectionTimer];
    }
}

-(void)connectionDidTimeout:(NSTimer*)timer{
    NSLog(@" + Connection timed out: %@", self.connectedPeripheral.name);
    [self disconnectPeripheral];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"centralManagerDidUpdateState state: %d", central.state);

    switch (central.state) {
        case CBCentralManagerStatePoweredOn: // Good to go
            if (self.shouldScan) {
                [self scanForPeripherals];
            }
            break;
        case CBCentralManagerStatePoweredOff:
            [self cleanup];
            break;
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnauthorized:
        case CBCentralManagerStateUnknown:
        default:
            break;
    }

}
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    NSLog(@"didRetrievePeripherals %@", peripherals);
    
    // TODO: Add peripherals to array
    // If not already in list, connect and read wallet address.
    
}
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals{
    NSLog(@"didRetrieveConnectedPeripherals");
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"didDiscoverPeripheral %@: %@", peripheral.name, peripheral.UUID);

    self.connectedPeripheral = peripheral;
    [self startConnectionTimer];
    [central stopScan];
    [central connectPeripheral:peripheral options:nil];

}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"didConnectPeripheral: %@", peripheral.name);

    [self stopConnectionTimer];
    self.connectedPeripheral.delegate = self;
    [self.connectedPeripheral discoverServices:peripheral.services];

}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didFailToConnectPeripheral - Reason: %@", error);
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didDisconnectPeripheral - Reason: %@", error);
    self.connectedPeripheral = nil;
}

#pragma mark - CBPeripheralDelegate

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    NSLog(@"peripheralDidUpdateName: %@", peripheral.name);
}

- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral{
    NSLog(@"peripheralDidInvalidateServices");
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"peripheralDidUpdateRSSI: %@. Err: %@", peripheral.RSSI, error);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"didDiscoverServices - Err: %@", error);

    // Discover characteristics
    for (CBService* service in peripheral.services) {
        NSLog(@" = Service UUID: %@", service.UUID);
        
        // Only read our custom service. Apple gets cranky if we read the GAP service characteristics
        if ([service.UUID isEqual:[CBUUID UUIDWithString:BTC2WalletServiceUUID]]) {
            [peripheral discoverCharacteristics:service.characteristics
                                     forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    NSLog(@"didDiscoverIncludedServicesForService. Err: %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"didDiscoverCharacteristicsForService. Err: %@", error);

    // If found wallet address characteristic, read it
    for (CBCharacteristic* characteristic in service.characteristics){
        [peripheral readValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didUpdateValueForCharacteristic. Err: %@", error);

    // Let system know a characteristic has been read
    NSString* stringValue = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@" Characteristic [%@] : %@", characteristic.UUID, stringValue);

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didWriteValueForCharacteristic. Err: %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didUpdateNotificationStateForCharacteristic. Err: %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didDiscoverDescriptorsForCharacteristic. Err: %@", error);

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSLog(@"didUpdateValueForDescriptor. Err: %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSLog(@"didWriteValueForDescriptor. Err: %@", error);
}



@end
