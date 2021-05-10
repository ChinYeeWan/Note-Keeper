import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:note_keeper/models/note.dart';
import 'package:note_keeper/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';


class NoteDetail extends StatefulWidget {

  final String appBarTitle;
  final Note note;

  NoteDetail(this.note, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState(this.note, this.appBarTitle);
  }
}

class NoteDetailState extends State<NoteDetail> {
  static var _priorities = ["High", "Low"];

  DatabaseHelper helper = DatabaseHelper();
  var _formKey = GlobalKey<FormState>();

  String appBarTitle;
  Note note;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  NoteDetailState(this.note, this.appBarTitle);

  @override
  Widget build(BuildContext context) {

    TextStyle textStyle = Theme.of(context).textTheme.title;

    titleController.text = note.title;
    descriptionController.text = note.description;

    return WillPopScope(
        onWillPop: (){
          //Write some code to control things, when user press Back navigation button in device
          moveToLastScreen();
        },

        child: Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                moveToLastScreen();
              },
            ),
          ),

        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
            child: ListView(
              children: <Widget>[
                //First Element
                ListTile(
                  title: DropdownButton(
                    items: _priorities.map(
                          (String dropDownStringItem) {
                        return DropdownMenuItem<String>(
                          value: dropDownStringItem,
                          child: Text(dropDownStringItem),
                        );
                      },
                    ).toList(),
                    style: textStyle,
                    value: getPriorityAsString(note.priority),
                    onChanged: (valueSelectedByUser) {
                      setState(() {
                        debugPrint("user selected $valueSelectedByUser");
                        updatePriorityAsInt(valueSelectedByUser);
                      });
                    },
                  ),
                ),

                //Second element TITLE text field
                Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                  child: TextFormField(
                    controller: titleController,
                    style: textStyle,
                    validator: (String value){
                      if (value.isEmpty){
                        return 'Please enter the title';
                      }
                    },
                    onChanged: (value) {
                      debugPrint("Something change in TITLE");
                      updateTitle();
                    },
                    decoration: InputDecoration(
                        labelText: "Title",
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )),
                  ),
                ),


                //Third element DESCRIPTION text field
                Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                  child: TextFormField(
                    controller: descriptionController,
                    style: textStyle,
                    validator: (String value){
                      if (value.isEmpty){
                        return 'Please enter the description';
                      }
                    },
                    onChanged: (value) {
                      debugPrint("Something change in DESCRIPTION");
                      updateDescription();
                    },
                    decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: textStyle,
                        errorStyle: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )),
                  ),
                ),

                //Fourth element 2 raised button
                Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          textColor: Theme.of(context).primaryColorLight,
                          child: Text(
                            'Save',
                            textScaleFactor: 1.5,
                          ),
                          onPressed: () {
                            setState(() {
                              debugPrint("Save");
                              if(_formKey.currentState.validate()){
                                _save();
                              }
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 5.0,
                      ),
                      Expanded(
                        child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          textColor: Theme.of(context).primaryColorLight,
                          child: Text(
                            'Delete',
                            textScaleFactor: 1.5,
                          ),
                          onPressed: () {
                            setState(() {
                              debugPrint("Delete");
                              _delete();
                            });
                          },
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }

  void moveToLastScreen() {
    Navigator.pop(context, true);
  }

  //Covert the String priority in the form of integer before saving it to Database
  void updatePriorityAsInt(String value){
    switch(value){
      case 'High':
        note.priority = 1;
        break;
      case 'Low':
        note.priority = 2;
        break;
    }
  }

  //Covert int priority to String priority and display it to user in DropDown
  String getPriorityAsString(int value){
    String priority;
    switch(value){
      case 1:
        priority = _priorities[0]; //'High'
        break;
      case 2:
        priority = _priorities[1]; //'Low'
        break;
    }
    return priority;
  }

  //Update the title of Note object
  void updateTitle(){
    note.title = titleController.text;
  }

  //Update the description of Note object
  void updateDescription(){
    note.description = descriptionController.text;
  }

  //Save data to database
  void _save() async{

    moveToLastScreen();

    note.date = DateFormat.yMMMd().format(DateTime.now());
    int result;

    if(note.id != null){
      //Case 1: Update operation (edit)
      result = await helper.updateNote(note);

    }else{
      //Case 2: Insert operation (add)
      result = await helper.insertNote(note);
    }

    if(result != 0){
      //Success
      _showAlertDialog('Status', 'Note Saved Successfully');
    }else{
      //Failure
      _showAlertDialog('Warning', 'Problem Saving Note');
    }
  }

  void _delete() async {
    moveToLastScreen();

    if (note.id == null) {
      //Case 1: If user is trying to delete the NEW note i.e. he has come to the
      //detail page by pressing the FAB of NoteList page.
      _showAlertDialog('Status', 'No Note was deleted');
      return;
    }
    //Case 2: User is trying to delete the pld note that already has valid ID
    int result = await helper.deleteNote(note.id);
    if(result != 0){
      //Success
      _showAlertDialog('Status', 'Note Deleted Successfully');
    }else{
      //Failure
      _showAlertDialog('Warning', 'Problem Deleting Note');
    }
  }

  void _showAlertDialog(String title, String message){
    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );

    showDialog(
      context: context,
      builder: (_) => alertDialog,
    );
  }
}


