
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/app_logo.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF102653);
  static const Color blue = Color(0xFF1769F4);
  static const Color background = Color(0xFFF5F7FB);

  late final AnimationController _controller;
  late final Animation<double> _animation;

  final List<Map<String, String>> properties = const [
    {
      'title': 'Modern Apartments',
      'subtitle': 'Discover apartments for sale and rent',
      'image':
          'https://images.unsplash.com/photo-1460317442991-0ec209397118?w=900',
    },
    {
      'title': 'Family Houses',
      'subtitle': 'Find a home that fits your lifestyle',
      'image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900',
    },
    {
      'title': 'Residential Properties',
      'subtitle': 'Explore real estate opportunities',
      'image':
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=900',
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              FadeTransition(
                opacity: _animation,
                child: Column(
                  children: [
                    _buildHero(isMobile),
                    _buildPropertySection(isMobile),
                    _buildAboutSection(),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isVerySmall = constraints.maxWidth < 370;

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 40,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Responsive logo
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppLogo(
                      light: false,
                      size: isVerySmall ? 22 : (isMobile ? 25 : 30),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Log In button: visible on ALL screen sizes
              TextButton(
                onPressed: () => context.push(Routes.login),
                style: TextButton.styleFrom(
                  foregroundColor: navy,
                  minimumSize: const Size(55, 40),
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmall ? 5 : 10,
                  ),
                ),
                child: const Text(
                  'Log In',
                  maxLines: 1,
                ),
              ),

              const SizedBox(width: 4),

              // Sign Up button
              SizedBox(
                width: isVerySmall
                    ? 76
                    : (isMobile ? 90 : 160),
                child: FilledButton(
                  onPressed: () => context.push(Routes.register),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                  ),
                  child: Text(
                    isMobile ? 'Sign Up' : 'Create Account',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVerySmall ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 45 : 65,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            navy,
            Color(0xFF1B3A7A),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Find Your Dream Property\nin Tunisia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 30 : 44,
              height: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Discover apartments, houses and real estate '
            'opportunities across Tunisia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCategory(Icons.apartment, 'Apartments'),
              _buildCategory(Icons.home_outlined, 'Houses'),
              _buildCategory(Icons.business, 'Buildings'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 40,
      ),
      child: Column(
        children: [
          const Text(
            'Explore Real Estate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Find the right property for your needs.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isMobile
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: properties.map((property) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildPropertyCard(property),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, String> property) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            property['image']!,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 190,
                color: const Color(0xFFE1EAFF),
                child: const Center(
                  child: Icon(
                    Icons.apartment,
                    size: 60,
                    color: blue,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title']!,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property['subtitle']!,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFFC),
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(
            Icons.real_estate_agent,
            size: 44,
            color: blue,
          ),
          SizedBox(height: 14),
          Text(
            'Why Choose ImmoFind?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'ImmoFind helps you discover, explore and '
            'manage real estate properties in Tunisia.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: navy,
      padding: const EdgeInsets.all(22),
      child: const Text(
        'ImmoFind - Find Your Next Home',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
