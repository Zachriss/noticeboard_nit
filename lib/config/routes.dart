import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student/student_home.dart';
import '../screens/student/notice_details_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/faq_screen.dart';
import '../screens/student/feedback_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/create_notice_screen.dart';
import '../screens/admin/manage_notices_screen.dart';
import '../screens/admin/view_feedback_screen.dart';
import '../screens/super_admin/super_admin_dashboard.dart';
import '../screens/super_admin/manage_admins_screen.dart';
import '../screens/super_admin/approve_notices_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String studentHome = '/student/home';
  static const String studentProfile = '/student/profile';
  static const String noticeDetails = '/notice/details';
  static const String faq = '/faq';
  static const String feedback = '/feedback';
  static const String adminDashboard = '/admin/dashboard';
  static const String createNotice = '/admin/create-notice';
  static const String manageNotices = '/admin/manage-notices';
  static const String viewFeedback = '/admin/view-feedback';
  static const String superAdminDashboard = '/superadmin/dashboard';
  static const String manageAdmins = '/superadmin/manage-admins';
  static const String approveNotices = '/superadmin/approve-notices';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case studentProfile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case noticeDetails:
        final noticeId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => NoticeDetailsScreen(noticeId: noticeId));
      case faq:
        return MaterialPageRoute(builder: (_) => const FAQScreen());
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case createNotice:
        return MaterialPageRoute(builder: (_) => const CreateNoticeScreen());
      case manageNotices:
        return MaterialPageRoute(builder: (_) => const ManageNoticesScreen());
      case viewFeedback:
        return MaterialPageRoute(builder: (_) => const ViewFeedbackScreen());
      case superAdminDashboard:
        return MaterialPageRoute(builder: (_) => const SuperAdminDashboard());
      case manageAdmins:
        return MaterialPageRoute(builder: (_) => const ManageAdminsScreen());
      case approveNotices:
        return MaterialPageRoute(builder: (_) => const ApproveNoticesScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}