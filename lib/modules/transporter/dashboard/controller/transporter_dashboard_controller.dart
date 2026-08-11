import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:get/get.dart';

// --- Hardcoded Data Models ---
class MetricCard {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  MetricCard({required this.title, required this.value, required this.change, required this.isPositive});
}

class KpiItem {
  final String title;
  final dynamic value;
  final String subtitle;
  final String type;
  final String redirectTo;
  final String screen;

  KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.type,
    required this.redirectTo,
    required this.screen,
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      title: json['title'] ?? '',
      value: json['value'] ?? 0,
      subtitle: json['subtitle'] ?? '',
      type: json['type'] ?? '',
      redirectTo: json['redirect_to'] ?? '',
      screen: json['screen'] ?? '',
    );
  }
}

class ChartData {
  final List<String> labels;
  final List<double> values;
  ChartData({required this.labels, required this.values});
}

class DonutItem {
  final String label;
  final double percentage;
  DonutItem({required this.label, required this.percentage});
}

class BarItem {
  final String label;
  final double value;
  BarItem({required this.label, required this.value});
}

class ActivityItem {
  final String type; // 'trip', 'driver', 'branch'
  final String title;
  final String subtitle;
  final String time;
  final String status;
  ActivityItem({required this.type, required this.title, required this.subtitle, required this.time, required this.status});
}

class TransporterDashboardController extends GetxController {
  var isLoading = false.obs;
  var isExpanded = false.obs;
  
  var username = ''.obs;
  var branchName = 'Mumbai Central Branch'.obs;
  var dateStr = '22 May, 2025'.obs;

  // Overview metrics
  var dynamicKpis = <KpiItem>[].obs;

  // Analytics Trends
  var earningsTrend = ChartData(
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    values: [8, 10, 11, 10, 14, 16, 20],
  ).obs;

  var deliveryStatus = [
    DonutItem(label: 'Delivered', percentage: 68),
    DonutItem(label: 'In Transit', percentage: 24),
    DonutItem(label: 'Pending', percentage: 8),
  ].obs;

  var transportTypes = [
    DonutItem(label: 'FTL', percentage: 52),
    DonutItem(label: 'PTL', percentage: 28),
    DonutItem(label: 'Express', percentage: 20),
  ].obs;

  var topRoutes = [
    BarItem(label: 'Mumbai - Delhi', value: 512),
    BarItem(label: 'Mumbai - Pune', value: 423),
    BarItem(label: 'Delhi - Bengaluru', value: 312),
    BarItem(label: 'Chennai - Hyderabad', value: 198),
  ].obs;

  // Performance Insights
  var avgDeliveryTime = MetricCard(title: "Avg. Delivery Time", value: "2.6 Days", change: "- 0.8 Days", isPositive: true).obs;
  var onTimeDelivery = MetricCard(title: "On-Time Delivery", value: "92.5%", change: "+ 4.2%", isPositive: true).obs;
  var fuelEfficiency = MetricCard(title: "Fuel Efficiency", value: "6.8 km/l", change: "+ 0.6 km/l", isPositive: true).obs;
  var customerRating = MetricCard(title: "Customer Rating", value: "4.6/5", change: "+ 0.3", isPositive: true).obs;

  // Monthly Revenue
  var monthlyRevenue = ChartData(
    labels: ['Jan', 'Feb', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    values: [12, 14, 15, 20, 42, 14, 15, 12, 14, 13, 14],
  ).obs;

  // Recent Activity
  var activities = [
    ActivityItem(
      type: 'trip', 
      title: 'Trip #TRP-4872 Completed', 
      subtitle: 'Mumbai to Delhi', 
      time: 'Today, 10:30 AM', 
      status: 'Completed'
    ),
    ActivityItem(
      type: 'driver', 
      title: 'Driver Amit Singh Assigned', 
      subtitle: 'Vehicle MH-12-AB-1234', 
      time: 'Today, 09:15 AM', 
      status: 'Assigned'
    ),
    ActivityItem(
      type: 'branch', 
      title: 'Branch Access Approved', 
      subtitle: 'Bengaluru Hub', 
      time: 'Today, 08:45 AM', 
      status: 'Approved'
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    fetchDashboardOverview();
  }

  Future<void> _loadUserInfo() async {
    final storedName = await AppPreferences.getUsername();
    username.value = (storedName != null && storedName.isNotEmpty) ? storedName : 'Rahul';
  }

  Future<void> fetchDashboardOverview() async {
    try {
      isLoading(true);
      
      final response = await ApiClient.get(endpoint: ApiUrls.transporterDashboard, requireAuth: true);
      
      if (response != null && response['success'] == true) {
        final kpisJson = response['data']?['kpis'] as List?;
        if (kpisJson != null) {
          dynamicKpis.value = kpisJson.map((e) => KpiItem.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("Error fetching KPIs: $e");
    } finally {
      isLoading(false);
    }
  }
}
