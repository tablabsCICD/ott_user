// import 'package:flutter/material.dart';

// class CategoryMoviesPage extends StatelessWidget {
//   final String categoryTitle;
//   final List<Map<String, dynamic>> movies;

//   const CategoryMoviesPage({
//     Key? key,
//     required this.categoryTitle,
//     required this.movies,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(categoryTitle),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: movies.isNotEmpty
//           ? ListView.builder(
//               itemCount: movies.length,
//               itemBuilder: (context, index) {
//                 var movie = movies[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(
//                       vertical: 8.0, horizontal: 16.0),
//                   child: Text('${movie['title']}'),
//                 );
//               },
//             )
//           : Center(
//               child: Text(
//                 'No movies available in this category',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//     );
//   }
// }
