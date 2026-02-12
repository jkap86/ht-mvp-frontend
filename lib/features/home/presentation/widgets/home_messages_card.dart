// Removed: HomeMessagesCard displayed unread message counts that were not
// backed by a real backend endpoint (unreadChatMessages is hardcoded to 0
// in dashboard.service.ts). This widget was dead code - never used on the
// home screen. Removed to prevent accidental reintroduction of fake numbers.
//
// To restore: implement read receipts on the backend first, then rebuild
// this widget with real data from a working endpoint.
