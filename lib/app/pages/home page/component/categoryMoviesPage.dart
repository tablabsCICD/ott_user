import 'package:flutter/material.dart';
import 'package:ott/app/widgets/movieCard.dart';

class CategoryMoviesPage extends StatelessWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>> movies;

  const CategoryMoviesPage({
    Key? key,
    required this.categoryTitle,
    required this.movies,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: movies.isNotEmpty
          ? ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                var movie = movies[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Text('${movie['title']}'),
                  // child: MovieCard(
                  //   movieId: movie['id'],
                  //   movieName: movie['title'] ?? 'Unknown Movie',
                  //   poster_url: movie['poster_url'][0] ?? '',
                  //   rating: movie['rating'] ?? 0.0,
                  //   rating_count: movie['rating_count'] ?? 0,
                  // ),
                );
              },
            )
          : Center(
              child: Text(
                'No movies available in this category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
