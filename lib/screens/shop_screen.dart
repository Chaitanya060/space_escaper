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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
}
