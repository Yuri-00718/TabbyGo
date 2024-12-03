// ignore_for_file: depend_on_referenced_packages, file_names
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<types.Message> _messages = [];
  final types.User _user = types.User(
    id: FirebaseAuth.instance.currentUser!.uid,
  );

  late StreamSubscription<QuerySnapshot> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  void _fetchMessages() {
    _messagesSubscription = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        _messages.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final senderName = data['senderName'] ?? 'Unknown';

          if (data['imageUrl'] != null) {
            _messages.add(
              types.ImageMessage(
                id: doc.id,
                author: types.User(
                  id: data['senderId'],
                  firstName: senderName,
                ),
                uri: data['imageUrl'],
                createdAt: data['timestamp'].millisecondsSinceEpoch,
                name: 'Image',
                size: data['imageSize'] ?? 0,
              ),
            );
          } else {
            _messages.add(
              types.TextMessage(
                id: doc.id,
                author: types.User(
                  id: data['senderId'],
                  firstName: senderName,
                ),
                text: data['text'],
                createdAt: data['timestamp'].millisecondsSinceEpoch,
              ),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    super.dispose();
  }

  String _generateUsername(String email) {
    return email.split('@')[0];
  }

  void _sendMessage(types.Message message) async {
    final messageId = const Uuid().v4();
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final senderName =
          currentUser.displayName ?? _generateUsername(currentUser.email!);

      final messageData = {
        'senderId': currentUser.uid,
        'senderName': senderName,
        'timestamp': Timestamp.now(),
      };

      if (message is types.ImageMessage) {
        messageData['imageUrl'] = message.uri;
        messageData['imageSize'] = message.size;
      } else if (message is types.TextMessage) {
        messageData['text'] = message.text;
      }

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _sendMessage(const types.PartialText(text: 'File attached')
          as types.Message); // Send a placeholder text message
      _addMessage(message);
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('chat_images/${const Uuid().v4()}');
      await imageRef.putFile(image);
      return await imageRef.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Image upload failed: $e');
      }
      rethrow;
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final file = File(result.path);

      try {
        final imageUrl = await _uploadImage(file);

        final message = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: 100,
          id: const Uuid().v4(),
          name: result.name,
          size: await file.length(),
          uri: imageUrl,
          width: 100,
        );

        _sendMessage(message);
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _sendMessage(textMessage); // Pass the TextMessage to _sendMessage
    _addMessage(textMessage); // Add it to the local state as well
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Image.asset(
              'assets/images/Back_Arrow.png',
              width: 30,
              height: 30,
              color: const Color.fromARGB(255, 107, 21, 219),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Communication Hub',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
        ),
        body: Chat(
          messages: _messages,
          onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          showUserAvatars: true,
          showUserNames: true,
          user: _user,
        ),
      );
}
