import 'roster_lineup.dart';
import 'roster_player.dart';

/// Severity level for roster legality warnings
enum LegalityLevel {
  /// Something the user should fix before games start
  warning,

  /// Informational notice (e.g., bye week conflicts)
  info,
}

/// A single legality warning about the roster/lineup state
class RosterLegalityWarning {
  final LegalityLevel level;
  final String message;
  final String? detail;
  final int? playerId;

  const RosterLegalityWarning({
    required this.level,
    required this.message,
    this.detail,
    this.playerId,
  });
}

/// Describes why a player cannot be moved to a specific slot
class SlotIneligibilityReason {
  final LineupSlot slot;
  final String reason;

  const SlotIneligibilityReason({
    required this.slot,
    required this.reason,
  });
}

/// Result of checking which slots a player can move to
class MoveValidation {
  /// Slots the player can legally move to
  final List<LineupSlot> validSlots;

  /// Slots the player cannot move to, with explanations
  final List<SlotIneligibilityReason> ineligibleSlots;

  const MoveValidation({
    required this.validSlots,
    required this.ineligibleSlots,
  });
}

/// Validates roster and lineup legality, producing descriptive messages.
class RosterLegalityValidator {
  const RosterLegalityValidator();

  /// Check the overall lineup for legality issues.
  /// Returns a list of warnings/issues the user should address.
  List<RosterLegalityWarning> validateLineup({
    required List<RosterPlayer> players,
    required RosterLineup? lineup,
    required RosterConfig config,
    required int currentWeek,
  }) {
    final warnings = <RosterLegalityWarning>[];

    if (lineup == null || players.isEmpty) return warnings;

    final slots = lineup.lineup;

    // Check for empty starting slots
    _checkEmptyStarterSlots(warnings, slots, config);

    // Check for players on bye week in starting lineup
    _checkByeWeekStarters(warnings, slots, players, currentWeek);

    // Check for injured starters
    _checkInjuredStarters(warnings, slots, players);

    // Check IR slot legality
    _checkIRSlotLegality(warnings, slots, players);

    return warnings;
  }

  /// Check if there are empty starting slots that should be filled.
  void _checkEmptyStarterSlots(
    List<RosterLegalityWarning> warnings,
    LineupSlots slots,
    RosterConfig config,
  ) {
    final slotChecks = <String, int>{};
    if (config.qb > 0) slotChecks['QB'] = config.qb - slots.qb.length;
    if (config.rb > 0) slotChecks['RB'] = config.rb - slots.rb.length;
    if (config.wr > 0) slotChecks['WR'] = config.wr - slots.wr.length;
    if (config.te > 0) slotChecks['TE'] = config.te - slots.te.length;
    if (config.flex > 0) slotChecks['FLEX'] = config.flex - slots.flex.length;
    if (config.superFlex > 0) slotChecks['Super Flex'] = config.superFlex - slots.superFlex.length;
    if (config.recFlex > 0) slotChecks['Rec Flex'] = config.recFlex - slots.recFlex.length;
    if (config.k > 0) slotChecks['K'] = config.k - slots.k.length;
    if (config.def > 0) slotChecks['DEF'] = config.def - slots.def.length;
    if (config.dl > 0) slotChecks['DL'] = config.dl - slots.dl.length;
    if (config.lb > 0) slotChecks['LB'] = config.lb - slots.lb.length;
    if (config.db > 0) slotChecks['DB'] = config.db - slots.db.length;
    if (config.idpFlex > 0) slotChecks['IDP Flex'] = config.idpFlex - slots.idpFlex.length;

    final emptySlots = <String>[];
    for (final entry in slotChecks.entries) {
      final emptyCount = entry.value;
      if (emptyCount > 0) {
        if (emptyCount == 1) {
          emptySlots.add(entry.key);
        } else {
          emptySlots.add('${entry.key} x$emptyCount');
        }
      }
    }

    if (emptySlots.isNotEmpty) {
      warnings.add(RosterLegalityWarning(
        level: LegalityLevel.warning,
        message: 'Your lineup has empty starting slots',
        detail: 'Empty: ${emptySlots.join(", ")}',
      ));
    }
  }

  /// Check for starters who are on bye this week.
  void _checkByeWeekStarters(
    List<RosterLegalityWarning> warnings,
    LineupSlots slots,
    List<RosterPlayer> players,
    int currentWeek,
  ) {
    final starterIds = slots.starters.toSet();
    final byeStarters = players.where(
      (p) =>
          starterIds.contains(p.playerId) &&
          p.byeWeek != null &&
          p.byeWeek == currentWeek,
    );

    for (final player in byeStarters) {
      warnings.add(RosterLegalityWarning(
        level: LegalityLevel.warning,
        message: '${player.fullName ?? "A player"} is on bye week $currentWeek',
        detail: 'Consider benching them or moving to another slot',
        playerId: player.playerId,
      ));
    }
  }

  /// Check for injured players in the starting lineup.
  void _checkInjuredStarters(
    List<RosterLegalityWarning> warnings,
    LineupSlots slots,
    List<RosterPlayer> players,
  ) {
    final starterIds = slots.starters.toSet();
    final injuredStarters = players.where(
      (p) =>
          starterIds.contains(p.playerId) &&
          p.injuryStatus != null &&
          _isSignificantInjury(p.injuryStatus!),
    );

    for (final player in injuredStarters) {
      warnings.add(RosterLegalityWarning(
        level: LegalityLevel.warning,
        message:
            '${player.fullName ?? "A player"} is ${player.injuryStatus} and starting',
        detail: 'Consider moving them to bench or IR',
        playerId: player.playerId,
      ));
    }
  }

  /// Check that players on IR are actually injured.
  void _checkIRSlotLegality(
    List<RosterLegalityWarning> warnings,
    LineupSlots slots,
    List<RosterPlayer> players,
  ) {
    if (slots.ir.isEmpty) return;

    final playerMap = {for (final p in players) p.playerId: p};
    for (final playerId in slots.ir) {
      final player = playerMap[playerId];
      if (player == null) continue;

      final injStatus = player.injuryStatus;
      if (injStatus == null || !_isIReligible(injStatus)) {
        warnings.add(RosterLegalityWarning(
          level: LegalityLevel.info,
          message:
              '${player.fullName ?? "A player"} on IR is not designated as injured',
          detail: injStatus == null
              ? 'Player has no injury designation'
              : 'Status "$injStatus" may not qualify for IR',
          playerId: player.playerId,
        ));
      }
    }
  }

  /// Determine which slots a player can legally move to.
  MoveValidation getValidMoveTargets({
    required RosterPlayer player,
    required LineupSlot? currentSlot,
    required RosterConfig config,
    required LineupSlots lineup,
  }) {
    final validSlots = <LineupSlot>[];
    final ineligible = <SlotIneligibilityReason>[];

    final allSlots = [
      if (config.qb > 0) LineupSlot.qb,
      if (config.rb > 0) LineupSlot.rb,
      if (config.wr > 0) LineupSlot.wr,
      if (config.te > 0) LineupSlot.te,
      if (config.flex > 0) LineupSlot.flex,
      if (config.superFlex > 0) LineupSlot.superFlex,
      if (config.recFlex > 0) LineupSlot.recFlex,
      if (config.k > 0) LineupSlot.k,
      if (config.def > 0) LineupSlot.def,
      if (config.dl > 0) LineupSlot.dl,
      if (config.lb > 0) LineupSlot.lb,
      if (config.db > 0) LineupSlot.db,
      if (config.idpFlex > 0) LineupSlot.idpFlex,
      LineupSlot.bn,
      if (config.ir > 0) LineupSlot.ir,
      if (config.taxi > 0) LineupSlot.taxi,
    ];

    for (final slot in allSlots) {
      if (slot == currentSlot) {
        // Already in this slot
        continue;
      }

      // Check position eligibility for starter slots
      if (slot != LineupSlot.bn &&
          slot != LineupSlot.ir &&
          slot != LineupSlot.taxi) {
        if (!slot.canFill(player.position)) {
          final positions = _getEligiblePositionsForSlot(slot);
          ineligible.add(SlotIneligibilityReason(
            slot: slot,
            reason:
                '${player.position ?? "?"} cannot play ${slot.displayName} (requires ${positions.join(", ")})',
          ));
          continue;
        }

        // Check if slot is full
        final slotCount = _getSlotCount(slot, config);
        final currentCount = _getCurrentSlotCount(slot, lineup);
        if (currentCount >= slotCount) {
          ineligible.add(SlotIneligibilityReason(
            slot: slot,
            reason:
                '${slot.displayName} slots are full ($currentCount/$slotCount)',
          ));
          continue;
        }
      }

      // Check IR eligibility
      if (slot == LineupSlot.ir) {
        if (player.injuryStatus == null || !_isIReligible(player.injuryStatus!)) {
          ineligible.add(SlotIneligibilityReason(
            slot: slot,
            reason: player.injuryStatus == null
                ? 'Cannot move to IR: ${player.fullName ?? "Player"} has no injury designation'
                : 'Cannot move to IR: "${player.injuryStatus}" may not qualify for Injured Reserve',
          ));
          continue;
        }

        final irCount = lineup.ir.length;
        if (irCount >= config.ir) {
          ineligible.add(SlotIneligibilityReason(
            slot: slot,
            reason: 'IR is full ($irCount/${config.ir} slots)',
          ));
          continue;
        }
      }

      // Check taxi eligibility
      if (slot == LineupSlot.taxi) {
        final taxiCount = lineup.taxi.length;
        if (taxiCount >= config.taxi) {
          ineligible.add(SlotIneligibilityReason(
            slot: slot,
            reason:
                'Taxi squad is full ($taxiCount/${config.taxi} players)',
          ));
          continue;
        }
      }

      validSlots.add(slot);
    }

    return MoveValidation(
      validSlots: validSlots,
      ineligibleSlots: ineligible,
    );
  }

  /// Build a descriptive error message for a failed player move.
  String describeMoveFailure({
    required RosterPlayer player,
    required LineupSlot targetSlot,
    required RosterConfig config,
    required LineupSlots lineup,
  }) {
    final playerName = player.fullName ?? 'Player';

    // Position mismatch
    if (targetSlot != LineupSlot.bn &&
        targetSlot != LineupSlot.ir &&
        targetSlot != LineupSlot.taxi) {
      if (!targetSlot.canFill(player.position)) {
        final eligible = _getEligiblePositionsForSlot(targetSlot);
        return 'Cannot start $playerName at ${targetSlot.displayName}: '
            '${player.position ?? "Unknown position"} is not eligible '
            '(requires ${eligible.join(", ")})';
      }
    }

    // IR check
    if (targetSlot == LineupSlot.ir) {
      if (player.injuryStatus == null) {
        return 'Cannot move $playerName to IR: '
            'Player is not designated as injured';
      }
      if (!_isIReligible(player.injuryStatus!)) {
        return 'Cannot move $playerName to IR: '
            '"${player.injuryStatus}" does not qualify for Injured Reserve';
      }
      if (lineup.ir.length >= config.ir) {
        return 'Cannot move $playerName to IR: '
            'IR is full (${config.ir} max)';
      }
    }

    // Taxi check
    if (targetSlot == LineupSlot.taxi) {
      if (lineup.taxi.length >= config.taxi) {
        return 'Cannot move $playerName to Taxi Squad: '
            'Taxi squad is full (max ${config.taxi} players)';
      }
    }

    // Slot full
    final slotCount = _getSlotCount(targetSlot, config);
    final currentCount = _getCurrentSlotCount(targetSlot, lineup);
    if (currentCount >= slotCount) {
      return 'Cannot start $playerName: '
          '${targetSlot.displayName} slots are all filled ($currentCount/$slotCount)';
    }

    return 'Cannot move $playerName to ${targetSlot.displayName}';
  }

  /// Get a descriptive message for roster capacity.
  String describeRosterCapacity({
    required int currentCount,
    required int maxSize,
  }) {
    if (currentCount >= maxSize) {
      return 'Roster is full ($currentCount/$maxSize). You must drop a player before adding.';
    }
    return 'Roster: $currentCount/$maxSize players';
  }

  /// Determine if an injury status qualifies for IR.
  bool _isIReligible(String injuryStatus) {
    final status = injuryStatus.toUpperCase();
    return status == 'IR' ||
        status == 'OUT' ||
        status == 'PUP' ||
        status == 'NFI' ||
        status == 'SUS' ||
        status == 'COV';
  }

  /// Determine if an injury status is significant enough to warn about.
  bool _isSignificantInjury(String injuryStatus) {
    final status = injuryStatus.toUpperCase();
    return status == 'OUT' ||
        status == 'IR' ||
        status == 'DOUBTFUL' ||
        status == 'PUP' ||
        status == 'NFI' ||
        status == 'SUS';
  }

  /// Get the eligible positions for a slot type.
  List<String> _getEligiblePositionsForSlot(LineupSlot slot) {
    switch (slot) {
      case LineupSlot.qb:
        return ['QB'];
      case LineupSlot.rb:
        return ['RB'];
      case LineupSlot.wr:
        return ['WR'];
      case LineupSlot.te:
        return ['TE'];
      case LineupSlot.flex:
        return ['RB', 'WR', 'TE'];
      case LineupSlot.superFlex:
        return ['QB', 'RB', 'WR', 'TE'];
      case LineupSlot.recFlex:
        return ['WR', 'TE'];
      case LineupSlot.k:
        return ['K'];
      case LineupSlot.def:
        return ['DEF'];
      case LineupSlot.dl:
        return ['DL'];
      case LineupSlot.lb:
        return ['LB'];
      case LineupSlot.db:
        return ['DB'];
      case LineupSlot.idpFlex:
        return ['DL', 'LB', 'DB'];
      case LineupSlot.bn:
      case LineupSlot.ir:
      case LineupSlot.taxi:
        return ['Any'];
    }
  }

  /// Get the configured slot count.
  int _getSlotCount(LineupSlot slot, RosterConfig config) {
    switch (slot) {
      case LineupSlot.qb:
        return config.qb;
      case LineupSlot.rb:
        return config.rb;
      case LineupSlot.wr:
        return config.wr;
      case LineupSlot.te:
        return config.te;
      case LineupSlot.flex:
        return config.flex;
      case LineupSlot.superFlex:
        return config.superFlex;
      case LineupSlot.recFlex:
        return config.recFlex;
      case LineupSlot.k:
        return config.k;
      case LineupSlot.def:
        return config.def;
      case LineupSlot.dl:
        return config.dl;
      case LineupSlot.lb:
        return config.lb;
      case LineupSlot.db:
        return config.db;
      case LineupSlot.idpFlex:
        return config.idpFlex;
      case LineupSlot.bn:
        return config.bn;
      case LineupSlot.ir:
        return config.ir;
      case LineupSlot.taxi:
        return config.taxi;
    }
  }

  /// Get the current count of players in a slot.
  int _getCurrentSlotCount(LineupSlot slot, LineupSlots lineup) {
    switch (slot) {
      case LineupSlot.qb:
        return lineup.qb.length;
      case LineupSlot.rb:
        return lineup.rb.length;
      case LineupSlot.wr:
        return lineup.wr.length;
      case LineupSlot.te:
        return lineup.te.length;
      case LineupSlot.flex:
        return lineup.flex.length;
      case LineupSlot.superFlex:
        return lineup.superFlex.length;
      case LineupSlot.recFlex:
        return lineup.recFlex.length;
      case LineupSlot.k:
        return lineup.k.length;
      case LineupSlot.def:
        return lineup.def.length;
      case LineupSlot.dl:
        return lineup.dl.length;
      case LineupSlot.lb:
        return lineup.lb.length;
      case LineupSlot.db:
        return lineup.db.length;
      case LineupSlot.idpFlex:
        return lineup.idpFlex.length;
      case LineupSlot.bn:
        return lineup.bn.length;
      case LineupSlot.ir:
        return lineup.ir.length;
      case LineupSlot.taxi:
        return lineup.taxi.length;
    }
  }
}
