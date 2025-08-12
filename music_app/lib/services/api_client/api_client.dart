import 'dart:convert';

import 'package:xml2json/xml2json.dart';
import 'package:http/http.dart' as http;
import 'api_note.dart';

class ApiClient {
  static final ApiClient inst = ApiClient._init();
  ApiClient._init();

  Future<List<String>> fetchSuggestions(String query) async {
    List<String> suggestions = [];
    const region = null; // await LocalStore.instance.getRegion();
    String baseUrl = ApiNote.getSuggestion;
    baseUrl = baseUrl.replaceAll(':hl', region?.code ?? 'en');

    var client = http.Client();
    final myTranformer = Xml2Json();
    var response = await client.get(Uri.parse(baseUrl + query));
    var body = response.body;
    myTranformer.parse(body);
    var data = myTranformer.toGData();
    var jsonData = jsonDecode(data);

    var toplevel = jsonData['toplevel'];
    if (toplevel.containsKey('CompleteSuggestion')) {
      List? suggestionsData = toplevel['CompleteSuggestion'];
      for (var suggestion in suggestionsData!) {
        suggestions.add(suggestion['suggestion']['data'].toString());
      }
    }

    return suggestions;
  }
}
