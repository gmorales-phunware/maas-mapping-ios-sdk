//
//  PWMapKit.h
//  PWMapKit
//
//  Copyright (c) 2014 Phunware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PWMapView.h"
#import "PWMapView+ZoomWorkaround.h"
#import "PWSVPulsingAnnotationView.h"
#import "PWUserTrackingBarButtonItem.h"
#import "PWIndoorUserTracking.h"
#import "PWAnnotationProtocol.h"
#import "PWAnnotationType.h"
#import "PWBuilding.h"
#import "PWBuildingAnnotationProtocol.h"
#import "PWBuildingAnnotationView.h"
#import "PWBuildingAnnotation.h"
#import "PWBuildingManager.h"
#import "PWBuildingFloor.h"
#import "PWBuildingFloorResource.h"
#import "PWBuildingFloorReference.h"
#import "PWBuildingOverlay.h"
#import "PWBuildingOverlayRenderer.h"
#import "PWMapDocument.h"
#import "PWDirections.h"
#import "PWDirectionsRequest.h"
#import "PWDirectionsResponse.h"
#import "PWRoute.h"
#import "PWRouteStep.h"
#import "PWRouteAnnotation.h"
#import "PWAnnotationLabel.h"
#import "PWIndoorUserLocation.h"

/**
 The `PWMapKit` framework provides an interface for embedding indoor maps directly into your own windows and views. This framework also provides support for annotating the map, finding your location, fetching routes, drawing routes and more.
 */

@interface PWMapKit : NSObject

///----------------------
/// @name Utility Methods
///----------------------

/**
 Returns PWMapKit.
 */
+ (NSString *)serviceName;

@end