class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final double ratingRate;
  final int ratingCount;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.ratingRate,
    required this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // FakeStoreAPI prices can sometimes be parsed as int, so we convert them to double safely.
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as double);
    }

    double parsedRate = 0.0;
    int parsedCount = 0;
    if (json['rating'] != null) {
      var rating = json['rating'];
      parsedRate = rating['rate'] != null
          ? ((rating['rate'] is int)
              ? (rating['rate'] as int).toDouble()
              : (rating['rate'] as double))
          : 0.0;
      parsedCount = rating['count'] != null ? rating['count'] as int : 0;
    }

    return Product(
      id: json['id'] as int,
      title: json['title'] ?? '',
      price: parsedPrice,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      ratingRate: parsedRate,
      ratingCount: parsedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': {
        'rate': ratingRate,
        'count': ratingCount,
      },
    };
  }
}
