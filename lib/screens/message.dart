import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insta_node_app/constants/asset_helper.dart';
import 'package:insta_node_app/models/conversation.dart';
import 'package:insta_node_app/models/message.dart';
import 'package:insta_node_app/models/post.dart';
import 'package:insta_node_app/providers/auth_provider.dart';
import 'package:insta_node_app/recources/message_api.dart';
import 'package:insta_node_app/utils/show_snack_bar.dart';
import 'package:insta_node_app/utils/socket_config.dart';
import 'package:insta_node_app/utils/video_call.dart';
import 'package:insta_node_app/widgets/call_message.dart';
import 'package:insta_node_app/widgets/input_message.dart';
import 'package:insta_node_app/widgets/media_message.dart';
import 'package:insta_node_app/widgets/text_message.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessageScreen extends StatefulWidget {
  final String? conversationId;
  final UserPost user;
  final List<Messages> firstListMessages;
  const MessageScreen(
      {super.key,
      required this.user,
      required this.firstListMessages,
      this.conversationId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  List<String> media = [];
  bool _isLoadMore = true;
  Conversations? conversation;
  int page = 2;
  int limit = 20;

  @override
  void initState() {
    super.initState();
    SocketConfig.socket.on('addMessageToClient', (data) {
      if (!mounted) return;
      setState(() {
        // widget.firstListMessages.insert(0, Messages.fromJson(data));
      });
    });
    if(widget.firstListMessages.length < limit) {
      setState(() {
        _isLoadMore = false;
      });
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _handleLoadMoreMessage();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _scrollController.dispose();
  }

  void _handleLoadMoreMessage() async {
    final accessToken =
        Provider.of<AuthProvider>(context, listen: false).auth.accessToken!;
    if (widget.firstListMessages.isNotEmpty &&
        widget.firstListMessages.length % limit != 0) {
      setState(() {
        _isLoadMore = false;
      });
      return;
    }
    final res = await MessageApi()
        .getMessages(widget.conversationId != null ? widget.conversationId! : widget.user.sId!, accessToken, page, limit);
    if (res is String) {
      if (!mounted) return;
      showSnackBar(context, 'Error', res);
    } else {
      setState(() {
        widget.firstListMessages.addAll([...res]);
        page++;
      });
    }
  }

  void handleCreateMessage() async {
    final accessToken =
        Provider.of<AuthProvider>(context, listen: false).auth.accessToken!;
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).auth.user!;
    final message = {
      'conversationId': widget.conversationId ?? widget.user.sId,
      'avatar': currentUser.avatar,
      'username': currentUser.username,
      'text': _messageController.text,
      'senderId': currentUser.sId,
      'recipientId': widget.user.sId,
      'media': media,
      'call': null
    };
    final res = await MessageApi().createMessageText(message, accessToken);
    if (res is String) {
      if (!mounted) return;
      showSnackBar(context, 'Error', res);
    } else {
      setState(() {
        widget.firstListMessages.insert(0, Messages.fromJson(res['message']));
        conversation = Conversations.fromJson({
          ...res['conversation'],
          'messages': [res['message']]
        });
      });
        setState(() {
          media = [];
          _messageController.clear();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).auth.user!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              final msg = {
                'sender': currentUser.sId!,
                'recipient': widget.user.sId,
                'avatar': currentUser.avatar,
                'fullname': currentUser.fullname,
              };
              SocketConfig.callUser(msg);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => VideoCallScreen()));
            },
            icon: Icon(
              FontAwesomeIcons.phone,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          IconButton(
            onPressed: () {
              AudioPlayer player = AudioPlayer();
              player.play(AssetSource(AssetHelper.soundCall));
            },
            icon: Icon(FontAwesomeIcons.video),
          ),
        ],
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context, conversation);
              },
              child: const Icon(
                Icons.arrow_back,
                size: 30,
              ),
            ),
            const SizedBox(
              width: 24,
            ),
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.user.avatar!),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullname!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active now',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      body: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
            children: [
              Expanded(
                child: widget.firstListMessages.isNotEmpty
                    ? ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: widget.firstListMessages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == widget.firstListMessages.length) {
                            return SizedBox(
                                height: 70,
                                child: Opacity(
                                    opacity: _isLoadMore ? 1 : 0,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ))));
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: buildMessageCard(
                                widget.firstListMessages[index],
                                currentUser.sId!),
                          );
                        },
                      )
                    : Container(),
              ),
              InputMessageWidget(
                  media: media,
                  handleCreateMessage: handleCreateMessage,
                  controller: _messageController,
                  recipientId: widget.user.sId!)
            ],
          )),
    );
  }

  Widget buildMessageCard(Messages message, String currentId) {
    bool isShowAvatar = message.senderId == currentId ? false : true;
    final color = message.senderId == currentId
        ? Colors.blue
        : Colors.grey.withOpacity(0.5);
    final mainAxisAlignment = message.senderId == currentId
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final crossAxisAliment = message.senderId == currentId
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.7,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isShowAvatar
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.user.avatar!),
                )
              : Container(),
          const SizedBox(
            width: 10,
          ),
          Column(
            crossAxisAlignment: crossAxisAliment,
            children: [
              message.text != ''
                  ? TextMessageWidget(color: color, text: message.text!)
                  : Container(),
              // Image
              message.media!.isNotEmpty
                  ? MediaMessageWidget(media: message.media!, crossAxisAlignment: crossAxisAliment)
                  : Container(),
              // call
              message.call != null
                  ? CallMessageWidget(
                      call: message.call!, createAt: message.createdAt!)
                  : Container(),
              Text(
                  DateFormat('dd/MM/yyyy hh:mm a')
                      .format(DateTime.parse(message.createdAt!)),
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
