import 'package:flutter/material.dart';

class RouteSegmentDemo {
  const RouteSegmentDemo({
    required this.name,
    required this.distance,
    required this.eta,
    required this.color,
  });

  final String name;
  final String distance;
  final String eta;
  final Color color;
}

class DemoIncidentProfile {
  const DemoIncidentProfile({
    required this.usernameKey,
    required this.stagingCoordinates,
    required this.incidentCoordinates,
    required this.patientIdentity,
    required this.reportedEvent,
    required this.locationEstimate,
    required this.estimatedDistance,
    required this.estimatedResponseTime,
    required this.totalResponseTime,
    required this.totalDistance,
    required this.respondersOnDuty,
    required this.ambulanceId,
    required this.routeSegments,
    required this.pavedInstructionDistance,
    required this.pavedInstructionText,
    required this.offroadAdvisoryTitle,
    required this.offroadAdvisoryDetails,
    required this.walkingAdvisoryTitle,
    required this.walkingAdvisoryDetails,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.hospitalDistance,
    required this.hospitalEta,
    required this.hospitalRouteType,
    required this.pavedSurfaceStatus,
    required this.pavedCurrentSpeed,
    required this.pavedRoadEta,
    required this.pavedRouteProgress,
    required this.offroadFieldAccessLabel,
    required this.offroadHeading,
    required this.offroadDistToExit,
    required this.offroadAlignHint,
    required this.offroadCurrentSpeed,
    required this.walkingTelemetryTitle,
    required this.walkingCriticalLabel,
    required this.walkingHeartRate,
    required this.walkingSpo2,
    required this.walkingResp,
    required this.patientSecuredTitle,
    required this.patientSecuredDetails,
  });

  final String usernameKey;
  final String stagingCoordinates;
  final String incidentCoordinates;
  final String patientIdentity;
  final String reportedEvent;
  final String locationEstimate;
  final String estimatedDistance;
  final String estimatedResponseTime;
  final String totalResponseTime;
  final String totalDistance;
  final List<String> respondersOnDuty;
  final String ambulanceId;
  final List<RouteSegmentDemo> routeSegments;
  final String pavedInstructionDistance;
  final String pavedInstructionText;
  final String offroadAdvisoryTitle;
  final String offroadAdvisoryDetails;
  final String walkingAdvisoryTitle;
  final String walkingAdvisoryDetails;
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalDistance;
  final String hospitalEta;
  final String hospitalRouteType;
  final String pavedSurfaceStatus;
  final String pavedCurrentSpeed;
  final String pavedRoadEta;
  final String pavedRouteProgress;
  final String offroadFieldAccessLabel;
  final String offroadHeading;
  final String offroadDistToExit;
  final String offroadAlignHint;
  final String offroadCurrentSpeed;
  final String walkingTelemetryTitle;
  final String walkingCriticalLabel;
  final String walkingHeartRate;
  final String walkingSpo2;
  final String walkingResp;
  final String patientSecuredTitle;
  final String patientSecuredDetails;
}

const DemoIncidentProfile defaultDemoProfile = DemoIncidentProfile(
  usernameKey: 'default',
  stagingCoordinates: 'N 34.1328, W 116.3106',
  incidentCoordinates: 'N 34.1341, W 116.3131',
  patientIdentity: 'John Mueller, 54',
  reportedEvent: 'Cardiac Event / Collapse',
  locationEstimate: 'Crop Field (Corn)',
  estimatedDistance: '3.2 Miles',
  estimatedResponseTime: '11 Mins',
  totalResponseTime: '11.2 MINS',
  totalDistance: '3.26 MI',
  respondersOnDuty: <String>['S. Miller', 'T. Gibson', 'A. Ruiz'],
  ambulanceId: 'MED-1284',
  routeSegments: <RouteSegmentDemo>[
    RouteSegmentDemo(
      name: 'Paved Roads',
      distance: '2.4 mi',
      eta: '6.5 mins',
      color: Color(0xFF1E3B1B),
    ),
    RouteSegmentDemo(
      name: 'Offroad Trail',
      distance: '0.8 mi',
      eta: '3.2 mins',
      color: Color(0xFFD4A017),
    ),
    RouteSegmentDemo(
      name: 'Walking (Corn)',
      distance: '340 ft',
      eta: '1.5 mins',
      color: Color(0xFFE53935),
    ),
  ],
  pavedInstructionDistance: 'IN 0.4 MILES',
  pavedInstructionText: 'Turn Right on County Rd O',
  offroadAdvisoryTitle: 'TERRAIN ADVISORY: OFFROAD ENTRY',
  offroadAdvisoryDetails: 'Reduce speed to < 15 MPH - 4WD engaged',
  walkingAdvisoryTitle: 'DISMOUNT POINT REACHED',
  walkingAdvisoryDetails: 'Proceed on foot - Crop Field - Corn',
  hospitalName: 'Sauk Prairie Healthcare',
  hospitalAddress: '251 26th St, Prairie du Sac, WI 53578',
  hospitalDistance: '8.2 MI',
  hospitalEta: '14 MIN',
  hospitalRouteType: 'PAVED (FAST)',
  pavedSurfaceStatus: 'PAVED SURFACE OK',
  pavedCurrentSpeed: '54',
  pavedRoadEta: '5.8 MIN',
  pavedRouteProgress: '1.6 / 2.4 Miles',
  offroadFieldAccessLabel: 'FIELD ACCESS ROAD',
  offroadHeading: '315° NW',
  offroadDistToExit: 'DIST TO OFFROAD EXIT 0.3 MI',
  offroadAlignHint: 'Align compass to patient',
  offroadCurrentSpeed: '12 MPH',
  walkingTelemetryTitle: 'LIVE TELEMETRY (BYSTANDER RELAY)',
  walkingCriticalLabel: 'CRITICAL',
  walkingHeartRate: '142 BPM',
  walkingSpo2: '89%',
  walkingResp: '24/MIN',
  patientSecuredTitle: 'PATIENT SECURED',
  patientSecuredDetails:
      'Timestamp 14:48:12 UTC - transfer to transport active',
);

const DemoIncidentProfile rlowdenDemoProfile = DemoIncidentProfile(
  usernameKey: 'rlowden',
  stagingCoordinates: 'N 44.9562, W 89.4188',
  incidentCoordinates: 'N 44.9682, W 89.4124',
  patientIdentity: 'John Mueller, 54',
  reportedEvent: 'Cardiac Event / Collapse',
  locationEstimate: 'Crop Field (Corn)',
  estimatedDistance: '3.2 Miles',
  estimatedResponseTime: '11 Mins',
  totalResponseTime: '11.2 MINS',
  totalDistance: '3.26 MI',
  respondersOnDuty: <String>['S. Miller', 'T. Gibson', 'K. Doyle'],
  ambulanceId: 'MED-7821',
  routeSegments: <RouteSegmentDemo>[
    RouteSegmentDemo(
      name: 'Paved Roads',
      distance: '2.4 mi',
      eta: '6.5 mins',
      color: Color(0xFF1E3B1B),
    ),
    RouteSegmentDemo(
      name: 'Offroad Trail',
      distance: '0.8 mi',
      eta: '3.2 mins',
      color: Color(0xFFD4A017),
    ),
    RouteSegmentDemo(
      name: 'Walking (Corn)',
      distance: '340 ft',
      eta: '1.5 mins',
      color: Color(0xFFE53935),
    ),
  ],
  pavedInstructionDistance: 'IN 0.4 MILES',
  pavedInstructionText: 'Turn Right on County Rd O',
  offroadAdvisoryTitle: 'TERRAIN ADVISORY: OFFROAD ENTRY',
  offroadAdvisoryDetails: 'Reduce speed to < 15 MPH - 4WD engaged',
  walkingAdvisoryTitle: 'DISMOUNT POINT REACHED',
  walkingAdvisoryDetails: 'Proceed on foot - Crop Field - Corn',
  hospitalName: 'Sauk Prairie Healthcare',
  hospitalAddress: '251 26th St, Prairie du Sac, WI 53578',
  hospitalDistance: '8.2 MI',
  hospitalEta: '14 MIN',
  hospitalRouteType: 'PAVED (FAST)',
  pavedSurfaceStatus: 'PAVED SURFACE OK',
  pavedCurrentSpeed: '54',
  pavedRoadEta: '5.8 MIN',
  pavedRouteProgress: '1.6 / 2.4 Miles',
  offroadFieldAccessLabel: 'FIELD ACCESS ROAD',
  offroadHeading: '315° NW',
  offroadDistToExit: 'DIST TO OFFROAD EXIT 0.3 MI',
  offroadAlignHint: 'Align compass to patient',
  offroadCurrentSpeed: '12 MPH',
  walkingTelemetryTitle: 'LIVE TELEMETRY (BYSTANDER RELAY)',
  walkingCriticalLabel: 'CRITICAL',
  walkingHeartRate: '142 BPM',
  walkingSpo2: '89%',
  walkingResp: '24/MIN',
  patientSecuredTitle: 'PATIENT SECURED',
  patientSecuredDetails:
      'Timestamp 14:48:12 UTC - transfer to transport active',
);

const DemoIncidentProfile joshDemoProfile = DemoIncidentProfile(
  usernameKey: 'josh',
  stagingCoordinates: 'N 33.7083, W 116.3744',
  incidentCoordinates: 'N 33.7159, W 116.3592',
  patientIdentity: 'Erin Walker, 29',
  reportedEvent: 'Heat Illness / Dehydration',
  locationEstimate: 'Dry Wash (East Ridge)',
  estimatedDistance: '4.7 Miles',
  estimatedResponseTime: '16 Mins',
  totalResponseTime: '16.4 MINS',
  totalDistance: '4.95 MI',
  respondersOnDuty: <String>['J. Tanner', 'M. Shaw', 'R. Patel', 'L. Chen'],
  ambulanceId: 'MED-4619',
  routeSegments: <RouteSegmentDemo>[
    RouteSegmentDemo(
      name: 'Paved Roads',
      distance: '3.1 mi',
      eta: '8.4 mins',
      color: Color(0xFF1E3B1B),
    ),
    RouteSegmentDemo(
      name: 'Offroad Access',
      distance: '1.4 mi',
      eta: '6.1 mins',
      color: Color(0xFFD4A017),
    ),
    RouteSegmentDemo(
      name: 'Foot Trail',
      distance: '0.45 mi',
      eta: '3.0 mins',
      color: Color(0xFFE53935),
    ),
  ],
  pavedInstructionDistance: 'IN 0.6 MILES',
  pavedInstructionText: 'Merge Left onto Desert Spur Rd',
  offroadAdvisoryTitle: 'TERRAIN ADVISORY: SOFT SAND ENTRY',
  offroadAdvisoryDetails: 'Maintain momentum - reduce to < 12 MPH',
  walkingAdvisoryTitle: 'DISMOUNT POINT REACHED',
  walkingAdvisoryDetails: 'Proceed on foot - wash crossing - loose rock',
  hospitalName: 'Desert Regional Medical Center',
  hospitalAddress: '1150 N Indian Canyon Dr, Palm Springs, CA 92262',
  hospitalDistance: '12.6 MI',
  hospitalEta: '21 MIN',
  hospitalRouteType: 'PAVED (FAST)',
  pavedSurfaceStatus: 'PAVED SURFACE CLEAR',
  pavedCurrentSpeed: '48',
  pavedRoadEta: '7.1 MIN',
  pavedRouteProgress: '2.0 / 3.1 Miles',
  offroadFieldAccessLabel: 'SAND ACCESS TRACK',
  offroadHeading: '298° WNW',
  offroadDistToExit: 'DIST TO OFFROAD EXIT 0.5 MI',
  offroadAlignHint: 'Keep ridge line to patient',
  offroadCurrentSpeed: '10 MPH',
  walkingTelemetryTitle: 'LIVE TELEMETRY (BYSTANDER RELAY)',
  walkingCriticalLabel: 'PRIORITY',
  walkingHeartRate: '128 BPM',
  walkingSpo2: '92%',
  walkingResp: '22/MIN',
  patientSecuredTitle: 'PATIENT SECURED',
  patientSecuredDetails:
      'Timestamp 13:12:39 UTC - transfer to transport active',
);

DemoIncidentProfile demoProfileForUsername(String username) {
  final key = username.trim().toLowerCase();

  if (key == rlowdenDemoProfile.usernameKey) {
    return rlowdenDemoProfile;
  }

  if (key == joshDemoProfile.usernameKey) {
    return joshDemoProfile;
  }

  return defaultDemoProfile;
}
