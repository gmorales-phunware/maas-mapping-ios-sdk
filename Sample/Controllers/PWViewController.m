//
//  PWViewController.m
//  PWMapKitSample
//
//  Copyright (c) 2014 Phunware, Inc. All rights reserved.
//

#import "PWViewController.h"
#import "PWViewController+Routing.h"

#import "PWMapOptionsView.h"
#import "PWPitchBarButtonItem.h"
#import "PWRouteViewController.h"

#import <PWLocation/PWLocation.h>

static NSString *kMapBuildings = @"kMapBuildings";
static NSString *urlAsString = @"http://lbs-dev.s3.amazonaws.com/locationSample.json";

@interface PWViewController () <PWMapViewDelegateProtocol, UIActionSheetDelegate, UIGestureRecognizerDelegate, UIPopoverControllerDelegate, PWLocationManagerDelegate>

@property (nonatomic, strong) NSDictionary *buildings;

@property (nonatomic, weak) UIActionSheet *buildingActionSheet;
@property (nonatomic, weak) UIActionSheet *floorActionSheet;

@property (nonatomic, strong) UIPopoverController *optionsPopoverController;

@property (nonatomic, strong) PWMapOptionsView *mapOptionsView;


@end

@implementation PWViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.buildings = [[NSBundle mainBundle] objectForInfoDictionaryKey:kMapBuildings];
    NSInteger firstBuildingID = [[self.buildings.allValues firstObject] integerValue];
    
    // Load the specified building
    [self.mapView loadBuilding:firstBuildingID];
    self.mapView.mapType = MKMapTypeStandard;
    
    NSString *buildingName = [self.buildings.allKeys firstObject];
    self.navigationItem.title = buildingName;
    self.currentBuildingName = buildingName;
    
    // Replace the placeholder toolbar buttons since we can't instantiate these button types in a xib file
    PWUserTrackingBarButtonItem *mapViewButton = [[PWUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    PWPitchBarButtonItem *pitchButton = [[PWPitchBarButtonItem alloc] initWithMapView:self.mapView];
    
    NSMutableArray *toolBarItems = self.toolbarItems.mutableCopy;
    
    [toolBarItems replaceObjectAtIndex:0 withObject:mapViewButton];
    [toolBarItems replaceObjectAtIndex:2 withObject:pitchButton];
    [self setToolbarItems:toolBarItems animated:NO];
    
    
    // Center the map on Phunware Austin at the appropriate zoom level
    CLLocationCoordinate2D phunwareAustin = CLLocationCoordinate2DMake(30.36009374347881, -97.74251619815914);
    MKMapCamera *camera = [MKMapCamera
                           cameraLookingAtCenterCoordinate:phunwareAustin
                           fromEyeCoordinate:phunwareAustin
                           eyeAltitude:(CLLocationDistance)0];
    
    [self.mapView setCamera:camera animated:NO];
    
    __weak __typeof(self)weakSelf = self;
    
    [self.mapOptionsView setShowBlock:^(void){
        [weakSelf.navigationItem.leftBarButtonItem setEnabled:NO];
        [weakSelf.navigationItem.rightBarButtonItem setEnabled:NO];
    }];
    
    [self.mapOptionsView setDismissBlock:^(void) {
        [weakSelf.navigationItem.leftBarButtonItem setEnabled:YES];
        [weakSelf.navigationItem.rightBarButtonItem setEnabled:YES];
    }];
    
    // Set a default location service
    [self registerLocationManager:(PWLocationManagerTypeBLE)];
    
    // Setup the map options
    self.mapOptionsView = [[PWMapOptionsView alloc] initWithViewController:self];
}

#pragma mark - Actions

- (void)registerLocationManager:(PWLocationManagerType)locationManagerType {
    id<PWLocationManager> locationManager = nil;
    
    // Stop the current location service
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    
    // Start a new one
    switch (locationManagerType) {
        case PWLocationManagerTypeMSE:
        {
            locationManager = [[PWMSELocationManager alloc] initWithVenueGUID:@"YOUR_VENUE_GUID"
                                                                     location:CLLocationCoordinate2DMake(30.360200, -97.742555)];
            // Register location manager for PWMapView
            [self.mapView registerLocationManagerForIndoorLocationUpdates:locationManager];
            self.locationManager = locationManager;
            
            break;
        }
            
        case PWLocationManagerTypeBLE:
        {
            locationManager = [[PWSLLocationManager alloc] initWithMapIdentifier:@"YOUR_MAP_ID"
                                                              customerIdentifier:@"YOUR_CUSTOMER_ID"
                                                                        location:CLLocationCoordinate2DMake(30.360200, -97.742555)];
            // Register location manager for PWMapView
            [self.mapView registerLocationManagerForIndoorLocationUpdates:locationManager];
            self.locationManager = locationManager;
            
            break;
        }
            
        case PWLocationManagerTypeMock:
        {
            PWMockLocationManagerConfiguration *configuration = [PWMockLocationManagerConfiguration unpack:[self getMockData]];
            locationManager = [[PWMockLocationManager alloc] initWithMockLocationManagerWithConfiguration:configuration];
            // Register location manager for PWMapView
            [self.mapView registerLocationManagerForIndoorLocationUpdates:locationManager];
            self.locationManager = locationManager;
            
            break;
        }
            
        default:
            break;
    }
}

- (NSDictionary*)getMockData {
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    NSURLResponse* urlResponse;
    NSError *error = nil;
    NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:dataResponse options:0 error:nil];
    
    return parsedObject;
}

#pragma mark - Actions

- (IBAction)showMapSettings
{
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
		UIViewController *optionsViewController = [[UIViewController alloc] init];
		optionsViewController.view = self.mapOptionsView;
		
		UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:optionsViewController];
		_optionsPopoverController = popoverController;
		_optionsPopoverController.delegate = self;
		[_optionsPopoverController setPopoverContentSize:optionsViewController.view.frame.size animated:NO];
		
		NSMutableArray *toolBarItems = self.toolbarItems.mutableCopy;
		
		[_optionsPopoverController presentPopoverFromBarButtonItem:[toolBarItems objectAtIndex:6] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
	else
	{
		[self.mapOptionsView showInView:self.navigationController.view];
	}
}

- (IBAction)showRoute
{
    // The annotations we want to route between
    PWBuildingAnnotation *start = self.mapView.annotations.firstObject;
    PWBuildingAnnotation *end = self.mapView.annotations.lastObject;
    
    [self showRouteWithStart:start end:end type:PWDirectionsTypeAny];
}

- (void)showRouteWithStart:(PWBuildingAnnotation *)start end:(PWBuildingAnnotation *)end type:(PWDirectionsType)type
{
    // Instantiate a directions request
    PWDirectionsRequest *request = [[PWDirectionsRequest alloc] initWithSource:start destination:end type:type];
    
    // Instantiate a directions object
    PWDirections *directions = [[PWDirections alloc] initWithRequest:request];
    
    __weak __typeof(self)weakSelf = self;
    
    [directions calculateDirectionsWithCompletionHandler:^(PWDirectionsResponse *response, NSError *error) {
        if (error == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                PWRoute *route = response.routes.firstObject;
                [weakSelf.mapView plotRoute:route];
                
                PWRouteStep* firstStep = route.steps.firstObject;
 
                // Center the route at the appropriate zoom level
                // - Set altitude to distance * 3 to get better zoom level
                CLLocationCoordinate2D routeCenter = firstStep.polyline.coordinate;
                MKMapCamera *camera = [MKMapCamera
                                       cameraLookingAtCenterCoordinate:routeCenter
                                       fromEyeCoordinate:routeCenter
                                       eyeAltitude:(CLLocationDistance)(firstStep.distance * 3)];
                [weakSelf.mapView setCamera:camera animated:YES];

                [weakSelf showRouteControls];
            });
        }
        else
        {
            if (error.userInfo) {
                NSString *msg = [NSString stringWithFormat:@"%@", [[error.userInfo allValues] firstObject]];
                [self showAlert:msg withTitle:@"Error"];
            }
            NSLog(@"Error: %@", error);
        };
    }];
}

- (IBAction)showFloorOptions:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Floor" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (PWBuildingFloor *floor in self.mapView.building.floors)
    {
        [actionSheet addButtonWithTitle:floor.name];
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet addButtonWithTitle:@"Cancel"];
        [actionSheet setCancelButtonIndex:self.mapView.building.floors.count];
        [actionSheet showInView:self.view];
        self.floorActionSheet = actionSheet;
    }
}

- (IBAction)showBuildingList:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Building" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [self.buildings enumerateKeysAndObjectsUsingBlock:^(NSString *buildingName, NSString *buildingID, BOOL *stop) {
        [actionSheet addButtonWithTitle:buildingName];
    }];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet addButtonWithTitle:@"Cancel"];
        [actionSheet setCancelButtonIndex:self.mapView.building.floors.count];
        [actionSheet showInView:self.view];
    }
    
    self.buildingActionSheet = actionSheet;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.buildingActionSheet)
    {
        if (buttonIndex < self.buildings.allValues.count) {
            NSInteger buildingID = [self.buildings.allValues[buttonIndex] integerValue];
            [self.mapView loadBuilding:buildingID];
            
            NSString *buildingName = self.buildings.allKeys[buttonIndex];
            self.navigationItem.title = buildingName;
            self.currentBuildingName = buildingName;
        }
    } else if (actionSheet == self.floorActionSheet) {
        if (buttonIndex < self.mapView.building.floors.count) {
            PWBuildingFloor *selectedFloor = self.mapView.building.floors[buttonIndex];
            [self.mapView setCurrentFloor:selectedFloor];
        }
    }
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	if (popoverController == _optionsPopoverController)
	{
		_optionsPopoverController.delegate = nil;
        _optionsPopoverController = nil;
	}
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Route Segue
    if ([segue.destinationViewController isKindOfClass:[PWRouteViewController class]]) {
        PWRouteViewController* routeViewController = (PWRouteViewController *)segue.destinationViewController;
        
        // Pass mapView to PWRoute VC
        routeViewController.mapView = self.mapView;
    }
}

- (IBAction)route:(UIStoryboardSegue *)segue
{
    PWRouteViewController *routeViewController = (PWRouteViewController *)segue.sourceViewController;
    
    if (routeViewController.routeStartPoint == nil && routeViewController.routeEndPoint == nil) {
        [self showAlert:@"Route start & end points are not set" withTitle:@"Error"];
    } else if (routeViewController.routeStartPoint == nil) {
        [self showAlert:@"Route start point is not set" withTitle:@"Error"];
    } else if (routeViewController.routeEndPoint == nil) {
        [self showAlert:@"Route end point is not set" withTitle:@"Error"];
    } else {
		[self showRouteWithStart:routeViewController.routeStartPoint end:routeViewController.routeEndPoint type:routeViewController.shouldUseAccessibleRoutes ? PWDirectionsTypeAccessible : PWDirectionsTypeAny];
	}
}
            
- (void) showAlert: (NSString *) message withTitle: (NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

#pragma mark - MockLocationManagerDelegate

- (void)locationManager:(id<PWLocationManager>)manager didUpdateToLocation:(id<PWLocation>)location {
    NSString *locationDescription = [NSString stringWithFormat:@"Location : (%f, %f) \n Radius : %f \n FloorID : %ld",
                                     [location coordinate].latitude,
                                     [location coordinate].longitude,
                                     [location horizontalAccuracy],
                                     (long)[location floorID]];
    
    NSLog(@"Success: %@", locationDescription);
}

- (void)locationManager:(id<PWLocationManager>)manager failedWithError:(NSError *)error {
    NSString *errorDescription = [NSString stringWithFormat:@"%ld : %@", (long)error.code, [error.userInfo objectForKey:NSLocalizedDescriptionKey]];
    NSLog(@"Failed: %@", errorDescription);
}

- (void)mapView:(PWMapView *)mapView didFinishLoadingBuilding:(PWBuilding *)building
{
    [self.mapView setCenterCoordinate:building.location animated:YES];
}

@end