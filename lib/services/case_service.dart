import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/case.dart';
import '../utils/env_config.dart';
import '../utils/populate_cases.dart';

class CaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _climateKeywords = [
    'flood victim', 'drought victim', 'wildfire victim', 'hurricane victim',
    'landslide victim', 'tsunami victim', 'extreme weather victim',
    'climate refugee', 'environmental refugee', 'disaster victim',
    'lost home flood', 'lost home wildfire', 'lost home hurricane',
    'displaced by climate', 'climate migration', 'climate displacement'
  ];

  static const List<String> _excludeKeywords = [
    'climate policy', 'climate summit', 'climate agreement', 'climate conference',
    'climate scientist', 'climate research', 'climate study', 'climate report',
    'climate data', 'climate model', 'climate prediction', 'climate forecast'
  ];

  static Future<List<Case>> getCases() async {
    try {
      print('📰 CaseService: Fetching cases from Firebase...');
      final snapshot = await _firestore.collection('cases')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final cases = snapshot.docs.map((doc) {
        final data = doc.data();
        return Case.fromJson({...data, 'id': doc.id});
      }).toList();

      print('✅ CaseService: Loaded ${cases.length} cases from Firebase');
      return cases;
    } catch (e) {
      print('❌ CaseService: Error fetching cases: $e');
      return [];
    }
  }

  static Future<List<Case>> getCasesWithFallback() async {
    final indianCases = _createSampleCases();
    final List<Case> additionalCases = [];

    try {
      print('📰 CaseService: Fetching cases from Firebase...');
      final firebaseCases = await getCases();
      for (final c in firebaseCases) {
        final isDuplicate = indianCases.any((ic) =>
            ic.personName.toLowerCase().trim() == c.personName.toLowerCase().trim() ||
            ic.story.toLowerCase().trim() == c.story.toLowerCase().trim());
        if (!isDuplicate) {
          additionalCases.add(c);
        }
      }
    } catch (e) {
      print('⚠️ CaseService: Firebase fetch error: $e');
    }

    if (additionalCases.isEmpty) {
      try {
        final gNewsCases = await _fetchFromGNews();
        for (final c in gNewsCases) {
          final isDuplicate = indianCases.any((ic) =>
              ic.personName.toLowerCase().trim() == c.personName.toLowerCase().trim());
          if (!isDuplicate) {
            additionalCases.add(c);
          }
        }
      } catch (e) {
        print('⚠️ CaseService: GNews fetch error: $e');
      }
    }

    // ALWAYS return authentic Indian climate cases FIRST, followed by additional remote cases
    print('✅ CaseService: Returning ${indianCases.length} Indian cases + ${additionalCases.length} additional cases');
    return [...indianCases, ...additionalCases];
  }

  static Future<void> populateFirebaseWithSampleCases() async {
    try {
      print('🔥 CaseService: Populating Firebase with sample cases...');
      await PopulateCases.populateWithSampleCases();
      print('✅ CaseService: Successfully populated Firebase with sample cases');
    } catch (e) {
      print('❌ CaseService: Error populating Firebase: $e');
    }
  }

  static Future<void> addCaseToFirebase(Case caseData) async {
    try {
      await _firestore.collection('cases').add(caseData.toJson());
      print('✅ CaseService: Added case to Firebase: ${caseData.personName}');
    } catch (e) {
      print('❌ CaseService: Error adding case to Firebase: $e');
    }
  }

  static Future<void> fetchAndProcessNews() async {
    try {
      print('🔄 CaseService: Fetching climate victim news from APIs...');

      final cases = await _fetchFromNewsAPI();

      for (final caseData in cases) {
        await _saveCaseToFirebase(caseData);
      }

      print('✅ CaseService: Processed and saved ${cases.length} cases from API');
    } catch (e) {
      print('❌ CaseService: Error fetching news: $e');
    }
  }

  static List<Case> getIndianCases() => _createSampleCases();

  static List<Case> _createSampleCases() {
    return [
      Case(
        id: 'indian_case_1',
        personName: 'Rewa Ultra Mega Solar Park',
        story: 'Asia\'s flagship 750 MW single-site solar power project powering Delhi Metro and reducing 1.5M tonnes of CO₂ annually.',
        climateEvent: 'Solar Energy & Grid Decarbonization',
        location: 'Rewa, Madhya Pradesh, India',
        impact: '750 MW Capacity',
        date: DateTime.now().subtract(const Duration(days: 1)),
        sourceUrl: 'https://rewa.nic.in/',
        imageUrl: 'https://images.unsplash.com/photo-1509391365360-2e959784a276?auto=format&fit=crop&w=600&q=80',
        severity: 'high',
        source: 'Rewa Ultra Mega Solar Ltd (RUMSL)',
        isReviewed: true,
        description: 'Pioneered utility-scale solar generation in India. Provides clean power to the Delhi Metro Rail Corporation (DMRC), setting benchmark low solar tariffs across South Asia.',
      ),
      Case(
        id: 'indian_case_2',
        personName: 'Indore Zero-Waste & Bio-CNG Model',
        story: '100% door-to-door waste segregation fueling Asia\'s largest Gobar-Dhan Bio-CNG plant for city public transit.',
        climateEvent: 'Circular Economy & Waste Management',
        location: 'Indore, Madhya Pradesh, India',
        impact: '550 TPD Bio-CNG',
        date: DateTime.now().subtract(const Duration(days: 2)),
        sourceUrl: 'https://indoremunicipalcorporation.org/',
        imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80',
        severity: 'high',
        source: 'Indore Municipal Corporation',
        isReviewed: true,
        description: 'Voted India\'s cleanest city 6 years in a row. Segregates municipal waste into 6 streams at source, converting 550 tonnes of wet waste daily into Bio-CNG for 400+ city buses.',
      ),
      Case(
        id: 'indian_case_3',
        personName: 'Sikkim 100% Organic State Policy',
        story: 'World\'s first 100% organic state eliminating synthetic fertilizers across 75,000 hectares of Himalayan land.',
        climateEvent: 'Sustainable Agriculture & Soil Health',
        location: 'Gangtok, Sikkim, India',
        impact: '100% Organic State',
        date: DateTime.now().subtract(const Duration(days: 3)),
        sourceUrl: 'https://sikkim.gov.in/',
        imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
        severity: 'high',
        source: 'Government of Sikkim',
        isReviewed: true,
        description: 'Awarded the UN Future Policy Award. Completely phased out chemical pesticides and synthetic fertilizers, boosting soil organic carbon and protecting fragile Himalayan eco-zones.',
      ),
      Case(
        id: 'indian_case_4',
        personName: 'Delhi Electric Vehicle (EV) Policy',
        story: 'Rapid urban transport electrification target of 25% new vehicle registrations by 2024 with 8,000+ e-buses.',
        climateEvent: 'E-Mobility & Urban Air Quality',
        location: 'New Delhi, Delhi NCR, India',
        impact: '8,000+ E-Buses',
        date: DateTime.now().subtract(const Duration(days: 4)),
        sourceUrl: 'https://ev.delhi.gov.in/',
        imageUrl: 'https://images.unsplash.com/photo-1558441719-aa34bf57312c?auto=format&fit=crop&w=600&q=80',
        severity: 'high',
        source: 'Delhi Transport Department',
        isReviewed: true,
        description: 'Pioneered comprehensive urban EV incentives, charging hub networks, and bus fleet electrification to reduce transport emissions in Delhi NCR.',
      ),
      Case(
        id: 'indian_case_5',
        personName: 'Gujarat Canal-Top Solar Power Project',
        story: 'Innovative solar panels mounted atop Narmada irrigation canals generating clean power while stopping evaporation.',
        climateEvent: 'Solar Power & Water Conservation',
        location: 'Charanka & Narmada Canals, Gujarat, India',
        impact: 'Zero Land Footprint',
        date: DateTime.now().subtract(const Duration(days: 5)),
        sourceUrl: 'https://geda.gujarat.gov.in/',
        imageUrl: 'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?auto=format&fit=crop&w=600&q=80',
        severity: 'medium',
        source: 'Gujarat Energy Development Agency',
        isReviewed: true,
        description: 'Eliminates land acquisition requirements by utilizing canal top space, conserving millions of liters of irrigation water from evaporation annually.',
      ),
      Case(
        id: 'indian_case_6',
        personName: 'Sundarbans Coastal Mangrove Restoration',
        story: 'Community-led planting of 15 million+ native mangroves to create bio-shields against Bay of Bengal cyclones.',
        climateEvent: 'Coastal Protection & Carbon Sinks',
        location: 'Sundarbans Biosphere, West Bengal, India',
        impact: '15M+ Mangroves Planted',
        date: DateTime.now().subtract(const Duration(days: 6)),
        sourceUrl: 'https://westbengalforest.gov.in/',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80',
        severity: 'high',
        source: 'West Bengal Forest Department',
        isReviewed: true,
        description: 'Restores mangrove forest cover across vulnerable estuarine islands, shielding 4.5 million coastal residents while sequestering blue carbon.',
      ),
    ];
  }

  static Future<List<Case>> _fetchFromNewsAPI() async {
    try {
      final apiKey = EnvConfig.newsApiKey;
      if (apiKey.isEmpty) return [];

      final keyword = 'climate refugee';
      final url = 'https://newsapi.org/v2/everything?'
          'q=$keyword&'
          'language=en&'
          'sortBy=publishedAt&'
          'pageSize=5&'
          'apiKey=$apiKey';

      print('📡 CaseService: Fetching from NewsAPI with keyword: $keyword');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processNewsAPIResponse(data);
      } else {
        print('❌ CaseService: NewsAPI error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ CaseService: NewsAPI error: $e');
    }
    return [];
  }

  static Future<List<Case>> _fetchFromGNews() async {
    try {
      final apiKey = EnvConfig.gNewsApiKey;
      if (apiKey.isEmpty) return [];

      final effectiveKeywords = [
        'India climate', 'India flood', 'India heatwave', 'India solar', 'India renewable'
      ];

      final keywords = effectiveKeywords.join(' OR ');
      final url = 'https://gnews.io/api/v4/search?'
          'q=$keywords&'
          'lang=en&'
          'country=in&'
          'max=10&'
          'apikey=$apiKey';

      print('📡 CaseService: Fetching from GNews with keywords: $keywords');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processGNewsResponse(data);
      } else {
        print('❌ CaseService: GNews error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ CaseService: GNews error: $e');
    }
    return [];
  }

  static List<Case> _processNewsAPIResponse(Map<String, dynamic> data) {
    final cases = <Case>[];
    final articles = data['articles'] as List? ?? [];

    for (final article in articles) {
      if (_isValidClimateStory(article['title'] ?? '', article['description'] ?? '')) {
        final caseData = _extractCaseFromArticle(article, 'NewsAPI');
        if (caseData != null) {
          cases.add(caseData);
        }
      }
    }
    return cases;
  }

  static List<Case> _processGNewsResponse(Map<String, dynamic> data) {
    final cases = <Case>[];
    final articles = data['articles'] as List? ?? [];

    for (final article in articles) {
      if (_isValidClimateStory(article['title'] ?? '', article['content'] ?? '')) {
        final caseData = _extractCaseFromArticle(article, 'GNews');
        if (caseData != null) {
          cases.add(caseData);
        }
      }
    }
    return cases;
  }

  static bool _isValidClimateStory(String title, String content) {
    final text = '${title.toLowerCase()} ${content.toLowerCase()}';

    final hasClimateKeyword = _climateKeywords.any((keyword) =>
        text.contains(keyword.toLowerCase()));

    final hasExcludeKeyword = _excludeKeywords.any((keyword) =>
        text.contains(keyword.toLowerCase()));

    return hasClimateKeyword && !hasExcludeKeyword;
  }

  static Case? _extractCaseFromArticle(Map<String, dynamic> article, String source) {
    try {
      final title = article['title'] ?? '';
      final content = article['content'] ?? article['description'] ?? '';
      final url = article['url'] ?? '';
      final publishedAt = article['publishedAt'] ?? '';
      final imageUrl = article['urlToImage'];

      final personName = _extractPersonName(title, content);

      final climateEvent = _extractClimateEvent(title, content);

      final location = _extractLocation(title, content);

      final impact = _extractImpact(title, content);

      if (personName.isNotEmpty && climateEvent.isNotEmpty) {
        return Case(
          id: '',
          personName: personName,
          story: title,
          climateEvent: climateEvent,
          location: location,
          impact: impact,
          date: DateTime.tryParse(publishedAt) ?? DateTime.now(),
          sourceUrl: url,
          imageUrl: imageUrl,
          severity: _determineSeverity(title, content),
          source: source,
        );
      }
    } catch (e) {
      print('❌ CaseService: Error extracting case: $e');
    }
    return null;
  }

  static String _extractPersonName(String title, String content) {
    final namePattern = RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b');
    final matches = namePattern.allMatches('$title $content');
    return matches.isNotEmpty ? matches.first.group(0) ?? '' : '';
  }

  static String _extractClimateEvent(String title, String content) {
    final climateEvents = [
      'flooding', 'drought', 'wildfire', 'hurricane', 'typhoon',
      'sea level rise', 'extreme heat', 'climate change', 'global warming',
      'extreme weather', 'climate disaster', 'environmental disaster'
    ];

    final text = '$title $content'.toLowerCase();
    for (final event in climateEvents) {
      if (text.contains(event)) {
        return event.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      }
    }
    return 'Climate Event';
  }

  static String _extractLocation(String title, String content) {
    final locationPattern = RegExp(r'\b[A-Z][a-z]+(?: [A-Z][a-z]+)*,? [A-Z]{2}\b');
    final matches = locationPattern.allMatches('$title $content');
    return matches.isNotEmpty ? matches.first.group(0) ?? '' : 'Unknown Location';
  }

  static String _extractImpact(String title, String content) {
    final impacts = [
      'lost home', 'displaced', 'injured', 'missing', 'died',
      'lost livelihood', 'forced to move', 'evacuated', 'homeless'
    ];

    final text = '$title $content'.toLowerCase();
    for (final impact in impacts) {
      if (text.contains(impact)) {
        return impact.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      }
    }
    return 'Affected by Climate Event';
  }

  static String _determineSeverity(String title, String content) {
    final text = '$title $content'.toLowerCase();
    final highSeverityWords = ['died', 'death', 'fatal', 'killed', 'dead'];
    final mediumSeverityWords = ['injured', 'hospitalized', 'serious', 'critical'];

    if (highSeverityWords.any((word) => text.contains(word))) {
      return 'high';
    } else if (mediumSeverityWords.any((word) => text.contains(word))) {
      return 'medium';
    }
    return 'low';
  }

  static Future<void> _saveCaseToFirebase(Case caseData) async {
    try {

      final existing = await _firestore.collection('cases')
          .where('personName', isEqualTo: caseData.personName)
          .where('climateEvent', isEqualTo: caseData.climateEvent)
          .where('date', isEqualTo: Timestamp.fromDate(caseData.date))
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('cases').add(caseData.toJson());
        print('✅ CaseService: Saved new case: ${caseData.personName}');
      }
    } catch (e) {
      print('❌ CaseService: Error saving case: $e');
    }
  }

  static Future<void> markCaseAsReviewed(String caseId, String userId) async {
    try {
      await _firestore.collection('cases').doc(caseId).update({
        'isReviewed': true,
        'reviewedBy': userId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ CaseService: Error marking case as reviewed: $e');
    }
  }
}