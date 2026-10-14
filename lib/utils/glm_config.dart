import '../utils/env_config.dart';

class GLMConfig {
  static Map<String, Map<String, dynamic>> get endpoints {
    return {
      'gemini': {
        'url': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        'model': 'gemini-2.5-flash',
        'headers': {
          'Content-Type': 'application/json',
        },
        'parameters': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        },
      },
      'palm': {
        'url': 'https://generativelanguage.googleapis.com/v1beta/models/chat-bison-001:generateMessage',
        'model': 'chat-bison-001',
        'headers': {
          'Content-Type': 'application/json',
        },
        'parameters': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        },
      },
      'local': {
        'url': 'local',
        'model': 'local-fallback',
        'headers': {},
        'parameters': {},
      },
    };
  }

  static const String systemPrompt = """
You are ClimaAI (YuvaSathi), an expert environmental science tutor and campus sustainability guide for Indian university and school students within the Green Yuva platform.

Green Yuva Modules:
1. YuvaVibe: Campus community forum and eco-activity groups for 8 premier Indian institutes (PCCOE Pune, IIT Bombay, COEP Tech, BITS Pilani, VIT Vellore, NIT Trichy, Manipal MIT, DTU Delhi).
2. YuvaSwap: Circular campus marketplace where students trade pre-owned textbooks, drafting kits, lab equipment, and bicycles, calculating carbon and water saved.
3. GreenRush: GPS geo-located action hubs and campus climate missions where students plant trees, conduct rooftop energy audits, verify with photos/GPS, and earn GreenKarma Coins.
4. YuvaSense: Interactive climate intelligence hub featuring 10-question topic quizzes, real-time Indian disaster tracking (IMD, CPCB, NDMA alerts), and Indian climate scientist case studies (Dr. Roxy Mathew Koll, Dr. Sunita Narain, Prof. Navroz Dubash, Dr. Chirag Dhara).
5. GreenKarma: Reward currency (Karma Coins) earned through climate actions, redeemable for eco-friendly campus perks.

Always provide accurate, educational, and actionable answers. Use Indian environmental context, government initiatives (National Solar Mission, LiFE Mission, CPCB standards), and Green Yuva module guidance.
""";

  static Map<String, dynamic>? getEndpoint(String name) {
    return endpoints[name];
  }

  static List<String> getEndpointNames() {
    return ['gemini', 'palm', 'local'];
  }

  static String getContextualFallbackResponse(String message) {
    final lower = message.toLowerCase().trim();

    // Greetings
    if (lower == 'hi' || lower == 'hello' || lower.contains('namaste') || lower.contains('who are you') || lower.contains('introduce')) {
      return """Namaste! I am ClimaAI (YuvaSathi), your dedicated environmental tutor and campus climate action guide on Green Yuva.

I can help you with:
- Understanding Green Yuva modules (YuvaVibe, YuvaSwap, GreenRush, YuvaSense, and GreenKarma)
- Preparing for Topic Quizzes & understanding climate science
- Learning about Indian climate challenges (AQI, monsoons, heatwaves, renewable energy)
- Practical steps to earn Karma Coins and organize sustainability drives on your campus!

What would you like to explore today?""";
    }

    // GreenKarma / Points
    if (lower.contains('karma') || lower.contains('coin') || lower.contains('reward') || lower.contains('point')) {
      return """🪙 GreenKarma & Karma Coins:

Karma Coins are Green Yuva's campus sustainability currency awarded when you take tangible climate actions:

1. How to Earn:
- Complete GreenRush campus missions (+50 to +150 Karma Coins)
- List or exchange pre-owned items on YuvaSwap (+75 Karma Coins)
- Score 80%+ on YuvaSense Topic Quizzes (+10 to +30 Karma Coins)
- Join and participate in YuvaVibe campus drives (+40 Karma Coins)

2. Leaderboard & Rewards:
- Your Karma Coins determine your rank on the campus and All-India Leaderboards.
- Accumulated coins can be redeemed for sustainable campus vouchers, cafeteria discounts, and eco-merchandise!""";
    }

    // YuvaSwap / Marketplace
    if (lower.contains('swap') || lower.contains('market') || lower.contains('exchange') || lower.contains('sell') || lower.contains('book')) {
      return """🔄 YuvaSwap — Circular Campus Marketplace:

YuvaSwap allows students across Indian institutes to exchange, donate, or purchase pre-owned academic items rather than buying new ones:

- What you can swap: Engineering textbooks, lab coats, drafting mini-drafters, scientific calculators, bicycles, and electronics.
- Environmental Impact: Every item reused prevents manufacturing emissions. For example, reusing one engineering textbook saves ~1.5 kg CO2 and 1,200 liters of fresh water!
- How to use: Tap "+ List Item" on YuvaSwap, select your campus (e.g. PCCOE Pune, IIT Bombay, COEP), enter the price in ₹ or Karma Coins, and upload a photo.""";
    }

    // GreenRush / GPS Missions
    if (lower.contains('rush') || lower.contains('greenrush') || lower.contains('mission') || lower.contains('gps') || lower.contains('map') || lower.contains('hub')) {
      return """🎮 GreenRush — GPS Map & Campus Action Hubs:

GreenRush turns campus sustainability into an interactive, real-world exploration game:

1. Action Hubs: Explore geo-fenced campus locations at PCCOE Pune, IIT Bombay, COEP, BITS Pilani, VIT Vellore, and DTU.
2. Live Missions: Tap on any hub marker to discover high-impact tasks such as:
   - Rooftop Solar Efficiency Audit (+120 Karma Coins)
   - Miyawaki Urban Afforestation Drive (+150 Karma Coins)
   - Mess Food Waste Composting (+100 Karma Coins)
   - E-Waste Segregation Audit (+80 Karma Coins)
3. Verification: Complete the task, upload verification evidence, and earn instant Karma Coins!""";
    }

    // YuvaVibe / Community
    if (lower.contains('vibe') || lower.contains('yuvavibe') || lower.contains('community') || lower.contains('college') || lower.contains('school') || lower.contains('pccoe') || lower.contains('iit')) {
      return """🤝 YuvaVibe — School Community & Social Feed:

YuvaVibe is your campus hub for peer discussions, organizing environmental campaigns, and sharing sustainability wins:

- Integrated Campuses: PCCOE — Pune, IIT Bombay — Mumbai, COEP Technological University — Pune, BITS Pilani, VIT Vellore, NIT Trichy, Manipal Institute of Technology, and DTU — Delhi.
- Activities: Join live campus initiatives like E-Waste Drives, Solar Audits, and Tree Plantations.
- Join the Discussion: Post ideas, comment on campus initiatives, and tag student groups to drive collective green impact!""";
    }

    // YuvaSense / Quizzes / Disasters
    if (lower.contains('sense') || lower.contains('yuvasense') || lower.contains('quiz') || lower.contains('disaster') || lower.contains('climasight') || lower.contains('case study')) {
      return """⚡ YuvaSense (ClimaSight) — Climate Intelligence Hub:

YuvaSense combines real-time data with rigorous learning through three specialized sections:

1. Topic Quizzes: Complete 10-question masterclasses on Carbon Footprint, Renewable Energy, SDG 13, and Circular Economy to earn Karma Coins.
2. Disaster Tracker: Real-time early warning bulletins linked to IMD (cyclone/rainfall alerts), CPCB (AQI tracking), and NDMA (landslide advisories) for Indian geography.
3. Case Studies: Explore pioneering research by leading Indian scientists including Dr. Roxy Mathew Koll (IITM Pune, Ocean Warming), Dr. Sunita Narain (CSE, Clean Air & Water), and Dr. Chirag Dhara (MoES Assessment Author).""";
    }

    // Air Quality / Smog / Delhi
    if (lower.contains('air') || lower.contains('aqi') || lower.contains('pollution') || lower.contains('smog') || lower.contains('stubble') || lower.contains('pm2.5')) {
      return """🌫️ Air Quality & Particulate Pollution in India:

- The Challenge: During winter, Indo-Gangetic plains face severe AQI (350-450+) due to a combination of meteorological temperature inversions, farm stubble burning, vehicular emissions, and dust.
- PM2.5 & PM10: Microscopic particulates smaller than 2.5 micrometers penetrate deep into lungs and bloodstream, causing serious cardiopulmonary risks.
- Solutions: Stubble bio-decomposers (developed by IARI Pusa), Happy Seeders for zero-till sowing, electrification of public buses, smog towers, and CPCB GRAP (Graded Response Action Plan) stages I-IV.""";
    }

    // Landslides / Western Ghats / Kerala
    if (lower.contains('landslide') || lower.contains('wayanad') || lower.contains('kerala') || lower.contains('ghat')) {
      return """⛰️ Western Ghats Landslide Risks & Slope Dynamics:

- Recent Events: Catchments like Wayanad and Idukki experience intense localized cloudburst events where saturated topsoil on deforested slopes loses cohesion, triggering debris flows.
- Scientific Cause: Studies by IITM Pune show Arabian Sea warming has intensified pre-monsoon and monsoon precipitation bursts over narrow coastal ranges.
- Mitigation: Restoring native deep-rooted root networks (Miyawaki method), enforcing Gadgil/Kasturirangan Committee ecological zoning, and installing NDMA geotechnical sensor telemetry.""";
    }

    // Cyclones / Bay of Bengal
    if (lower.contains('cyclone') || lower.contains('bay of bengal') || lower.contains('typhoon') || lower.contains('storm')) {
      return """🌀 Bay of Bengal Cyclones & Coastal Resilience:

- Ocean Warming: The Bay of Bengal and Arabian Sea have seen elevated sea surface temperatures (>29°C), facilitating rapid intensification of storms within 24 hours (e.g., Cyclone Dana, Biparjoy).
- Early Warning: IMD's Doppler Radar network provides 3-hour track forecasts with over 90% landfall precision.
- Nature-based Defense: Restoring Sundarbans and coastal mangrove forests reduces storm surge height by up to 60%, buffering coastal fishing panchayats.""";
    }

    // Renewable Energy / Solar
    if (lower.contains('solar') || lower.contains('renewable') || lower.contains('energy') || lower.contains('wind') || lower.contains('500 gw')) {
      return """☀️ India's Renewable Energy Revolution:

- National Target: India has committed to achieving 500 GW of non-fossil energy capacity by 2030 and net-zero emissions by 2070.
- Solar Parks: Flagship projects like Bhadla Solar Park (Rajasthan, 2.25 GW) and Pavagada Solar Park (Karnataka) are among the largest in the world.
- Campus Action: Colleges in Maharashtra and Karnataka are installing rooftop photovoltaic (RTPV) panels, reducing campus electricity expenses by 40% while qualifying for Green Campus certifications!""";
    }

    // Carbon Footprint
    if (lower.contains('carbon') || lower.contains('footprint') || lower.contains('emission') || lower.contains('co2')) {
      return """👣 Understanding & Slashing Your Carbon Footprint:

- Global vs India: The average Indian emits ~1.9 tonnes of CO2/year, compared to the global average of ~4.7 tonnes and US average of ~15 tonnes.
- Key Contributors: Campus electricity (coal-dominated grid), daily motorcycle/cab commutes, single-use food packaging, and consumer electronics turnover.
- Top 3 Campus Reductions:
  1. Switch to bicycles or public transit for hostel-campus travel.
  2. Source textbooks and equipment via YuvaSwap to eliminate supply-chain emissions.
  3. Eliminate single-use plastics in canteens by carrying reusable bottles and dabbas.""";
    }

    // Waste Management & Recycling
    if (lower.contains('waste') || lower.contains('plastic') || lower.contains('recycle') || lower.contains('compost') || lower.contains('segregat')) {
      return """♻️ Zero-Waste Campus & Segregation Guidelines:

- 3-Stream Segregation: Blue (Dry/Recyclable paper, plastic, metal), Green (Wet/Biodegradable food scraps), and Red/Black (E-Waste and Hazardous sanitary items).
- Composting: University mess halls generate up to 200 kg of food waste daily. Aerobic composting pits convert this into nitrogen-rich organic fertilizer for campus gardens in 45 days.
- Plastic Ban: Under India's Plastic Waste Management Rules, single-use plastic cutlery, straws, and polybags <120 microns are legally banned across campuses.""";
    }

    // Fallback general
    return """🌱 Climate & Sustainability Insight:

Every step toward sustainability matters—especially when led by students across India's top colleges. Whether you are cutting food waste in hostel messes, auditing campus energy efficiency in GreenRush, or participating in YuvaVibe afforestation drives, collective youth action accelerates India's net-zero transition.

Ask me specific questions about GreenRush missions, YuvaSwap marketplace, quiz preparation, or Indian environmental science!""";
  }
}
