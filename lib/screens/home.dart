import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insta_node_app/constants/asset_helper.dart';
import 'package:insta_node_app/models/conversation.dart';
import 'package:insta_node_app/models/notify.dart';
import 'package:insta_node_app/models/post.dart';
import 'package:insta_node_app/providers/auth_provider.dart';
import 'package:insta_node_app/recources/post_api.dart';
import 'package:insta_node_app/screens/conversation.dart';
import 'package:insta_node_app/screens/keep_alive_screen.dart';
import 'package:insta_node_app/screens/notifications.dart';
import 'package:insta_node_app/utils/show_snack_bar.dart';
import 'package:insta_node_app/widgets/post_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String accessToken;
  const HomeScreen({super.key, required this.accessToken});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  static int page = 1;
  static const int limit = 8;
  List<Notify> _notifications = [];
  List<Conversations> _conversations = [];
  bool _isLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        getPosts();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void getPosts() async {
    if (_posts.isNotEmpty && _posts.length % limit != 0) {
      setState(() {
        _isLoadMore = false;
      });
      return;
    }
    final res = await PostApi().getPosts(widget.accessToken, page, limit);
    if (res is List) {
      setState(() {
        _posts = [..._posts, ...res];
        page++;
      });
    } else {
      if (!mounted) return;
      showSnackBar(context, 'Error', res);
    }
  }

  void _deletePost(String postId) async {
    print('halo');
    final res = await PostApi().deletePost(postId, widget.accessToken);
    if (res is String) {
      if (!mounted) return;
      showSnackBar(context, 'Error', res);
    } else {
      setState(() {
        _posts.removeWhere((post) => post.sId == postId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context).auth;
    return Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () async {
          setState(() {
            _posts = [];
            page = 1;
          });
          getPosts();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverAppBar(
                centerTitle: false,
                backgroundColor: Theme.of(context).primaryColor,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Scroll to top
                        _scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SvgPicture.asset(
                          AssetHelper.icSvg,
                          height: 32,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                        onTap: () async {
                          final storageNotifi = await Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (context) => KeepAlivePage(
                                          child: NotificationScreen(
                                        notifications: _notifications,
                                        accessToken: widget.accessToken,
                                      ))));
                          setState(() {
                            _notifications = [...storageNotifi];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.favorite_outline),
                        )),
                    GestureDetector(
                      onTap: () async {
                        final storageConversation =
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ConversationScreen(
                                      conversations: _conversations,
                                      accessToken: widget.accessToken,
                                    )));
                        setState(() {
                          _conversations = [...storageConversation];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(FontAwesomeIcons.comment),
                      ),
                    ),
                  ],
                ))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                          color: Colors.red),
                    );
                  },
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (index == _posts.length) {
                    return SizedBox(
                        height: 200,
                        child: Center(
                          child: Opacity(
                              opacity: _isLoadMore ? 1.0 : 0.0,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                        ));
                  }
                  return PostCard(
                    post: _posts[index],
                    deletePost: _deletePost,
                    auth: auth,
                  );
                },
                childCount: _posts.length + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
