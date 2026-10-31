import 'package:flutter/material.dart';
import 'package:muzee/main.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:muzee/widgets/spinner.dart';

/// A small helper that reduces boilerplate around common FutureBuilder
/// usage: shows a spinner while waiting, a standardized error widget on
/// error, and calls [builder] when data is available. If [emptyWidget]
/// is provided and the data is an empty [Iterable] or `null`, it will be
/// shown instead of calling [builder].
///
/// Pass [onRetry] to give the default error widget a Retry button; it should
/// start the same request again.
class AsyncLoader<T> extends StatefulWidget {
  const AsyncLoader({
    super.key,
    required this.future,
    required this.builder,
    this.emptyWidget = const SizedBox.shrink(),
    this.loadingWidget = const Center(child: Spinner()),
    this.errorBuilder,
    this.onRetry,
  });

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget emptyWidget;
  final Widget loadingWidget;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;
  final Future<T> Function()? onRetry;

  @override
  State<AsyncLoader<T>> createState() => _AsyncLoaderState<T>();
}

class _AsyncLoaderState<T> extends State<AsyncLoader<T>> {
  late Future<T> _future = widget.future;

  @override
  void didUpdateWidget(AsyncLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.future != oldWidget.future) {
      _future = widget.future;
    }
  }

  void _retry() {
    setState(() {
      _future = widget.onRetry!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget;
        }

        if (snapshot.hasError) {
          logger.log(
            'AsyncLoader error',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          final errorBuilder = widget.errorBuilder;
          if (errorBuilder != null) {
            return errorBuilder(context, snapshot.error, snapshot.stackTrace);
          }
          return LoadErrorView(onRetry: widget.onRetry != null ? _retry : null);
        }

        final data = snapshot.data;
        if (data == null) return widget.emptyWidget;

        if (data is Iterable && data.isEmpty) {
          return widget.emptyWidget;
        }

        return widget.builder(context, data);
      },
    );
  }
}
