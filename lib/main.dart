import 'dart:convert';

// import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'models/note.dart';
// import 'package:swipe_gesture_recognizer/swipe_gesture_recognizer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(title: 'Note App'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Note> notesList = [];
  String appBarTitle = "Note App";
  String label = "";
  String text = "tiles";
  List<String> inputLabels = [];
  List<String> labelCategories = ['No Labels at the moment'];
  TextEditingController LabelController = new TextEditingController();
  TextEditingController TitleController = new TextEditingController();
  TextEditingController TextController = new TextEditingController();

  Future<List<Note>> getNotes(String label) async {
    var notes = await http.get(Uri.http("192.168.2.7:5000", "/api/v1/notes/", {"labels": label}));
    List<dynamic> list = jsonDecode(notes.body);
    List<Note> notesList = [];
    list.forEach((note) {
      List<String> strList = [];
      for (String label in note['labels']) {
        strList.add(label);
      }
      note['id'] = note['_id'];
      note['labels'] = strList;
      notesList.add(new Note.fromJson(note));
    });
    return notesList;
  }

  Future<List<String>> getLabels() async {
    var res = await http.get(Uri.http("192.168.2.7:5000", "/api/v1/labels/"));

    List<String> val = [];
    if (!res.body.isEmpty) {
      val = res.body.substring(1, res.body.length - 1).split(",");

      for (int i = 0; i < val.length; i++) {
        val[i] = val[i].substring(1, val[i].length - 1);
      }
    }
    return val;
  }

  @override
  void initState() {
    super.initState();
    getNotes("").then((value) => {
          setState(() => {notesList = value})
        });
    getLabels().then((value) {
      setState(() => {labelCategories = value});
    });
  }

  List<Widget> buildDrawer() {
    List<Widget> drawer = [];
    drawer.add(Image(
      image: AssetImage("ii.png"),
    ));
    for (String label in labelCategories) {
      drawer.add(ListTile(
          onTap: () {
            Navigator.pop(context);
            getNotes(label).then((value) => {
              setState(() => {notesList = value, appBarTitle = label+" Notes"})
            });
            showSnackBar("$label Clicked");
          },
          title: Text(
            "$label",
            style: TextStyle(fontSize: 20),
          )));
    }
    return drawer;
  }

  void postNotes() async {
    var response =
        await http.post(Uri.http("192.168.2.7:5000", "/api/v1/notes/"),
            headers: {"Content-Type": "application/json; charset=UTF-8"},
            body: jsonEncode({
              "title": TitleController.text,
              "text": TextController.text,
              "labels": inputLabels
            }));
    if (response.statusCode == 200) {
      getNotes("").then((value) => {
            setState(() => {notesList = value})
          });
      getLabels().then((value) {
        setState(() => {labelCategories = value});
      });
    }
    inputLabels = [];
    TitleController.clear();
    TextController.clear();
    Navigator.of(context).pop();
  }

  void deleteNote(String index) async {
    var response = await http.delete(
        Uri.parse("http://192.168.2.7:5000/api/v1/notes/$index/"),
        headers: {"Content-Type": "application/json; charset=UTF-8"});
    print(response.body);
    if (response.statusCode == 204) {
      getNotes("").then((value) => {
            setState(() => {notesList = value})
          });
      getLabels().then((value) {
        setState(() => {labelCategories = value});
      });
    }
  }

  void refreshData() async {
    getNotes("").then((value) {
      this.setState(() => {notesList = value});
    });
  }

  SnackBar getSnackbar(String text) {
    return SnackBar(
      duration: Duration(milliseconds: 500),
      content: Text(
        '$text',
        style: TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.yellow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50))),
    );
  }

  SnackBar getErrorSnackbar(String text) {
    return SnackBar(
      duration: Duration(seconds: 2),
      content: Text(
        '$text',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50))),
    );
  }

  showSnackBar(String sb_text) {
    ScaffoldMessenger.of(context).showSnackBar(getSnackbar(sb_text));
  }

  List<Chip> buildChips(List<String> labels) {
    List<Chip> chips = [];
    for (String label in labels) {
      chips.add(Chip(
        avatar: CircleAvatar(
          child: Text(label[0]),
          backgroundColor: Colors.red,
        ),
        label: Text(label),
        deleteIcon: Icon(Icons.cancel),
        deleteIconColor: Colors.black,
        onDeleted: () {
          setState(() {
            inputLabels.remove(label);
          });
        },
      ));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.note_add_rounded),
                tooltip: "Add Note",
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: "Add Note",
                  onPressed: () {
                    refreshData();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(getSnackbar("Refreshing Notes..."));
                  }),
            )
          ],
        ),
        drawer: Drawer(
          child: ListView(children: buildDrawer()),
        ),
        endDrawer: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Add Note",
                        style: TextStyle(color: Colors.green, fontSize: 30),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          controller: TitleController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30)),
                            labelText: "Title",
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          onSubmitted: (text) {
                            setState(() {
                              inputLabels.add(LabelController.text);
                            });
                            LabelController.clear();
                          },
                          controller: LabelController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              labelText: "Label",
                              helperText: "Click plus to add label",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.add,
                                ),
                                color: Colors.purple,
                                onPressed: () {
                                  setState(() {
                                    inputLabels.add(LabelController.text);
                                  });
                                  LabelController.clear();
                                },
                              ))),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: buildChips(inputLabels)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          controller: TextController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30)),
                            labelText: "Note",
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        color: Colors.green,
                        textColor: Colors.white,
                        onPressed: () {
                          if (inputLabels.length > 0 &&
                              TitleController.text != null &&
                              TextController.text != null) {
                            postNotes();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                getErrorSnackbar("All fields are required"));
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [Icon(Icons.add), Text("Add Note")],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: ListView.builder(
              reverse: true,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(notesList[index].title),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    color: Colors.red,
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) => {deleteNote(notesList[index].id)},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black38)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: ExpansionTile(
                          // backgroundColor: Colors.white,
                          title: Text(notesList[index].title),
                          leading: Icon(
                            Icons.book,
                            color: Colors.blue,
                          ),
                          trailing: Icon(Icons.arrow_drop_down_circle),
                          children: <Widget>[
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 18.0, left: 10.0, right: 10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20.0),
                                      child: Column(
                                        children: [
                                          Container(
                                            child: IconButton(
                                                tooltip: "Click to edit note",
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.lightGreen,
                                                ),
                                                onPressed: () {
                                                  print("Edit note");
                                                }),
                                          ),
                                          Container(
                                              child:
                                                  Text(notesList[index].text))
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                          children: buildChips(
                                              notesList[index].labels)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        /*
        floatingActionButton: FloatingActionButton(
          // backgroundColor: Colors.red,
          onPressed: () {
            refreshData();
            ScaffoldMessenger.of(context)
                .showSnackBar(getSnackbar("Refreshing Notes..."));
          },
          tooltip: 'Refresh Notes',
          child: Icon(Icons.refresh),
          // elevation: 5.0,
        ),
         */
        bottomNavigationBar: BottomAppBar(
            color: Colors.blueGrey,
            shape: CircularNotchedRectangle(),
            // color: Colors.lightBlue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // IconButton(
                  //     icon: Icon(Icons.inbox_rounded),
                  //     onPressed: () {
                  //       ScaffoldMessenger.of(context)
                  //           .showSnackBar(getSnackbar("Expand False"));
                  //     }),
                  // IconButton(
                  //     icon: Icon(Icons.credit_card),
                  //     onPressed: () {
                  //       ScaffoldMessenger.of(context)
                  //           .showSnackBar(getSnackbar("Expand True"));
                  //     }),
                ],
              ),
            )));
  }
}
