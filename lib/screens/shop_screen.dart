import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/powerup_data.dart';
import '../data/progression_data.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_CoinPack> _coinPacks = const [
    _CoinPack(price: '₹19', coins: 2000, tag: 'Mini Pack', color: Color(0xFFFFD93D)),
    _CoinPack(price: '₹29', coins: 3500, tag: 'Best for Beginners', color: Color(0xFFFFD93D)),
    _CoinPack(price: '₹49', coins: 7000, tag: 'Popular', color: Color(0xFF00D9FF)),
    _CoinPack(price: '₹79', coins: 12000, tag: 'Most Value', color: Color(0xFF00D9FF)),
    _CoinPack(price: '₹99', coins: 16000, tag: 'Best Seller ⭐', color: Color(0xFF00D9FF)),
    _CoinPack(price: '₹199', coins: 40000, tag: 'Mega Pack', color: Color(0xFFA855F7)),
    _CoinPack(price: '₹299', coins: 70000, tag: 'Ultra Pack', color: Color(0xFFA855F7)),
    _CoinPack(price: '₹499', coins: 150000, tag: 'Galaxy Pack 🚀', color: Color(0xFFA855F7)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SHOP',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD93D),
          labelColor: const Color(0xFFFFD93D),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ITEMS'),
            Tab(text: 'SKILLS'),
            Tab(text: 'COINS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Currency bar
          _buildCurrencyBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConsumablesTab(),
                _buildSkillsTab(),
                _buildCoinsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1929),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD93D), size: 20),
          const SizedBox(width: 6),
          Text('${GameStorage.totalCoins}',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD93D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 24),
          const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 6),
          Text('${GameStorage.stardust}',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildConsumablesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allConsumables.length,
      itemBuilder: (context, index) {
        final c = allConsumables[index];
        final owned = GameStorage.getConsumableCount(c.type.name);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1929),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.color.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(c.icon, color: c.color, size: 24),
            ),
            title: Text(c.name,
                style: GoogleFonts.orbitron(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Owned: $owned',
                    style: TextStyle(
                        color: c.color.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
            trailing: GestureDetector(
              onTap: () {
                if (GameStorage.spendCoins(c.coinCost)) {
                  GameStorage.addConsumable(c.type.name);
                  setState(() {});
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.color, c.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('${c.coinCost}',
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skillTree.length,
      itemBuilder: (context, index) {
        final skill = skillTree[index];
        final level = GameStorage.getSkillLevel(skill.id);
        final isMaxed = level >= skill.maxLevel;
        final cost = skill.costPerLevel * (level + 1);
        final canBuy = !isMaxed && GameStorage.stardust >= cost;
        bool prereqMet = true;
        if (skill.prerequisite != null) {
          prereqMet = GameStorage.getSkillLevel(skill.prerequisite!) > 0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1929),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMaxed
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : prereqMet
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF1E293B).withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: Icon(skill.icon,
                color: level > 0
                    ? const Color(0xFF00D9FF)
                    : prereqMet
                        ? Colors.white38
                        : Colors.white12,
                size: 28),
            title: Text(
              skill.name,
              style: GoogleFonts.orbitron(
                color: prereqMet ? Colors.white : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.description,
                    style: TextStyle(
                        color: prereqMet ? Colors.white54 : Colors.white12,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(skill.maxLevel, (i) {
                    return Container(
                      width: 12,
                      height: 6,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: i < level
                            ? const Color(0xFF00D9FF)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
            trailing: isMaxed
                ? Text('MAX',
                    style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFD700), fontWeight: FontWeight.bold))
                : prereqMet
                    ? GestureDetector(
                        onTap: canBuy
                            ? () {
                                GameStorage.upgradeSkill(skill.id, cost);
                                setState(() {});
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: canBuy
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text('$cost',
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : const Icon(Icons.lock_outline,
                        color: Colors.white12, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildCoinsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coinPacks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1929),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Coin Packs', style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD93D), fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Starter • Mid • High Tier', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        }
        final p = _coinPacks[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1929),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.color.withValues(alpha: 0.35)),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.monetization_on, color: Colors.white, size: 24),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${p.coins} COINS', style: GoogleFonts.orbitron(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.color.withValues(alpha: 0.6)),
                  ),
                  child: Text(p.tag, style: GoogleFonts.orbitron(
                    color: p.color, fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ],
            ),
            subtitle: Text(p.price, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: GestureDetector(
              onTap: () => _purchaseCoins(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.color, p.color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(p.price, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _purchaseCoins(_CoinPack p) {
    GameStorage.addCoins(p.coins);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchased ${p.coins} coins'),
        backgroundColor: p.color,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _CoinPack {
  final String price;
  final int coins;
  final String tag;
  final Color color;
  const _CoinPack({required this.price, required this.coins, required this.tag, required this.color});
}
