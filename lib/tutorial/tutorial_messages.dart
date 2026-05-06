import '../data/settings_service.dart';
import '../widgets/main_menu_sheet.dart';
import 'tutorial_ids.dart';

enum TutorialGesture {
  tap,
  longPress,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
}

class TutorialMessage {
  final String id;
  final String targetId;
  final String title;
  final String body;
  final TutorialGesture? gesture;

  const TutorialMessage({
    required this.id,
    required this.targetId,
    required this.title,
    required this.body,
    this.gesture,
  });
}

class TutorialMessages {
  static const Map<String, TutorialMessage> all = {
    TutorialIds.dashWelcomeTopcard: TutorialMessage(
      id: TutorialIds.dashWelcomeTopcard,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Welcome to Kovira',
      body:
          'This is your dashboard. Swipe the top card to see Goals, '
          'Income Sources, and Budget. Tap any card to dive in.',
    ),
    TutorialIds.dashExpenseBtn: TutorialMessage(
      id: TutorialIds.dashExpenseBtn,
      targetId: TutorialTargetIds.dashExpenseBtn,
      title: 'Log an expense',
      body:
          'Tap here whenever you spend something. It is the fastest '
          'way to keep your ledger up to date.',
    ),
    TutorialIds.dashSettingsGear: TutorialMessage(
      id: TutorialIds.dashSettingsGear,
      targetId: TutorialTargetIds.dashSettingsGear,
      title: 'Settings live here',
      body: 'Theme, backup, and tutorial replay all sit behind the gear.',
    ),
    TutorialIds.dashNavigation: TutorialMessage(
      id: TutorialIds.dashNavigation,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Swipe between pages',
      body:
          'Swipe left or right anywhere on a page to move between '
          'Records, Budget, Income Sources, Expenses, Bills, Tags, '
          'and Goals.',
    ),

    TutorialIds.accountsAddBtn: TutorialMessage(
      id: TutorialIds.accountsAddBtn,
      targetId: TutorialTargetIds.accountsAddBtn,
      title: 'Add an income source',
      body:
          'Cash, bank, mobile wallet. Every place your money lives '
          'is an income source.',
    ),
    TutorialIds.acctDialogFields: TutorialMessage(
      id: TutorialIds.acctDialogFields,
      targetId: TutorialTargetIds.acctDialogName,
      title: 'Name this income source',
      body:
          'Pick an emoji and give it a short name. Starting '
          'balance below is optional.',
    ),
    TutorialIds.incomeDialogIntro: TutorialMessage(
      id: TutorialIds.incomeDialogIntro,
      targetId: TutorialTargetIds.incomeDialogName,
      title: 'Recurring income (optional)',
      body:
          'For money that arrives on a schedule, like salary, '
          'allowance, etc. Tap Skip to set it up later.',
    ),
    TutorialIds.accountsCardTap: TutorialMessage(
      id: TutorialIds.accountsCardTap,
      targetId: TutorialTargetIds.accountsAddBtn,
      title: 'Tap a card to expand it',
      body:
          'Each income source card opens to show recent activity, recurring '
          'income, and transfer shortcuts.',
    ),
    TutorialIds.accountsCardExpanded: TutorialMessage(
      id: TutorialIds.accountsCardExpanded,
      targetId: TutorialTargetIds.accountsExpandedBtns,
      title: 'Three shortcuts per income source',
      body:
          'Quick Add = one-off income. Middle = save a recurring '
          'income button. Right = transfer out.',
    ),
    TutorialIds.accountsRecentStrip: TutorialMessage(
      id: TutorialIds.accountsRecentStrip,
      targetId: TutorialTargetIds.accountsRecentStrip,
      title: 'Your recent activity',
      body:
          'Latest incomes and transfers land here. Tap the strip '
          'to open the full Records page.',
    ),
    TutorialIds.accountsCardActivity: TutorialMessage(
      id: TutorialIds.accountsCardActivity,
      targetId: TutorialTargetIds.accountsCardDiff,
      title: 'Month-to-date change',
      body:
          'The small +/- number shows how much this income source has '
          'moved since the start of the month.',
    ),

    TutorialIds.dashActivityStrip: TutorialMessage(
      id: TutorialIds.dashActivityStrip,
      targetId: TutorialTargetIds.dashActivityStrip,
      title: 'Recent activity',
      body:
          'Your latest entries show up here. Tap the strip to open '
          'the full Records page.',
    ),

    TutorialIds.entryPaidDueToggle: TutorialMessage(
      id: TutorialIds.entryPaidDueToggle,
      targetId: TutorialTargetIds.entryPaidDue,
      title: 'Paid or due?',
      body:
          'Pick Paid if the money already left your income source, or Due '
          'if you owe it later.',
    ),
    TutorialIds.entrySourcePicker: TutorialMessage(
      id: TutorialIds.entrySourcePicker,
      targetId: TutorialTargetIds.entrySourcePicker,
      title: 'Which income source?',
      body:
          'Select where this money came from: cash, bank, wallet, or '
          'whatever you use.',
    ),
    TutorialIds.entryCategoryIntro: TutorialMessage(
      id: TutorialIds.entryCategoryIntro,
      targetId: TutorialTargetIds.entryCategoryPicker,
      title: 'Pick a tag',
      body:
          'Tags help the Records and Budget pages summarise '
          'your spending. Long-press to manage them.',
    ),
    TutorialIds.entryAmountInput: TutorialMessage(
      id: TutorialIds.entryAmountInput,
      targetId: TutorialTargetIds.entryAmountField,
      title: 'How much?',
      body:
          'Enter the amount. You can add a name for it later if you '
          'want.',
    ),
    TutorialIds.entryNameOptional: TutorialMessage(
      id: TutorialIds.entryNameOptional,
      targetId: TutorialTargetIds.entryNameChip,
      title: 'Name it (optional)',
      body:
          'Tap to add a custom name. The tag name is used by '
          'default.',
    ),

    TutorialIds.dashExpenseSection: TutorialMessage(
      id: TutorialIds.dashExpenseSection,
      targetId: TutorialTargetIds.dashExpenseSection,
      title: 'This month\'s spending',
      body:
          'Paid expenses for the current month land here, grouped by '
          'tag.',
    ),
    TutorialIds.dashDueSection: TutorialMessage(
      id: TutorialIds.dashDueSection,
      targetId: TutorialTargetIds.dashDueSection,
      title: 'What you owe',
      body: 'Anything you marked Due waits here until you settle it.',
    ),

    TutorialIds.billsAddBtn: TutorialMessage(
      id: TutorialIds.billsAddBtn,
      targetId: TutorialTargetIds.billsAddBtn,
      title: 'Recurring bills',
      body:
          'Save bills you pay regularly so they are one tap away when '
          'they come due.',
    ),
    TutorialIds.billDialogFields: TutorialMessage(
      id: TutorialIds.billDialogFields,
      targetId: TutorialTargetIds.billDialogName,
      title: 'Name the bill',
      body:
          'Pick an emoji and name it. Set the amount below, or '
          'mark it variable.',
    ),
    TutorialIds.billsCardTapHint: TutorialMessage(
      id: TutorialIds.billsCardTapHint,
      targetId: TutorialTargetIds.billsFirstCard,
      title: 'Tap to pay',
      body:
          'A single tap logs a payment from your chosen income source. '
          'Long-press to edit or delete the bill.',
    ),
    TutorialIds.categoriesAddBtn: TutorialMessage(
      id: TutorialIds.categoriesAddBtn,
      targetId: TutorialTargetIds.categoriesAddBtn,
      title: 'Manage tags',
      body:
          'Add, rename, or delete the buckets your spending falls '
          'into.',
    ),
    TutorialIds.catDialogFields: TutorialMessage(
      id: TutorialIds.catDialogFields,
      targetId: TutorialTargetIds.catDialogName,
      title: 'Name the tag',
      body:
          'A short descriptive name works best. Records and Budget '
          'will group your spending under it.',
    ),
    TutorialIds.catsCardTapHint: TutorialMessage(
      id: TutorialIds.catsCardTapHint,
      targetId: TutorialTargetIds.catsFirstCard,
      title: 'Tap to open',
      body:
          'Tapping a tag opens its full entry list. Long-press '
          'to rename, re-emoji, or delete.',
    ),
    TutorialIds.goalsAddBtn: TutorialMessage(
      id: TutorialIds.goalsAddBtn,
      targetId: TutorialTargetIds.goalsAddBtn,
      title: 'Savings goals',
      body: 'Set a target, contribute over time, watch the bar fill.',
    ),
    TutorialIds.goalDialogFields: TutorialMessage(
      id: TutorialIds.goalDialogFields,
      targetId: TutorialTargetIds.goalDialogName,
      title: 'Name the goal',
      body:
          'Pick an emoji and name the goal. Set the target amount '
          'below. You can optionally pick a deadline and a colour.',
    ),
    TutorialIds.goalsCardTapHint: TutorialMessage(
      id: TutorialIds.goalsCardTapHint,
      targetId: TutorialTargetIds.goalsFirstCard,
      title: 'Tap to contribute',
      body:
          'A tap opens a contribution sheet so you can move money '
          'from any income source into the goal. Long-press to edit.',
    ),
    TutorialIds.budgetAddBtn: TutorialMessage(
      id: TutorialIds.budgetAddBtn,
      targetId: TutorialTargetIds.budgetAddBtn,
      title: 'Monthly budgets',
      body:
          'Cap how much each tag can spend in a month. Overrides '
          'work per-month if a single month is special.',
    ),
    TutorialIds.budgetDialogFields: TutorialMessage(
      id: TutorialIds.budgetDialogFields,
      targetId: TutorialTargetIds.budgetDialogField,
      title: 'Set the cap',
      body:
          'Type the maximum this tag can spend in a month. '
          'Tap Clear later to remove the cap.',
    ),
    TutorialIds.budgetCardTapHint: TutorialMessage(
      id: TutorialIds.budgetCardTapHint,
      targetId: TutorialTargetIds.budgetFirstCard,
      title: 'Tap to adjust',
      body:
          'Tap the row to change the cap for this month only. The '
          'default cap still applies to future months. Long-press to '
          'remove the budget entirely.',
    ),

    TutorialIds.recordsIntro: TutorialMessage(
      id: TutorialIds.recordsIntro,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Every entry, sorted',
      body:
          'Swipe left and right to change month. Use the sort menu to '
          're-order by date or amount.',
    ),
    TutorialIds.recordsGraphMode: TutorialMessage(
      id: TutorialIds.recordsGraphMode,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Switch to graph mode',
      body:
          'Tap the bottom button to flip into a visual breakdown of '
          'the month.',
    ),

    TutorialIds.settingsBackup: TutorialMessage(
      id: TutorialIds.settingsBackup,
      targetId: TutorialTargetIds.settingsBackupTile,
      title: 'Back up to Drive',
      body:
          'Sign in once and Kovira can snapshot your ledger to your '
          'own Google Drive whenever you tap here.',
    ),

    TutorialIds.learnDashTabsIntro: TutorialMessage(
      id: TutorialIds.learnDashTabsIntro,
      targetId: '',
      title: 'This is Expenses',
      body: 'Your home page. Earned and Spent above, expenses by tag below.',
    ),
    TutorialIds.learnDashTabsSwipeTop: TutorialMessage(
      id: TutorialIds.learnDashTabsSwipeTop,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Swipe the top card',
      body: 'Cycle through Goals, Sources, and Budget.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnDashTabsTopCard: TutorialMessage(
      id: TutorialIds.learnDashTabsTopCard,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Tap a card to open it',
      body: 'Goes straight to the full page.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDashTabsExpenses: TutorialMessage(
      id: TutorialIds.learnDashTabsExpenses,
      targetId: '',
      title: 'Tap a tag to drill in',
      body: 'See every expense under that tag.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDashTabsAdd: TutorialMessage(
      id: TutorialIds.learnDashTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to log an expense',
      body: 'The colored circle on the active tab is the action for this page.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnDashDedIntro: TutorialMessage(
      id: TutorialIds.learnDashDedIntro,
      targetId: '',
      title: 'This is Expenses',
      body: 'Your home page. Earned and Spent above, expenses by tag below.',
    ),
    TutorialIds.learnDashDedSwipeTop: TutorialMessage(
      id: TutorialIds.learnDashDedSwipeTop,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Swipe the top card',
      body: 'Cycle through Goals, Sources, and Budget.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnDashDedTopCard: TutorialMessage(
      id: TutorialIds.learnDashDedTopCard,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Tap a card to open it',
      body: 'Goes straight to the full page.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDashDedAdd: TutorialMessage(
      id: TutorialIds.learnDashDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to log an expense',
      body: 'The bottom button is the action for whichever page you are on.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDashDedNav: TutorialMessage(
      id: TutorialIds.learnDashDedNav,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Swipe up to navigate',
      body: 'Pulls up a drawer with all seven pages.',
      gesture: TutorialGesture.swipeUp,
    ),

    TutorialIds.learnRecordsTabsIntro: TutorialMessage(
      id: TutorialIds.learnRecordsTabsIntro,
      targetId: '',
      title: 'Every transaction',
      body: 'Expenses, income, transfers, dues. Sort and filter from the top.',
    ),
    TutorialIds.learnRecordsTabsToggle: TutorialMessage(
      id: TutorialIds.learnRecordsTabsToggle,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to toggle graph',
      body: 'Switches between list view and graph view.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnRecordsTabsSwipeMonth: TutorialMessage(
      id: TutorialIds.learnRecordsTabsSwipeMonth,
      targetId: '',
      title: 'Swipe to change month',
      body: 'Left for next, right for previous.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnRecordsTabsSwipe: TutorialMessage(
      id: TutorialIds.learnRecordsTabsSwipe,
      targetId: '',
      title: 'Swipe in graph mode',
      body: 'Cycles between graph types.',
      gesture: TutorialGesture.swipeRight,
    ),

    TutorialIds.learnRecordsDedIntro: TutorialMessage(
      id: TutorialIds.learnRecordsDedIntro,
      targetId: '',
      title: 'Every transaction',
      body: 'Expenses, income, transfers, dues. Sort and filter from the top.',
    ),
    TutorialIds.learnRecordsDedToggle: TutorialMessage(
      id: TutorialIds.learnRecordsDedToggle,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to toggle graph',
      body: 'Switches between list view and graph view.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnRecordsDedLongPress: TutorialMessage(
      id: TutorialIds.learnRecordsDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),
    TutorialIds.learnRecordsDedSwipeMonth: TutorialMessage(
      id: TutorialIds.learnRecordsDedSwipeMonth,
      targetId: '',
      title: 'Swipe to change month',
      body: 'Left for next, right for previous.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnRecordsDedSwipe: TutorialMessage(
      id: TutorialIds.learnRecordsDedSwipe,
      targetId: '',
      title: 'Swipe in graph mode',
      body: 'Cycles between graph types.',
      gesture: TutorialGesture.swipeRight,
    ),

    TutorialIds.learnBudgetTabsIntro: TutorialMessage(
      id: TutorialIds.learnBudgetTabsIntro,
      targetId: '',
      title: 'Monthly spending caps',
      body: 'Each tile shows progress for one tag. Tap to edit or clear.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBudgetTabsAdd: TutorialMessage(
      id: TutorialIds.learnBudgetTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to set a cap',
      body: 'Picks a tag, then asks the monthly amount.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnBudgetDedIntro: TutorialMessage(
      id: TutorialIds.learnBudgetDedIntro,
      targetId: '',
      title: 'Monthly spending caps',
      body: 'Each tile shows progress for one tag. Tap to edit or clear.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBudgetDedAdd: TutorialMessage(
      id: TutorialIds.learnBudgetDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to set a cap',
      body: 'Picks a tag, then asks the monthly amount.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBudgetDedLongPress: TutorialMessage(
      id: TutorialIds.learnBudgetDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),

    TutorialIds.learnSourcesTabsIntro: TutorialMessage(
      id: TutorialIds.learnSourcesTabsIntro,
      targetId: '',
      title: 'Tap a card to expand',
      body: 'Each source has Quick Add, Recurring Income, and Transfer inside.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnSourcesTabsAdd: TutorialMessage(
      id: TutorialIds.learnSourcesTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to add a source',
      body: 'Pick an emoji, name it, set the starting balance.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnSourcesDedIntro: TutorialMessage(
      id: TutorialIds.learnSourcesDedIntro,
      targetId: '',
      title: 'Tap a card to expand',
      body: 'Each source has Quick Add, Recurring Income, and Transfer inside.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnSourcesDedAdd: TutorialMessage(
      id: TutorialIds.learnSourcesDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to add a source',
      body: 'Pick an emoji, name it, set the starting balance.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnSourcesDedLongPress: TutorialMessage(
      id: TutorialIds.learnSourcesDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),

    TutorialIds.learnBillsTabsIntro: TutorialMessage(
      id: TutorialIds.learnBillsTabsIntro,
      targetId: '',
      title: 'Tap a bill to pay',
      body: 'Fixed bills log instantly. Variable ones ask the amount.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBillsTabsAdd: TutorialMessage(
      id: TutorialIds.learnBillsTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to add a bill',
      body: 'Pick fixed or variable, set a reminder day if you want.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnBillsDedIntro: TutorialMessage(
      id: TutorialIds.learnBillsDedIntro,
      targetId: '',
      title: 'Tap a bill to pay',
      body: 'Fixed bills log instantly. Variable ones ask the amount.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBillsDedAdd: TutorialMessage(
      id: TutorialIds.learnBillsDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to add a bill',
      body: 'Pick fixed or variable, set a reminder day if you want.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnBillsDedLongPress: TutorialMessage(
      id: TutorialIds.learnBillsDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),

    TutorialIds.learnTagsTabsIntro: TutorialMessage(
      id: TutorialIds.learnTagsTabsIntro,
      targetId: '',
      title: 'Long-press a tag',
      body: 'To rename or delete it. General and Bills are locked.',
      gesture: TutorialGesture.longPress,
    ),
    TutorialIds.learnTagsTabsAdd: TutorialMessage(
      id: TutorialIds.learnTagsTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to add a tag',
      body: 'Pick an emoji and name it.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnTagsDedIntro: TutorialMessage(
      id: TutorialIds.learnTagsDedIntro,
      targetId: '',
      title: 'Long-press a tag',
      body: 'To rename or delete it. General and Bills are locked.',
      gesture: TutorialGesture.longPress,
    ),
    TutorialIds.learnTagsDedAdd: TutorialMessage(
      id: TutorialIds.learnTagsDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to add a tag',
      body: 'Pick an emoji and name it.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnTagsDedLongPress: TutorialMessage(
      id: TutorialIds.learnTagsDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),

    TutorialIds.learnGoalsTabsIntro: TutorialMessage(
      id: TutorialIds.learnGoalsTabsIntro,
      targetId: '',
      title: 'Tap a goal to contribute',
      body: 'Long-press for edit, archive, or delete.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnGoalsTabsAdd: TutorialMessage(
      id: TutorialIds.learnGoalsTabsAdd,
      targetId: TutorialTargetIds.tabActiveAdd,
      title: 'Tap to add a goal',
      body: 'Pick an emoji, name it, set the target.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnGoalsDedIntro: TutorialMessage(
      id: TutorialIds.learnGoalsDedIntro,
      targetId: '',
      title: 'Tap a goal to contribute',
      body: 'Long-press for edit, archive, or delete.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnGoalsDedAdd: TutorialMessage(
      id: TutorialIds.learnGoalsDedAdd,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Tap to add a goal',
      body: 'Pick an emoji, name it, set the target.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnGoalsDedLongPress: TutorialMessage(
      id: TutorialIds.learnGoalsDedLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),

    TutorialIds.learnDialogExpense: TutorialMessage(
      id: TutorialIds.learnDialogExpense,
      targetId: '',
      title: 'Walk through the steps',
      body: 'Choose Paid or Due, pick a source, pick a tag, enter the amount.',
    ),
    TutorialIds.learnDialogTag: TutorialMessage(
      id: TutorialIds.learnDialogTag,
      targetId: '',
      title: 'Name the tag',
      body: 'Pick an emoji from the row, type a short name, hit Save.',
    ),
    TutorialIds.learnDialogBill: TutorialMessage(
      id: TutorialIds.learnDialogBill,
      targetId: '',
      title: 'Set up the bill',
      body: 'Name it, choose fixed or variable, set the amount and reminder.',
    ),
    TutorialIds.learnDialogGoal: TutorialMessage(
      id: TutorialIds.learnDialogGoal,
      targetId: '',
      title: 'Define the goal',
      body: 'Name it, set the target. Optional deadline and color.',
    ),
    TutorialIds.learnDialogBudget: TutorialMessage(
      id: TutorialIds.learnDialogBudget,
      targetId: '',
      title: 'Pick a tag, set the cap',
      body: 'Tap any tag in the grid, then enter the monthly limit.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDialogSource: TutorialMessage(
      id: TutorialIds.learnDialogSource,
      targetId: '',
      title: 'Set up the source',
      body: 'Pick an emoji, name it, set the starting balance.',
    ),

    TutorialIds.learnGlobalTopCardForward: TutorialMessage(
      id: TutorialIds.learnGlobalTopCardForward,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Swipe the top card',
      body: 'Cycles through Goals, Income Sources, and Budget summaries.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnGlobalTopCardBack: TutorialMessage(
      id: TutorialIds.learnGlobalTopCardBack,
      targetId: TutorialTargetIds.dashTopCard,
      title: 'Now swipe back',
      body: 'Same gesture in the other direction returns you.',
      gesture: TutorialGesture.swipeRight,
    ),
    TutorialIds.learnGlobalLongPress: TutorialMessage(
      id: TutorialIds.learnGlobalLongPress,
      targetId: TutorialTargetIds.dedActionButton,
      title: 'Long-press to come home',
      body: 'Hold the bottom button on any page to jump back to Expenses.',
      gesture: TutorialGesture.longPress,
    ),
    TutorialIds.learnGlobalSwipePage: TutorialMessage(
      id: TutorialIds.learnGlobalSwipePage,
      targetId: '',
      title: 'Swipe to change page',
      body: 'Swipe left or right anywhere on the body to move between pages.',
      gesture: TutorialGesture.swipeLeft,
    ),
    TutorialIds.learnGlobalBackArrow: TutorialMessage(
      id: TutorialIds.learnGlobalBackArrow,
      targetId: TutorialTargetIds.shellBackArrow,
      title: 'Tap back to return',
      body: 'The arrow at top-left takes you to the previous page.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnDataDashTap: TutorialMessage(
      id: TutorialIds.learnDataDashTap,
      targetId: TutorialTargetIds.dashExpenseSection,
      title: 'Tap a tag to drill in',
      body: 'See every expense logged under that tag this month.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataRecordsTap: TutorialMessage(
      id: TutorialIds.learnDataRecordsTap,
      targetId: '',
      title: 'Tap a record',
      body: 'Long-press to edit or delete it.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataAccountsTap: TutorialMessage(
      id: TutorialIds.learnDataAccountsTap,
      targetId: '',
      title: 'Tap a card to expand',
      body: 'Each source opens to show recent activity and shortcuts.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataBillsTap: TutorialMessage(
      id: TutorialIds.learnDataBillsTap,
      targetId: TutorialTargetIds.billsFirstCard,
      title: 'Tap to pay',
      body: 'A single tap logs the bill. Long-press to edit or delete.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataCatsTap: TutorialMessage(
      id: TutorialIds.learnDataCatsTap,
      targetId: TutorialTargetIds.catsFirstCard,
      title: 'Tap to open',
      body: 'Opens the tag\'s entry list. Long-press to edit or delete.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataGoalsTap: TutorialMessage(
      id: TutorialIds.learnDataGoalsTap,
      targetId: TutorialTargetIds.goalsFirstCard,
      title: 'Tap to contribute',
      body: 'Move money into the goal. Long-press to edit, archive, or delete.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnDataBudgetTap: TutorialMessage(
      id: TutorialIds.learnDataBudgetTap,
      targetId: TutorialTargetIds.budgetFirstCard,
      title: 'Tap to adjust',
      body: 'Change the cap for this month only. Long-press to remove it.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnExpenseDialogIntro: TutorialMessage(
      id: TutorialIds.learnExpenseDialogIntro,
      targetId: '',
      title: 'Walk through the expense',
      body: 'A few quick steps. Tap to advance through each one.',
    ),
    TutorialIds.learnExpenseDialogPaidDue: TutorialMessage(
      id: TutorialIds.learnExpenseDialogPaidDue,
      targetId: TutorialTargetIds.entryPaidDue,
      title: 'Paid or due?',
      body: 'Paid means money already left. Due means you owe it later.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnExpenseDialogSource: TutorialMessage(
      id: TutorialIds.learnExpenseDialogSource,
      targetId: TutorialTargetIds.entrySourcePicker,
      title: 'Pick the source',
      body: 'Where the money came from: cash, bank, wallet, etc.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnExpenseDialogTag: TutorialMessage(
      id: TutorialIds.learnExpenseDialogTag,
      targetId: TutorialTargetIds.entryCategoryPicker,
      title: 'Pick a tag',
      body: 'Tags group your spending. Long-press in the list to manage them.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnExpenseDialogAmount: TutorialMessage(
      id: TutorialIds.learnExpenseDialogAmount,
      targetId: TutorialTargetIds.entryAmountField,
      title: 'Enter the amount',
      body: 'Type the value. Decimals work if you turn them on in Settings.',
      gesture: TutorialGesture.tap,
    ),
    TutorialIds.learnExpenseDialogName: TutorialMessage(
      id: TutorialIds.learnExpenseDialogName,
      targetId: TutorialTargetIds.entryNameChip,
      title: 'Name it (optional)',
      body: 'Tap to add a custom name. The tag name is used by default.',
      gesture: TutorialGesture.tap,
    ),

    TutorialIds.learnNoAccountsBlock: TutorialMessage(
      id: TutorialIds.learnNoAccountsBlock,
      targetId: '',
      title: 'You need a source first',
      body:
          'Tap "Add Income Source" to head over to Sources. Add one there, '
          'then come back to log expenses.',
    ),
  };

  static TutorialMessage? get(String id) => all[id];

  static List<String> learnChainFor(MainScreen page, BottomBarMode mode) {
    final tabs = mode == BottomBarMode.tabs;
    switch (page) {
      case MainScreen.dashboard:
        return tabs
            ? const [TutorialIds.learnDashTabsAdd]
            : const [
                TutorialIds.learnDashDedAdd,
                TutorialIds.learnDashDedNav,
              ];
      case MainScreen.records:
        return tabs
            ? const [TutorialIds.learnRecordsTabsToggle]
            : const [
                TutorialIds.learnRecordsDedToggle,
                TutorialIds.learnRecordsDedLongPress,
              ];
      case MainScreen.budget:
        return tabs
            ? const [TutorialIds.learnBudgetTabsAdd]
            : const [
                TutorialIds.learnBudgetDedAdd,
                TutorialIds.learnBudgetDedLongPress,
              ];
      case MainScreen.accounts:
        return tabs
            ? const [TutorialIds.learnSourcesTabsAdd]
            : const [
                TutorialIds.learnSourcesDedAdd,
                TutorialIds.learnSourcesDedLongPress,
              ];
      case MainScreen.bills:
        return tabs
            ? const [TutorialIds.learnBillsTabsAdd]
            : const [
                TutorialIds.learnBillsDedAdd,
                TutorialIds.learnBillsDedLongPress,
              ];
      case MainScreen.categories:
        return tabs
            ? const [TutorialIds.learnTagsTabsAdd]
            : const [
                TutorialIds.learnTagsDedAdd,
                TutorialIds.learnTagsDedLongPress,
              ];
      case MainScreen.goals:
        return tabs
            ? const [TutorialIds.learnGoalsTabsAdd]
            : const [
                TutorialIds.learnGoalsDedAdd,
                TutorialIds.learnGoalsDedLongPress,
              ];
    }
  }
}
