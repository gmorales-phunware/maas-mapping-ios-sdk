//
//  ViewController.m
//  LoadMap
//
//  Created on 7/25/16.
//  Copyright © 2016 Phunware Inc. All rights reserved.
//

#import <PWMapKit/PWMapKit.h>
#import <PWLocation/PWLocation.h>

#import "ViewController.h"

#define kBLECustomerIdentifier @"<Senion Customer Identifier>"
#define kBLEMapIdentifier @"<Senion Map Identifier>"
#define kVirtualBeaconToken @"<Senion Map Identifier>"
#define kBuildingIdentifier 0

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loadMapButton;

- (IBAction)loadMap:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)loadMap:(id)sender {
    [PWBuilding buildingWithIdentifier:kBuildingIdentifier completion:^(PWBuilding *building, NSError *error) {
        // UI view controller initialization
        PWMapViewController *mapViewController = [[PWMapViewController alloc] initWithBuilding:building];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mapViewController];
        // Present
        [self presentViewController:navigationController animated:YES completion:^{
            // Set center of map
            [mapViewController setCenterCoordinate:building.coordinate zoomLevel:19 animated:NO];
            
            // Initialize the manager
            PWManagedLocationManager *manager = [[PWManagedLocationManager alloc] initWithBuildingId:kBuildingIdentifier];
            
            // Configure the internal providers
            manager.senionCustomerID = kBLECustomerIdentifier;
            manager.senionMapID = kBLEMapIdentifier;
            manager.virtualBeaconToken = kVirtualBeaconToken;
            
            // Regester the manager
            [mapViewController.mapView registerLocationManager:manager];
        }];
    }];
}

@end
