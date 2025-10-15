import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double starSize;
  final double textSize;
  final Color filledColor;
  final Color unfilledColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.textSize = 12,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$rating ',
          style: TextStyle(
            fontSize: textSize,
            color: filledColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) => Icon(
            Icons.star,
            color: filledColor,
          ),
          itemCount: 5,
          itemSize: starSize,
          unratedColor: unfilledColor,
          direction: Axis.horizontal,
        ),
      ],
    );
  }
}
