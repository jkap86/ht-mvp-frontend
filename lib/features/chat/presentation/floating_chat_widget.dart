import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dm/presentation/providers/dm_inbox_provider.dart';
import 'providers/unified_chat_provider.dart';
import 'widgets/dm_conversation_list.dart';
import 'widgets/dm_conversation_view.dart';
import 'widgets/dm_new_conversation_view.dart';
import 'widgets/league_chat_view.dart';

/// Floating chat widget that can be collapsed to a FAB or expanded to a
/// draggable, resizable panel. Supports both DM and League Chat with tabs.
/// When leagueId is null, shows DM only. When leagueId is provided, shows both.
class FloatingChatWidget extends ConsumerStatefulWidget {
  final int? leagueId;

  const FloatingChatWidget({super.key, this.leagueId});

  @override
  ConsumerState<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends ConsumerState<FloatingChatWidget>
    with TickerProviderStateMixin {
  // Persistence keys
  static const _keyPositionX = 'floating_chat_position_x';
  static const _keyPositionY = 'floating_chat_position_y';
  static const _keyWidth = 'floating_chat_width';
  static const _keyHeight = 'floating_chat_height';

  // Size constraints
  static const _minSize = Size(280, 300);
  static const _maxSize = Size(500, 600);
  static const _defaultSize = Size(350, 400);

  // State
  bool _isExpanded = false;
  Offset? _position;
  Size _size = _defaultSize;
  bool _isLoaded = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Tab controller (only used when leagueId is provided)
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _initTabController();
    _loadSavedState();
  }

  void _initTabController() {
    _tabController?.removeListener(_onTabChanged); // Remove listener BEFORE dispose
    _tabController?.dispose();
    if (widget.leagueId != null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    } else {
      _tabController = null;
    }
  }

  void _onTabChanged() {
    if (_tabController == null) return;
    final chatNotifier = ref.read(unifiedChatProvider.notifier);
    if (_tabController!.index == 0) {
      chatNotifier.setTab(ChatTab.dm);
    } else {
      chatNotifier.setTab(ChatTab.league);
    }
  }

  @override
  void didUpdateWidget(covariant FloatingChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leagueId != oldWidget.leagueId) {
      _initTabController();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animationController.forward();
  }

  void _collapse() {
    _animationController.reverse().then((_) {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble(_keyPositionX);
    final savedY = prefs.getDouble(_keyPositionY);
    final savedWidth = prefs.getDouble(_keyWidth);
    final savedHeight = prefs.getDouble(_keyHeight);

    setState(() {
      if (savedX != null && savedY != null) {
        _position = Offset(savedX, savedY);
      }
      if (savedWidth != null && savedHeight != null) {
        _size = Size(
          savedWidth.clamp(_minSize.width, _maxSize.width),
          savedHeight.clamp(_minSize.height, _maxSize.height),
        );
      }
      _isLoaded = true;
    });
  }

  Future<void> _saveState() async {
    if (_position == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPositionX, _position!.dx);
    await prefs.setDouble(_keyPositionY, _position!.dy);
    await prefs.setDouble(_keyWidth, _size.width);
    await prefs.setDouble(_keyHeight, _size.height);
  }

  Offset _getDefaultPosition(Size screenSize) {
    return Offset(
      screenSize.width - _size.width - 16,
      screenSize.height - _size.height - 16,
    );
  }

  void _clampPosition(Size screenSize) {
    if (_position == null) return;
    final maxX = screenSize.width - _size.width;
    final maxY = screenSize.height - _size.height;
    _position = Offset(
      _position!.dx.clamp(0, maxX.clamp(0, double.infinity)),
      _position!.dy.clamp(0, maxY.clamp(0, double.infinity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSize = Size(constraints.maxWidth, constraints.maxHeight);

        _position ??= _getDefaultPosition(availableSize);
        _clampPosition(availableSize);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Transparent layer that ignores pointer events
            const IgnorePointer(
              child: SizedBox.expand(),
            ),
            if (!_isExpanded || _animationController.isAnimating)
              _buildCollapsedButton(),
            if (_isExpanded || _animationController.isAnimating)
              _buildExpandedPanel(availableSize),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedButton() {
    final dmUnread = ref.watch(dmUnreadCountProvider);
    final totalUnread = dmUnread;

    return Positioned(
      right: 16,
      bottom: 16,
      child: Badge(
        isLabelVisible: totalUnread > 0,
        label: Text('$totalUnread'),
        child: FloatingActionButton(
          heroTag: 'floating_chat_fab',
          onPressed: _expand,
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(Size availableSize) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomRight,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: _size.width,
              height: _size.height,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildHeader(colorScheme, availableSize),
                  Expanded(child: _buildContent()),
                  _buildResizeHandle(availableSize, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, Size availableSize) {
    final hasLeagueChat = widget.leagueId != null;
    final unifiedState = ref.watch(unifiedChatProvider);
    final isInDmSubView = unifiedState.dmViewMode != DmViewMode.inbox;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final maxX = availableSize.width - _size.width;
          final maxY = availableSize.height - _size.height;
          _position = Offset(
            (_position!.dx + details.delta.dx).clamp(0, maxX.clamp(0, double.infinity)),
            (_position!.dy + details.delta.dy).clamp(0, maxY.clamp(0, double.infinity)),
          );
        });
      },
      onPanEnd: (_) => _saveState(),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle row
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.drag_indicator,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  if (!hasLeagueChat || isInDmSubView)
                    Expanded(
                      child: Text(
                        'Messages',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
                    onPressed: _collapse,
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // Tab bar (only if league context and not in DM conversation)
            if (hasLeagueChat && !isInDmSubView)
              Builder(
                builder: (context) {
                  final dmUnreadCount = ref.watch(dmUnreadCountProvider);
                  return Container(
                    color: colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('DM'),
                              if (dmUnreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$dmUnreadCount',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Tab(text: 'League'),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final unifiedState = ref.watch(unifiedChatProvider);

    // If we have league context and tabs, use TabBarView (only when in inbox mode)
    if (widget.leagueId != null && unifiedState.dmViewMode == DmViewMode.inbox) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildDmView(),
          LeagueChatView(leagueId: widget.leagueId!),
        ],
      );
    }

    // Otherwise, just show DM view (inbox, conversation, or newConversation)
    return _buildDmView();
  }

  Widget _buildDmView() {
    final unifiedState = ref.watch(unifiedChatProvider);

    switch (unifiedState.dmViewMode) {
      case DmViewMode.inbox:
        return DmConversationList(
          onSelect: (conversationId, username) {
            ref.read(unifiedChatProvider.notifier).selectConversation(conversationId, username);
          },
          onNewConversation: () {
            ref.read(unifiedChatProvider.notifier).startNewConversation();
          },
        );
      case DmViewMode.conversation:
        return DmConversationView(
          conversationId: unifiedState.selectedConversationId!,
          otherUsername: unifiedState.selectedConversationUsername ?? 'Unknown',
          onBack: () {
            ref.read(unifiedChatProvider.notifier).backToInbox();
          },
        );
      case DmViewMode.newConversation:
        return DmNewConversationView(
          onBack: () {
            ref.read(unifiedChatProvider.notifier).backToInbox();
          },
          onConversationCreated: (conversationId, username) {
            ref.read(unifiedChatProvider.notifier).selectConversation(conversationId, username);
          },
        );
    }
  }

  Widget _buildResizeHandle(Size availableSize, ColorScheme colorScheme) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final maxWidth = (availableSize.width - _position!.dx - 8)
              .clamp(_minSize.width, _maxSize.width);
          final maxHeight = (availableSize.height - _position!.dy - 8)
              .clamp(_minSize.height, availableSize.height - 8);

          final newWidth = (_size.width + details.delta.dx)
              .clamp(_minSize.width, maxWidth);
          final newHeight = (_size.height + details.delta.dy)
              .clamp(_minSize.height, maxHeight);
          _size = Size(newWidth, newHeight);
        });
      },
      onPanEnd: (_) => _saveState(),
      child: Align(
        alignment: Alignment.bottomRight,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: Icon(
              Icons.open_in_full,
              size: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
