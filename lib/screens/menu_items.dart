import '../models/image_group.dart';

//----------- from here ----------------------------------
final Map<String, List<ImageGroup>> sections = {
  'In Car': [
    ImageGroup(
      title: 'Cockpit Drill',
      baseImage: 'assets/displayimages/101 Cockpit.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Gears',
      baseImage: 'assets/displayimages/102 Gears.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Mirrors',
      baseImage: 'assets/displayimages/103 Mirrors.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Steering',
      baseImage: 'assets/displayimages/104 Steering.webp',
      overlays: [
        OverlayImage('assets/displayimages/104 Steering Normal.webp', 'Normal'),
        OverlayImage(
            'assets/displayimages/104 Steering Over.webp', 'Over Steer'),
        OverlayImage(
            'assets/displayimages/104 Steering Under.webp', 'Under Steer'),
      ],
    ),
  ],

  'Moving off / Junctions': [
    ImageGroup(
      title: 'Moving Off',
      baseImage: 'assets/displayimages/201 Move Off back.webp',
      overlays: [
        OverlayImage('assets/displayimages/201 Move Off Cars.webp', 'Cars'),
        OverlayImage('assets/displayimages/201 Move Off Info.webp', 'Info'),
      ],
    ),
    ImageGroup(
      title: 'Pulling up / Stopping',
      baseImage: 'assets/displayimages/202 Pull In back.webp',
      overlays: [
        OverlayImage('assets/displayimages/202 Pull In Cars.webp', 'Cars'),
        OverlayImage('assets/displayimages/202 Pull In Info.webp', 'Info'),
      ],
    ),
    ImageGroup(
      title: 'Turning Left',
      baseImage: 'assets/displayimages/203 Left Turn Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/203 Left Turn Cars.webp', 'Cars'),
        OverlayImage('assets/displayimages/203 Left Turn Info.webp', 'Info'),
      ],
    ),
    ImageGroup(
      title: 'Turning Right',
      baseImage: 'assets/displayimages/204 Right Turn Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/204 Right Turn Cars.webp', 'Cars'),
        OverlayImage('assets/displayimages/204 Right Turn Info.webp', 'Info'),
      ],
    ),
    ImageGroup(
      title: 'Emerging',
      baseImage: 'assets/displayimages/205 Emerging Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/205 Emerging Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/205 Emerging Bus Stop.webp', 'Bus Stop'),
      ],
    ),
    ImageGroup(
      title: 'Emerging - Closed Junction',
      baseImage: 'assets/displayimages/206 Emerging Closed Back.webp',
      overlays: [
        OverlayImage(
            'assets/displayimages/206 Emerging Closed Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/206 Emerging Closed blind spots.webp',
            'Blind Spots'),
      ],
    ),
    ImageGroup(
      title: 'Crossroads',
      baseImage: 'assets/displayimages/207 Cross Roads Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/207 Cross Roads Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/207 Cross Roads Markings.webp', 'Lines'),
      ],
    ),
    ImageGroup(
      title: 'Traffic Lights',
      baseImage: 'assets/displayimages/208 Traffic Lights Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/208 Traffic Lights Lights.webp',
            'Traffic Lights'),
        OverlayImage('assets/displayimages/208 Traffic Lights Box.webp', 'Box'),
      ],
    ),
    ImageGroup(
      title: 'Dedicated Right Turn',
      baseImage: 'assets/displayimages/209 dedicated right turn.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Giveway / Stop',
      baseImage: 'assets/displayimages/210 Giveway Stop.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Blind Spots',
      baseImage: 'assets/displayimages/211 Blindspots back.webp',
      overlays: [
        OverlayImage('assets/displayimages/211 Blindspots Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/211 Blindspots Blind Spots.webp', 'Vision'),
      ],
    ),
  ],

  'Roundabouts': [
    ImageGroup(
      title: 'Three way Roundabout',
      baseImage: 'assets/displayimages/301 Roundabouts 3 way back.webp',
      overlays: [
        OverlayImage('assets/displayimages/301 Roundabouts 3 way lines.webp', 'Cars'),
      ],
    ),
    ImageGroup(
      title: 'Four Way Roundabout',
      baseImage: 'assets/displayimages/302 Roundabouts 4 way Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/302 Roundabouts 4 way lines.webp',
            'Center Lines'),
        OverlayImage('assets/displayimages/302 Roundabouts 4 way Left.webp',
            'Going Left'),
        OverlayImage('assets/displayimages/302 Roundabouts 4 way Ahead.webp',
            'Going Ahead'),
        OverlayImage('assets/displayimages/302 Roundabouts 4 way Right.webp',
            'Going Right'),
      ],
    ),
    ImageGroup(
      title: 'Five Way Roundabouts',
      baseImage: 'assets/displayimages/303 Roundabouts 5 way Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/303 Roundabouts 5 way Lines.webp',
            'Center Lines'),
      ],
    ),
    ImageGroup(
      title: 'Mini Roundabouts',
      baseImage: 'assets/displayimages/304 Mini Roundabouts Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Spiral Roundabouts',
      baseImage: 'assets/displayimages/305 Spiral Roundabout Back.webp',
      overlays: [
        OverlayImage(
            'assets/displayimages/305 Spiral Roundabout Path 1.webp', 'Path 1'),
        OverlayImage(
            'assets/displayimages/305 Spiral Roundabout Path 2.webp', 'Path 2'),
        OverlayImage(
            'assets/displayimages/305 Spiral Roundabout Path 3.webp', 'Path 3'),
      ],
    ),
    ImageGroup(
      title: 'Magic Roundabout - Swindon',
      baseImage: 'assets/displayimages/306 Magic Roundabout.webp',
      overlays: [],
    ),
  ],

  'Maneuvers': [
    ImageGroup(
      title: 'Parallel Park',
      baseImage: 'assets/displayimages/401 Parr Park Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/401 Parr Park parked cars.webp',
            'Target Car'),
        OverlayImage(
            'assets/displayimages/401 Parr Park Our Car.webp', 'Our Car'),
        OverlayImage(
            'assets/displayimages/401 Parr Park 2 cars.webp', '2 Car Lengths'),
        OverlayImage('assets/displayimages/401 Parr Park Info.webp', 'Info'),
      ],
    ),
    ImageGroup(
      title: 'Bay Park (Reverse and Forward)',
      baseImage: 'assets/displayimages/402 Carpark Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/402 Carpark Cars.webp', 'cars'),
      ],
    ),
    ImageGroup(
      title: 'Park on the Right',
      baseImage: 'assets/displayimages/404 Park on Right Back.webp',
      overlays: [
        OverlayImage(
            'assets/displayimages/404 Park on Right Cars.webp', 'cars'),
      ],
    ),
    // ImageGroup(
    //   title: 'Pulling in',
    //   baseImage: 'assets/displayimages/pullin base.webp',
    //   overlays: [
    //     OverlayImage('assets/displayimages/pullin cars.webp', 'Cars'),
    //     OverlayImage('assets/displayimages/pullin info.webp', 'Info'),
    //   ],
    // ),
    ImageGroup(
      title: 'Normal Stops',
      baseImage: 'assets/displayimages/406 Normal Stops Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Hill Starts',
      baseImage: 'assets/displayimages/407 Hill Starts Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Angled Start',
      baseImage: 'assets/displayimages/408 Angled Start Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/408 Angled Start Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/408 Angled Start space.webp', 'Space'),
      ],
    ),
  ],

  'Driving': [
    ImageGroup(
      title: 'Following Distance',
      baseImage: 'assets/displayimages/501 Following Distance Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'All Signals',
      baseImage: 'assets/displayimages/502 Signals All Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Pedestrian Crossings',
      baseImage: 'assets/displayimages/504 Ped Cross Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Light Controlled Crossings',
      baseImage: 'assets/displayimages/505 Light Ped Cross Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Meeting Traffic 1',
      baseImage: 'assets/displayimages/506 Meeting Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/506 Meeting Cars.webp', 'Cars'),
        OverlayImage(
            'assets/displayimages/506 Meeting Cars faded.webp', 'Faded Cars'),
      ],
    ),
    ImageGroup(
      title: 'Meeting Traffic 2',
      baseImage: 'assets/displayimages/507 Meeting 2 back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Duel Carriageways',
      baseImage: 'assets/displayimages/508 Duel Carriageways Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Motorways',
      baseImage: 'assets/displayimages/509 Motorway Back.webp',
      overlays: [
        OverlayImage('assets/displayimages/509 Motorway cars.webp', 'Cars'),
      ],
    ),
    ImageGroup(
      title: 'Bends',
      baseImage: 'assets/displayimages/510 Bends back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'One Way',
      baseImage: 'assets/displayimages/511 One Way Back.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Overtaking',
      baseImage: 'assets/displayimages/512  Overtaking Back.webp',
      overlays: [],
    ),
  ],

  'Blank Sheets': [
    ImageGroup(
      title: 'Straight Road',
      baseImage: 'assets/displayimages/601 Straight Road.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Bend',
      baseImage: 'assets/displayimages/602 Bend.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'T Junction',
      baseImage: 'assets/displayimages/603 T Junc.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Left Junction',
      baseImage: 'assets/displayimages/604 Left.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Right Junction',
      baseImage: 'assets/displayimages/605 Right.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Y Junction',
      baseImage: 'assets/displayimages/606 Y junction.webp',
      overlays: [],
    ),
  ],

  // ============================================================================
  // TEMPORARY SECTION - REMOVE BEFORE PRODUCTION
  // See: lib/temp_content_to_remove.dart for removal instructions
  // Images are in: assets/temp/ folder
  // ============================================================================
  'Rhyl Specific': [
    ImageGroup(
      title: 'Test Center',
      baseImage: 'assets/temp/801 rhyl TC carpark.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Rhyl H Bridge',
      baseImage: 'assets/temp/802 rhylhbridge.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Kinmel Bay Junction',
      baseImage: 'assets/temp/803rhylkimmeljunction.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Sainsburys Three: ALL',
      baseImage: 'assets/temps/804rhylall3.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Sainsburys Three: All Portrait',
      baseImage: 'assets/temp/805rhylall3port.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Sainsburys Three: Mc\'Donalds',
      baseImage: 'assets/temp/806rhylrb1.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Sainsburys Three: Center',
      baseImage: 'assets/temp/807rhylrb2.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Sainsburys Three: Flyover',
      baseImage: 'assets/temp/808rhylrb3.webp',
      overlays: [],
    ),
  ],
  // ============================================================================
  // END OF TEMPORARY SECTION - 'Rhyl Specific'
  // ============================================================================

  'Misc Sheets': [
    ImageGroup(
      title: 'Whiteboard',
      baseImage: 'assets/displayimages/701 Whiteboard.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Test Sheet',
      baseImage: 'assets/displayimages/702 Test Sheet.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Show Me Questions',
      baseImage: 'assets/displayimages/703 Show Me.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Tell Me Questions 1',
      baseImage: 'assets/displayimages/704 Tell 1.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Tell Me Questions 2',
      baseImage: 'assets/displayimages/704 Tell 2.webp',
      overlays: [],
    ),
  ],

  // ============================================================================
  // TEMPORARY SECTION - REMOVE BEFORE PRODUCTION
  // See: lib/temp_content_to_remove.dart for removal instructions
  // Images are in: assets/temp/ folder
  // ============================================================================
  'Photos - User': [
    ImageGroup(
      title: 'Glan Clwyd Mini Roundabout',
      baseImage: 'assets/temp/901 Hospital Mini back.webp',
      overlays: [
        OverlayImage('assets/temp/901 Hospital Mini overlay.webp',
            'Road Overlay'),
        OverlayImage(
            'assets/temp/901 Hospital Mini Kerb.webp', 'Kerb'),
        OverlayImage('assets/temp/901 Hospital Mini Incorrect.webp',
            'Incorrect'),
        OverlayImage(
            'assets/temp/901 Hospital Mini Correct.webp', 'Correct'),
      ],
    ),
    ImageGroup(
      title: 'Rhyl - H Bridge',
      baseImage: 'assets/temp/902 H Bridge.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Rhyl - One Way',
      baseImage: 'assets/temp/903 One Way.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Rhyl - Test Center - Traffic Lights 1',
      baseImage: 'assets/temp/904 TC Traffic lights 1.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Rhyl - Test Center - Traffic Lights 2',
      baseImage: 'assets/temp/905 TC Traffic Lights 2.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Rhyl Test Center',
      baseImage: 'assets/temp/906 Rhyl Test Center.webp',
      overlays: [],
    ),
    ImageGroup(
      title: 'Kinmel Bay Traffic Lights',
      baseImage: 'assets/temp/907 Kinmel bat Junction.webp',
      overlays: [],
    ),
  ],
  // ============================================================================
  // END OF TEMPORARY SECTION - 'Photos - User'
  // ============================================================================
};
//--------------------- To here ------------------------------------
