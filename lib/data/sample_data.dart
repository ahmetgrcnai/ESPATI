/// Sample / mock data for the Espati app.
/// This data populates all screens so they look realistic out of the box.
library;

class SampleData {
  SampleData._();

  // ─── Stories ───
  static const List<Map<String, String>> stories = [
    {'name': 'Your Story', 'avatar': 'https://placekitten.com/100/100', 'isOwn': 'true'},
    {'name': 'Luna', 'avatar': 'https://placekitten.com/101/101'},
    {'name': 'Max', 'avatar': 'https://placekitten.com/102/102'},
    {'name': 'Bella', 'avatar': 'https://placekitten.com/103/103'},
    {'name': 'Charlie', 'avatar': 'https://placekitten.com/104/104'},
    {'name': 'Coco', 'avatar': 'https://placekitten.com/105/105'},
    {'name': 'Buddy', 'avatar': 'https://placekitten.com/106/106'},
    {'name': 'Daisy', 'avatar': 'https://placekitten.com/107/107'},
  ];

  // ─── Feed Posts ───
  static const List<Map<String, dynamic>> posts = [
    {
      'username': 'luna_the_golden',
      'avatar': 'https://placekitten.com/50/50',
      'image': 'https://placekitten.com/600/600',
      'caption': 'Morning walk vibes 🐾☀️ Nothing beats a sunny day at the park!',
      'likes': 234,
      'comments': 18,
      'timeAgo': '2h ago',
    },
    {
      'username': 'max_adventures',
      'avatar': 'https://placekitten.com/51/51',
      'image': 'https://placekitten.com/601/601',
      'caption': 'Found a new pet-friendly cafe! 🐶☕ The staff even gave Max a treat.',
      'likes': 456,
      'comments': 32,
      'timeAgo': '4h ago',
    },
    {
      'username': 'bella_whiskers',
      'avatar': 'https://placekitten.com/52/52',
      'image': 'https://placekitten.com/602/602',
      'caption': 'Lazy Sunday with my best friend 😻 Who else has a cat that loves blankets?',
      'likes': 789,
      'comments': 56,
      'timeAgo': '6h ago',
    },
    {
      'username': 'charlie_paws',
      'avatar': 'https://placekitten.com/53/53',
      'image': 'https://placekitten.com/603/603',
      'caption': 'Training session complete ✅🐕 Charlie learned a new trick today!',
      'likes': 345,
      'comments': 24,
      'timeAgo': '8h ago',
    },
  ];

  // ─── Conversations ───
  static const List<Map<String, String>> conversations = [
    {
      'name': 'Pet Park Group',
      'avatar': 'https://placekitten.com/60/60',
      'lastMessage': 'Anyone bringing their dogs tomorrow?',
      'time': '2m',
      'isGroup': 'true',
      'unread': '3',
    },
    {
      'name': 'Sarah & Luna',
      'avatar': 'https://placekitten.com/61/61',
      'lastMessage': 'Thanks for the vet recommendation!',
      'time': '15m',
      'isGroup': 'false',
      'unread': '1',
    },
    {
      'name': 'Cat Lovers Club',
      'avatar': 'https://placekitten.com/62/62',
      'lastMessage': 'Check out this adorable photo 😍',
      'time': '1h',
      'isGroup': 'true',
      'unread': '0',
    },
    {
      'name': 'Mike - Dog Walker',
      'avatar': 'https://placekitten.com/63/63',
      'lastMessage': 'I can pick up Max at 3pm',
      'time': '2h',
      'isGroup': 'false',
      'unread': '0',
    },
    {
      'name': 'Vet Dr. Emily',
      'avatar': 'https://placekitten.com/64/64',
      'lastMessage': 'The lab results look great!',
      'time': '1d',
      'isGroup': 'false',
      'unread': '0',
    },
    {
      'name': 'Puppy Training 101',
      'avatar': 'https://placekitten.com/65/65',
      'lastMessage': 'Session starts at 10am sharp',
      'time': '1d',
      'isGroup': 'true',
      'unread': '0',
    },
  ];

  // ─── Chat Messages (for chat detail) ───
  static const List<Map<String, dynamic>> chatMessages = [
    {'text': 'Hey! How is Luna doing today?', 'isMe': false, 'time': '10:30 AM'},
    {'text': 'She is amazing! We went to the park this morning 🐾', 'isMe': true, 'time': '10:32 AM'},
    {'text': 'That sounds great! Which park did you go to?', 'isMe': false, 'time': '10:33 AM'},
    {'text': 'The one near downtown, it has a new dog area!', 'isMe': true, 'time': '10:35 AM'},
    {'text': 'Oh nice! I should take Max there sometime', 'isMe': false, 'time': '10:36 AM'},
    {'text': 'Definitely! It is very pet-friendly. They even have water bowls 💧', 'isMe': true, 'time': '10:38 AM'},
  ];

  // ─── Pet-Friendly Places ───
  static const List<Map<String, dynamic>> places = [
    {
      'name': 'Paws & Coffee',
      'category': 'Cafe',
      'icon': 'coffee',
      'rating': 4.8,
      'distance': '0.5 km',
      'address': '123 Pet Street',
    },
    {
      'name': 'Central Dog Park',
      'category': 'Park',
      'icon': 'park',
      'rating': 4.9,
      'distance': '1.2 km',
      'address': '456 Green Avenue',
    },
    {
      'name': 'Happy Paws Vet Clinic',
      'category': 'Vet',
      'icon': 'vet',
      'rating': 4.7,
      'distance': '2.0 km',
      'address': '789 Health Blvd',
    },
    {
      'name': 'Pet Paradise Store',
      'category': 'Pet Shop',
      'icon': 'shop',
      'rating': 4.5,
      'distance': '0.8 km',
      'address': '321 Shop Lane',
    },
    {
      'name': 'Bark & Brunch',
      'category': 'Cafe',
      'icon': 'coffee',
      'rating': 4.6,
      'distance': '1.5 km',
      'address': '654 Brunch Road',
    },
  ];

  // ─── Lost Pet Reports ───
  static const List<Map<String, dynamic>> lostPets = [
    {
      'name': 'Rocky',
      'type': 'Golden Retriever',
      'lastSeen': 'Central Park area',
      'date': 'March 2, 2026',
      'image': 'https://placekitten.com/200/200',
      'contact': '+1 555-0101',
      'description': 'Friendly male, 3 years old. Wearing a red collar with tags.',
    },
    {
      'name': 'Mimi',
      'type': 'Tabby Cat',
      'lastSeen': 'Oak Street neighborhood',
      'date': 'March 1, 2026',
      'image': 'https://placekitten.com/201/201',
      'contact': '+1 555-0102',
      'description': 'Small female cat, gray with stripes. Very shy.',
    },
    {
      'name': 'Snowball',
      'type': 'White Persian Cat',
      'lastSeen': 'Near Main St grocery',
      'date': 'Feb 28, 2026',
      'image': 'https://placekitten.com/202/202',
      'contact': '+1 555-0103',
      'description': 'Fluffy white cat, blue eyes. Indoor cat that escaped.',
    },
  ];

  // ─── Vet Q&A ───
  static const List<Map<String, dynamic>> vetQuestions = [
    {
      'question': 'My dog is scratching a lot, what could it be?',
      'author': 'pet_parent_22',
      'answers': 5,
      'category': 'Dermatology',
    },
    {
      'question': 'How often should I take my cat to the vet for checkups?',
      'author': 'cat_lover_99',
      'answers': 8,
      'category': 'General',
    },
    {
      'question': 'Is it safe to give my dog human food?',
      'author': 'new_owner',
      'answers': 12,
      'category': 'Nutrition',
    },
  ];

  // ─── User Profile ───
  static const Map<String, dynamic> userProfile = {
    'name': 'Ahmet',
    'username': '@ahmet_pets',
    'bio': 'Pet lover 🐾 | 2 cats & 1 dog | Sharing our adventures',
    'avatar': 'https://placekitten.com/150/150',
    'posts': 47,
    'followers': 1234,
    'following': 567,
  };

  // ─── User's Pets ───
  static const List<Map<String, String>> userPets = [
    {
      'name': 'Luna',
      'breed': 'Persian Cat',
      'image': 'https://placekitten.com/120/120',
      'age': '3 years',
    },
    {
      'name': 'Max',
      'breed': 'Golden Retriever',
      'image': 'https://placekitten.com/121/121',
      'age': '2 years',
    },
    {
      'name': 'Bella',
      'breed': 'Siamese Cat',
      'image': 'https://placekitten.com/122/122',
      'age': '1 year',
    },
  ];

  // ─── User's Posts (for profile grid) ───
  static const List<String> userPostImages = [
    'https://placekitten.com/300/300',
    'https://placekitten.com/301/301',
    'https://placekitten.com/302/302',
    'https://placekitten.com/303/303',
    'https://placekitten.com/304/304',
    'https://placekitten.com/305/305',
    'https://placekitten.com/306/306',
    'https://placekitten.com/307/307',
    'https://placekitten.com/308/308',
  ];
}
