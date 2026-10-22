import 'package:flutter_test/flutter_test.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/continueWatchedResponse.dart';

void main() {
  group('Continue Watching Response Parsing Tests', () {
    test('parses response when backend returns success: true and data list', () {
      final jsonResponse = {
        "message": "Continue watching fetched",
        "statusCode": 200,
        "success": true,
        "data": [
          {
            "id": 101,
            "title": "Inception",
            "type": "MOVIE",
            "watchedSeconds": 300,
            "watchedPercentage": 45,
          },
          {
            "id": 102,
            "title": "Interstellar",
            "type": "MOVIE",
            "watched_seconds": 600,
            "contentPercentage": 50,
          }
        ]
      };

      final response = ContinueWatchedResponse.fromJson(jsonResponse);

      expect(response.isSuccess, isTrue);
      expect(response.success, isTrue);
      expect(response.statusCode, 200);
      expect(response.data?.length, 2);

      final movie1 = response.data![0];
      expect(movie1.id, 101);
      expect(movie1.title, "Inception");
      expect(movie1.watchedSeconds, 300);
      expect(movie1.watchedPercentage, 45);

      final movie2 = response.data![1];
      expect(movie2.id, 102);
      expect(movie2.title, "Interstellar");
      expect(movie2.watchedSeconds, 600);
      expect(movie2.watchedPercentage, 50);
    });

    test('parses nested movie structure in continue watching data', () {
      final jsonResponse = {
        "message": "Success",
        "statusCode": 200,
        "isSuccess": true,
        "data": [
          {
            "watchedPercentage": 35,
            "watchedSeconds": 210,
            "movie": {
              "id": 201,
              "title": "Tenet",
              "type": "MOVIE",
            }
          }
        ]
      };

      final response = ContinueWatchedResponse.fromJson(jsonResponse);

      expect(response.isSuccess, isTrue);
      expect(response.data?.length, 1);
      final item = response.data![0];
      expect(item.id, 201);
      expect(item.title, "Tenet");
      expect(item.watchedSeconds, 210);
      expect(item.watchedPercentage, 35);
    });

    test('Content.fromJson parses alternate percentage and second keys', () {
      final json = {
        "id": 301,
        "title": "Dark Knight",
        "watched_percentage": 70,
        "watched_seconds": 1200,
      };

      final content = Content.fromJson(json);
      expect(content.watchedPercentage, 70);
      expect(content.watchedSeconds, 1200);
    });
  });
}
