import 'tutorial_ids.dart';

class TutorialMessage {
  final String id;
  final String targetId;
  final String title;
  final String body;

  const TutorialMessage({
    required this.id,
    required this.targetId,
    required this.title,
    required this.body,
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
          'Records, Budget, Income Sources, Dashboard, Bills, Categories, '
          'and Goals.',
    ),

    TutorialIds.accountsAddBtn: TutorialMessage(
      id: TutorialIds.accountsAddBtn,
      targetId: TutorialTargetIds.accountsAddBtn,
      title: 'Add an income source',
      body:
          'Cash, bank, mobile wallet — every place your money lives '
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
          'For money that arrives on a schedule — salary, '
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
      title: 'Pick a category',
      body:
          'Categories help the Records and Budget pages summarise '
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
          'Tap to add a custom name. The category name is used by '
          'default.',
    ),

    TutorialIds.dashExpenseSection: TutorialMessage(
      id: TutorialIds.dashExpenseSection,
      targetId: TutorialTargetIds.dashExpenseSection,
      title: 'This month\'s spending',
      body:
          'Paid expenses for the current month land here, grouped by '
          'category.',
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
          'Pick an emoji and name it. Set the amount below — or '
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
      title: 'Manage categories',
      body:
          'Add, rename, or delete the buckets your spending falls '
          'into.',
    ),
    TutorialIds.catDialogFields: TutorialMessage(
      id: TutorialIds.catDialogFields,
      targetId: TutorialTargetIds.catDialogName,
      title: 'Name the category',
      body:
          'A short descriptive name works best — Records and Budget '
          'will group your spending under it.',
    ),
    TutorialIds.catsCardTapHint: TutorialMessage(
      id: TutorialIds.catsCardTapHint,
      targetId: TutorialTargetIds.catsFirstCard,
      title: 'Tap to open',
      body:
          'Tapping a category opens its full entry list. Long-press '
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
          'below — you can optionally pick a deadline and a colour.',
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
          'Cap how much each category can spend in a month. Overrides '
          'work per-month if a single month is special.',
    ),
    TutorialIds.budgetDialogFields: TutorialMessage(
      id: TutorialIds.budgetDialogFields,
      targetId: TutorialTargetIds.budgetDialogField,
      title: 'Set the cap',
      body:
          'Type the maximum this category can spend in a month. '
          'Tap Clear later to remove the cap.',
    ),
    TutorialIds.budgetCardTapHint: TutorialMessage(
      id: TutorialIds.budgetCardTapHint,
      targetId: TutorialTargetIds.budgetFirstCard,
      title: 'Tap to adjust',
      body:
          'Tap the row to change the cap for this month only — the '
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
  };

  static TutorialMessage? get(String id) => all[id];
}
