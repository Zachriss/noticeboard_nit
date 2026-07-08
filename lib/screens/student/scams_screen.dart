import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../services/notice_service.dart';
import '../../widgets/notice_card.dart';
import 'notice_details_screen.dart';

class ScamsScreen extends StatefulWidget {
  const ScamsScreen({super.key});

  @override
  State<ScamsScreen> createState() => _ScamsScreenState();
}

class _ScamsScreenState extends State<ScamsScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  final NoticeService _noticeService = NoticeService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoticeModel>>(
      // Use the indexed "approved + createdAt" query, then filter category
      // client-side. This avoids needing a composite index on
      // (status, category, createdAt) which would fail when online.
      stream: _noticeService.getAllNotices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading scam alerts',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        var notices = snapshot.data ?? [];

        // Filter by the Scams/Fraud category (client-side).
        notices = notices
            .where((n) => n.category == 'Scams/Fraud')
            .toList();

        // Filter by search text.
        if (_searchText.isNotEmpty) {
          notices = notices.where((n) {
            return n.title.toLowerCase().contains(_searchText.toLowerCase()) ||
                n.description.toLowerCase().contains(_searchText.toLowerCase());
          }).toList();
        }

        // Empty state when no scam/fraud notices exist.
        if (notices.isEmpty && _searchText.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No scam or fraud alerts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reported scams/fraud notices will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // Empty search results.
        if (_searchText.isNotEmpty && notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scams / Fraud (${notices.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search scam alerts...',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Scam/fraud notices list.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  return NoticeCard(
                    notice: notice,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoticeDetailScreen(notice: notice),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}