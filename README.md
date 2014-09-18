ViewModel: MVVM for Meteor
==========================

Declarative > Imperative

Reactive > Event Driven

Install:
--------
meteor add manuel:viewmodel

The Problem
-----------

Meteor is a leap forward in web development but one aspect that has remained behind is the way you deal with UI events. I'm referring to the interactions with the user and between UI elements. Right now it's done in an event driven fashion. You listen for events, then run a piece of code that does something, you then update the UI in some way. Develop any interactive UI and you end up with many, many levers and knobs that you have to synchronize to get the experience you want.

The solution
------------

The solution is to use an MVVM like pattern: You keep the state of the UI in a javascript object and bind the UI elements to properties of that object. You declare what happens and when it happens, and then Meteor will update the UI accordingly and best of all... reactively.

Go to [viewmodel.meteor.com][1] for examples and full documentation.

[1]:http://viewmodel.meteor.com/