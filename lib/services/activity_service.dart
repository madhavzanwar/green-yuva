import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../services/user_service.dart';

class ActivityService {
  final CollectionReference schoolsCollection = FirebaseFirestore.instance.collection('schools');
  final UserService _userService = UserService();

  CollectionReference getActivitiesCollection(String schoolId) {
    return schoolsCollection.doc(schoolId).collection('activities');
  }

  Future<List<Activity>> getActivities(String schoolId, {int limit = 10, DocumentSnapshot? startAfter}) async {
    try {
      print('🔍 ActivityService: Fetching activities for school: $schoolId');

      Query query = getActivitiesCollection(schoolId).orderBy('date', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final activities = snapshot.docs.map((doc) =>
        Activity.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();

      if (activities.isNotEmpty) {
        print('✅ ActivityService: Successfully fetched ${activities.length} activities');
        return activities;
      }
      return _getSchoolSpecificActivities(schoolId).map((m) => Activity.fromMap(m['id'] as String, m)).toList();
    } catch (e) {
      print('❌ ActivityService: Error fetching activities: $e, using campus default activities');
      return _getSchoolSpecificActivities(schoolId).map((m) => Activity.fromMap(m['id'] as String, m)).toList();
    }
  }

  Future<List<Activity>> getUpcomingActivities(String schoolId, {int limit = 10}) async {
    try {
      final now = DateTime.now();
      final snapshot = await getActivitiesCollection(schoolId)
          .where('date', isGreaterThan: now)
          .orderBy('date', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) =>
        Activity.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('❌ ActivityService: Error fetching upcoming activities: $e');
      return [];
    }
  }

  Future<List<Activity>> getRecentActivities(String schoolId, {int limit = 10}) async {
    try {
      final now = DateTime.now();
      final snapshot = await getActivitiesCollection(schoolId)
          .where('date', isLessThan: now)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) =>
        Activity.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('❌ ActivityService: Error fetching recent activities: $e');
      return [];
    }
  }

  Future<void> addActivity(String schoolId, Activity activity) async {
    try {
      await getActivitiesCollection(schoolId).doc(activity.id).set(activity.toMap());
    } catch (e) {
      print('❌ ActivityService: Error adding activity: $e');
      rethrow;
    }
  }

  Future<Activity?> getActivityById(String schoolId, String activityId) async {
    try {
      final doc = await getActivitiesCollection(schoolId).doc(activityId).get();
      if (doc.exists) {
        return Activity.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ ActivityService: Error fetching activity by ID: $e');
      return null;
    }
  }

  Future<void> createSchoolSpecificActivities(String schoolId) async {
    try {
      final activitiesCollection = getActivitiesCollection(schoolId);
      final snapshot = await activitiesCollection.get();
      if (snapshot.docs.isNotEmpty) {
        print('✅ ActivityService: Activities already exist for school $schoolId');
        return;
      }

      print('📝 ActivityService: Creating school-specific activities for $schoolId');

      final activities = _getSchoolSpecificActivities(schoolId);

      for (final activity in activities) {
        await activitiesCollection.doc(activity["id"] as String).set(activity);
      }

      print('✅ ActivityService: Created ${activities.length} activities for school $schoolId');
    } catch (e) {
      print('❌ ActivityService: Error creating school activities: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getSchoolSpecificActivities(String schoolId) {
    final now = DateTime.now();
    final normalizedId = schoolId.toLowerCase();

    // 1. PCCOE Pune
    if (normalizedId.contains('pccoe')) {
      return [
        {
          "id": "${schoolId}_pawana_cleanup",
          "title": "Pawana River Basin Desilting & Macro-Plastic Extraction",
          "type": "Hydrology & Water Action",
          "points": 550,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Join the PCCOE Environmental Engineering Wing at the Nigdi-Ravet stretch of the Pawana River.
Volunteers will extract floating plastics, unblock stormwater outfalls, and remove invasive hyacinth weeds.
We deploy multi-parameter handheld probes to measure dissolved oxygen (DO), pH, and TDS levels before and after cleanup.
Collected macro-plastics will be segregated on-site into recyclable polymers and sent to municipal baling units.
Safety wading gear, puncture-resistant gloves, grabbers, and fresh hydration are fully provided.
Earn verified community service credits, practical telemetry experience, and 550 GreenKarma coins.
Please assemble at the PCCOE Main Gate by 6:45 AM wearing sturdy closed boots and carrying a reusable water flask.
Team briefing on aquatic bio-indicators and riparian zone conservation will precede field deployment.""",
          "location": "Pawana River Bank, Ravet-Nigdi Weir, Pune",
          "communityName": "PCCOE Green Earth Guild",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_solar_tracker",
          "title": "Dual-Axis Solar Microgrid Optimization & Inverter Audit",
          "type": "Clean Energy Transition",
          "points": 480,
          "participants": [],
          "date": now.add(const Duration(days: 4)),
          "endDate": now.add(const Duration(days: 4, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Hands-on technical sprint on the terrace of PCCOE Mechanical & Electrical Engineering Building.
Students will inspect the 150 kWp rooftop solar photovoltaic array, analyzing dust soiling losses and thermal hotspots.
We calibrate automated pyranometers, log inverter conversion efficiency, and assess string-level MPPT performance.
Participants will perform dry-brush microfiber cleaning to eliminate particulate crust without wasting potable water.
Calculations of avoided campus coal emissions and rooftop kilowatt-hour yields will be integrated into the campus dashboard.
An excellent skill-building workshop for engineering undergraduates targeting solar renewables careers.
Equipped with multimeter probes, thermal infrared cameras, and safety harness gear provided by the college lab.
Concludes with an expert lecture on grid-tie net metering policies under Maharashtra MSEDCL regulations.""",
          "location": "Mechanical Building Terrace, PCCOE Campus, Pune",
          "communityName": "Renewable Energy Research Chapter",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_ewaste_drive",
          "title": "Pimpri-Chinchwad Lab E-Waste & Precious Metals Reclamation",
          "type": "Circular Economy",
          "points": 500,
          "participants": [],
          "date": now.add(const Duration(days: 7)),
          "endDate": now.add(const Duration(days: 7, hours: 4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Mobilizing all PCCOE student hostels, IT departments, and fabrication laboratories for hazardous e-waste collection.
Bring obsolete printed circuit boards, drained lead-acid and lithium cells, burnt resistors, and defunct cables.
Our volunteer team will systematically catalogue, weigh, and triage items into salvageable maker parts versus e-scrap.
Recoverable semiconductors, copper inductors, and stepper motors are routed to the student robotics inventory.
Unusable hazardous scrap is transferred directly to authorized MPCB-certified scientific recycling handlers.
Prevent heavy neurotoxic metals like lead, cadmium, and mercury from leaching into suburban Pimpri groundwater.
Earn bonus GreenKarma coins for every 2 kilograms of verifiable e-scrap deposited at the registration tent.
Includes a live soldering demonstration on desoldering components for sustainable hardware prototyping.""",
          "location": "Central Courtyard & Innovation Hub, PCCOE",
          "communityName": "Circularity & Maker Cell",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_mess_compost",
          "title": "Hostel Mess Wet Waste Composting & Biogas Feedstock Audit",
          "type": "Zero-Waste & Soil",
          "points": 420,
          "participants": [],
          "date": now.add(const Duration(days: 10)),
          "endDate": now.add(const Duration(days: 10, hours: 2)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Transform daily organic food scraps from the PCCOE Boy's and Girl's Mess into rich vermicompost.
Volunteers will measure per-meal plate wastage, record food disposal weights, and evaluate kitchen prep organics.
We will mix segregated food remains with dry cocopeat, carbon sawdust, and active microbial bio-cultures.
Participants will aerate the five central tumbling composters and check moisture, pile temperature, and odor control.
The stabilized rich organic humus will be distributed directly to nourish the campus medicinal herb garden.
Discover how diverting 120 kg of wet waste daily avoids significant anaerobic methane emissions at landfills.
Workshop includes hands-on training in Bokashi fermentation and home composter fabrication using terracotta pots.
Every participant receives a free 1-kg bag of mature campus organic bio-fertilizer for home or hostel plants.""",
          "location": "Central Dining Mess & Bio-Compost Yard, PCCOE",
          "communityName": "Zero-Waste Campus Brigade",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_miyawaki_drive",
          "title": "Pradhikaran Miyawaki Dense Native Forest Plantation",
          "type": "Ecological Restoration",
          "points": 600,
          "participants": [],
          "date": now.add(const Duration(days: 14)),
          "endDate": now.add(const Duration(days: 14, hours: 5)),
          "imageUrl": "assets/images/tree.png",
          "description": """Collaborate with the Pimpri Chinchwad Municipal Corporation (PCMC) to establish a fast-growing Miyawaki micro-forest.
Planting 250 native saplings across 4 distinct layers: canopy, sub-tree, shrub, and ground-cover perennials.
Species include indigenous Western Ghats flora: Neem, Jamun, Banyan, Kadamba, Karanj, and Indian Gooseberry (Amla).
Volunteers will excavate soil beds, incorporate vermicompost and rice husk mulch, and install drip irrigation pipes.
Miyawaki forests grow 10 times faster, absorb 30 times more CO2, and provide habitat for local birds and pollinators.
Learn soil preparation, seedling root architecture, and long-term geotagged survival monitoring protocols.
Digging spades, organic mulch, tree guards, and protective garden gloves will be supplied at the venue.
Celebrate campus biodiversity while leaving a living carbon sink legacy for future generations of engineering students.""",
          "location": "PCCOE Sports Complex Perimeter (North Boundary), Pune",
          "communityName": "Flora & Biodiversity Club",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_mobility_rally",
          "title": "Akurdi-Pradhikaran Low-Carbon Bicycle & EV Mobility Drive",
          "type": "Sustainable Mobility",
          "points": 380,
          "participants": [],
          "date": now.subtract(const Duration(days: 3)),
          "endDate": now.subtract(const Duration(days: 3, hours: -3)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Completed campus cycle rally advocating for dedicated non-motorized transport lanes around Sector 26 Pradhikaran.
Over 180 PCCOE students and faculty rode their pedal bicycles and electric two-wheelers across a 12 km green circuit.
We conducted roadside tailpipe emission surveys and distributed informational brochures on public transport integration.
Demonstrated the carbon offset achieved when commuters switch from single-occupancy petrol scooters to cycles.
Culminated in a signing of the PCCOE Active Commuter Charter to install 50 additional sheltered bicycle racks on campus.
Participants logged real-time GPS routes via the Green Yuva app to quantify collective fuel savings of 84 liters.
Refreshments, healthy fruit snacks, and cycle tune-up services were sponsored by local cycling clubs.
Check the photos, badge awards, and leaderboards to see how your hostel wing ranked in total active kilometers!""",
          "location": "Akurdi Railway Station to PCCOE Main Gate, Pune",
          "communityName": "Green Commuter League",
          "mapUrl": "https://maps.google.com/?q=PCCOE+Pune",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 2. COEP Technological University — Pune
    if (normalizedId.contains('coep')) {
      return [
        {
          "id": "${schoolId}_mula_river_cleanup",
          "title": "Mula-Mutha Confluence Wetland Desilting & Aquatic Trash Boom Deployment",
          "type": "Hydrology & River Basin",
          "points": 580,
          "participants": [],
          "date": now.add(const Duration(days: 1)),
          "endDate": now.add(const Duration(days: 1, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Historic action at the iconic COEP Boat Club riverbank along the Mula River in Shivajinagar.
Civil and environmental engineering students will install a floating trash boom to capture upstream nylon and plastic trash.
We deploy spectrophotometers to monitor biochemical oxygen demand (BOD) and chemical pollutants entering the stream.
Volunteers will manually desilt the heritage stone slipway and extract submerged non-biodegradable debris.
In partnership with the Pune Municipal Corporation (PMC), salvaged debris will be systematically weighed and logged.
Safety lifejackets, grab ropes, puncture-proof wading boots, and antiseptic first aid stations are strictly in place.
Contribute toward rejuvenating Pune's primary lifelines and preserving the historic riverfront ecosystem.
Briefing begins at 6:30 AM at the COEP Boat Club Regatta Pavillion; bring your college ID and work attire.""",
          "location": "COEP Boat Club, Mula Riverbank, Shivajinagar, Pune",
          "communityName": "COEP Regatta Eco-Corps",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_heritage_solar",
          "title": "Heritage Building Rooftop Solar Inspection & Micro-Inverter Sync",
          "type": "Clean Energy",
          "points": 460,
          "participants": [],
          "date": now.add(const Duration(days: 3)),
          "endDate": now.add(const Duration(days: 3, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Technical workshop across COEP's heritage Main Hall and modern academic building rooftops.
Conduct an electrical audit of the grid-interactive solar arrays, verifying anti-islanding protection and phase balances.
Students will use infrared thermography cameras to identify micro-cracked cells and bypass diode failures.
Learn how heritage stone architecture can seamlessly integrate clean solar energy without altering architectural integrity.
Data collected will calibrate the COEP campus carbon telemetry portal and help achieve net-zero building status.
Instruction led by faculty from the Department of Electrical and Instrumentation Engineering.
Work with calibrated clamp meters, pyranometers, and safety harness ropes under supervision of certified engineers.
Earn 460 GreenKarma coins and an official peer-reviewed certificate of clean energy system commissioning.""",
          "location": "COEP Main Heritage Building & North Terraces, Pune",
          "communityName": "COEP Energy & Clean-Tech Forum",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_aqi_mesh",
          "title": "Shivajinagar Urban Micro-Climate & Low-Cost IoT AQI Grid Calibration",
          "type": "Clean Air & IoT",
          "points": 520,
          "participants": [],
          "date": now.add(const Duration(days: 6)),
          "endDate": now.add(const Duration(days: 6, hours: 4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Deploy 12 student-assembled ESP32 microcontroller air quality sensor pods along the congested Shivajinagar traffic corridor.
Calibrate optical laser particle counters (PM2.5 and PM10) alongside MQ-135 gas sensors against government CPCB stations.
Analyze real-time vehicular emissions, temperature inversion layers, and humidity gradients across COEP campus gates.
Students will write open-source Python telemetry scrapers to publish live micro-climate warnings for campus pedestrians.
Investigate the particulate filtration efficacy of campus banyan tree barriers along the Mumbai-Pune highway boundary.
A multidisciplinary sprint combining electronics, computer science, and environmental atmospheric modeling.
Laptops, microcontrollers, breadboards, solar power banks, and mounting enclosures are provided by the innovation lab.
Final sensor telemetry dashboard will be projected on the COEP central campus digital bulletin display.""",
          "location": "COEP Instrumentation Labs & Shivajinagar Junction, Pune",
          "communityName": "COEP IoT & Robotics Guild",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_hostel_audit",
          "title": "COEP Hostel Zero-Plastic Transition & Cloth Bag Lending Library",
          "type": "Plastic Abatement",
          "points": 390,
          "participants": [],
          "date": now.add(const Duration(days: 9)),
          "endDate": now.add(const Duration(days: 9, hours: 2)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Transforming all 10 wings of the COEP Hostel Campus at Shivajinagar into a certified zero single-use plastic zone.
Volunteers will audit daily trash streams, cataloguing plastic wrapper counts, disposable cutlery, and delivery boxes.
Set up a permanent 'Bag-Share Kiosk' stocking 400 durable khadi canvas tote bags for students going to local markets.
Conduct door-to-door hostel room interactions demonstrating affordable bamboo toothbrushes, metal straws, and solid shampoos.
Hostel canteens will sign a formal memorandum to replace plastic lined paper cups with stainless steel glasses.
Calculate total prevented non-biodegradable landfill waste over an academic semester using empirical data.
Exciting peer competition: the hostel wing that cuts disposable plastic trash by the largest percentage wins a solar pizza party!
All active volunteers will receive a customised COEP Eco-Warrior canvas tote and 390 GreenKarma coins.""",
          "location": "COEP Hostel Grounds & Central Canteen, Shivajinagar, Pune",
          "communityName": "Hostel Sustainability Committee",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_rainwater_recharge",
          "title": "Groundwater Aquifer Injection & Heritage Well Restoration Sprint",
          "type": "Water Resilience",
          "points": 620,
          "participants": [],
          "date": now.add(const Duration(days: 13)),
          "endDate": now.add(const Duration(days: 13, hours: 5)),
          "imageUrl": "assets/images/river.png",
          "description": """Rehabilitate the historic 120-year-old stone open well and aquifer recharge pits located in the COEP Civil quadrangle.
Students will construct sand-gravel-charcoal bio-filtration trenches to route rooftop stormwater directly into the aquifer.
Clear silt accumulation, remove weeds, and measure the static water table using acoustic water level depth indicators.
Conduct laboratory chemical titration on water samples to ensure zero biological or chemical contamination in the recharge stream.
This initiative enables the campus to recharge an estimated 4.2 million liters of clean monsoon rainwater annually.
Learn hydrogeology, percolation rates, Darcy's law in practice, and decentralized campus water self-sufficiency.
Heavy safety equipment, submersible water testing meters, and protective gear are supervised by faculty.
Participating engineering students will receive practical field hydrometry certification for their professional resumes.""",
          "location": "Civil Engineering Quadrangle & Heritage Well, COEP, Pune",
          "communityName": "Civil Engineering Society",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_tree_census",
          "title": "Campus Heritage Tree Geotagging & Carbon Sequestration Registry",
          "type": "Biodiversity & Forestry",
          "points": 360,
          "participants": [],
          "date": now.subtract(const Duration(days: 4)),
          "endDate": now.subtract(const Duration(days: 4, hours: -3)),
          "imageUrl": "assets/images/tree.png",
          "description": """Completed campus-wide botanical and carbon accounting audit across COEP's 38-acre historic campus.
Mapped 420 heritage mature trees including century-old Rain Trees, Gulmohars, Tamarinds, Peepals, and Mahuas.
Students measured tree diameter at breast height (DBH), total canopy spread, and estimated biomass carbon sequestration.
Generated QR-code plaques mounted on trees linking to botanical data, medicinal uses, and bird nesting records.
Discovered that COEP's urban canopy sequesters over 65 metric tons of atmospheric carbon dioxide each year.
The digital campus green map was officially integrated into the Pune Open Data initiative and Green Yuva portal.
Great collaborative effort between first-year student volunteers and senior environmental researchers.
Check out the interactive map on the YuvaVibe feed to view tree profiles right outside your lecture hall!""",
          "location": "Entire COEP Academic Campus, Shivajinagar, Pune",
          "communityName": "COEP Botany & Green Guild",
          "mapUrl": "https://maps.google.com/?q=COEP+Technological+University",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 3. VIT Pune (Vishwakarma Institute of Technology)
    if (normalizedId.contains('vit_pune')) {
      return [
        {
          "id": "${schoolId}_watershed_recharge",
          "title": "Bibwewadi Hill Slope Watershed Trenches & Percolation Well Dig",
          "type": "Water Conservation",
          "points": 560,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Execute contour trenching and watershed management on the slopes behind the VIT Pune Upper Indira Nagar campus.
Volunteers will dig continuous contour trenches (CCT) to retard rainwater runoff velocity and prevent topsoil erosion.
We will pack trenches with vetiver grass root bundles known for their deep tensile soil stabilization properties.
Measure soil moisture retention curves and percolation rates using automated soil tensiometers before monsoon onset.
Prevents seasonal flash flooding of low-lying Bibwewadi residential colonies while recharging dry borewells.
Tools, pickaxes, measuring tapes, gloves, safety helmets, and energy drinks are provided at the site.
Gain practical earth-engineering experience in sustainable hillside rainwater harvesting and slope stabilization.
Assemble at the VIT Building No. 2 Mechanical workshop entrance at 7:00 AM sharp.""",
          "location": "Hill Slope Ridge, VIT Pune Campus, Bibwewadi, Pune",
          "communityName": "VIT Eco-Civil Brigade",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_drone_thermal",
          "title": "Drone Aerial Thermal Mapping of Urban Heat Islands & Roof Albedo",
          "type": "Atmospheric Science",
          "points": 510,
          "participants": [],
          "date": now.add(const Duration(days: 5)),
          "endDate": now.add(const Duration(days: 5, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Deploy high-resolution thermal imaging radiometers mounted on quadcopter drones over VIT campus rooftops.
Identify building surfaces experiencing severe solar heat gain and quantify the urban heat island (UHI) phenomenon.
Students will test high-albedo reflective white paints versus bare concrete, measuring surface delta-T differentials.
Process multispectral orthomosaic orthophotos using GIS software to calculate Normalized Difference Vegetation Index (NDVI).
Formulate data-backed architectural recommendations to slash air conditioning power consumption by up to 22%.
Open to all students interested in drone piloting, photogrammetry, computer vision, and green architecture.
Drone piloting will be conducted strictly within DGCA designated green zones under licensed faculty oversight.
Participants receive hands-on training in thermal image radiometric calibration and GIS mapping.""",
          "location": "VIT Football Ground & Building Terraces, Pune",
          "communityName": "VIT Aero-Clima Research Group",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_lithium_salvage",
          "title": "Lithium-Ion Cell Diagnostic & Secondary Life Battery Pack Assembly",
          "type": "Circular Hardware",
          "points": 540,
          "participants": [],
          "date": now.add(const Duration(days: 8)),
          "endDate": now.add(const Duration(days: 8, hours: 4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Salvage discarded laptop battery packs and power banks collected from campus dormitories and Pune tech hubs.
Students will carefully disassemble battery casing using non-conductive ceramic tools under strict fire-safe protocols.
Test individual 18650 cylindrical cells for internal resistance (mOhm), thermal leakage, and nominal capacity retention.
Good cells with over 80% remaining state-of-health (SoH) will be spot-welded into secondary-life solar storage packs.
These refurbished clean energy battery packs will power emergency LED lighting across campus security booths.
Learn Battery Management System (BMS) balancing algorithms, cell chemistry lifecycle analysis, and fire safety.
Equipment provided: digital cell testers, resistance meters, spot welders, fire blankets, and safety face shields.
A stellar sustainability and engineering project for electrical, electronics, and mechanical students.""",
          "location": "VIT Innovation Hub & Electrical Machines Lab, Pune",
          "communityName": "EV & Battery Storage Lab",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_bio_enzymes",
          "title": "Citrus Peel Bio-Enzyme Formulation & Chemical Cleaner Replacement",
          "type": "Green Chemistry",
          "points": 410,
          "participants": [],
          "date": now.add(const Duration(days: 11)),
          "endDate": now.add(const Duration(days: 11, hours: 2)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Collect discarded citrus, lemon, and orange peels from campus juice shops and cafeterias across Bibwewadi.
Formulate multi-purpose natural bio-enzymes combining organic fruit peels, jaggery molasses, and active yeast cultures.
Students will study the anaerobic fermentation kinetics and organic acid (acetic and citric acid) production over 90 days.
The resulting natural enzyme cleaner will replace toxic, caustic chemical floor detergents across all VIT campus labs.
Prevents harmful phosphate and chlorine surfactants from entering the local drainage system and contaminating soil.
Participants will test microbial disinfection potency against standard commercial synthetic cleansers in the bio lab.
Each attendee will prepare and bottle their own 1-liter fermenter to take home with clear pH monitoring instructions.
Earn 410 GreenKarma coins and discover how simple biochemistry creates zero-carbon circular sanitation.""",
          "location": "Department of Chemical Engineering Labs, VIT Pune",
          "communityName": "Green Chem & Bio-Tech Forum",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_pv_cleaning",
          "title": "Automated Solar Panel Dusting Robot Demonstration & Efficiency Hackathon",
          "type": "Renewable Tech",
          "points": 490,
          "participants": [],
          "date": now.add(const Duration(days: 15)),
          "endDate": now.add(const Duration(days: 15, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Test student-built robotic crawler bots designed to clean rooftop solar arrays without consuming water.
Fine airborne particulate matter in Pune reduces rooftop photovoltaic power output by up to 18% within two weeks.
Evaluate dry silicone roller brushes and electrostatic air knife mechanisms running along VIT Building No. 1 arrays.
Measure real-time string voltage and current outputs before and after the robotic cleaning pass.
Students will optimize obstacle-crossing algorithms, edge detection sensors, and solar-recharge docking stations.
Teams will present algorithm modifications to enhance crawler speed and battery autonomy in a 2-hour mini hackathon.
Cash prizes, Karma coin bonuses, and prototyping grants awarded to top-performing student robotics teams.
All engineering branches are welcome; mentors from VIT faculty and clean-tech startups will evaluate pitches.""",
          "location": "Building 1 Terrace & Embedded Systems Lab, VIT Pune",
          "communityName": "VIT Robotics & Automation Forum",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_shuttle_pledge",
          "title": "Campus Carpooling Algorithm Launch & Electric Scooter Fleet Trial",
          "type": "Sustainable Transit",
          "points": 370,
          "participants": [],
          "date": now.subtract(const Duration(days: 2)),
          "endDate": now.subtract(const Duration(days: 2, hours: -3)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Successfully launched the student-developed VIT GreenPool dynamic ride-sharing algorithm for Pune commuters.
Over 340 students and staff commuting from Kothrud, Hadapsar, and Pimpri registered their daily transit routes.
Integrated 15 shared campus electric scooters with dedicated solar charging docks located at the VIT gate.
During the trial week, participants collectively logged 4,200 shared kilometers, preventing 860 kg of CO2 emissions.
Demonstrated a 35% reduction in morning vehicular congestion along the narrow Bibwewadi campus access roads.
Commuters who logged more than 4 rides earned priority parking passes and special discount coupons at the canteen.
Check your updated GreenKarma wallet to verify your commute rewards and keep sharing rides every semester!""",
          "location": "VIT Main Gate & Student Parking Quadrangle, Pune",
          "communityName": "VIT Smart Commute Cell",
          "mapUrl": "https://maps.google.com/?q=VIT+Pune",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 4. PICT Pune (Pune Institute of Computer Technology)
    if (normalizedId.contains('pict')) {
      return [
        {
          "id": "${schoolId}_server_heat",
          "title": "Data Center Waste Heat Harvesting & Green Computing Optimization",
          "type": "Green Computing",
          "points": 530,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Audit the thermal performance and power usage effectiveness (PUE) of the PICT Central Computer Center.
Students will measure hot-aisle and cold-aisle airflows, processor power draw under workload, and cooling energy waste.
Prototype a closed-loop heat pipe heat exchanger that repurposes server rack exhaust heat to warm hostel shower water.
Benchmark code energy consumption: profile neural network training scripts and implement carbon-aware job schedulers.
Learn how software architecture directly influences global digital carbon footprints and power consumption.
Instruction led by PICT Computer Engineering faculty with industrial telemetry and temperature sensor nodes.
Working with calibrated anemometers, thermal cameras, and smart power meters across the main server room.
Participants receive 530 GreenKarma coins and a badge in Certified Green Cloud Infrastructure Optimization.""",
          "location": "Central Computing Lab & Server Room, PICT Campus, Pune",
          "communityName": "PICT Green Algorithms Guild",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_katraj_cleanup",
          "title": "Katraj Lake Perimeter Wetland Cleanup & Water Quality Micro-Sensing",
          "type": "Hydrology & Ecosystem",
          "points": 570,
          "participants": [],
          "date": now.add(const Duration(days: 4)),
          "endDate": now.add(const Duration(days: 4, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Mobilize PICT students for an intensive ecological cleanup and water health survey around Katraj Lake.
Extract discarded plastic bottles, food cartons, and thermocol debris choking the southern wetland inlets.
Deploy IoT water monitoring buoys built by PICT students featuring turbidity sensors, dissolved oxygen, and pH monitors.
Map pollution heatmaps along the perimeter and transmit real-time telemetry over a campus LoRaWAN wireless gateway.
Segregate collected trash at the source, sending high-density polyethylene (HDPE) bottles for upcycling.
Safety gloves, gumboots, floating lifebuoys, trash bags, and clean drinking water are stationed along the lake banks.
Briefing at 6:45 AM at the PICT Gate before walking together to the Katraj Lake promenade.
Help protect one of South Pune's critical urban water bodies and migratory bird feeding grounds.""",
          "location": "Katraj Lake Promenade & Southern Wetland, Dhankawadi, Pune",
          "communityName": "PICT Eco-Warriors Wing",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_paperless_hack",
          "title": "Campus Paperless Workflow & Digital Assignment Platform Sprint",
          "type": "Resource Conservation",
          "points": 440,
          "participants": [],
          "date": now.add(const Duration(days: 7)),
          "endDate": now.add(const Duration(days: 7, hours: 4)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Collaborative developer hackathon to eliminate physical paper printouts for lab write-ups, forms, and term projects.
Students will build and test an end-to-end cryptographic digital signature workflow using Flutter and web tech.
Calculate total saved A4 reams, water utilized in paper milling, and avoided transport emissions across departments.
The platform will automatically integrate with college Moodle servers, enabling instant paperless submissions.
Prizes awarded for the cleanest UX, accessibility compliance, and mobile responsive layout.
A great opportunity for software developers to apply coding skills directly toward tangible campus sustainability.
Mentors will assist with API design, encryption standards, and scalable database schemas.
Pizza, coffee, and 440 GreenKarma coins provided to all registered hackers who deliver working pull requests.""",
          "location": "Auditorium & Computer Lab 3, PICT Campus, Pune",
          "communityName": "PICT Open Source & Green Tech Club",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_rainwater_well",
          "title": "Dhankawadi Aquifer Recharge Pit Maintenance & Flow Meter Installation",
          "type": "Water Resilience",
          "points": 500,
          "participants": [],
          "date": now.add(const Duration(days: 10)),
          "endDate": now.add(const Duration(days: 10, hours: 3)),
          "imageUrl": "assets/images/river.png",
          "description": """Inspect and clean the gravel-packed recharge wells connecting PICT building rooftops to the underground aquifer.
Volunteers will remove leaf litter, silt, and urban dust clogging the rooftop intake strainers and downspouts.
Install ultrasonic flow meters connected to an Arduino logger to measure cubic meters of injected rainwater.
Test the physical filtration efficiency of charcoal, crushed quartz sand, and aggregate beds inside the pits.
This infrastructure enables PICT to replenish over 2.8 million liters of water each monsoon, maintaining borewell levels.
Essential preparation before pre-monsoon showers begin across the Deccan plateau.
Work attire recommended; gloves, shovels, wrenches, and sensor wiring kits are provided.
Learn the mechanics of urban artificial aquifer recharge under the guidance of hydrology specialists.""",
          "location": "North Garden Recharge Wells, PICT Campus, Pune",
          "communityName": "PICT Infrastructure & Sustainability Cell",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_micro_composting",
          "title": "Hostel Canteen Vermiculture Bin Setup & Soil Microbiology Lab",
          "type": "Organic Composting",
          "points": 430,
          "participants": [],
          "date": now.add(const Duration(days: 13)),
          "endDate": now.add(const Duration(days: 13, hours: 2)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Set up three multi-tier vermiculture bio-bins processing organic vegetable scraps from PICT student messes.
Learn the biology and habitat requirements of Eisenia fetida (Red Wiggler worms) for hyper-efficient decomposition.
Students will balance carbon-to-nitrogen ratios, adjust moisture levels, and monitor bin pH and aeration.
Examine vermicompost samples under lab optical microscopes to analyze beneficial mycorrhizal and bacterial colonies.
Harvested nutrient-dense vermicompost tea will fertilize campus potted plants and medicinal botanical gardens.
Discover how decentralized vermiculture eliminates greenhouse methane emissions caused by landfill dumping.
Workshop participants will assemble and take home a miniature desktop vermicomposter for personal room plants.
Earn 430 GreenKarma coins and discover practical biotechnology for zero-waste living.""",
          "location": "Hostel Mess Courtyard & Chemistry Lab, PICT Pune",
          "communityName": "Zero-Waste Campus League",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_e_recycling_drive",
          "title": "Dhankawadi Campus E-Component Scavenge & Broken Tech Repair Cafe",
          "type": "E-Waste Reclamation",
          "points": 390,
          "participants": [],
          "date": now.subtract(const Duration(days: 5)),
          "endDate": now.subtract(const Duration(days: 5, hours: -4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Completed high-impact community repair cafe and electronic waste reclamation sprint at the PICT campus entrance.
Repaired 68 student laptops, headphones, monitors, and chargers, extending their operational lifespan and avoiding landfill waste.
Collected 420 kg of non-repairable electronics, routing them to authorized Maharashtra state pollution board recyclers.
Conducted interactive workshops teaching students basic soldering, multimeter troubleshooting, and battery replacement skills.
Demonstrated that repairing electronics prevents massive carbon footprints embedded in new hardware manufacturing.
The event was recognized by local Dhankawadi community leaders and covered in regional tech newsletters.
Check the YuvaVibe photo wall to see before-and-after restorations of rescued gadgets!""",
          "location": "PICT Main Entrance Canopy & Hardware Lab, Pune",
          "communityName": "PICT Hardware & Repair Forum",
          "mapUrl": "https://maps.google.com/?q=PICT+Pune",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 5. MIT-WPU Pune (MIT World Peace University)
    if (normalizedId.contains('mit_wpu') || normalizedId.contains('mit')) {
      return [
        {
          "id": "${schoolId}_tree_canopy",
          "title": "Kothrud Urban Canopy Health Telemetry & Botanical QR Geotagging",
          "type": "Urban Forestry",
          "points": 540,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/tree.png",
          "description": """Geotag and inspect over 300 urban trees lining Paud Road and the sprawling MIT-WPU Kothrud campus.
Students will use mobile GIS tools to record species, tree height, crown volume, and bark health indicators.
Affix waterproof laser-engraved bamboo QR tags detailing botanical names, oxygen production, and cultural significance.
Evaluate the impact of urban asphalt compaction on tree root respiration and excavate soil aeration rings around bases.
Collaborate with botanists and urban forestry experts to create a digital biodiversity map of Kothrud.
Protective vests, measuring calipers, botanical field guides, and tree nourishment supplies are provided.
Contribute toward preserving one of Pune's densest educational green canopies.
Meet at the World Peace Dome plaza at 7:00 AM; breakfast and fruit refreshments provided after the session.""",
          "location": "Paud Road & MIT-WPU World Peace Dome Plaza, Pune",
          "communityName": "MIT-WPU Green Horizon Wing",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_fashion_swap",
          "title": "Campus Circular Fashion Exchange & Garment Upcycling Workshop",
          "type": "Circular Economy",
          "points": 460,
          "participants": [],
          "date": now.add(const Duration(days: 5)),
          "endDate": now.add(const Duration(days: 5, hours: 3)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Tackle the massive carbon and water footprint of fast fashion with a campus-wide circular clothing swap.
Students deposit clean, gently worn garments in exchange for swap tokens to pick up fresh styles for the new semester.
Learn basic sewing, embroidery customization, and patch mending techniques at our volunteer-run stitching stations.
Unclaimed cotton garments will be mechanically upcycled into durable canvas shopping bags for campus convenience stores.
Every kilogram of recycled cotton prevents over 10,000 liters of freshwater consumption in textile manufacturing.
Live acoustic music, thrift styling competitions, and zero-waste refreshments will accompany the event.
Drop off items at the Student Activity Center starting Wednesday to receive early-bird swap passes.
Earn 460 GreenKarma coins and redefine sustainable college lifestyle with ethical circular choices.""",
          "location": "Student Activity Center (SAC), MIT-WPU Campus, Pune",
          "communityName": "MIT-WPU Sustainability & Design Cell",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_greywater_wetland",
          "title": "Constructed Wetland Greywater Purification & Reed Bed Maintenance",
          "type": "Ecological Engineering",
          "points": 580,
          "participants": [],
          "date": now.add(const Duration(days: 8)),
          "endDate": now.add(const Duration(days: 8, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Hands-on maintenance of the root-zone constructed wetland purifying greywater from campus hostel washrooms.
Prune overgrown Typha and Phragmites reeds that naturally absorb nitrates, phosphates, and suspended solids from wastewater.
Sample influent and effluent streams, testing for chemical oxygen demand (COD), turbidity, and total coliform bacteria.
Treated water is safely recirculated for irrigating 15 acres of campus lawns and decorative botanical gardens.
This nature-based wastewater treatment system slashes municipal freshwater dependency by 45,000 liters daily.
Learn environmental biotechnology, ecological sanitation, and zero-energy decentralized water recycling.
Rubber waders, sampling vials, lab test kits, and safety aprons are provided by the School of Civil Engineering.
Field volunteers will gain invaluable experience in nature-based engineering solutions for resilient cities.""",
          "location": "Constructed Wetland Facility, South Perimeter, MIT-WPU, Pune",
          "communityName": "Eco-Hydrology Research Group",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_biodigester_audit",
          "title": "Hostel Bio-Digester Gas Yield Optimization & Methane Flare Testing",
          "type": "Bio-Energy",
          "points": 500,
          "participants": [],
          "date": now.add(const Duration(days: 11)),
          "endDate": now.add(const Duration(days: 11, hours: 3)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Audit the continuous anaerobic digestion plant that processes 300 kg of daily dining hall organic scraps.
Measure biogas methane concentration using infrared gas analyzers and check volatile fatty acid (VFA) ratios.
Students will optimize feedstock dilution ratios and temperature jacket settings to maximize bacterial digestion kinetics.
The harvested clean biomethane is piped directly to the campus culinary labs, offsetting commercial LPG cylinder usage.
Discharged mineralized digestate slurry is dehydrated and packaged as odorless organic manure for campus gardens.
Safety first: training in gas pressure regulation, anaerobic microbiology, and combustible gas safety detectors.
Protective lab coats, safety goggles, digital gas sniffers, and sampling instruments will be provided.
Earn 500 GreenKarma coins and learn scalable biological waste-to-energy conversion firsthand.""",
          "location": "Bio-Digester Complex, MIT-WPU Hostels, Pune",
          "communityName": "Bio-Energy & Cleantech Guild",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_solar_dome",
          "title": "World Peace Dome Solar Array Radiometry & Microgrid Storage Study",
          "type": "Solar Power",
          "points": 520,
          "participants": [],
          "date": now.add(const Duration(days: 14)),
          "endDate": now.add(const Duration(days: 14, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Investigate the performance of the high-efficiency rooftop photovoltaic array atop the World Peace Dome complex.
Collect global horizontal irradiance (GHI) data using research-grade thermopile pyranometers across varying weather conditions.
Analyze battery energy storage system (BESS) charge and discharge curves to assess campus peak-shaving capabilities.
Calculate the economic payback period and lifetime greenhouse gas offsets achieved by the university microgrid.
A multidisciplinary session bridging renewable energy economics, power systems engineering, and climate governance.
Conducted under the guidance of MIT-WPU Department of Electrical Engineering professors and industry consultants.
Laptops with grid simulation software, wireless dataloggers, and safety terrace access badges provided.
All participants will receive a verified certificate in Campus Clean Energy Microgrid Operations.""",
          "location": "World Peace Dome Terrace & Renewable Energy Lab, MIT-WPU",
          "communityName": "MIT-WPU Solar & Energy League",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_ev_bus_route",
          "title": "Campus Electric Shuttle Route Expansion & Tailpipe Emission Audit",
          "type": "Green Mobility",
          "points": 380,
          "participants": [],
          "date": now.subtract(const Duration(days: 3)),
          "endDate": now.subtract(const Duration(days: 3, hours: -3)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Completed student-led transport survey expanding the zero-emission electric shuttle loop connecting Vanaz Metro Station to MIT-WPU.
Audited over 1,200 student commutes to establish optimal frequency schedules, cutting student wait times to under 6 minutes.
Conducted roadside exhaust particulate tests demonstrating an 88% reduction in toxic diesel smoke along the campus corridor.
The electric feeder shuttle has successfully transported over 4,500 students in its first month of full operation.
Celebrated with a green mobility awareness rally featuring electric bicycles, skateboards, and electric scooters.
Volunteers distributed reusable metro transit passes and smart commute tips to incoming first-year students.
Check the YuvaVibe leaderboard to see your department's collective electric transit savings!""",
          "location": "Vanaz Metro Station to MIT-WPU Main Campus Route, Pune",
          "communityName": "Clean Transport Coalition",
          "mapUrl": "https://maps.google.com/?q=MIT-WPU+Pune",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 6. VIIT Pune (Vishwakarma Institute of Information Technology)
    if (normalizedId.contains('viit')) {
      return [
        {
          "id": "${schoolId}_kondhwa_afforestation",
          "title": "Kondhwa Hills Miyawaki Afforestation & Native Seed Ball Broadcasting",
          "type": "Biodiversity Conservation",
          "points": 570,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/tree.png",
          "description": """Restore degraded rocky hill slopes surrounding the VIIT campus in Kondhwa with resilient indigenous flora.
Volunteers will prepare 1,500 nutrient-rich seed balls containing red clay, compost, and seeds of hardy Western Ghats species.
Broadcast seed balls across inaccessible barren contours and plant 200 saplings including Khair, Shisham, Babool, and Neem.
Build protective stone bunds (gabion structures) along hill gullies to retain moisture and halt seasonal topsoil loss.
Learn hands-on ecological restoration, micro-watershed management, and community-driven reforestation techniques.
Planting spades, seed-making materials, gloves, sun hats, and energy snacks are provided for all registered participants.
Breathtaking panoramic views of the Pune skyline make this both an environmental mission and an inspiring outdoor trek.
Assemble at the VIIT Main Parking Lot at 6:30 AM; transportation to the hill site is arranged.""",
          "location": "Kondhwa Hill Ridge, Adjacent to VIIT Campus, Pune",
          "communityName": "VIIT Nature & Adventure Club",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_borewell_recharge",
          "title": "Kondhwa Deep Borewell Silt-Filter Maintenance & Water Hardness Test",
          "type": "Water Resilience",
          "points": 490,
          "participants": [],
          "date": now.add(const Duration(days: 5)),
          "endDate": now.add(const Duration(days: 5, hours: 3)),
          "imageUrl": "assets/images/river.png",
          "description": """Service and regenerate the three deep groundwater recharge wells that sustain VIIT campus water needs.
Volunteers will excavate accumulated clay silt from the gravel filtration beds that surround the casing pipes.
Replace exhausted activated carbon filter layers and measure water absorption rates using volumetric flumes.
Conduct titration tests for groundwater fluoride, calcium hardness, and total dissolved solids (TDS) in the environmental lab.
This ongoing recharge initiative prevents seasonal borewell failure, ensuring sustainable campus water security.
Essential engineering training in hydrogeological conservation for civil, chemical, and mechanical students.
Wear sturdy clothing and footwear; all digging tools, testing kits, and safety gear are provided.
Earn 490 GreenKarma coins and a practical certificate in Urban Groundwater Conservation Practices.""",
          "location": "Groundwater Recharge Complex, VIIT Sports Ground, Pune",
          "communityName": "VIIT Water Resource Cell",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_ewaste_clinic",
          "title": "Kondhwa Community E-Waste Drop-Off & Household Appliance Clinic",
          "type": "Circular Economy",
          "points": 520,
          "participants": [],
          "date": now.add(const Duration(days: 8)),
          "endDate": now.add(const Duration(days: 8, hours: 4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Open the VIIT campus gates to Kondhwa residents for a weekend electrical recycling and repair drive.
Students diagnose and repair broken consumer electronics: electric kettles, study lamps, chargers, and ceiling fans.
Items beyond repair are dismantled safely to harvest reusable copper coils, aluminum heat sinks, and relays.
Hazardous lead-containing cathode tubes, cadmium switches, and circuit boards are handed over to certified MPCB recyclers.
Prevent toxic electronics from being illegally burned in scrap yards or dumped along rural Pune roadsides.
Students sharpen hands-on diagnostic, soldering, and component reclamation skills under faculty supervision.
Digital multimeters, soldering irons, desoldering pumps, and safety goggles provided at each workbench.
Celebrate practical engineering that serves the neighborhood while preventing severe toxic pollution.""",
          "location": "VIIT Workshop Quadrangle & Main Entrance, Pune",
          "communityName": "VIIT Electronics & Social Impact Cell",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_solar_cleaning",
          "title": "Rooftop Solar Array Washing & Net-Metering Yield Assessment",
          "type": "Renewable Energy",
          "points": 470,
          "participants": [],
          "date": now.add(const Duration(days: 11)),
          "endDate": now.add(const Duration(days: 11, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Climb up to the VIIT Building A and B rooftop arrays to assess solar output after heavy particulate buildup.
Learn the science of solar irradiance, temperature derating coefficients, and photovoltaic string losses.
Teams will clean 240 solar panels using recycled treated greywater and specialized soft scratch-proof squeegees.
Compare instantaneous kW generation readings before and after washing using the college SMA inverter portal.
Typically, removing thick urban dust crust produces an immediate 14-19% boost in daily solar kilowatt-hours!
Calculate the financial savings and avoided carbon footprint achieved by just one morning of active maintenance.
Harness safety lines, non-slip footwear, water hoses, and monitoring tablets provided by the facilities department.
Earn 470 GreenKarma coins and gain firsthand experience in utility-scale solar asset management.""",
          "location": "Building A & B Terraces, VIIT Campus, Kondhwa, Pune",
          "communityName": "VIIT Solar Champions Forum",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_plastic_ban",
          "title": "Campus Canteen Single-Use Plastic Elimination & Steel Tumbler Bank",
          "type": "Waste Minimization",
          "points": 400,
          "participants": [],
          "date": now.add(const Duration(days: 14)),
          "endDate": now.add(const Duration(days: 14, hours: 2)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Inaugurate the VIIT 'Rent-a-Tumbler' zero-waste initiative across all campus snack shops and tea stalls.
Distribute 500 food-grade stainless steel cups and lunch containers, replacing disposable paper and plastic cups.
Students scan an NFC tag with the Green Yuva app to borrow a sanitized tumbler, returning it to collection bins after use.
Volunteers will monitor kiosk stations, educate incoming students on microplastics, and oversee sanitation cycles.
Eliminates an estimated 1,400 disposable plastic cups from campus trash bins every single working day.
Calculate the reduced solid waste disposal fees and municipal hauling carbon footprint.
Exciting badge rewards, free chai coupons, and 400 GreenKarma coins for active volunteers and frequent borrowers.
Join the movement making VIIT one of Pune's premier zero single-use plastic engineering campuses!""",
          "location": "VIIT Central Canteen & Student Plaza, Kondhwa, Pune",
          "communityName": "VIIT Green Campus Coalition",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_vermicompost_harvest",
          "title": "Hostel Organic Fertilizer Harvest & Kondhwa Farmer Seedling Distribution",
          "type": "Soil Regeneration",
          "points": 360,
          "participants": [],
          "date": now.subtract(const Duration(days: 4)),
          "endDate": now.subtract(const Duration(days: 4, hours: -3)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Completed harvest of 650 kg of rich organic vermicompost produced from 3 months of VIIT hostel dining waste.
Students sifted, bagged, and labeled nutrient-rich vermicast with complete N-P-K microbiological lab assays.
Distributed free fertilizer packets and indigenous vegetable saplings (tomato, chili, brinjal) to local peri-urban farmers.
Demonstrated the complete circular loop where kitchen leftovers replenish agricultural soils without synthetic chemicals.
The initiative was widely applauded by the local Kondhwa community development council.
All student volunteers earned 360 GreenKarma coins and free packets of organic soil booster for their home gardens.
View the photo gallery on YuvaVibe to see the joyful handover to local farming families!""",
          "location": "VIIT Organic Farm Yard & Agriculture Outreach Stall, Pune",
          "communityName": "Community Soil & Farming Wing",
          "mapUrl": "https://maps.google.com/?q=VIIT+Pune",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 7. BITS Pilani (Birla Institute of Technology and Science, Pilani)
    if (normalizedId.contains('bits') || normalizedId.contains('pilani')) {
      return [
        {
          "id": "${schoolId}_khejri_planting",
          "title": "Thar Desert Fringe Khejri Afforestation & Sand Dune Stabilization",
          "type": "Arid Zone Restoration",
          "points": 610,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/tree.png",
          "description": """Venture into the arid desert fringes surrounding Vidya Vihar campus in Pilani, Rajasthan.
Plant 300 drought-tolerant native Khejri (Prosopis cineraria), Rohida, and Kair saplings known as the lifelines of the Thar desert.
Install terracotta pitcher sub-surface irrigation pots that deliver micro-droplets of water directly to roots with zero evaporation.
Construct natural brushwood check-dams to arrest windward sand dune migration toward student residential quarters.
Learn desert permaculture, xeriscaping, and traditional Shekhawati ecological wisdom from local Bishnoi elders.
Shovels, terracotta irrigation ollas, seedling saplings, protective sun turbans, and hydration stations provided.
Experience the profound satisfaction of creating a living green shield against desertification.
Assemble at the BITS Clock Tower at 6:00 AM sharp; sturdy desert boots and sun protection are mandatory.""",
          "location": "Vidya Vihar Desert Perimeter & South Sand Dunes, BITS Pilani",
          "communityName": "BITS Environmental & Desert Ecology Club",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_solar_thermal",
          "title": "Parabolic Solar Concentrator Calibration & Thermal Storage Yield Sprint",
          "type": "Concentrated Solar Power",
          "points": 530,
          "participants": [],
          "date": now.add(const Duration(days: 5)),
          "endDate": now.add(const Duration(days: 5, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Technical inspection of the parabolic solar concentrators and 1 MW rooftop photovoltaic installations at BITS Pilani.
Students will align mirrored parabolic troughs with the sun's azimuth angle to achieve peak thermal concentration.
Measure molten salt heat transfer fluid temperatures, thermodynamic Carnot efficiencies, and steam boiler heat yields.
Clean glass reflectors of abrasive desert dust using electrostatic micro-fiber sweeps that preserve mirror coatings.
Analyze Pilani's exceptional Direct Normal Irradiance (DNI) metrics using high-precision pyrheliometers.
A benchmark learning experience for mechanical, chemical, and electrical students targeting clean energy careers.
Heat-resistant safety gloves, optical alignment laser tools, and irradiance loggers are provided by the lab.
Concludes with a live demonstration of solar steam-powered community cooking at the student mess.""",
          "location": "BITS Renewable Energy Park & Solar Thermal Facility, Pilani",
          "communityName": "BITS Energy Society",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_shekhawati_kunds",
          "title": "Traditional Shekhawati Rainwater Kunds & Step-Well Restoration",
          "type": "Heritage Hydrology",
          "points": 590,
          "participants": [],
          "date": now.add(const Duration(days: 8)),
          "endDate": now.add(const Duration(days: 8, hours: 5)),
          "imageUrl": "assets/images/river.png",
          "description": """Restore the century-old lime-plastered underground rainwater harvesting reservoirs (Kunds) across the campus grounds.
Clean lime catchment basins, clear windblown silt from inlet ducts, and apply traditional neem-turmeric antimicrobial whitewash.
Students calculate catchment runoff coefficients and storage volume capacities capable of holding over 1.2 million liters.
In an arid zone receiving less than 350 mm of rainfall annually, preserving traditional rainwater harvesting is vital.
Combine ancient Shekhawati architectural brilliance with modern water purity testing sensors and solar pumps.
Gloves, safety harnesses for underground inspection, silt buckets, and natural whitewash brushes are provided.
Led by BITS Civil Engineering faculty and veteran master-masons skilled in lime mortar technology.
All participants earn 590 GreenKarma coins and a certificate in Traditional Arid Zone Water Heritage Engineering.""",
          "location": "Historic Rainwater Kunds & Heritage Well, BITS Pilani",
          "communityName": "Pilani Water Conservation Cell",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_ewaste_scavenge",
          "title": "Robotics & Microcontroller E-Waste Dismantling and Circuit Salvage",
          "type": "Circular Electronics",
          "points": 480,
          "participants": [],
          "date": now.add(const Duration(days: 11)),
          "endDate": now.add(const Duration(days: 11, hours: 4)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Recover valuable electronic modules and IC chips from discarded hardware across BITS computing and electronics labs.
Systematically desolder operational microcontrollers, motor drivers, LCD displays, and voltage regulators from old circuit boards.
Tested components are catalogued into the student maker inventory for upcoming APOGEE technical festival projects.
Ensures students don't purchase new imported silicon when perfectly good chips can be upcycled locally.
All unusable toxic scrap is sealed in hazardous containment drums for collection by licensed e-waste recyclers.
Hands-on training in surface-mount desoldering, flux cleaning, oscilloscope diagnostics, and ESD prevention.
Soldering rework stations, fume extractors, multimeters, and component storage cases provided.
Earn 480 GreenKarma coins and take home useful salvaged components for your own DIY electronics projects!""",
          "location": "Pilani Innovation Centre & Maker Lab, BITS Pilani",
          "communityName": "BITS Hardware & Maker Forum",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_mess_methane",
          "title": "Student Mess Food Scrap Anaerobic Digestion & Biomethane Analysis",
          "type": "Food Waste Energy",
          "points": 440,
          "participants": [],
          "date": now.add(const Duration(days: 14)),
          "endDate": now.add(const Duration(days: 14, hours: 2)),
          "imageUrl": "assets/images/cooking.png",
          "description": """Audit the continuous bio-digester converting post-meal food waste from BITS hostels into clean cooking fuel.
Measure daily scrap weights across Shankar, Vyas, and Budh bhavans, tracking carbohydrate versus protein ratios.
Calibrate gas flow meters, test biogas methane percentage with gas chromatography, and monitor digester slurry pH.
The generated methane directly fires the stove burners of the campus night canteen, closing the local energy loop.
Calculate total carbon dioxide equivalent emissions prevented compared to conventional diesel transport and landfilling.
Hands-on biotechnology training in anaerobic microbial consortia, thermophilic digestion, and renewable gases.
Protective lab wear, digital pH pens, biogas sniffers, and sampling tubes supplied at the digestion facility.
Each volunteer receives 440 GreenKarma coins and an organic garden fertilizer kit.""",
          "location": "Bio-Energy Plant & Mess Complex, BITS Pilani",
          "communityName": "BITS Sustainable Waste Cell",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_desert_windbreak",
          "title": "Vidya Vihar Desert Windbreak Plantation & Dust Mitigation Review",
          "type": "Erosion Control",
          "points": 350,
          "participants": [],
          "date": now.subtract(const Duration(days: 3)),
          "endDate": now.subtract(const Duration(days: 3, hours: -3)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Completed multi-row windbreak shelterbelt plantation along the western boundary of the BITS Pilani campus.
Planted 280 hardy Casuarina and Eucalyptus trees in staggered rows to deflect ferocious desert dust storms (Aandhi).
Installed solar-powered drip irrigation emitters ensuring over 95% water efficiency in harsh arid soil conditions.
Post-plantation air quality sensors recorded a 42% drop in airborne sand particle penetration across hostel corridors.
Organized in partnership with the Rajasthan State Forest Department and campus volunteer corps.
Student volunteers demonstrated the power of green bio-shields over expensive artificial concrete retaining walls.
Check the photos and satellite view updates on YuvaVibe to see the budding green wall protecting Vidya Vihar!""",
          "location": "Western Perimeter Fence, Vidya Vihar, BITS Pilani",
          "communityName": "BITS Desert Ecology Wing",
          "mapUrl": "https://maps.google.com/?q=BITS+Pilani",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // 8. VIT Vellore (Vellore Institute of Technology, Vellore)
    if (normalizedId.contains('vit_vellore') || normalizedId.contains('vellore')) {
      return [
        {
          "id": "${schoolId}_palar_river",
          "title": "Palar River Basin Sand Bed Hydration & Macro-Plastic Retrieval",
          "type": "River Rejuvenation",
          "points": 590,
          "participants": [],
          "date": now.add(const Duration(days: 2)),
          "endDate": now.add(const Duration(days: 2, hours: 4)),
          "imageUrl": "assets/images/river.png",
          "description": """Assemble at the dry sandy riverbed of the Palar River near the Katpadi railway bridge in Vellore.
Volunteers will clear single-use plastics, dumped construction debris, and synthetic textile waste clogging the channel.
Excavate percolation bunds in the dry coarse sand to trap seasonal floodwaters and facilitate deep underground infiltration.
Measure groundwater levels in adjacent community borewells and collect soil samples for salinity and chromium testing.
The Palar river basin supplies drinking water to millions in northern Tamil Nadu; keeping its sand beds clean is paramount.
Heavy-duty gloves, sand rakes, collection sacks, sun caps, and fresh hydration stations provided.
Briefing at 6:30 AM at the VIT Main Gate before boarding the volunteer transport buses.
Earn 590 GreenKarma coins and contribute directly toward regional water security in drought-prone Vellore.""",
          "location": "Palar River Bed, Katpadi Bridge Section, Vellore, Tamil Nadu",
          "communityName": "VIT River Care Guild",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_floating_wetland",
          "title": "VIT Campus Lake Floating Bio-Filter Islands & Algae Control",
          "type": "Aquatic Biotechnology",
          "points": 540,
          "participants": [],
          "date": now.add(const Duration(days: 5)),
          "endDate": now.add(const Duration(days: 5, hours: 3)),
          "imageUrl": "assets/images/river.png",
          "description": """Construct and launch 6 floating artificial wetland rafts on the central campus lake at VIT Vellore.
Rafts are fabricated using upcycled bamboo frames and non-toxic buoyant recycled PET bottles.
Plant indigenous aquatic macrophytes including Vetiver, Canna indica, and Water Iris whose roots absorb excess nitrogen and phosphorus.
This nature-based solution starves toxic blue-green algal blooms, dramatically improving lake water clarity and odor.
Monitor dissolved oxygen (DO) levels and sunlight penetration depths using portable Secchi disks and multi-probes.
An inspiring cross-disciplinary project linking environmental biotechnology, naval engineering, and campus aesthetics.
Lifejackets, floating dock safety harnesses, planting seedlings, and water analysis meters provided.
Earn 540 GreenKarma coins and watch your living floating islands clean the campus lake all semester long!""",
          "location": "Central Campus Lake & Boating Pier, VIT Vellore",
          "communityName": "VIT Eco-Water Research Hub",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_palmyra_planting",
          "title": "State Tree Palmyra Palm (Panai Maram) Seedling Plantation",
          "type": "Indigenous Conservation",
          "points": 560,
          "participants": [],
          "date": now.add(const Duration(days: 8)),
          "endDate": now.add(const Duration(days: 8, hours: 4)),
          "imageUrl": "assets/images/tree.png",
          "description": """Plant 250 seedlings of Tamil Nadu's official state tree, the resilient Palmyra Palm (Borassus flabellifer).
Palmyra palms are living ecological fortresses: their deep taproots bind sandy soil, prevent erosion, and elevate groundwater tables.
Volunteers will plant along the perimeter lakeshore and agricultural fields of the expansive VIT Vellore campus.
Learn traditional Tamil ecological knowledge regarding the 800+ uses of the Palmyra palm in sustainable rural livelihoods.
Seedlings require zero chemical fertilizer and thrive on minimal monsoon rainfall once their deep roots establish.
Digging tools, organic compost, palm seedling baskets, and protective sun wear are provided.
Special keynote address by Tamil Nadu traditional agro-forestry experts prior to the field plantation.
Leave a 100-year ecological legacy on campus while earning 560 GreenKarma coins!""",
          "location": "South Agricultural Plots & Lake Perimeter, VIT Vellore",
          "communityName": "Tamil Nadu Heritage & Forestry Guild",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_mega_hostel_audit",
          "title": "Mega-Hostel Smart Sub-Metering & Energy Conservation Hackathon",
          "type": "Energy Efficiency",
          "points": 490,
          "participants": [],
          "date": now.add(const Duration(days: 11)),
          "endDate": now.add(const Duration(days: 11, hours: 3)),
          "imageUrl": "assets/images/planning.png",
          "description": """Audit electrical consumption across the towering Mens and Womens Hostel blocks housing over 30,000 students.
Analyze real-time data from IoT smart energy sub-meters, identifying phantom standby power and HVAC cooling waste.
Students will write algorithms that predict hostel block load peaks and recommend automated thermostat duty cycling.
Hostel blocks will compete to reduce electricity draw during evening hours, with live standings shown on student dashboards.
A 10% reduction across VIT mega-hostels saves megawatts of thermal power and thousands of kilograms of daily carbon emissions!
Mentors from the School of Electrical Engineering will guide energy modeling and data analysis.
Laptops, energy logger telemetry APIs, and late-night snacks provided at the hackathon hub.
Top student teams will see their load-shedding algorithms implemented in the university facilities management system.""",
          "location": "Technology Tower & Mens Hostel Block R, VIT Vellore",
          "communityName": "Smart Grid & Energy Society",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_bicycle_corridor",
          "title": "Katpadi Junction to VIT Campus Green Bicycle Corridor Campaign",
          "type": "Sustainable Transport",
          "points": 420,
          "participants": [],
          "date": now.add(const Duration(days: 14)),
          "endDate": now.add(const Duration(days: 14, hours: 2)),
          "imageUrl": "assets/images/seminar.png",
          "description": """Campaign for dedicated cycle lanes and pedestrian safety between Katpadi Railway Junction and VIT Main Gate.
Over 250 students and faculty will ride their bicycles in an organized green commute rally to highlight sustainable transit.
Survey commuter travel times, fuel expenditure, and roadside particulate pollution along the congested railway corridor.
Present an urban design proposal to the Vellore City Municipal Corporation for a protected 3-kilometer cycle track.
Demonstrate how cycling slashes carbon footprints while improving cardiovascular health and reducing auto-rickshaw traffic jams.
Free bicycle mechanical tune-ups, tire inflation, and reflective safety stickers provided for all participant cycles.
Water stations, fresh coconut water, and 420 GreenKarma coins awarded at the finish line outside Food Mall.
Ride your cycle and be the catalyst for clean, non-motorized mobility in Vellore!""",
          "location": "Katpadi Junction to VIT Main Gate Corridor, Vellore",
          "communityName": "VIT Pedal Power Club",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": true,
          "isCompleted": false,
          "schoolId": schoolId,
        },
        {
          "id": "${schoolId}_ewaste_soldering",
          "title": "Campus Soldering Lab Component Salvage & Green Robotics Clinic",
          "type": "Hardware Circularity",
          "points": 380,
          "participants": [],
          "date": now.subtract(const Duration(days: 4)),
          "endDate": now.subtract(const Duration(days: 4, hours: -3)),
          "imageUrl": "assets/images/cleaning.png",
          "description": """Completed high-impact electronics salvage sprint across the electrical and electronics engineering teaching labs.
Desoldered, tested, and stored over 2,200 electronic components from decommissioned breadboards and PCB prototypes.
Saved resistors, capacitors, power MOSFETs, and relays from going to landfill, distributing them to incoming project teams.
Conducted hands-on training in lead-free solder techniques, thermal dissipation management, and circuit diagnostics.
Calculated an estimated university cost savings of ₹1.8 Lakhs in new component procurement.
Unrecoverable leaded boards were safely consigned to state-authorized hazardous e-waste recycling facilities.
Participants earned 380 GreenKarma coins and praise from the Dean of Engineering for exemplary circular resource management.""",
          "location": "Technology Tower Basement Labs, VIT Vellore",
          "communityName": "VIT Robotics & Electronics Recycling Cell",
          "mapUrl": "https://maps.google.com/?q=VIT+Vellore",
          "isUpcoming": false,
          "isCompleted": true,
          "schoolId": schoolId,
        },
      ];
    }

    // Default Fallback for other campuses (IIT Bombay, etc.)
    return [
      {
        "id": "${schoolId}_ewaste_drive",
        "title": "Campus E-Waste & Component Reclamation Drive",
        "type": "Waste Management",
        "points": 500,
        "participants": [],
        "date": now.add(const Duration(days: 2)),
        "endDate": now.add(const Duration(days: 2, hours: 4)),
        "imageUrl": "assets/images/cleaning.png",
        "description": """Collect obsolete computer motherboards, broken laptop chargers, cables, and dead lithium batteries across hostels and engineering labs.
All items are routed to verified green recyclers for precious metal recovery and environmental safety.
Participate in component sorting, weighing, and cataloguing to earn valuable karma coins.
Avoid hazardous heavy metals from entering local soil and municipal landfills.
Learn safe handling and proper segregation techniques from campus sustainability experts.
All volunteers will receive protective gloves, collection sacks, and verification certificates.
Earn 500 GreenKarma coins and help your campus reach zero e-waste certification!""",
        "location": "Main Academic Plaza / Tech Courtyard",
        "communityName": "Campus Green Chapter",
        "mapUrl": "https://maps.google.com/?q=Campus+Academic+Plaza",
        "isUpcoming": true,
        "isCompleted": false,
        "schoolId": schoolId,
      },
      {
        "id": "${schoolId}_solar_audit",
        "title": "Solar Rooftop Efficiency Audit & Energy Mapping",
        "type": "Energy Transition",
        "points": 450,
        "participants": [],
        "date": now.add(const Duration(days: 5)),
        "endDate": now.add(const Duration(days: 5, hours: 3)),
        "imageUrl": "assets/images/planning.png",
        "description": """Student-led audit assessing solar panel tilt angles, dust soiling losses, and inverter performance across campus building terraces.
Learn solar irradiance measurement, string inverter diagnostics, and kilowatt load balancing.
Clean soiled photovoltaic arrays using water-conserving dry microfiber brushes.
Calculate avoided campus coal emissions and upload yield statistics to the central dashboard.
A fantastic opportunity for engineering students to acquire practical clean energy technical skills.
Digital pyranometers, multimeters, and safety harness gear are provided.
Earn 450 GreenKarma coins and an official peer-reviewed certificate of solar system commissioning.""",
        "location": "Electrical Engineering Dept Terrace",
        "communityName": "Solar & Renewable Energy Tech Club",
        "mapUrl": "https://maps.google.com/?q=Electrical+Department+Terrace",
        "isUpcoming": true,
        "isCompleted": false,
        "schoolId": schoolId,
      },
      {
        "id": "${schoolId}_food_compost",
        "title": "Hostel Mess Food Waste Audit & Bio-Composting",
        "type": "Food Resilience",
        "points": 400,
        "participants": [],
        "date": now.add(const Duration(days: 8)),
        "endDate": now.add(const Duration(days: 8, hours: 2)),
        "imageUrl": "assets/images/cooking.png",
        "description": """Measure and document post-dinner food scrap volumes across student messes to prevent unnecessary organic waste.
Transfer segregated kitchen leftovers into campus aerobic composters to fertilize native gardens and eliminate landfill methane.
Mix food waste with dry carbon sawdust and natural microbial starter inoculants.
Evaluate moisture and temperature curves inside the aerobic composting drums.
Harvest rich organic humus for campus trees and botanical gardens.
Practical workshop on Bokashi fermentation and household zero-waste cooking.
Receive 400 GreenKarma coins and a complimentary bag of organic compost for your room plants.""",
        "location": "Central Dining Mess & Bio-Compost Yard",
        "communityName": "Zero-Waste Campus Coalition",
        "mapUrl": "https://maps.google.com/?q=Central+Dining+Mess",
        "isUpcoming": true,
        "isCompleted": false,
        "schoolId": schoolId,
      },
      {
        "id": "${schoolId}_miyawaki_planting",
        "title": "Miyawaki Urban Forest Planting & Biodiversity Census",
        "type": "Restoration",
        "points": 600,
        "participants": [],
        "date": now.add(const Duration(days: 12)),
        "endDate": now.add(const Duration(days: 12, hours: 4)),
        "imageUrl": "assets/images/tree.png",
        "description": """Plant 150 indigenous saplings following the rapid-growth Miyawaki dense planting technique.
Species include native Neem, Peepal, Jamun, and Karanj to expand local biodiversity and carbon absorption.
Volunteers will excavate soil beds, incorporate vermicompost, and mulch to retain moisture.
Learn seedling root architecture, spacing principles, and geotagged survival monitoring.
Miyawaki micro-forests grow 10x faster and absorb up to 30x more carbon dioxide than monocultures.
Protective gardening gloves, spades, and refreshments provided.
Earn 600 GreenKarma coins and build a permanent ecological asset for future campus generations.""",
        "location": "Campus Sports Complex (North Field)",
        "communityName": "Green Yuva Green Brigade",
        "mapUrl": "https://maps.google.com/?q=Campus+Sports+Grounds",
        "isUpcoming": true,
        "isCompleted": false,
        "schoolId": schoolId,
      },
      {
        "id": "${schoolId}_drainage_cleanup",
        "title": "Rainwater Channel Desilting & River Cleanup",
        "type": "Hydrology",
        "points": 550,
        "participants": [],
        "date": now.add(const Duration(days: 16)),
        "endDate": now.add(const Duration(days: 16, hours: 3)),
        "imageUrl": "assets/images/river.png",
        "description": """Clear debris, accumulated silt, and plastic trash from perimeter stormwater recharge ditches and retention ponds.
Ensures unhindered rainwater harvesting and aquifer replenishment before the arrival of seasonal monsoon downpours.
Measure water flow rates, turbidity levels, and plastic pollution quantities using portable sensors.
All extracted plastic will be segregated and dispatched to municipal baling facilities.
Safety boots, trash grabbers, heavy-duty gloves, and first aid kits will be provided at the site.
Gain practical field hydrology experience while protecting the local watershed.
All participants will be awarded 550 GreenKarma coins and certificates of environmental service.""",
        "location": "Campus Retention Pond & East Perimeter Ditch",
        "communityName": "Water Warriors Network",
        "mapUrl": "https://maps.google.com/?q=Campus+Retention+Pond",
        "isUpcoming": true,
        "isCompleted": false,
        "schoolId": schoolId,
      },
      {
        "id": "${schoolId}_plastic_ban_drive",
        "title": "Single-Use Plastic Eradication & Canvas Tote Drive",
        "type": "Sustainable Living",
        "points": 350,
        "participants": [],
        "date": now.subtract(const Duration(days: 3)),
        "endDate": now.subtract(const Duration(days: 3, hours: -2)),
        "imageUrl": "assets/images/seminar.png",
        "description": """Distributed reusable unbleached cotton tote bags and stainless steel glasses to campus snack stalls and departmental cafeterias.
Successfully replaced single-use polythene wrappers and disposable plastic cups across the campus.
Students conducted interactive awareness kiosks educating peers on ocean microplastic pollution.
Audit showed a 75% drop in single-use plastic waste generation in campus trash bins over one week.
Volunteers helped set up a permanent bag sharing station at the campus student convenience store.
Check out the event gallery and your GreenKarma badge rewards in the Green Yuva profile!""",
        "location": "Student Activity Centre & Food Court",
        "communityName": "Green Yuva Action League",
        "mapUrl": "https://maps.google.com/?q=Student+Activity+Centre",
        "isUpcoming": false,
        "isCompleted": true,
        "schoolId": schoolId,
      },
    ];
  }

  Future<void> joinActivity(String schoolId, String activityId, String userId) async {
    try {
      print('🎯 ActivityService: User $userId joining activity $activityId');

      final activityDoc = await getActivitiesCollection(schoolId).doc(activityId).get();
      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data() as Map<String, dynamic>;
      final points = (activityData['points'] as num?)?.toInt() ?? 0;

      print('💰 ActivityService: Activity offers $points points');

      // Atomically add the participant only if not already joined, so points
      // and the participant counter are never awarded twice.
      final activityRef = getActivitiesCollection(schoolId).doc(activityId);
      final newlyJoined = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(activityRef);
        final data = (snap.data() as Map<String, dynamic>?) ?? {};
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(userId)) return false;
        tx.update(activityRef, {
          'participants': FieldValue.arrayUnion([userId]),
          'participantCount': FieldValue.increment(1),
        });
        return true;
      });

      if (!newlyJoined) {
        print('ℹ️ ActivityService: User $userId already joined $activityId, no points awarded');
        return;
      }

      await _userService.addUserPoints(userId, points);
      await _userService.addUserAction(userId);

      print('🎉 ActivityService: Successfully joined activity and awarded $points points');
    } catch (e) {
      print('❌ ActivityService: Error joining activity: $e');
      rethrow;
    }
  }

  Future<void> leaveActivity(String schoolId, String activityId, String userId) async {
    try {
      print('👋 ActivityService: User $userId leaving activity $activityId');

      final activityDoc = await getActivitiesCollection(schoolId).doc(activityId).get();
      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data() as Map<String, dynamic>;
      final points = (activityData['points'] as num?)?.toInt() ?? 0;

      final activityRef = getActivitiesCollection(schoolId).doc(activityId);
      final wasJoined = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(activityRef);
        final data = (snap.data() as Map<String, dynamic>?) ?? {};
        final participants = List<String>.from(data['participants'] ?? []);
        if (!participants.contains(userId)) return false;
        tx.update(activityRef, {
          'participants': FieldValue.arrayRemove([userId]),
          'participantCount': FieldValue.increment(-1),
        });
        return true;
      });

      if (!wasJoined) {
        print('ℹ️ ActivityService: User $userId was not in $activityId, no points deducted');
        return;
      }

      await _userService.addUserPoints(userId, -points);

      print('✅ ActivityService: Successfully left activity');
    } catch (e) {
      print('❌ ActivityService: Error leaving activity: $e');
      rethrow;
    }
  }

  Future<bool> isUserParticipating(String schoolId, String activityId, String userId) async {
    try {
      final doc = await getActivitiesCollection(schoolId).doc(activityId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        return participants.contains(userId);
      }
      return false;
    } catch (e) {
      print('❌ ActivityService: Error checking participation: $e');
      return false;
    }
  }

  Future<bool> isUserJoinedActivity(String schoolId, String activityId, String userId) =>
      isUserParticipating(schoolId, activityId, userId);
}
