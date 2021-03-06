import 'dart:async';

import 'package:flutter/material.dart';

class InfiniteList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final void Function(Completer) fetchMore;
  final bool keepAlive;

  const InfiniteList(
      {Key key,
      this.itemCount,
      this.itemBuilder,
      this.fetchMore,
      this.keepAlive = false})
      : super(key: key);

  @override
  InfiniteListState createState() => InfiniteListState();
}

class InfiniteListState extends State<InfiniteList>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  double Function() _offsetToLoad = () => 0;
  Completer completer = Completer()..complete();

  void scrollToOffset(double offset,
      {Duration duration = const Duration(milliseconds: 300)}) {
    _scrollController.animateTo(offset, duration: duration, curve: Curves.ease);
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels + _offsetToLoad() >= position.maxScrollExtent &&
          completer.isCompleted) {
        completer = Completer();
        widget.fetchMore(completer);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _offsetToLoad = () => MediaQuery.of(context).size.height * 3;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
