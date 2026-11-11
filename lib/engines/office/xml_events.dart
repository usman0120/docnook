import 'package:docnook/core/failures.dart';
import 'package:xml/xml.dart' show XmlException;
import 'package:xml/xml_events.dart';

export 'package:xml/xml_events.dart'
    show
        XmlCDATAEvent,
        XmlEndElementEvent,
        XmlEvent,
        XmlEventAttribute,
        XmlStartElementEvent,
        XmlTextEvent;

/// Streams XML events from [source], lazily.
///
/// Office and ODF parts never need a DTD, and a DTD is the only way to mount
/// an entity-expansion attack, so any document type declaration is rejected
/// outright (BLUEPRINT 8.1). External entities are never resolved.
Iterable<XmlEvent> xmlEvents(String source) sync* {
  try {
    for (final event in parseEvents(source)) {
      if (event is XmlDoctypeEvent) {
        throw const DocNookFailure.corrupt(detail: 'xml: doctype');
      }
      yield event;
    }
  } on XmlException {
    throw const DocNookFailure.corrupt(detail: 'xml: malformed');
  }
}

extension XmlStartAttributes on XmlStartElementEvent {
  /// Attribute value by qualified name (e.g. `r:id`), or null.
  String? attr(String name) {
    for (final attribute in attributes) {
      if (attribute.name == name) return attribute.value;
    }
    return null;
  }

  /// Attribute value by local name, ignoring any namespace prefix.
  String? attrLocal(String localName) {
    for (final attribute in attributes) {
      if (attribute.localName == localName) return attribute.value;
    }
    return null;
  }

  int? intAttr(String name) {
    final value = attr(name);
    return value == null ? null : int.tryParse(value);
  }

  double? doubleAttr(String name) {
    final value = attr(name);
    return value == null ? null : double.tryParse(value);
  }

  /// OOXML booleans: present with no value, "1", "true" or "on" mean true.
  bool boolAttr(String name, {bool whenMissing = false}) {
    final value = attr(name);
    if (value == null) return whenMissing;
    return value == '1' || value == 'true' || value == 'on';
  }
}
