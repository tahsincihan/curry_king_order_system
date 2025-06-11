import 'order_model.dart';

class MenuData {
  static List<MenuItem> getAllMenuItems() {
    return [
      ...starters,
      ...specialities,
      ...biryaniDishes,
      ...tandooriDishes,
      ...baltiDishes,
      ...chickenDishes,
      ...lambDishes,
      ...seafoodDishes,
      ...vegetableSideDishes,
      ...riceAndAccompaniments,
      ...englishDishes,
    ];
  }

  static List<String> getCategories() {
    return [
      'Starters',
      'Specialities',
      'Biryani Dishes',
      'Tandoori Dishes',
      'Balti Dishes',
      'Chicken Dishes',
      'Lamb Dishes',
      'Seafood Dishes',
      'Vegetable Side Dishes',
      'Rice & Accompaniments',
      'English Dishes',
    ];
  }

  static List<MenuItem> getItemsByCategory(String category) {
    switch (category) {
      case 'Starters':
        return starters;
      case 'Specialities':
        return specialities;
      case 'Biryani Dishes':
        return biryaniDishes;
      case 'Tandoori Dishes':
        return tandooriDishes;
      case 'Balti Dishes':
        return baltiDishes;
      case 'Chicken Dishes':
        return chickenDishes;
      case 'Lamb Dishes':
        return lambDishes;
      case 'Seafood Dishes':
        return seafoodDishes;
      case 'Vegetable Side Dishes':
        return vegetableSideDishes;
      case 'Rice & Accompaniments':
        return riceAndAccompaniments;
      case 'English Dishes':
        return englishDishes;
      default:
        return [];
    }
  }

  // STARTERS
  static List<MenuItem> starters = [
    MenuItem(name: 'King Prawn Puri', price: 6.50, dineInPrice: 5.50, category: 'Starters', description: 'King Prawn fried in spicy sauce and served with pancake type bread'),
    MenuItem(name: 'Tandoori Chicken', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Pieces of spring chicken lightly spiced and grilled in clay oven'),
    MenuItem(name: 'Chicken Tikka', price: 5.50, dineInPrice: 4.50, category: 'Starters'),
    MenuItem(name: 'Chicken Pakora', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Sliced chicken pieces coated in special flour with spices, deep fried'),
    MenuItem(name: 'Chicken Chat Puri', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Chicken pieces cooked in tamarind sauce served with pancake type bread'),
    MenuItem(name: 'Tikka Kebab Platter (For Two)', price: 11.95, dineInPrice: 9.95, category: 'Starters', description: 'A selection of Chicken Tikka, Lamb Tikka and Tandoori Chicken'),
    MenuItem(name: 'Indian Mix (For Two)', price: 12.95, dineInPrice: 10.95, category: 'Starters', description: 'Consists of Chicken Tikka, Lamb Tikka, Sheek Kebab and Onion Bhaji'),
    MenuItem(name: 'Seekh Kebab', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Minced lamb with herbs and spices skewered and barbecued'),
    MenuItem(name: 'Meat Samosa', price: 4.00, dineInPrice: 3.50, category: 'Starters', description: 'Savoury triangular shapes filled with spicy minced lamb and served with salad'),
    MenuItem(name: 'Vegetable Samosa', price: 4.00, dineInPrice: 3.50, category: 'Starters', description: 'Savoury triangular shapes filled with spicy vegetables and served with salad'),
    MenuItem(name: 'Onion Bhaji', price: 4.00, dineInPrice: 3.50, category: 'Starters', description: 'Chopped onion, gram flour and herbs, shaped into round cake and cooked in oil'),
    MenuItem(name: 'Chicken Chat', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Chicken cooked in tamarind sauce'),
    MenuItem(name: 'Aloo Chat', price: 5.00, dineInPrice: 4.00, category: 'Starters', description: 'Potato cooked in tamarind sauce'),
    MenuItem(name: 'Variety Mix (For Two)', price: 10.95, dineInPrice: 8.95, category: 'Starters', description: 'A selection of Vegetable samosa, Meat Samosa, Onion bhaji and seekh kebab'),
    MenuItem(name: 'Prawn Cocktail', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Prawn served with cocktail sauce and salad'),
    MenuItem(name: 'King Prawn Butterfly', price: 6.50, dineInPrice: 5.50, category: 'Starters', description: 'Delicately spiced King Prawn coated in batter and fried in ghee'),
    MenuItem(name: 'Tandoori King Prawn', price: 7.50, dineInPrice: 6.50, category: 'Starters', description: 'King size prawn marinated in tandoori spices and cooked in clay oven'),
    MenuItem(name: 'Prawn and Puri', price: 5.50, dineInPrice: 4.50, category: 'Starters', description: 'Prawn fried in spicy sauce and served with pancake type bread'),
  ];

  // SPECIALITIES
  static List<MenuItem> specialities = [
    MenuItem(name: 'Chicken Tikka Masala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Marinated chicken pieces grilled in charcoal, cooked with thick creamy sauce'),
    MenuItem(name: 'Lamb Tikka Masala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Marinated lamb pieces, cooked with thick creamy sauce'),
    MenuItem(name: 'Garlic and Herb Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Spring chicken marinated in tandoori spices, cooked with garlic, spring onions and herbs'),
    MenuItem(name: 'Tandoori King Prawn Masala', price: 13.95, dineInPrice: 11.95, category: 'Specialities', description: 'Marinated king prawns, charcoal grilled, cooked in thick creamy sauce'),
    MenuItem(name: 'Chicken Rezala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Pieces of Spring chicken barbecued in clay oven then cooked with tomato, green pepper, onion and green chillies'),
    MenuItem(name: 'Lamb Rezala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Lamb Tikka cooked with tomato, green pepper, onion and green chillies'),
    MenuItem(name: 'Chicken Passanda', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Marinated chicken pieces cooked in a mild creamy sauce with almond & coconut'),
    MenuItem(name: 'Lamb Passanda', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Lamb marinated in special spices, cooked with butter in a thick sauce'),
    MenuItem(name: 'Chicken Tikka Karahi', price: 11.95, dineInPrice: 9.95, category: 'Specialities'),
    MenuItem(name: 'Lamb Tikka Karahi', price: 10.95, dineInPrice: 8.95, category: 'Specialities'),
    MenuItem(name: 'Peshwari Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'A richly spiced curry cooked with Bengali cooking lemon'),
    MenuItem(name: 'Peshwari Lamb', price: 11.95, dineInPrice: 9.95, category: 'Specialities'),
    MenuItem(name: 'Special King Prawn', price: 16.95, dineInPrice: 14.95, category: 'Specialities', description: 'Whole king prawns cooked with butter, onion, green peppers and tomato served in boiling souk'),
    MenuItem(name: 'Butter Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Marinated chicken, cooked in a mild, creamy sauce with butter & cottage cheese'),
    MenuItem(name: 'Hara Mirch Ka Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Chicken cooked in a medley of spices with diced onion, fresh green chillies and mint garnished with lemon juice & coriander'),
    MenuItem(name: 'Hara Mirch Ka Lamb', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Lamb cooked in a medley of spices with diced onion, fresh green chillies and mint garnished with lemon juice & coriander'),
    MenuItem(name: 'Chicken Jaipur', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Marinated chicken pieces cooked in a clay oven served in special medium lamb sauce with Indian cheese'),
    MenuItem(name: 'Chicken Chilli Garlic', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Chicken pieces marinated in garlic, ginger, yoghurt and spices then slowly cooked with onion, tomato, spring onion and fresh coriander'),
    MenuItem(name: 'Tawa Lamb', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Tender pieces of lamb, tikka fried with garlic, cooked in slightly hot sauce along with pepper, onion, tomato and coriander'),
    MenuItem(name: 'Tawa Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities'),
    MenuItem(name: 'Chicken Mirchiwala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Hot & Tangy sizzling hot curry cooked with whole red chillies, pickle and garlic'),
    MenuItem(name: 'Shatkora Chicken', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'A richly spiced curry cooked with Bengali cooking lemon'),
    MenuItem(name: 'Shatkora Lamb', price: 12.95, dineInPrice: 10.95, category: 'Specialities'),
    MenuItem(name: 'Garlic Chicken', price: 12.95, dineInPrice: 10.95, category: 'Specialities', description: 'Diced pieces of spring chicken stir fried with garlic butter, red & green peppers'),
    MenuItem(name: 'Nagga Chicken Special', price: 12.95, dineInPrice: 10.95, category: 'Specialities', description: 'Nagga Chilli sauce with green pepper, red pepper, tomatoes and fresh coriander'),
    MenuItem(name: 'Nagga Lamb Special', price: 12.95, dineInPrice: 10.95, category: 'Specialities'),
    MenuItem(name: 'Chicken Green Masala', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'A fairly spicy dish, cooked with fresh coriander; fresh tomatoes, ginger; garlic and herbs'),
    MenuItem(name: 'Lamb Green Masala', price: 11.95, dineInPrice: 9.95, category: 'Specialities'),
    MenuItem(name: 'King Prawn Tawa', price: 11.95, dineInPrice: 9.95, category: 'Specialities', description: 'Shell on prawn with a green chilli, tomato, fresh coriander, garlic, onion and a special spice'),
    MenuItem(name: 'King Prawn Green Masala', price: 14.95, dineInPrice: 12.95, category: 'Specialities', description: 'Whole king prawns cooked with fresh coriander, fresh tomatoes, ginger, garlic and herbs'),
    MenuItem(name: 'Prawn Green Masala', price: 13.95, dineInPrice: 11.95, category: 'Specialities', description: 'Prawns cooked with fresh coriander, fresh tomatoes, ginger, garlic and herbs'),
  ];

  // BIRYANI DISHES
  static List<MenuItem> biryaniDishes = [
    MenuItem(name: 'Curry King Special Biryani', price: 13.95, dineInPrice: 11.95, category: 'Biryani Dishes', description: 'Chicken, Lamb and Prawn'),
    MenuItem(name: 'Chicken Tikka Biryani', price: 13.95, dineInPrice: 11.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Lamb Tikka Biryani', price: 12.95, dineInPrice: 10.95, category: 'Biryani Dishes'),
    MenuItem(name: 'King Prawn Biryani', price: 14.95, dineInPrice: 12.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Chicken Biryani', price: 11.95, dineInPrice: 9.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Lamb Biryani', price: 11.95, dineInPrice: 9.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Prawn Biryani', price: 13.95, dineInPrice: 11.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Vegetable Biryani', price: 10.95, dineInPrice: 8.95, category: 'Biryani Dishes'),
    MenuItem(name: 'Mushroom Biryani', price: 10.95, dineInPrice: 8.95, category: 'Biryani Dishes'),
  ];

  // TANDOORI DISHES
  static List<MenuItem> tandooriDishes = [
    MenuItem(name: 'Tandoori King Prawn', price: 14.95, dineInPrice: 12.95, category: 'Tandoori Dishes', description: 'King Prawn marinated in yoghurt and spices, then cooked in clay oven'),
    MenuItem(name: 'Tandoori Mixed Grill', price: 12.95, dineInPrice: 10.95, category: 'Tandoori Dishes', description: 'Selection of lamb tikka, chicken tikka, tandoori chicken, seekh kebab and naan bread'),
    MenuItem(name: 'Chicken Shashlik', price: 11.95, dineInPrice: 9.95, category: 'Tandoori Dishes', description: 'Pieces of spring chicken cooked in clay oven with onions, green peppers'),
    MenuItem(name: 'Chicken Tikka', price: 11.95, dineInPrice: 9.95, category: 'Tandoori Dishes', description: 'Pieces of spring chicken marinated in yoghurt and spices cooked in clay oven'),
    MenuItem(name: 'Lamb Tikka', price: 11.95, dineInPrice: 9.95, category: 'Tandoori Dishes', description: 'Tender lamb cubes marinated in yoghurt and selected spices and cooked in clay oven'),
    MenuItem(name: 'Tandoori Chicken', price: 10.95, dineInPrice: 8.95, category: 'Tandoori Dishes', description: '(Half) Spring Chicken on the bone marinated in yoghurt and spices cooked in clay oven'),
    MenuItem(name: 'Lamb Shashlik', price: 11.95, dineInPrice: 9.95, category: 'Tandoori Dishes', description: 'Tender lamb pieces cooked with onion, tomato and green peppers in clay oven'),
    MenuItem(name: 'Seekh Kebab', price: 11.95, dineInPrice: 9.95, category: 'Tandoori Dishes', description: 'Minced lamb marinated with herbs and spices skewered and barbecued'),
  ];

  // BALTI DISHES
  static List<MenuItem> baltiDishes = [
    MenuItem(name: 'Balti Curry King Special', price: 12.95, dineInPrice: 10.95, category: 'Balti Dishes', description: 'Chicken tikka, Lamb tikka, Mixed vegetables'),
    MenuItem(name: 'Balti Tropical', price: 12.95, dineInPrice: 10.95, category: 'Balti Dishes', description: 'Lamb, Chicken, Prawn'),
    MenuItem(name: 'Balti Chicken Chilli Masala', price: 11.95, dineInPrice: 9.95, category: 'Balti Dishes', description: 'Flavoured with fresh green chilli to a hot taste'),
    MenuItem(name: 'Balti Lamb Tikka Masala', price: 11.95, dineInPrice: 9.95, category: 'Balti Dishes', description: 'Creamy and medium hot'),
    MenuItem(name: 'Balti Chicken Tikka Masala', price: 11.95, dineInPrice: 9.95, category: 'Balti Dishes', description: 'Creamy and medium hot'),
    MenuItem(name: 'Balti Navrattan Multiveg', price: 10.95, dineInPrice: 8.95, category: 'Balti Dishes', description: 'Made with cauliflower, carrot, chickpeas, mushroom, beans, peas, cabbage and spinach'),
    MenuItem(name: 'Balti Chicken (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Balti Dishes'),
    MenuItem(name: 'Balti Lamb (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Balti Dishes'),
    MenuItem(name: 'Balti Prawn (Medium)', price: 12.95, dineInPrice: 10.95, category: 'Balti Dishes'),
    MenuItem(name: 'Balti King Prawn (Medium)', price: 14.95, dineInPrice: 12.95, category: 'Balti Dishes'),
  ];

  // CHICKEN DISHES
  static List<MenuItem> chickenDishes = [
    MenuItem(name: 'Chicken Korma (Very Mild)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes'),
    MenuItem(name: 'Chicken Curry (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes'),
    MenuItem(name: 'Chicken Madras (Fairly Hot)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes'),
    MenuItem(name: 'Chicken Vindaloo (Very Hot)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes'),
    MenuItem(name: 'Chicken Dupiaza (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium with fried onion, peppers and tomato'),
    MenuItem(name: 'Chicken Rogon (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium, Spicy curry with tomato and herbs'),
    MenuItem(name: 'Chicken Dhansak (Slightly Hot)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Slightly Hot, Sweet and sour with lentils'),
    MenuItem(name: 'Chicken Bhuna (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium, With tomato and onion in thick sauce'),
    MenuItem(name: 'Chicken and Saag (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium, with spinach'),
    MenuItem(name: 'Chicken Karahi (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium, with chickpeas'),
    MenuItem(name: 'Chicken Malaya (Mild)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Mild, Creamy with pineapple'),
    MenuItem(name: 'Chicken Kashmir (Very Mild)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Very Mild, Creamy with banana'),
    MenuItem(name: 'Chicken Pathia (Hot)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Hot, Sweet and sour with tomato'),
    MenuItem(name: 'Chicken & Mushroom (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes'),
    MenuItem(name: 'Chicken Bombay (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Chicken Dishes', description: 'Medium, with egg and potato'),
    MenuItem(name: 'Chicken Jalfrezi', price: 11.95, dineInPrice: 9.95, category: 'Chicken Dishes', description: 'Fairly Hot, onion, tomato, green peppers, green chilli'),
  ];

  // LAMB DISHES
  static List<MenuItem> lambDishes = [
    MenuItem(name: 'Lamb Korma (Very Mild)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes'),
    MenuItem(name: 'Lamb Curry (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes'),
    MenuItem(name: 'Lamb Madras (Fairly Hot)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes'),
    MenuItem(name: 'Lamb Vindaloo (Very Hot)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes'),
    MenuItem(name: 'Lamb Dupiaza (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Medium with fried onion, peppers and tomato'),
    MenuItem(name: 'Lamb Rogon (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Medium, Spicy curry with tomato and herbs'),
    MenuItem(name: 'Lamb Dhansak (Slightly Hot)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Slightly Hot, Sweet and sour with lentils'),
    MenuItem(name: 'Lamb Bhuna (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Medium, With tomato and onion in thick sauce'),
    MenuItem(name: 'Lamb and Saag (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Lamb Dishes', description: 'Medium, with spinach'),
    MenuItem(name: 'Lamb Karahi (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Lamb Dishes', description: 'Medium, with thick sauce served in boiling souk'),
    MenuItem(name: 'Lamb and Chana (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Lamb Dishes', description: 'Medium, With Chick peas'),
    MenuItem(name: 'Lamb Malaya (Mild)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Mild, Creamy with pineapple'),
    MenuItem(name: 'Lamb Kashmir (Very Mild)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Very Mild, Creamy with banana'),
    MenuItem(name: 'Lamb & Mushroom (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes'),
    MenuItem(name: 'Lamb Bombay (Medium)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Medium, with egg and potato'),
    MenuItem(name: 'Lamb Pathia (Hot)', price: 10.95, dineInPrice: 8.95, category: 'Lamb Dishes', description: 'Hot, Sweet and sour with tomato'),
    MenuItem(name: 'Lamb Jalfrezi', price: 11.95, dineInPrice: 9.95, category: 'Lamb Dishes', description: 'Fairly Hot, onion, tomato, green peppers, green chilli'),
  ];

  // SEAFOOD DISHES
  static List<MenuItem> seafoodDishes = [
    MenuItem(name: 'Prawn Korma (Very Mild)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes'),
    MenuItem(name: 'Prawn Curry (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes'),
    MenuItem(name: 'Prawn Madras (Fairly Hot)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes'),
    MenuItem(name: 'Prawn Vindaloo (Very Hot)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes'),
    MenuItem(name: 'Prawn Dupiaza (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'with fried onion, peppers and tomato'),
    MenuItem(name: 'Prawn Dhansak (Slightly Hot)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'Sweet and sour with lentils'),
    MenuItem(name: 'Prawn Bhuna (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'With tomato and onion in thick sauce'),
    MenuItem(name: 'Prawn and Saag (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'with spinach'),
    MenuItem(name: 'Prawn & Mushroom (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes'),
    MenuItem(name: 'Prawn Pathia (Hot)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'Sweet and sour with tomato'),
    MenuItem(name: 'Prawn Tawa (Medium)', price: 11.95, dineInPrice: 9.95, category: 'Seafood Dishes', description: 'fried garlic, cooked in slightly hot sauce, with pepper, onion, tomato and coriander'),
    MenuItem(name: 'King Prawn Korma (Very Mild)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes'),
    MenuItem(name: 'King Prawn Curry (Medium)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes'),
    MenuItem(name: 'King Prawn Madras (Fairly Hot)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes'),
    MenuItem(name: 'King Prawn Vindaloo (Very Hot)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes'),
    MenuItem(name: 'King Prawn Dupiaza (Medium)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'with fried onion, peppers and tomato'),
    MenuItem(name: 'King Prawn Jalfrezi (Fairly Hot)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'with fried onion, tomato and green chillies'),
    MenuItem(name: 'King Prawn Dhansak (Slightly Hot)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'Sweet and sour with lentils'),
    MenuItem(name: 'King Prawn Bhuna (Medium)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'With tomato and onion in thick sauce'),
    MenuItem(name: 'King Prawn Pathia (Hot)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'Sweet and sour with tomato'),
    MenuItem(name: 'King Prawn & Mushroom (Medium)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes'),
    MenuItem(name: 'King Prawn Karahi (Medium)', price: 13.95, dineInPrice: 11.95, category: 'Seafood Dishes', description: 'With thick sauce served in boiling souk'),
    MenuItem(name: 'King Prawn Tawa (Medium)', price: 14.95, dineInPrice: 12.95, category: 'Seafood Dishes', description: 'fried garlic, cooked in slightly hot sauce, with pepper, onion, tomato and coriander'),
  ];

  // VEGETABLE SIDE DISHES
  static List<MenuItem> vegetableSideDishes = [
    MenuItem(name: 'Plain Dhal (Lentil)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Tarka Dhal (Lentil with garlic)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Saag Paneer (Spinach with cottage cheese)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Chana Masala (Chick peas)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Mattar Paneer (Peas with cottage cheese)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Brinjol Bhaji (Aubergine with spices)', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Mixed Vegetable Curry', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Mixed Dry Vegetables', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Bombay Aloo', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Aloo Gobi', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Saag Aloo', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Cauliflower Bhaji', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Bhindi Bhaji', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Aloo Peas', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Saag Bhaji', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Onion Bhaji', price: 4.50, category: 'Vegetable Side Dishes'),
    MenuItem(name: 'Mushroom Bhaji', price: 4.50, category: 'Vegetable Side Dishes'),
  ];

  // RICE AND ACCOMPANIMENTS
  static List<MenuItem> riceAndAccompaniments = [
    MenuItem(name: 'Plain Rice', price: 2.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Pilau Rice', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Special Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Mushroom Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Egg Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Garlic Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Onion Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Coconut Fried Rice', price: 3.50, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Keema Rice', price: 3.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Naan', price: 2.60, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Keema Naan (Minced Beef)', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Garlic Naan', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Peshwari Naan (Almond, coconut and sultanas)', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Vegetable Naan', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Cheese Naan', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Paratha (Thick deep fried bread)', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Stuffed Paratha (Bread stuffed with vegetables)', price: 2.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Chapati (Thin bread baked)', price: 1.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Puri (Thin bread like pancake deep fried)', price: 1.95, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Chips', price: 3.00, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Papadom', price: 0.80, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Raita (Cucumber or onion)', price: 2.25, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Green Salad', price: 3.00, category: 'Rice & Accompaniments'),
    MenuItem(name: 'Chutney and Pickles', price: 0.80, category: 'Rice & Accompaniments'),
  ];

  // ENGLISH DISHES
  static List<MenuItem> englishDishes = [
    MenuItem(name: 'Chips', price: 3.00, category: 'English Dishes'),
    MenuItem(name: 'Scampi and Chips', price: 9.95, category: 'English Dishes'),
    MenuItem(name: 'Chicken Omelette and Chips', price: 9.95, category: 'English Dishes'),
    MenuItem(name: 'Prawn Omelette and Chips', price: 9.95, category: 'English Dishes'),
    MenuItem(name: 'Mushroom Omelette and Chips', price: 9.95, category: 'English Dishes'),
    MenuItem(name: 'Chicken Nuggets and Chips', price: 9.95, category: 'English Dishes'),
  ];
}