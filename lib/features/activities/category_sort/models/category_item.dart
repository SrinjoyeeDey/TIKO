/// Item model for FFC semantic categorization.
class CategoryItem {
  final String key;
  final String displayName;
  final String emoji;
  final String categoryKey;

  const CategoryItem({
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.categoryKey,
  });

  static const List<CategoryItem> defaultPool = [
    // Food
    CategoryItem(key: 'apple', displayName: 'Apple', emoji: '🍎', categoryKey: 'Food'),
    CategoryItem(key: 'pizza', displayName: 'Pizza', emoji: '🍕', categoryKey: 'Food'),
    CategoryItem(key: 'cake', displayName: 'Cake', emoji: '🎂', categoryKey: 'Food'),
    CategoryItem(key: 'banana', displayName: 'Banana', emoji: '🍌', categoryKey: 'Food'),
    CategoryItem(key: 'burger', displayName: 'Burger', emoji: '🍔', categoryKey: 'Food'),

    // Animals
    CategoryItem(key: 'dog', displayName: 'Dog', emoji: '🐕', categoryKey: 'Animals'),
    CategoryItem(key: 'cat', displayName: 'Cat', emoji: '🐱', categoryKey: 'Animals'),
    CategoryItem(key: 'fish', displayName: 'Fish', emoji: '🐟', categoryKey: 'Animals'),
    CategoryItem(key: 'bird', displayName: 'Bird', emoji: '🐦', categoryKey: 'Animals'),
    CategoryItem(key: 'rabbit', displayName: 'Rabbit', emoji: '🐇', categoryKey: 'Animals'),

    // Clothing
    CategoryItem(key: 'hat', displayName: 'Hat', emoji: '🧢', categoryKey: 'Clothing'),
    CategoryItem(key: 'shirt', displayName: 'Shirt', emoji: '👕', categoryKey: 'Clothing'),
    CategoryItem(key: 'shoe', displayName: 'Shoe', emoji: '👟', categoryKey: 'Clothing'),
    CategoryItem(key: 'sock', displayName: 'Sock', emoji: '🧦', categoryKey: 'Clothing'),
    CategoryItem(key: 'jacket', displayName: 'Jacket', emoji: '🧥', categoryKey: 'Clothing'),

    // Places
    CategoryItem(key: 'house', displayName: 'House', emoji: '🏠', categoryKey: 'Places'),
    CategoryItem(key: 'school', displayName: 'School', emoji: '🏫', categoryKey: 'Places'),
    CategoryItem(key: 'park', displayName: 'Park', emoji: '🌳', categoryKey: 'Places'),
    CategoryItem(key: 'store', displayName: 'Store', emoji: '🏪', categoryKey: 'Places'),
    CategoryItem(key: 'beach', displayName: 'Beach', emoji: '🏖️', categoryKey: 'Places'),
  ];
}
