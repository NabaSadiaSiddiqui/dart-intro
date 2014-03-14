// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math' show Random;
import 'dart:convert' show JSON;
import 'dart:async' show Future;

ButtonElement genButton;  
final String TREASURE_KEY = 'pirateName'; //Key to the name of the pirate in the local storage
SpanElement badgeNameElement; //Stash the span element for repeated use instead of querying the DOM for it

void main() {
  //Stash the input element in a local variable
  InputElement inputField = querySelector('#inputName');
  //Register the function updateBadge() to handle input events on the input field
  inputField.onInput.listen(updateBadge);
  
  //Stash the button in the global variable
  genButton = querySelector('#generateButton');
  //Register the function generateBadge() to the button genButton's mouse click
  genButton.onClick.listen(generateBadge);
  
  //Stash the span element in the global variable
  badgeNameElement = querySelector('#badgeName');
  
  //Read names and appellations from json file into 2 lists once readyThePirates() returns a Future
  PirateName.readyThePirates().then((_) {
    //on success
    inputField.disabled = false;
    genButton.disabled = false;
    //Initialize the badge name from the last saved pirate name
    setBadgeName(getBadgeNameFromStorage());
  })
  .catchError((arrr) {  //Exception handler
    print('Error initializing pirate names: $arrr');
    badgeNameElement.text = 'Arrr! No names.';
  });
}

//Event handler to set the text of badgeName element from the value of the input field
void updateBadge(Event e) {
  String inputName = (e.target as InputElement).value;
  setBadgeName(new PirateName(firstName: inputName));
  
  if(inputName.trim().isEmpty) {
    genButton..disabled = false
             ..text = 'Aye! Gimme a name!';
  }
  else {
    genButton..disabled = true
             ..text = 'Arrr! Write yer name!';
  }
}

//Function to update the badge on the HTML page with the new name
void setBadgeName(PirateName newName) {
  if(newName == null) {
    return;
  }
  querySelector('#badgeName').text = newName.pirateName;
  //Save pirate name to local storage when badge name changes (as provided by browser's window)
  window.localStorage[TREASURE_KEY] = newName.jsonString;
}

//Create a random pirate name badge <-- click handler for the button genButton
void generateBadge(Event e) {
  setBadgeName(new PirateName());
}

class PirateName {
  static final Random indexGen = new Random();
  String _firstName;
  String _appellation;
  
  static List<String> names = [];
  static List<String> appellations = [];

  //Constructor
  PirateName({String firstName, String appellation}) {
    if (firstName == null) {
      _firstName = names[indexGen.nextInt(names.length)];
    }
    else {
      _firstName = firstName;
    }
    
    if(appellation == null) {
      _appellation = appellations[indexGen.nextInt(appellations.length)];
    }
    else {
      _appellation = appellation;
    }
  }
  
  //Named constructor
  PirateName.fromJSON(String jsonString) {
    Map storedName = JSON.decode(jsonString);
    _firstName = storedName['f'];
    _appellation = storedName['a'];
  }
  
  //Getter function for pirate name
  String get pirateName => _firstName.isEmpty ? '' : '$_firstName the $_appellation';
  
  //Getter to the PirateName class that encodes a priate name in a JSON string
  String get jsonString => JSON.encode({"f": _firstName, "a":_appellation});

  //Function to read names and appellations from json file
  static Future readyThePirates(){
    var path = 'piratenames.json';
    return HttpRequest.getString(path).then(_parsePirateNamesFromJSON);
  }
  
  //Call back function for http get request
  static _parsePirateNamesFromJSON(String jsonString) {
    Map pirateNames = JSON.decode(jsonString);
    names = pirateNames['names'];
    appellations = pirateNames['appellations'];
  }
}

//Function to retrieve the pirate name from local storage and create a PirateName object from it
PirateName getBadgeNameFromStorage() {
  String storedName = window.localStorage[TREASURE_KEY];
  if(storedName != null) {
    return new PirateName.fromJSON(storedName);
  }
  else {
    return null;
  }
}