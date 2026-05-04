const Map<String, List<String>> emojiNameSuggestions = {
  '🍔': ['Food', 'Fast food', 'Takeout'],
  '🍕': ['Pizza', 'Food', 'Dining out'],
  '☕': ['Coffee', 'Cafe', 'Drinks'],
  '🍺': ['Drinks', 'Bar', 'Alcohol'],
  '🍰': ['Desserts', 'Sweets', 'Bakery'],
  '🍜': ['Food', 'Dining out', 'Lunch'],
  '🥗': ['Healthy food', 'Groceries', 'Salad'],
  '🍎': ['Groceries', 'Fruits', 'Food'],

  '🚕': ['Taxi', 'Transport', 'Ride'],
  '🚌': ['Bus', 'Transport', 'Commute'],
  '🚗': ['Car', 'Transport', 'Fuel'],
  '⛽': ['Fuel', 'Petrol', 'Gas'],
  '✈️': ['Travel', 'Flights', 'Trip'],
  '🚂': ['Train', 'Transport', 'Commute'],
  '🛵': ['Bike fuel', 'Scooter', 'Transport'],
  '🚲': ['Bike', 'Cycling', 'Transport'],

  '🏠': ['Rent', 'Home', 'Housing'],
  '🏢': ['Office', 'Rent', 'Workspace'],
  '⚡': ['Electricity', 'Power', 'Utilities'],
  '💡': ['Electricity', 'Utilities', 'Bills'],
  '🚰': ['Water', 'Utilities', 'Bills'],
  '🔥': ['Gas', 'Heating', 'Utilities'],
  '🛋️': ['Furniture', 'Home', 'Living'],
  '🧹': ['Cleaning', 'Household', 'Chores'],
  '📶': ['Internet', 'Wifi', 'Utilities'],
  '🌐': ['Internet', 'Web', 'Utilities'],

  '🎮': ['Gaming', 'Entertainment', 'Fun'],
  '🎬': ['Movies', 'Cinema', 'Entertainment'],
  '🎵': ['Music', 'Streaming', 'Entertainment'],
  '📺': ['Streaming', 'Video', 'Entertainment'],
  '🎨': ['Art', 'Hobby', 'Supplies'],
  '🎭': ['Theatre', 'Shows', 'Entertainment'],
  '🎸': ['Music', 'Hobby', 'Instruments'],
  '📷': ['Photography', 'Hobby', 'Camera'],

  '🛒': ['Groceries', 'Shopping', 'Supermarket'],
  '👕': ['Clothes', 'Fashion', 'Shopping'],
  '👟': ['Shoes', 'Footwear', 'Fashion'],
  '💄': ['Cosmetics', 'Beauty', 'Makeup'],
  '🎁': ['Gifts', 'Presents', 'Occasions'],
  '🛍️': ['Shopping', 'Retail', 'Clothes'],
  '💎': ['Jewellery', 'Accessories', 'Luxury'],
  '🕶️': ['Accessories', 'Fashion', 'Sunglasses'],

  '💊': ['Medicine', 'Pharmacy', 'Health'],
  '🏥': ['Hospital', 'Medical', 'Health'],
  '🦷': ['Dentist', 'Dental', 'Health'],
  '💪': ['Gym', 'Fitness', 'Health'],
  '🧘': ['Yoga', 'Wellness', 'Fitness'],
  '🏃': ['Running', 'Fitness', 'Sports'],
  '🩺': ['Doctor', 'Medical', 'Checkup'],
  '🧴': ['Personal care', 'Toiletries', 'Health'],

  '📚': ['Books', 'Education', 'Reading'],
  '✏️': ['Stationery', 'School', 'Supplies'],
  '💼': ['Work', 'Business', 'Office'],
  '🎓': ['Tuition', 'Education', 'School'],
  '📝': ['Notes', 'Stationery', 'Study'],
  '💻': ['Tech', 'Computer', 'Work'],
  '📊': ['Reports', 'Work', 'Analytics'],
  '📞': ['Phone bill', 'Calls', 'Communication'],
  '☎️': ['Phone bill', 'Landline', 'Utilities'],

  '💰': ['Savings', 'Investment', 'Money'],
  '💳': ['Card bill', 'Credit', 'Payment'],
  '💵': ['Cash', 'Money', 'Payment'],
  '📱': ['Mobile bill', 'Phone', 'Recharge'],
  '🧾': ['Bill', 'Invoice', 'Receipt'],
  '🔧': ['Repairs', 'Maintenance', 'Tools'],
  '🐶': ['Pet', 'Dog', 'Pet care'],
  '🎯': ['Goals', 'Misc', 'Target'],
  '✂️': ['Haircut', 'Salon', 'Grooming'],
};

List<String> suggestionsForEmoji(String emoji) {
  return emojiNameSuggestions[emoji] ?? const [];
}

const Map<String, List<String>> accountEmojiSuggestions = {
  '💵': ['Cash', 'Wallet', 'Pocket money'],
  '🏦': ['Bank', 'Savings', 'Current account'],
  '📱': ['Mobile wallet', 'Digital wallet', 'Phone money'],
  '💳': ['Credit card', 'Debit card', 'Card'],
  '🪙': ['Coins', 'Loose change', 'Piggy bank'],
  '👛': ['Wallet', 'Pocket money', 'Cash'],
  '💰': ['Savings', 'Emergency fund', 'Piggy bank'],
  '🏧': ['ATM', 'Bank', 'Current account'],
  '💸': ['Spending money', 'Fun fund', 'Cash'],
  '🎁': ['Gift fund', 'Special fund', 'Savings'],
  '🏠': ['House fund', 'Rent account', 'Home savings'],
  '🚗': ['Car fund', 'Transport', 'Fuel fund'],
  '✈️': ['Travel fund', 'Holiday', 'Trip savings'],
  '🎓': ['Education fund', 'Tuition', 'School'],
  '💎': ['Investment', 'Savings', 'Gold'],
};

List<String> accountSuggestionsForEmoji(String emoji) {
  return accountEmojiSuggestions[emoji] ?? const [];
}

const Map<String, List<String>> incomeButtonSuggestions = {
  '💵': ['Cash income', 'Side income', 'Tips'],
  '🏦': ['Salary', 'Bonus', 'Interest'],
  '📱': ['Transfer', 'Refund', 'Client payment'],
  '💳': ['Salary', 'Refund', 'Bonus'],
  '🪙': ['Coins saved', 'Spare change', 'Jar'],
  '👛': ['Pocket money', 'Allowance', 'Tips'],
  '💰': ['Savings add', 'Salary', 'Bonus'],
  '🏧': ['Salary', 'Withdrawal', 'Transfer'],
  '💸': ['Fun money', 'Weekly spend', 'Allowance'],
  '🎁': ['Gift received', 'Birthday money', 'Holiday gift'],
  '🏠': ['Rent received', 'House income', 'Property'],
  '🚗': ['Ride earnings', 'Trip', 'Delivery'],
  '✈️': ['Travel reimbursement', 'Trip budget', 'Per diem'],
  '🎓': ['Stipend', 'Scholarship', 'Tuition'],
  '💎': ['Dividend', 'Investment', 'Return'],
};

List<String> incomeButtonSuggestionsFor(String emoji) {
  return incomeButtonSuggestions[emoji] ??
      accountEmojiSuggestions[emoji] ??
      const [];
}
