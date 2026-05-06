import 'package:flutter/material.dart';

import '../app.dart';
import '../data/settings_service.dart';
import '../widgets/live_icon.dart';
import '../widgets/main_menu_sheet.dart';
import '../widgets/main_shell.dart';
import 'learn_service.dart';
import 'tutorial_ids.dart';
import 'tutorial_nav_observer.dart';
import 'tutorial_service.dart';

class LearnButton extends StatefulWidget {
  final MainScreen page;
  const LearnButton({super.key, required this.page});

  @override
  State<LearnButton> createState() => _LearnButtonState();
}

class _LearnButtonState extends State<LearnButton> {
  @override
  void initState() {
    super.initState();
    LearnService.instance.changeCounter.addListener(_onChange);
    bottomBarModeNotifier.addListener(_onChange);
  }

  @override
  void dispose() {
    LearnService.instance.changeCounter.removeListener(_onChange);
    bottomBarModeNotifier.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  String _dialogKeyFor(MainScreen p) {
    switch (p) {
      case MainScreen.dashboard:
        return 'expense';
      case MainScreen.accounts:
        return 'account';
      case MainScreen.bills:
        return 'bill';
      case MainScreen.categories:
        return 'tag';
      case MainScreen.goals:
        return 'goal';
      case MainScreen.budget:
        return 'budget';
      case MainScreen.records:
        return 'records';
    }
  }

  String _actionMessageId(MainScreen p, BottomBarMode mode) {
    final tabs = mode == BottomBarMode.tabs;
    switch (p) {
      case MainScreen.dashboard:
        return tabs
            ? TutorialIds.learnDashTabsAdd
            : TutorialIds.learnDashDedAdd;
      case MainScreen.records:
        return tabs
            ? TutorialIds.learnRecordsTabsToggle
            : TutorialIds.learnRecordsDedToggle;
      case MainScreen.budget:
        return tabs
            ? TutorialIds.learnBudgetTabsAdd
            : TutorialIds.learnBudgetDedAdd;
      case MainScreen.accounts:
        return tabs
            ? TutorialIds.learnSourcesTabsAdd
            : TutorialIds.learnSourcesDedAdd;
      case MainScreen.bills:
        return tabs
            ? TutorialIds.learnBillsTabsAdd
            : TutorialIds.learnBillsDedAdd;
      case MainScreen.categories:
        return tabs
            ? TutorialIds.learnTagsTabsAdd
            : TutorialIds.learnTagsDedAdd;
      case MainScreen.goals:
        return tabs
            ? TutorialIds.learnGoalsTabsAdd
            : TutorialIds.learnGoalsDedAdd;
    }
  }

  String? _dataMessageId(MainScreen p) {
    switch (p) {
      case MainScreen.dashboard:
        return TutorialIds.learnDataDashTap;
      case MainScreen.records:
        return TutorialIds.learnDataRecordsTap;
      case MainScreen.accounts:
        return TutorialIds.learnDataAccountsTap;
      case MainScreen.bills:
        return TutorialIds.learnDataBillsTap;
      case MainScreen.categories:
        return TutorialIds.learnDataCatsTap;
      case MainScreen.goals:
        return TutorialIds.learnDataGoalsTap;
      case MainScreen.budget:
        return TutorialIds.learnDataBudgetTap;
    }
  }

  static bool _chainInFlight = false;

  Future<void> _onTap() async {
    if (_chainInFlight) return;
    _chainInFlight = true;
    try {
      await _runChain();
    } finally {
      LearnService.instance.setPendingDialog(null);
      _chainInFlight = false;
    }
  }

  Future<void> _runChain() async {
    final mode = bottomBarModeNotifier.value;
    final page = widget.page;
    final shell = MainShell.maybeOf(context);
    final svc = TutorialService.instance;
    final learn = LearnService.instance;
    final baseDepth = TutorialNavObserver.instance.depth;

    await learn.markPageUsed(page, mode);
    if (!mounted) return;
    learn.setPendingDialog(_dialogKeyFor(page));

    final actionId = _actionMessageId(page, mode);
    await svc.show(context, actionId, force: true, forced: true);
    if (!mounted) return;
    await svc.waitForDepth(baseDepth);
    if (!mounted) return;

    bool onOriginPage() => MainShell.maybeOf(context)?.currentPage == page;
    final hasData = shell?.pageHasData(page) ?? false;

    if (onOriginPage() && hasData) {
      final dataId = _dataMessageId(page);
      if (dataId != null) {
        await svc.show(context, dataId, force: true, forced: false);
        if (!mounted) return;
        await svc.waitForDepth(baseDepth);
        if (!mounted) return;
      }
    }

    if (onOriginPage() &&
        page == MainScreen.dashboard &&
        !learn.topCardSeen) {
      await svc.show(
        context,
        TutorialIds.learnGlobalTopCardForward,
        force: true,
        forced: true,
      );
      if (!mounted) return;
      if (onOriginPage()) {
        await svc.show(
          context,
          TutorialIds.learnGlobalTopCardBack,
          force: true,
          forced: true,
        );
        if (!mounted) return;
      }
      await learn.markTopCardSeen();
      if (!mounted) return;
    }

    if (onOriginPage() &&
        page != MainScreen.dashboard &&
        mode == BottomBarMode.dedicated &&
        !learn.longPressSeen) {
      await svc.show(
        context,
        TutorialIds.learnGlobalLongPress,
        force: true,
        forced: true,
      );
      if (!mounted) return;
      await learn.markLongPressSeen();
      if (!mounted) return;
    }

    if (!learn.swipePageSeen) {
      await svc.show(
        context,
        TutorialIds.learnGlobalSwipePage,
        force: true,
        forced: true,
      );
      if (!mounted) return;
      await learn.markSwipePageSeen();
      if (!mounted) return;

      await svc.show(
        context,
        TutorialIds.learnGlobalBackArrow,
        force: true,
        forced: true,
      );
      if (!mounted) return;
      await learn.markBackArrowSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = bottomBarModeNotifier.value;
    if (LearnService.instance.isPageUsed(widget.page, mode)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const PulsingGlowIcon(
        icon: Icons.school_outlined,
        size: 24,
        color: Color(0xFFFFA000),
        glowColor: Color(0xFFFFA000),
        maxBlur: 14,
        minOpacity: 0.30,
        maxOpacity: 0.75,
        duration: Duration(milliseconds: 1300),
      ),
      tooltip: 'Tap to learn this page',
      onPressed: _onTap,
    );
  }
}
