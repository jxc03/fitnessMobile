import 'package:flutter/material.dart';

/// This screen displays the details of a specific exercise.
/// It presents information such as the exercise name, equipment needed, images etc

class ExerciseDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  // Define the color palette for the entire screen
  // These colors are to present healthy and wellness
  static const Color primaryColor = Color(0xFF2A6F97); // Deep blue - primary accent
  static const Color secondaryColor = Color(0xFF61A0AF); // Teal blue - secondary accent
  static const Color accentGreen = Color(0xFF4C956C); // Forest green - energy and growth
  static const Color accentTeal = Color(0xFF2F6D80); // Deep teal - calm and trust
  static const Color neutralDark = Color(0xFF3D5A6C); // Dark slate - professional text
  static const Color neutralLight = Color(0xFFF5F7FA); // Light gray - backgrounds
  static const Color neutralMid = Color(0xFFE1E7ED); // Mid gray - dividers, borders

  /// Build the main widget for the exercise detail screen
  @override
  Widget build(BuildContext context) {
    // Get the instructions from the exercise data
    final instructions = exercise['instructions'];
    
    return Scaffold(
      // App bar with updated styling
      appBar: AppBar(
        title: Text(
          exercise['name'] ?? 'Exercise Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Favorite functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise image with improved styling
                    _buildImageSection(exercise['images']),
                    
                    // Information section with consistent card styling
                    _buildInfoSection(context),
                  ],
                ),
              ),
              // Tab bar for instructions, tips, mistakes, and precautions
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'How to'),
                      Tab(text: 'Tips'),
                      Tab(text: 'Mistakes'),
                      Tab(text: 'Precautions'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Tab content with improved styling
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['steps'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['tips'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['commonMistakes'] : null),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildListSection(instructions != null ? instructions['precautions'] : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the information section with equipment, muscle groups, and tags
  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment Card
          _buildInfoCard(
            context,
            title: 'Equipment',
            icon: Icons.fitness_center,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                exercise['equipment']?.toString() ?? 'No equipment needed',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            iconColor: accentTeal,
          ),
          
          const SizedBox(height: 16),
          
          // Muscle Groups Card
          if (exercise['muscleGroups'] != null)
            _buildInfoCard(
              context,
              title: 'Muscle Groups',
              icon: Icons.accessibility_new,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildMuscleGroups(exercise['muscleGroups']),
              ),
              iconColor: primaryColor,
            ),
          
          const SizedBox(height: 16),
          
          // Tags Card
          if (exercise['tags'] != null)
            _buildInfoCard(
              context,
              title: 'Tags',
              icon: Icons.tag,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildTags(exercise['tags']),
              ),
              iconColor: primaryColor,
            ),
          
          const SizedBox(height: 16),
          
          // Videos Section
          if (exercise['videos'] != null) 
            _buildVideosCard(context),
            
          // Photos Gallery
          if (exercise['photos'] != null) 
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildInfoCard(
                context,
                title: 'Photo Gallery',
                icon: Icons.photo_library,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildPhotoGallery(exercise['photos']),
                ),
                iconColor: secondaryColor,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build reusable info card with consistent styling
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: neutralDark,
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
  
  /// Build videos section
  Widget _buildVideosCard(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Videos',
      icon: Icons.play_circle_filled,
      iconColor: primaryColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: neutralLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play button with animation effect
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Videos will be available soon',
                style: TextStyle(
                  color: neutralDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Styled notify button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Notify Me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build an image section to display the exercise image
  Widget _buildImageSection(dynamic imageUrl) {
    // Check if imageUrl is not null and is a string 
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      // Check if the image is a local asset or a network image
      final bool isLocalAsset = !imageUrl.toString().startsWith('http') &&
                                !imageUrl.toString().startsWith('https'); 
      return SizedBox(
        height: 250,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with gradient overlay
            ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, neutralDark.withOpacity(0.7)],
                  stops: const [0.7, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: isLocalAsset
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return _buildImagePlaceholder();
                    },
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  ),
            ),
            
            // Exercise name overlay at bottom of image (not sure to keep it)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                exercise['name'] ?? 'Exercise Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }
  
  /// Build a placeholder for when no image is available
  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: neutralMid,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 60, color: neutralDark.withOpacity(0.7)),
          const SizedBox(height: 16),
          const Text(
            'No image available',
            style: TextStyle(
              color: neutralDark,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the muscle groups section
  Widget _buildMuscleGroups(dynamic muscleGroups) {
    if (muscleGroups == null) {
      return const Text('No muscle groups specified');
    }
    
    if (muscleGroups is String) {
      // For a single string muscle group, display it as a chip
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: [
          _buildStyledChip(
            muscleGroups,
            accentGreen,
            Icons.accessibility_new,
          ),
        ],
      );
    } else if (muscleGroups is List) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: List.generate(
          muscleGroups.length,
          (index) => _buildStyledChip(
            muscleGroups[index].toString(),
            accentGreen,
            Icons.accessibility_new,
          ),
        ),
      );
    } else if (muscleGroups is Map) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: muscleGroups.entries.map((e) {
          return _buildStyledChip(
            e.value.toString(),
            accentGreen,
            Icons.accessibility_new,
          );
        }).toList(),
      );
    } else {
      // For any other data type, convert to string and display as a chip
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: [
          _buildStyledChip(
            muscleGroups.toString(),
            accentGreen,
            Icons.accessibility_new,
          ),
        ],
      );
    }
  }
  
  
  /// Build section for tags with improved chip design
  Widget _buildTags(dynamic tags) {
    if (tags == null) {
      return const Text('No tags specified');
    }
    
    if (tags is String) {
      return Text(
        tags,
        style: const TextStyle(fontSize: 16),
      );
    } else if (tags is List) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: List.generate(
          tags.length,
          (index) => _buildStyledChip(
            tags[index].toString(),
            accentGreen,
            Icons.tag,
          ),
        ),
      );
    } else if (tags is Map) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: tags.entries.map((e) {
          return _buildStyledChip(
            e.value.toString(),
            accentGreen,
            Icons.tag,
          );
        }).toList(),
      );
    } else {
      return Text(
        tags.toString(),
        style: const TextStyle(fontSize: 16),
      );
    }
  }
  
  /// Build a styled chip with icon and custom colors
  Widget _buildStyledChip(String label, Color color, IconData icon) {
    final Color backgroundColor = color.withOpacity(0.12);
    final Color textAndIconColor = color.withOpacity(0.9);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textAndIconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build photo gallery
  Widget _buildPhotoGallery(dynamic photos) {
    if (photos == null || (photos is List && photos.isEmpty) || (photos is String && photos.isEmpty)) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: neutralLight,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 40, color: neutralDark.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Photo gallery will be available soon',
              style: TextStyle(color: neutralDark, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Convert to a list if it's a single string
    List<String> photoList = [];
    if (photos is String) {
      photoList = [photos];
    } else if (photos is List) {
      photoList = List<String>.from(photos);
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoList.length,
        itemBuilder: (context, index) {
          final photo = photoList[index];
          final bool isLocalAsset = !photo.startsWith('http') && !photo.startsWith('https');
          
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                _showFullScreenImage(context, photo, index, photoList);
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: isLocalAsset
                    ? Image.asset(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: neutralLight,
                            child: Icon(Icons.broken_image, color: neutralDark.withOpacity(0.5)),
                          );
                        },
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: neutralLight,
                            child: Icon(Icons.broken_image, color: neutralDark.withOpacity(0.5)),
                          );
                        },
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to show full screen image (not working, need to keep debugging it)
  void _showFullScreenImage(BuildContext context, String imageUrl, int initialIndex, List<String> allImages) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${initialIndex + 1}/${allImages.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Stack(
            children: [
              // Image PageView
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final String currentImage = allImages[index];
                  final bool isLocalAsset = !currentImage.startsWith('http') && !currentImage.startsWith('https');
                
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 3,
                      child: isLocalAsset
                        ? Image.asset(
                            currentImage,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Error loading image', style: TextStyle(color: Colors.white)),
                              );
                            },
                          )
                        : Image.network(
                            currentImage,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Error loading image', style: TextStyle(color: Colors.white)),
                              );
                            },
                          ),
                    ),
                  );
                },
              ),
              
              // Bottom thumbnail strip
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Container(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final String thumbImage = allImages[index];
                      final bool isSelected = index == initialIndex;
                      final bool isLocalAsset = !thumbImage.startsWith('http') && !thumbImage.startsWith('https');
                      
                      return GestureDetector(
                        onTap: () {
                          // Update the page view to show the selected image
                          PageController(initialPage: index).animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: isLocalAsset
                              ? Image.asset(
                                  thumbImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.broken_image, color: Colors.white),
                                    );
                                  },
                                )
                              : Image.network(
                                  thumbImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.broken_image, color: Colors.white),
                                    );
                                  },
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build section for displaying the list of instructions with improved styling
  Widget _buildListSection(dynamic items) {
    // Check if items is empty
    if (items == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: neutralDark.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No information available',
              style: TextStyle(
                fontSize: 16,
                color: neutralDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Create an empty list to hold the list items
    List<Widget> listItems = [];

    // Check if items is a Map 
    if (items is Map) {
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No information available',
            style: TextStyle(color: neutralDark),
          ),
        );
      }

      // Sort the keys numerically
      final sortedKeys = items.keys.toList()..sort((a, b) {
        final aInt = a is String ? int.tryParse(a) ?? 0 : a;
        final bInt = b is String ? int.tryParse(b) ?? 0 : b;
        return aInt.compareTo(bInt);
      });

      for (var key in sortedKeys) {
        final value = items[key];
        final index = key is String ? int.tryParse(key) ?? 0 : key;
        
        listItems.add(
          _buildListItem(index, value.toString()),
        );
      }
    }
    // Handle List data structure
    else if (items is List) {
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No information available',
            style: TextStyle(color: neutralDark),
          ),
        );
      }
      
      for (int i = 0; i < items.length; i++) {
        final value = items[i];
        listItems.add(
          _buildListItem(i, value.toString()),
        );
      }
    }
    // Handle unexpected data types
    else {
      return Text('Unexpected data format: ${items.runtimeType}');
    }
    
    return ListView(
      padding: EdgeInsets.zero,
      children: listItems,
    );
  }
  
  // Helper method to build a single list item 
  Widget _buildListItem(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle with gradient and shadow
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: neutralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for the tab bar in the sliver app bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  
  _SliverAppBarDelegate(this.tabBar);
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}