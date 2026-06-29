import 'package:flutter/material.dart';

import 'md_dashboard.dart';

class MdDashboardUiScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdDashboardUiScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.dashboard,
      );
}

class MdMeetingsScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdMeetingsScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.meetings,
      );
}

class MdCalendarScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdCalendarScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.calendar,
      );
}

class MdTimeSelectionScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdTimeSelectionScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.timeSelection,
      );
}

class MdMeetingDetailsScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdMeetingDetailsScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.meetingDetails,
      );
}

class MdAddParticipantsScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdAddParticipantsScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.addParticipants,
      );
}

class MdAddAgendaScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdAddAgendaScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.addAgenda,
      );
}

class MdReviewMeetingScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdReviewMeetingScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.reviewMeeting,
      );
}

class MdMeetingScheduledScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdMeetingScheduledScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.meetingScheduled,
      );
}

class MdMeetingListScreen extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const MdMeetingListScreen({
    super.key,
    this.email = '',
    this.firstName = 'Robert',
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) => _MdAdaptiveScreenShell(
        email: email,
        firstName: firstName,
        userId: userId,
        screen: MdDashboardScreen.meetingList,
      );
}

class _MdAdaptiveScreenShell extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;
  final MdDashboardScreen screen;

  const _MdAdaptiveScreenShell({
    required this.email,
    required this.firstName,
    required this.userId,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return MdDashboard(
      email: email,
      firstName: firstName,
      userId: userId,
      initialScreen: screen,
    );
  }
}
