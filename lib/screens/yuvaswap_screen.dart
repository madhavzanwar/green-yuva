import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/swap_item.dart';
import '../services/yuvaswap_service.dart';
import '../theme/app_theme.dart';
import 'create_swap_item_screen.dart';
import 'swap_item_detail_screen.dart';
import 'main_screen.dart';

class YuvaSwapScreen extends StatefulWidget {
  const YuvaSwapScreen({super.key});

  @override
  State<YuvaSwapScreen> createState() => _YuvaSwapScreenState();
}

class _YuvaSwapScreenState extends State<YuvaSwapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  SwapCategory? _selectedCategory;
  SwapType? _selectedSwapType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapService = YuvaSwapService();

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: () {
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.onItemTapped(0);
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.recycling_rounded, color: AppColors.solidBlack, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'YuvaSwap',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 50)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(2, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                ),
                labelColor: AppColors.solidBlack,
                unselectedLabelColor: AppColors.solidBlack.withValues(alpha: 0.6),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Campus Market'),
                  Tab(text: 'My Swaps'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateSwapItemScreen()),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.dustyCoral,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(3.5, 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Post Item',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PaperGridBackground(
        child: AnimatedBuilder(
          animation: swapService,
          builder: (context, _) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(swapService),
                _buildMySwapsTab(swapService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrowseTab(YuvaSwapService swapService) {
    final items = swapService.filterItems(
      category: _selectedCategory,
      swapType: _selectedSwapType,
      searchQuery: _searchController.text,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // Landfill Waste Diverted Hero Card (NeoCard style)
        NeoCard(
          radius: 20,
          padding: const EdgeInsets.all(18),
          color: AppColors.sageGreen,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: Text(
                        'CAMPUS CIRCULAR IMPACT',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.solidBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${swapService.totalWasteDivertedKg.toStringAsFixed(1)} kg Waste Diverted',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~${swapService.totalCo2SavedKg.toStringAsFixed(1)} kg CO₂ saved by Indian students',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.solidBlack.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.handshake_rounded, color: AppColors.solidBlack, size: 30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar in NeoCard style
        NeoCard(
          radius: 16,
          padding: EdgeInsets.zero,
          color: AppColors.cardWhite,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.solidBlack,
            ),
            decoration: InputDecoration(
              hintText: 'Search textbooks, lab coats, calculators...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.solidBlack.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.solidBlack, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.solidBlack),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedCategory == null ? AppColors.dustyCoral : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: _selectedCategory == null
                        ? const [
                            BoxShadow(
                              color: AppColors.solidBlack,
                              offset: Offset(2, 2.5),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'All Items',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _selectedCategory == null ? Colors.white : AppColors.solidBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...SwapCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = isSelected ? null : cat;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.dustyCoral : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.solidBlack,
                                  offset: Offset(2, 2.5),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        SwapItem(
                          id: '',
                          title: '',
                          description: '',
                          category: cat,
                          condition: ItemCondition.good,
                          swapType: SwapType.freeGiveaway,
                          campusName: '',
                          wasteDivertedKg: 0,
                          co2SavedKg: 0,
                          donorName: '',
                          donorId: '',
                          donorKarmaScore: 0,
                          imageUrl: '',
                          createdAt: DateTime.now(),
                        ).categoryDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Items List
        if (items.isEmpty)
          NeoCard(
            radius: 18,
            padding: const EdgeInsets.all(32),
            color: AppColors.cardWhite,
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: AppColors.solidBlack),
                const SizedBox(height: 12),
                Text(
                  'No items found matching your filter.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to list an item from your campus!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildItemCard(item)),

        const SizedBox(height: 120), // Padding for floating bottom navbar
      ],
    );
  }

  Widget _buildItemCard(SwapItem item, {bool isMyListing = false, YuvaSwapService? swapService}) {
    return NeoCard(
      radius: 18,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      color: AppColors.cardWhite,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SwapItemDetailScreen(item: item),
          ),
        ).then((_) {
              if (mounted) setState(() {});
            });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Thumbnail with 2px black border
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.solidBlack, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.sageGreen.withValues(alpha: 0.3),
                  child: const Icon(Icons.school_rounded, color: AppColors.solidBlack, size: 36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: Text(
                        item.categoryDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.swapType == SwapType.freeGiveaway
                            ? AppColors.butterYellow
                            : AppColors.dustyCoral,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: Text(
                        item.swapTypeDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.solidBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.campusName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.recycling_rounded, size: 14, color: AppColors.solidBlack),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Saves ~${item.wasteDivertedKg}kg waste',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.solidBlack, width: 1.2),
                      ),
                      child: Text(
                        '${item.donorKarmaScore} Karma',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isMyListing && item.status != 'completed') ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      swapService?.markCompleted(item.id);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Handover completed! Thank you for reducing campus waste.'),
                          backgroundColor: AppColors.mintGreen,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '✓ Mark Handover Complete',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ),
                  ),
                ] else if (isMyListing && item.status == 'completed') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✓ Completed & Handed Over',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySwapsTab(YuvaSwapService swapService) {
    final listings = swapService.myListings;
    final requests = swapService.myRequests;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'My Active Listings (${listings.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        const SizedBox(height: 12),
        if (listings.isEmpty)
          NeoCard(
            radius: 16,
            padding: const EdgeInsets.all(20),
            color: AppColors.cardWhite,
            child: Text(
              'You have not posted any items yet. Help your juniors by posting textbooks, lab coats, or equipment!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          )
        else
          ...listings.map((item) => _buildItemCard(item, isMyListing: true, swapService: swapService)),

        const SizedBox(height: 24),
        Text(
          'My Active Requests (${requests.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          NeoCard(
            radius: 16,
            padding: const EdgeInsets.all(20),
            color: AppColors.cardWhite,
            child: Text(
              'You have no pending swap requests. Explore campus listings to request items!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          )
        else
          ...requests.map((item) => _buildItemCard(item)),
      ],
    );
  }
}
