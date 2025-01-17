// Copyright 2019 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:media_picker/picker_library/wechat_picker_library.dart';
import 'package:photo_manager/photo_manager.dart';

class LocallyAvailableBuilder extends StatefulWidget {
  const LocallyAvailableBuilder({
    required this.asset,
    required this.builder,
    super.key,
    this.isOriginal = true,
  });

  final AssetEntity asset;
  final Widget Function(BuildContext context, AssetEntity asset) builder;
  final bool isOriginal;

  @override
  State<LocallyAvailableBuilder> createState() =>
      _LocallyAvailableBuilderState();
}

class _LocallyAvailableBuilderState extends State<LocallyAvailableBuilder> {
  bool _isLocallyAvailable = false;
  PMProgressHandler? _progressHandler;

  @override
  void initState() {
    super.initState();
    _checkLocallyAvailable();
  }

  @override
  void didUpdateWidget(LocallyAvailableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset ||
        widget.isOriginal != oldWidget.isOriginal) {
      _isLocallyAvailable = false;
      _progressHandler = null;
      _checkLocallyAvailable();
    }
  }

  Future<void> _checkLocallyAvailable() async {
    _isLocallyAvailable = await widget.asset.isLocallyAvailable(
      isOrigin: widget.isOriginal,
    );
    if (!mounted) {
      return;
    }
    setState(() {});
    if (!_isLocallyAvailable) {
      _progressHandler = PMProgressHandler();
      await Future<void>(() async {
        final file = await widget.asset.loadFile(
          isOrigin: widget.isOriginal,
          withSubtype: true,
          progressHandler: _progressHandler,
        );
        if (file != null) {
          _isLocallyAvailable = true;
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
    _progressHandler?.stream.listen((PMProgressState s) {
      // assert(() {
      //   dev.log('Handling progress: $s.');
      //   return true;
      // }());
      if (s.state == PMRequestState.success) {
        _isLocallyAvailable = true;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Widget _indicator(BuildContext context) {
    return StreamBuilder<PMProgressState>(
      stream: _progressHandler!.stream,
      initialData: const PMProgressState(0, PMRequestState.prepare),
      builder: (BuildContext c, AsyncSnapshot<PMProgressState> s) {
        if (s.hasData) {
          final progress = s.data!.progress;
          final state = s.data!.state;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                state == PMRequestState.failed
                    ? Icons.cloud_off
                    : Icons.cloud_queue,
                color: context.iconTheme.color?.withOpacity(.4),
                size: 28,
              ),
              if (state != PMRequestState.success &&
                  state != PMRequestState.failed)
                ScaleText(
                  '  iCloud ${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: context.textTheme.bodyMedium?.color?.withOpacity(.4),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocallyAvailable) {
      return widget.builder(context, widget.asset);
    }
    if (_progressHandler != null) {
      return Center(child: _indicator(context));
    }
    return const SizedBox.shrink();
  }
}
