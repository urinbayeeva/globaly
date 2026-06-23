import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum DocumentStatus { required, recommended, optional }

class DocumentTemplate extends Equatable {
  const DocumentTemplate({
    required this.id,
    required this.title,
    required this.issuer,
    required this.icon,
    required this.status,
    this.description = '',
    this.validityYears,
    this.extendable = false,
    this.convertibleTo,
    this.notes = const <String>[],
  });

  final String id;
  final String title;
  final String issuer;
  final IconData icon;
  final DocumentStatus status;

  final String description;
  final int? validityYears;
  final bool extendable;
  final String? convertibleTo;
  final List<String> notes;

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        issuer,
        icon,
        status,
        description,
        validityYears,
        extendable,
        convertibleTo,
        notes,
      ];
}
