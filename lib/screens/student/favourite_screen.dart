import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/favourite_provider.dart';
import '../../widgets/notice_card.dart';
import '../../core/theme/app_theme.dart';
import 'notice_details_screen.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize provider with real-time stream listener.
    Future.microtask(() {
      if (mounted) {
        context.read<FavouriteProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Show confirmation dialog before removing from favourites.
  /// Returns true if user confirms removal.
  Future<bool?> _showRemoveDialog(NoticeModel notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favourites'),
        content: const Text('This notice will be removed from your favourites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppTheme.secondaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _removeFromFavourites(notice);
      return true;
    }
    return false;
  }

  /// Remove notice from favourites with animation.
  Future<void> _removeFromFavourites(NoticeModel notice) async {
    final provider = context.read<FavouriteProvider>();
    final removed = await provider.removeFromFavourites(notice.id);

    if (removed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favourites'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouriteProvider>(
      builder: (context, provider, _) {
        // Show loading indicator while initially fetching data.
        if (provider.isLoading && provider.likedNotices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state with retry option.
        if (provider.errorMessage != null && provider.likedNotices.isEmpty) {
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
                  'Error loading favourites',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadLikedNotices(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter notices by search text.
        var notices = provider.likedNotices;
        if (_searchText.isNotEmpty) {
          notices = notices.where((n) {
            return n.title.toLowerCase().contains(_searchText.toLowerCase()) ||
                n.description.toLowerCase().contains(_searchText.toLowerCase());
          }).toList();
        }

        // Show empty state when no favourites exist.
        if (provider.likedNotices.isEmpty && _searchText.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadLikedNotices(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favourite notices yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Like notices to save them here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show empty search results
        if (_searchText.isNotEmpty && notices.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadLikedNotices(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
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
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Main list view with pull-to-refresh.
        return Column(
          children: [
            // Header with favourite count.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.favouriteCount} ${provider.favouriteCount == 1 ? 'favourite' : 'favourites'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
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
                  hintText: 'Search favourites...',
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

            // Favourites list with pull-to-refresh.
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await provider.loadLikedNotices();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return Dismissible(
                      key: Key(notice.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                      confirmDismiss: (_) => _showRemoveDialog(notice),
                      child: NoticeCard(
                        notice: notice,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NoticeDetailScreen(notice: notice),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}