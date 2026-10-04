import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/disaster_event.dart';
import '../utils/env_config.dart';

class NewsService {

  static String get _newsApiKey => EnvConfig.newsApiKey;
  static String get _gNewsApiKey => EnvConfig.gNewsApiKey;

  static const String _newsApiBaseUrl = 'https://newsapi.org/v2';
  static const String _gNewsBaseUrl = 'https://gnews.io/api/v4';

  static const Map<String, String> _disasterTypeMapping = {
    'hurricane': 'HURRICANE',
    'typhoon': 'TYPHOON',
    'earthquake': 'EARTHQUAKE',
    'flood': 'FLOOD',
    'wildfire': 'WILDFIRE',
    'drought': 'DROUGHT',
    'landslide': 'LANDSLIDE',
    'tsunami': 'TSUNAMI',
    'volcanic': 'VOLCANIC ERUPTION',
    'tornado': 'TORNADO',
    'storm': 'STORM',
    'cyclone': 'CYCLONE',
  };

  static Future<List<DisasterEvent>> fetchClimateNews() async {
    try {
      print('🌍 Fetching real-time climate news from APIs...');
      final List<DisasterEvent> events = [];

      if (EnvConfig.enableNewsApi) {
        try {
          final newsApiEvents = await _fetchFromNewsAPI();
          events.addAll(newsApiEvents);
          print('✅ NewsAPI: Fetched ${newsApiEvents.length} events');
        } catch (e) {
          print('❌ NewsAPI error: $e');
        }
      } else {
        print('⚠️ NewsAPI disabled via toggle, skipping NewsAPI data');
      }

      try {
        final gNewsEvents = await _fetchFromGNews();
        events.addAll(gNewsEvents);
        print('✅ GNews: Fetched ${gNewsEvents.length} events');
      } catch (e) {
        print('❌ GNews error: $e');
      }

      if (events.isNotEmpty) {
        events.sort((a, b) => b.date.compareTo(a.date));
        print('🎉 Successfully fetched ${events.length} real climate events');
        return events;
      }

      print('⚠️ Using sample data as fallback');
      return _getSampleDisasterEvents();
    } catch (e) {
      print('❌ Error fetching climate news: $e');
      return _getSampleDisasterEvents();
    }
  }

  static Future<void> launchSourceUrl(String url) async {
    try {
      print('🔗 Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Successfully launched URL');
      } else {
        print('❌ Could not launch URL: $url');

        throw Exception('Unable to open link. Please check your internet connection.');
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      rethrow;
    }
  }

  static Future<List<DisasterEvent>> _fetchFromNewsAPI() async {
    try {
      final List<DisasterEvent> events = [];

      final focusedQuery = 'climate disaster OR natural disaster OR hurricane OR earthquake OR flood OR wildfire OR extreme weather';

      final response = await http.get(
        Uri.parse('$_newsApiBaseUrl/everything?q=$focusedQuery&sortBy=publishedAt&language=en&pageSize=20&sources=bbc-news,cnn,reuters,associated-press,the-guardian-uk,abc-news&apiKey=$_newsApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        for (var article in articles) {
          final event = _parseNewsAPIArticle(article);
          if (event != null) {
            events.add(event);
          }
        }
      } else if (response.statusCode == 429) {
        print('⚠️ NewsAPI rate limit exceeded, skipping NewsAPI data');
      } else {
        print('❌ NewsAPI error ${response.statusCode}: ${response.body}');
      }

      return events;
    } catch (e) {
      print('Error fetching from NewsAPI: $e');
      return [];
    }
  }

  static Future<List<DisasterEvent>> _fetchFromGNews() async {
    try {
      final List<DisasterEvent> events = [];

      final response = await http.get(
        Uri.parse('$_gNewsBaseUrl/search?q=climate+change+disaster+weather&lang=en&country=us&max=20&apikey=$_gNewsApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        for (var article in articles) {
          final event = _parseGNewsArticle(article);
          if (event != null) {
            events.add(event);
          }
        }
      } else if (response.statusCode == 429) {
        print('⚠️ GNews API rate limit exceeded, skipping GNews data');
      }

      return events;
    } catch (e) {
      print('Error fetching from GNews: $e');
      return [];
    }
  }

  static DisasterEvent? _parseNewsAPIArticle(Map<String, dynamic> article) {
    try {
      final title = article['title'] ?? '';
      final description = article['description'] ?? '';
      final content = article['content'] ?? '';
      final url = article['url'] ?? '';
      final imageUrl = article['urlToImage'] ?? '';
      final publishedAt = article['publishedAt'] ?? '';

      final disasterType = _extractDisasterType('$title $description $content');
      final location = _extractLocation('$title $description $content');
      final casualties = _extractCasualties('$title $description $content');
      final damage = _extractDamage('$title $description $content');

      return DisasterEvent(
        id: url.hashCode.toString(),
        title: title,
        description: description.isNotEmpty ? description : content.substring(0, content.length > 200 ? 200 : content.length),
        location: location,
        type: disasterType,
        date: DateTime.tryParse(publishedAt) ?? DateTime.now(),
        casualties: casualties,
        damage: damage,
        imageUrl: imageUrl,
        sourceUrl: url,
      );
    } catch (e) {
      print('Error parsing NewsAPI article: $e');
      return null;
    }
  }

  static DisasterEvent? _parseGNewsArticle(Map<String, dynamic> article) {
    try {
      final title = article['title'] ?? '';
      final description = article['description'] ?? '';
      final content = article['content'] ?? '';
      final url = article['url'] ?? '';
      final imageUrl = article['image'] ?? '';
      final publishedAt = article['publishedAt'] ?? '';

      final disasterType = _extractDisasterType('$title $description $content');
      final location = _extractLocation('$title $description $content');
      final casualties = _extractCasualties('$title $description $content');
      final damage = _extractDamage('$title $description $content');

      return DisasterEvent(
        id: url.hashCode.toString(),
        title: title,
        description: description.isNotEmpty ? description : content.substring(0, content.length > 200 ? 200 : content.length),
        location: location,
        type: disasterType,
        date: DateTime.tryParse(publishedAt) ?? DateTime.now(),
        casualties: casualties,
        damage: damage,
        imageUrl: imageUrl,
        sourceUrl: url,
      );
    } catch (e) {
      print('Error parsing GNews article: $e');
      return null;
    }
  }

  static String _extractDisasterType(String text) {
    final lowerText = text.toLowerCase();

    for (var entry in _disasterTypeMapping.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'CLIMATE EVENT';
  }

  static String _extractLocation(String text) {
    final locations = [
      'Seoul', 'Busan', 'Gangnam', 'Jeju-do', 'Pacific Ocean',
      'South Korea', 'Japan', 'Philippines', 'United States',
      'California', 'Florida', 'Texas', 'New York'
    ];

    for (String location in locations) {
      if (text.contains(location)) {
        return location;
      }
    }

    return 'Global';
  }

  static String _extractCasualties(String text) {
    final casualtiesPattern = RegExp(r'(\d+)\s*(?:people\s*)?(?:dead|killed|injured|missing)', caseSensitive: false);
    final match = casualtiesPattern.firstMatch(text);

    if (match != null) {
      return '${match.group(1)} people affected';
    }

    return 'Information not available';
  }

  static String _extractDamage(String text) {
    final damagePattern = RegExp(r'(\d+)\s*(?:buildings|homes|structures)\s*(?:damaged|destroyed)', caseSensitive: false);
    final match = damagePattern.firstMatch(text);

    if (match != null) {
      return '${match.group(1)} buildings damaged';
    }

    return 'Damage assessment ongoing';
  }

      static List<DisasterEvent> _getSampleDisasterEvents() {
    return [
      DisasterEvent(
        id: 'in_1',
        title: 'IMD Alert: Western Disturbance Heavy Precipitation Warning',
        description: 'India Meteorological Department issues orange alert for intense rainfall, flash floods, and cloudburst vulnerability across Western Himalayan catchments.',
        location: 'Himachal Pradesh & Uttarakhand, India',
        type: 'FLOOD',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        casualties: 'Vulnerable settlements alerted',
        damage: 'Hill road transit disrupted',
        imageUrl: 'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80',
        sourceUrl: 'https://mausam.imd.gov.in/',
      ),
      DisasterEvent(
        id: 'in_2',
        title: 'CPCB Air Quality Bulletin: Severe Winter Smog & Particulate Spike',
        description: 'Central Pollution Control Board records AQI exceeding 380 (Very Poor to Severe) across Indo-Gangetic plains; Stage-IV GRAP mitigation protocols activated.',
        location: 'Delhi-NCR & Northern Plains, India',
        type: 'AIR QUALITY',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        casualties: 'High respiratory health advisory',
        damage: 'Construction activities restricted',
        imageUrl: 'https://images.unsplash.com/photo-1576487246293-1383329b35b6?auto=format&fit=crop&w=800&q=80',
        sourceUrl: 'https://cpcb.nic.in/',
      ),
      DisasterEvent(
        id: 'in_3',
        title: 'NDMA Advisory: Western Ghats Slopes & Landslide Vulnerability',
        description: 'National Disaster Management Authority releases geotechnical slope stability report and early warning evacuation protocols for fragile ghat valleys.',
        location: 'Wayanad & Idukki, Kerala, India',
        type: 'LANDSLIDE',
        date: DateTime.now().subtract(const Duration(hours: 9)),
        casualties: 'Precautionary transit guidelines issued',
        damage: 'Topsoil saturation monitoring',
        imageUrl: 'https://images.unsplash.com/photo-1545645591-6671c6670876?auto=format&fit=crop&w=800&q=80',
        sourceUrl: 'https://ndma.gov.in/Natural-Hazards/Landslide',
      ),
      DisasterEvent(
        id: 'in_4',
        title: 'Bay of Bengal Cyclonic Storm Watch & Coastal Preparedness',
        description: 'Deep depression in Bay of Bengal tracked heading toward eastern seaboard. Fishermen advised against venture; coastal district NDRF units deployed.',
        location: 'Odisha & Andhra Pradesh Coastline, India',
        type: 'TYPHOON',
        date: DateTime.now().subtract(const Duration(hours: 14)),
        casualties: '12 coastal shelters activated',
        damage: 'Tidal surge embankments reinforced',
        imageUrl: 'https://images.unsplash.com/photo-1527482797697-8795b05a13fe?auto=format&fit=crop&w=800&q=80',
        sourceUrl: 'https://ndma.gov.in/Natural-Hazards/Cyclone',
      ),
      DisasterEvent(
        id: 'in_5',
        title: 'Down To Earth Special Report: High-Altitude GLOF Risk Mapping',
        description: 'Comprehensive satellite analysis reveals rapid expansion of glacial moraine dams in Eastern Himalayas, prompting automated early warning sensor installations.',
        location: 'Sikkim & Ladakh, India',
        type: 'CLIMATE EVENT',
        date: DateTime.now().subtract(const Duration(hours: 20)),
        casualties: 'Downstream river gauge alerts',
        damage: 'Hydropower diversion tunnels checked',
        imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
        sourceUrl: 'https://www.downtoearth.org.in/',
      ),
    ];
  }
}