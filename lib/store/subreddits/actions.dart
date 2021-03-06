import 'dart:async';

import 'package:reddigram/api/api.dart';
import 'package:reddigram/models/models.dart';
import 'package:reddigram/store/store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

ThunkAction<ReddigramState> fetchSubreddits(List<String> ids,
    {Completer completer}) {
  assert(ids.length <= 100, 'there\'s more than 100 ids. what.');

  return (Store<ReddigramState> store) {
    // Make a copy so we don't operate on a reference passed to the function
    var idsList = List.of(ids);
    // Firstly check the state for already fetched subreddits so we don't
    // have to call the API for the data we have.
    idsList.removeWhere((id) => store.state.subreddits.containsKey(id));
    // Remove duplicates.
    idsList = idsList.toSet().toList();

    redditRepository
        .subredditsBulk(idsList)
        .then((subreddits) => store.dispatch(FetchedSubreddits(subreddits)))
        .whenComplete(() => completer?.complete());
  };
}

/// [FetchedSubreddits] is called whenever we fetch the subreddit data.
/// It's used to show subreddits data to the user in various locations
/// across the application.
class FetchedSubreddits {
  final List<Subreddit> subreddits;

  FetchedSubreddits(this.subreddits);
}
