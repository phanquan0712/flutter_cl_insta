import 'package:flutter/material.dart';
import 'package:insta_node_app/views/add/screens/add_story/media_gallery_story.dart';

class StoryCardWidget extends StatelessWidget {
  final String avatar;
  const StoryCardWidget({super.key, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: NetworkImage(avatar),
                ),
                Positioned(
                  right: -2,
                  bottom: 5,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MediaGalleryStoryScreen())),
                    child: CircleAvatar(
                      radius: 15,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            child: Text(
              'Your Story',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          )
        ],
      )
    );
  }
}
