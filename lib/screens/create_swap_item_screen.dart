import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/swap_item.dart';
import '../services/yuvaswap_service.dart';
import '../theme/app_theme.dart';

class CreateSwapItemScreen extends StatefulWidget {
  const CreateSwapItemScreen({super.key});

  @override
  State<CreateSwapItemScreen> createState() => _CreateSwapItemScreenState();
}

class _CreateSwapItemScreenState extends State<CreateSwapItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _prefController = TextEditingController();

  bool _submitted = false;
  SwapCategory _selectedCategory = SwapCategory.textbooks;
  ItemCondition _selectedCondition = ItemCondition.good;
  SwapType _selectedSwapType = SwapType.freeGiveaway;

  String _selectedCampus = 'PCCOE — Pune';

  final List<String> _indianCampuses = [
    'PCCOE — Pune',
    'IIT Bombay — Mumbai',
    'COEP Technological University — Pune',
    'BITS Pilani — Pilani',
    'VIT Vellore — Vellore',
    'NIT Trichy — Tiruchirappalli',
    'Manipal Institute of Technology — Manipal',
    'Delhi Technological University (DTU) — Delhi',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _prefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimatedWaste = SwapItem.estimateWaste(_selectedCategory);
    final estimatedCo2 = SwapItem.estimateCo2(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.solidBlack, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          'Create Swap Item',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.solidBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              // Side-by-side Impact Estimator Cards (matching reference chip layout)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(3.5, 4.0),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.recycling_rounded, color: AppColors.solidBlack, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Waste Diverted',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '~${estimatedWaste}kg',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dustyCoral,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(3.5, 4.0),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.cloud_done_rounded, color: AppColors.solidBlack, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'CO₂ Prevented',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '~${estimatedCo2}kg',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Item Title (Yellow Input Box matching reference design)
              Text(
                'ITEM TITLE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3.5, 4.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.solidBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Engineering Physics by HK Malik',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.solidBlack.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Category Selection (NeoPills matching reference tags)
              Text(
                'CATEGORY',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SwapCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final label = SwapItem(
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
                  ).categoryDisplay;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.dustyCoral : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(24),
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
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.solidBlack,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Condition Selection
              Text(
                'CONDITION',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ItemCondition.values.map((cond) {
                  final isSelected = _selectedCondition == cond;
                  String label = cond == ItemCondition.likeNew
                      ? 'Like New'
                      : (cond == ItemCondition.good ? 'Good' : 'Fair');
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCondition = cond),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.sageGreen : AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(14),
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
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Exchange Type (Giveaway vs Swap)
              Text(
                'EXCHANGE TYPE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSwapType = SwapType.freeGiveaway),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedSwapType == SwapType.freeGiveaway
                              ? AppColors.butterYellow
                              : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.solidBlack, width: 2.0),
                          boxShadow: _selectedSwapType == SwapType.freeGiveaway
                              ? const [
                                  BoxShadow(
                                    color: AppColors.solidBlack,
                                    offset: Offset(2, 2.5),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedSwapType == SwapType.freeGiveaway
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 16,
                              color: AppColors.solidBlack,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Free Giveaway',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSwapType = SwapType.itemSwap),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedSwapType == SwapType.itemSwap
                              ? AppColors.butterYellow
                              : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.solidBlack, width: 2.0),
                          boxShadow: _selectedSwapType == SwapType.itemSwap
                              ? const [
                                  BoxShadow(
                                    color: AppColors.solidBlack,
                                    offset: Offset(2, 2.5),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedSwapType == SwapType.itemSwap
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 16,
                              color: AppColors.solidBlack,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Item Swap',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedSwapType == SwapType.itemSwap) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _prefController,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.solidBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What would you like in return? (e.g. NCERT Chemistry)',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppColors.solidBlack.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter what you would like in return'
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Campus Selector
              Text(
                'CAMPUS / INSTITUTION',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3.5, 4.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCampus,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.solidBlack, size: 28),
                    items: _indianCampuses.map((campus) {
                      return DropdownMenuItem(
                        value: campus,
                        child: Text(
                          campus,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (c) {
                      if (c != null) setState(() => _selectedCampus = c);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description (White Input Box matching reference)
              Text(
                'ITEM DETAILS & PICKUP NOTE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3.5, 4.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.solidBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mention edition, condition notes, and convenient campus pickup spot (e.g. Central Library, Canteen).',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.solidBlack.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter item details' : null,
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button (Butter Yellow NeoButton matching reference CTA)
              NeoButton(
                text: 'Post Item to Campus',
                leading: const Icon(Icons.check_rounded, color: AppColors.solidBlack, size: 20),
                color: AppColors.butterYellow,
                textColor: AppColors.solidBlack,
                height: 54,
                onPressed: () {
                  if (_submitted) return;
                  if (_formKey.currentState?.validate() ?? false) {
                    _submitted = true;
                    YuvaSwapService().addItem(
                      title: _titleController.text.trim(),
                      description: _descController.text.trim(),
                      category: _selectedCategory,
                      condition: _selectedCondition,
                      swapType: _selectedSwapType,
                      campusName: _selectedCampus,
                      swapPreference: _selectedSwapType == SwapType.itemSwap
                          ? _prefController.text.trim()
                          : null,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.solidBlack,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.butterYellow, width: 2),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.butterYellow),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Listing posted to YuvaSwap! +50 GreenKarma!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
