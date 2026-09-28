import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'semantic_action.dart';
import 'semantic_id_of_ancestor.dart';

/// Names and identifies a [DropdownMenu] without hiding its entries.
///
/// [SemanticAction] cannot be put around a [DropdownMenu]: the open menu lives
/// in the overlay and reaches the platform only as the traversal children of
/// the chooser's own node. Merged into a wrapper, that node is never sent, and
/// the entries go with it - on Android not one of them is in the accessibility
/// tree, and a screen reader can neither hear nor pick them.
///
/// Off the web the name and the id travel inside the chooser instead, through
/// [DropdownMenuCaption] handed to [DropdownMenu.label], and land on the node
/// that carries the expand action; this widget then adds nothing.
///
/// On the web [DropdownMenu] drops its text field from the tree, and the
/// caption with it, so there the chooser keeps the merged wrapper and a
/// [value] to announce the choice by.
class DropdownMenuSemantics extends StatelessWidget {
  const DropdownMenuSemantics({super.key, this.label, required this.identifier, this.value, required this.child});

  final String? label;
  final String identifier;

  /// What is chosen, as it should be spoken on the web.
  final String? value;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return SemanticAction(
      label: label,
      identifier: identifier,
      child: Semantics(value: value, child: child),
    );
  }
}

/// The [DropdownMenu.label] of a chooser wrapped in [DropdownMenuSemantics].
///
/// Forms no node of its own: the name and the id join the chooser's node,
/// which is the one that answers expand and collapse.
class DropdownMenuCaption extends StatelessWidget {
  const DropdownMenuCaption({super.key, this.label, required this.identifier, required this.child});

  final String? label;
  final String identifier;

  /// The caption as it is drawn in the frame around the chooser.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    return SemanticIdOfAncestor(
      identifier: identifier,
      child: label == null ? child : Semantics(label: label, child: child),
    );
  }
}
