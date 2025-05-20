import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:html_learning/screens/progressprovider.dart';
import 'package:provider/provider.dart';

import '../components/custom_drawer.dart';
import '../resources/shared_preferences.dart';
import 'coursecontent.dart';

extension StringExtension on String {
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : word)
        .join(' ');
  }
}

class Homepage extends StatefulWidget {
  final String userName;
  const Homepage({super.key, required this.userName});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final PageController _pageController = PageController();
  String displayName = "Learner";
  Set<String> _openedTopics = {};

  @override
  void initState() {
    super.initState();
    _fetchAndSetUserName();
    _loadOpenedTopics();
    print("DEBUG: Homepage initialized, userName: ${widget.userName}");
  }

  Future<void> _loadOpenedTopics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('openedTopics')
          .get();
      if (doc.exists) {
        List<String>? opened = List<String>.from(doc['topics'] ?? []);
        if (mounted) {
          setState(() {
            _openedTopics = opened.toSet();
          });
        }
        print("DEBUG: Loaded opened topics from Firestore: $_openedTopics");
      }
    }
  }

  Future<void> _saveOpenedTopic(String topic) async {
    if (!_openedTopics.contains(topic)) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _openedTopics.add(topic);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('progress')
            .doc('openedTopics')
            .set({
          'topics': _openedTopics.toList(),
        }, SetOptions(merge: true));
        print("DEBUG: Saved opened topic to Firestore: $topic");
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _fetchAndSetUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    print("DEBUG: Fetching username... User: ${user?.uid ?? 'No user'}");

    if (user != null) {
      print("DEBUG: widget.userName: ${widget.userName}");
      if (widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'learner' && widget.userName.toLowerCase() != 'user') {
        setState(() {
          displayName = widget.userName.capitalizeWords();
        });
        await SharedPrefHelper.setUserName(widget.userName);
        print("DEBUG: Set displayName from widget.userName: $displayName");
        return;
      }

      String? authName = user.displayName;
      print("DEBUG: Firebase Auth displayName: $authName");
      if (authName != null && authName.isNotEmpty && authName.toLowerCase() != 'learner' && authName.toLowerCase() != 'user') {
        setState(() {
          displayName = authName.capitalizeWords();
        });
        await SharedPrefHelper.setUserName(authName);
        print("DEBUG: Set displayName from Firebase Auth: $displayName");
        return;
      }

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print("DEBUG: Firestore fetch attempted. Doc exists: ${userDoc.exists}");
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>?;
          String fetchedName = data?['displayName'] ?? data?['name'] ?? '';
          print("DEBUG: Firestore displayName: $fetchedName");
          if (fetchedName.isNotEmpty && fetchedName.toLowerCase() != 'learner' && fetchedName.toLowerCase() != 'user') {
            setState(() {
              displayName = fetchedName.capitalizeWords();
            });
            await SharedPrefHelper.setUserName(fetchedName);
            if (user.displayName != fetchedName) {
              await user.updateDisplayName(fetchedName);
              print("DEBUG: Synced Firebase Auth displayName: $fetchedName");
            }
            print("DEBUG: Set displayName from Firestore: $displayName");
            return;
          }
        }
      } catch (e) {
        print("DEBUG: Error fetching from Firestore: $e");
      }

      String? storedName = await SharedPrefHelper.getUserName();
      print("DEBUG: Stored name from SharedPreferences: $storedName");
      if (storedName != null && storedName.isNotEmpty && storedName.toLowerCase() != 'learner' && storedName.toLowerCase() != 'user') {
        setState(() {
          displayName = storedName.capitalizeWords();
        });
        print("DEBUG: Set displayName from SharedPreferences: $displayName");
        return;
      }

      setState(() {
        displayName = "Learner";
      });
      await SharedPrefHelper.setUserName("Learner");
      print("DEBUG: Set displayName to default: $displayName");
    } else {
      setState(() {
        displayName = "Learner";
      });
      await SharedPrefHelper.setUserName("Learner");
      print("DEBUG: No user logged in. Set displayName to default: $displayName");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    print("DEBUG: Homepage disposed");
    super.dispose();
  }

  final List<Map<String, dynamic>> courses = [
    {'icon': Icons.language, 'title': 'HTML Fundamentals'},
    {'icon': Icons.text_format, 'title': 'Text Formatting'},
    {'icon': Icons.text_fields, 'title': 'Advanced Text Elements'},
    {'icon': Icons.article, 'title': 'Document Structure'},
    {'icon': Icons.view_agenda, 'title': 'Content Sections'},
    {'icon': Icons.navigation, 'title': 'Navigation & Layout'},
    {'icon': Icons.grid_view, 'title': 'Divs & Spans'},
    {'icon': Icons.style, 'title': 'Styling & CSS'},
    {'icon': Icons.palette, 'title': 'Colors & Formatting'},
    {'icon': Icons.image, 'title': 'Images & Media'},
    {'icon': Icons.play_circle_fill, 'title': 'Audio & Video'},
    {'icon': Icons.video_library, 'title': 'Embedded Content'},
    {'icon': Icons.link, 'title': 'Links & Navigation'},
    {'icon': Icons.list, 'title': 'Lists'},
    {'icon': Icons.description, 'title': 'Description Lists'},
    {'icon': Icons.table_chart, 'title': 'Tables'},
    {'icon': Icons.table_rows, 'title': 'Advanced Table Elements'},
    {'icon': Icons.input, 'title': 'Forms & Inputs'},
    {'icon': Icons.check_box, 'title': 'Form Elements'},
    {'icon': Icons.brush, 'title': 'Graphics & Canvas'},
    {'icon': Icons.code, 'title': 'Semantic HTML'},
    {'icon': Icons.api, 'title': 'HTML5 APIs'},
    {'icon': Icons.accessibility, 'title': 'Accessibility'},
    {'icon': Icons.emoji_symbols, 'title': 'Character Sets & Symbols'},
    {'icon': Icons.computer, 'title': 'Technical References'},
    {'icon': Icons.web, 'title': 'Web Standards & XHTML'},
    {'icon': Icons.extension, 'title': 'Legacy Tags'},
    {'icon': Icons.collections_bookmark, 'title': 'Miscellaneous'},
  ];

  final Map<String, List<String>> topicSubtopicFiles = {
    'HTML Fundamentals': [
      'assets/html_topics/html_intro.json',
      'assets/html_topics/html_basic.json',
      'assets/html_topics/html_elements.json',
      'assets/html_topics/html_attributes.json',
      'assets/html_topics/html_editors.json',
      'assets/html_topics/html5_syntax.json',
      'assets/html_topics/tag_doctype.json',
      'assets/html_topics/html_comments.json',
      'assets/quiz/quiz_1.json'
    ],
    'Text Formatting': [
      'assets/html_topics/html_formatting.json',
      'assets/html_topics/tag_b.json',
      'assets/html_topics/tag_i.json',
      'assets/html_topics/tag_u.json',
      'assets/html_topics/tag_strong.json',
      'assets/html_topics/tag_em.json',
      'assets/html_topics/tag_small.json',
      'assets/html_topics/tag_s.json',
      'assets/quiz/quiz_2.json'
    ],
    'Advanced Text Elements': [
      'assets/html_topics/tag_mark.json',
      'assets/html_topics/tag_del.json',
      'assets/html_topics/tag_ins.json',
      'assets/html_topics/tag_sub.json',
      'assets/html_topics/tag_sup.json',
      'assets/html_topics/tag_tt.json',
      'assets/html_topics/tag_kbd.json',
      'assets/html_topics/tag_code.json',
      'assets/quiz/quiz_3.json'
    ],
    'Document Structure': [
      'assets/html_topics/tag_html.json',
      'assets/html_topics/tag_head.json',
      'assets/html_topics/tag_title.json',
      'assets/html_topics/tag_meta.json',
      'assets/html_topics/tag_body.json',
      'assets/html_topics/html_head.json',
      'assets/html_topics/tag_base.json',
      'assets/html_topics/html_page_title.json',
      'assets/quiz/quiz_4.json'
    ],
    'Content Sections': [
      'assets/html_topics/html_headings.json',
      'assets/html_topics/html_paragraphs.json',
      'assets/html_topics/tag_p.json',
      'assets/html_topics/tag_br.json',
      'assets/html_topics/tag_hr.json',
      'assets/html_topics/tag_section.json',
      'assets/html_topics/tag_article.json',
      'assets/html_topics/html_blocks.json',
      'assets/quiz/quiz_5.json'
    ],
    'Navigation & Layout': [
      'assets/html_topics/tag_nav.json',
      'assets/html_topics/tag_aside.json',
      'assets/html_topics/tag_main.json',
      'assets/html_topics/tag_header.json',
      'assets/html_topics/tag_footer.json',
      'assets/html_topics/html_layout.json',
      'assets/html_topics/tag_hgroup.json',
      'assets/quiz/quiz_6.json'
    ],
    'Divs & Spans': [
      'assets/html_topics/html_div.json',
      'assets/html_topics/tag_div.json',
      'assets/html_topics/tag_span.json',
      'assets/html_topics/html_classes.json',
      'assets/html_topics/html_id.json',
      'assets/html_topics/tag_style.json',
      'assets/quiz/quiz_7.json'
    ],
    'Styling & CSS': [
      'assets/html_topics/html_styles.json',
      'assets/html_topics/html_css.json',
      'assets/html_topics/html_responsive.json',
      'assets/html_topics/html_scripts.json',
      'assets/html_topics/tag_script.json',
      'assets/html_topics/tag_noscript.json',
      'assets/quiz/quiz_8.json'
    ],
    'Colors & Formatting': [
      'assets/html_topics/html_colors.json',
      'assets/html_topics/html_colors_rgb.json',
      'assets/html_topics/html_colors_hex.json',
      'assets/html_topics/html_colors_hsl.json',
      'assets/html_topics/html_computercode_elements.json',
      'assets/quiz/quiz_9.json'
    ],
    'Images & Media': [
      'assets/html_topics/html_images.json',
      'assets/html_topics/tag_img.json',
      'assets/html_topics/html_images_background.json',
      'assets/html_topics/html_images_picture.json',
      'assets/html_topics/tag_picture.json',
      'assets/html_topics/html_images_imagemap.json',
      'assets/html_topics/tag_map.json',
      'assets/html_topics/tag_area.json',
      'assets/quiz/quiz_10.json'
    ],
    'Audio & Video': [
      'assets/html_topics/html_audio.json',
      'assets/html_topics/html_video.json',
      'assets/html_topics/tag_audio.json',
      'assets/html_topics/tag_video.json',
      'assets/html_topics/tag_source.json',
      'assets/html_topics/tag_track.json',
      'assets/html_topics/html_media.json',
      'assets/quiz/quiz_11.json'
    ],
    'Embedded Content': [
      'assets/html_topics/html_iframe.json',
      'assets/html_topics/tag_iframe.json',
      'assets/html_topics/tag_embed.json',
      'assets/html_topics/tag_object.json',
      'assets/html_topics/html_object.json',
      'assets/html_topics/tag_param.json',
      'assets/html_topics/html_favicon.json',
      'assets/quiz/quiz_12.json'
    ],
    'Links & Navigation': [
      'assets/html_topics/html_links.json',
      'assets/html_topics/html_links_colors.json',
      'assets/html_topics/tag_a.json',
      'assets/html_topics/html_links_bookmarks.json',
      'assets/html_topics/html_filepaths.json',
      'assets/html_topics/html_urlencode.json',
      'assets/html_topics/tag_link.json',
      'assets/quiz/quiz_13.json'
    ],
    'Lists': [
      'assets/html_topics/html_lists.json',
      'assets/html_topics/html_lists_ordered.json',
      'assets/html_topics/html_lists_unordered.json',
      'assets/html_topics/tag_ol.json',
      'assets/html_topics/tag_ul.json',
      'assets/html_topics/tag_li.json',
      'assets/quiz/quiz_14.json'
    ],
    'Description Lists': [
      'assets/html_topics/html_lists_other.json',
      'assets/html_topics/tag_dl.json',
      'assets/html_topics/tag_dt.json',
      'assets/html_topics/tag_dd.json',
      'assets/quiz/quiz_15.json'
    ],
    'Tables': [
      'assets/html_topics/html_tables.json',
      'assets/html_topics/html_table_borders.json',
      'assets/html_topics/html_table_styling.json',
      'assets/html_topics/html_table_colspan_rowspan.json',
      'assets/html_topics/html_table_headers.json',
      'assets/html_topics/html_table_colgroup.json',
      'assets/html_topics/tag_table.json',
      'assets/html_topics/tag_tr.json',
      'assets/quiz/quiz_16.json'
    ],
    'Advanced Table Elements': [
      'assets/html_topics/tag_th.json',
      'assets/html_topics/tag_td.json',
      'assets/html_topics/tag_thead.json',
      'assets/html_topics/tag_tbody.json',
      'assets/html_topics/tag_tfoot.json',
      'assets/html_topics/tag_col.json',
      'assets/html_topics/tag_colgroup.json',
      'assets/html_topics/tag_caption.json',
      'assets/quiz/quiz_17.json'
    ],
    'Forms & Inputs': [
      'assets/html_topics/html_forms.json',
      'assets/html_topics/html_form_attributes.json',
      'assets/html_topics/html_form_attributes_form.json',
      'assets/html_topics/html_form_input_types.json',
      'assets/html_topics/html_form_elements.json',
      'assets/html_topics/tag_form.json',
      'assets/html_topics/tag_input.json',
      'assets/html_topics/tag_label.json',
      'assets/quiz/quiz_18.json'
    ],
    'Form Elements': [
      'assets/html_topics/tag_select.json',
      'assets/html_topics/tag_option.json',
      'assets/html_topics/tag_optgroup.json',
      'assets/html_topics/tag_textarea.json',
      'assets/html_topics/tag_button.json',
      'assets/html_topics/tag_fieldset.json',
      'assets/html_topics/tag_legend.json',
      'assets/html_topics/tag_datalist.json',
      'assets/quiz/quiz_19.json'
    ],
    'Graphics & Canvas': [
      'assets/html_topics/html5_canvas.json',
      'assets/html_topics/html5_svg.json',
      'assets/html_topics/tag_canvas.json',
      'assets/html_topics/tag_svg.json',
      'assets/html_topics/tag_figure.json',
      'assets/html_topics/tag_figcaption.json',
      'assets/html_topics/ref_canvas.json',
      'assets/quiz/quiz_20.json'
    ],
    'Semantic HTML': [
      'assets/html_topics/html5_semantic_elements.json',
      'assets/html_topics/tag_blockquote.json',
      'assets/html_topics/tag_q.json',
      'assets/html_topics/tag_address.json',
      'assets/html_topics/tag_cite.json',
      'assets/html_topics/tag_summary.json',
      'assets/html_topics/tag_details.json',
      'assets/html_topics/html_quotation_elements.json',
      'assets/quiz/quiz_21.json'
    ],
    'HTML5 APIs': [
      'assets/html_topics/html5_api_whatis.json',
      'assets/html_topics/html5_geolocation.json',
      'assets/html_topics/html5_draganddrop.json',
      'assets/html_topics/html5_webstorage.json',
      'assets/html_topics/html5_webworkers.json',
      'assets/html_topics/html5_serversentevents.json',
      'assets/quiz/quiz_22.json'
    ],
    'Accessibility': [
      'assets/html_topics/html_accessibility.json',
      'assets/html_topics/tag_dfn.json',
      'assets/html_topics/tag_bdi.json',
      'assets/html_topics/tag_bdo.json',
      'assets/html_topics/tag_wbr.json',
      'assets/quiz/quiz_23.json'
    ],
    'Character Sets & Symbols': [
      'assets/html_topics/html_charset.json',
      'assets/html_topics/html_emojis.json',
      'assets/html_topics/html_entities.json',
      'assets/html_topics/html_symbols.json',
      'assets/quiz/quiz_24.json'
    ],
    'Technical References': [
      'assets/html_topics/ref_keyboardshortcuts.json',
      'assets/html_topics/ref_httpmethods.json',
      'assets/html_topics/ref_httpmessages.json',
      'assets/html_topics/ref_urlencode.json',
      'assets/html_topics/ref_eventattributes.json',
      'assets/html_topics/ref_byfunc.json',
      'assets/html_topics/html_examples.json',
      'assets/quiz/quiz_25.json'
    ],
    'Web Standards & XHTML': [
      'assets/html_topics/html_xhtml.json',
      'assets/html_topics/html_editor.json',
      'assets/html_topics/default.json',
      'assets/html_topics/default_1.json',
      'assets/quiz/quiz_26.json'
    ],
    'Legacy & Deprecated Tags': [
      'assets/html_topics/tag_applet.json',
      'assets/html_topics/tag_basefont.json',
      'assets/html_topics/tag_center.json',
      'assets/html_topics/tag_dir.json',
      'assets/html_topics/tag_font.json',
      'assets/html_topics/tag_strike.json',
      'assets/html_topics/tag_tt_1.json',
      'assets/quiz/quiz_27.json'
    ],
    'Miscellaneous': [
      'assets/html_topics/tag_abbr.json',
      'assets/html_topics/tag_acronym.json',
      'assets/html_topics/tag_data.json',
      'assets/html_topics/tag_dialog.json',
      'assets/html_topics/tag_hn.json',
      'assets/html_topics/tag_meter.json',
      'assets/html_topics/tag_output.json',
      'assets/html_topics/tag_template.json',
      'assets/quiz/quiz_28.json'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.05;

    print("DEBUG: Building Homepage, displayName: $displayName");
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(userName: displayName),
      appBar: AppBar(
        backgroundColor: Color(0xff023047),
        elevation: 0,
        toolbarHeight: screenSize.height * 0.25,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (BuildContext drawerContext) => GestureDetector(
                        onTap: () {
                          print("DEBUG: Menu icon tapped, opening drawer");
                          Scaffold.of(drawerContext).openDrawer();
                        },
                        child: const Icon(Icons.menu, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Hello, $displayName !",
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Keep learning HTML!",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    Consumer<ProgressProvider>(
                      builder: (context, progressProvider, child) {
                        double progress = progressProvider.globalTotal > 0
                            ? progressProvider.globalProgress / progressProvider.globalTotal
                            : 0.0;
                        print("DEBUG: Global progress: ${(progress * 100).toStringAsFixed(1)}%");
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[400],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Overall Progress: ${(progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/7.png',
                    fit: BoxFit.cover,
                    height: 180,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 50,
            color: Color(0xff023047),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Consumer<ProgressProvider>(
              builder: (context, progressProvider, child) {
                print("DEBUG: Rebuilding GridView with ${courses.length} courses");
                return GridView.builder(
                  padding: EdgeInsets.all(padding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final title = courses[index]['title'];
                    final progress = progressProvider.topicProgress[title] ?? 0.0;
                    return _courseContent(
                      context,
                      icon: courses[index]['icon'],
                      title: title,
                      progress: progress,
                      isOpened: _openedTopics.contains(title),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseContent(BuildContext context,
      {required IconData icon, required String title, required double progress, required bool isOpened}) {
    bool isCompleted = progress >= 1.0;
    print("DEBUG: Rendering tile: $title, progress: ${(progress * 100).toStringAsFixed(1)}%, isCompleted: $isCompleted, isOpened: $isOpened");
    return GestureDetector(
      onTap: () {
        _saveOpenedTopic(title);
        print("DEBUG: Navigating to CourseContentScreen, title: $title");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseContentScreen(
              filenames: topicSubtopicFiles[title] ?? [],
              title: title,
            ),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Color(0xffE6ECEF), // Replaced Color(0xffD0F0F5)
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [Color(0xff014062), Color(0xff011825)], // Replaced Colors.teal.shade400, Colors.teal.shade700
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      icon,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff023047),
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    borderRadius: BorderRadius.circular(20),
                    minHeight: 8,
                    backgroundColor: Color(0xffB3C7D1), // Replaced Colors.teal.shade200
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff023047)), // Replaced Colors.teal.shade600
                  ),
                ),
              ],
            ),
            if (isCompleted)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xff023047), // Replaced Colors.teal.shade600
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}