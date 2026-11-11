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

/// Pull-style reader over XML events, for recursive-descent parsers.
///
/// A handler passed to [children] may consume its element (by calling
/// [children] or [text] on it) or simply return; whatever it leaves unread is
/// skipped, so unknown markup never desynchronises the parser.
final class XmlPull {
  XmlPull(String source) : _events = xmlEvents(source).iterator;

  final Iterator<XmlEvent> _events;
  int _depth = 0;

  XmlEvent? _read() {
    if (!_events.moveNext()) return null;
    final event = _events.current;
    if (event is XmlStartElementEvent) {
      if (!event.isSelfClosing) _depth++;
    } else if (event is XmlEndElementEvent) {
      _depth--;
    }
    return event;
  }

  /// Advances to the next start element named [localName] at any depth.
  XmlStartElementEvent? find(String localName) {
    while (true) {
      final event = _read();
      if (event == null) return null;
      if (event is XmlStartElementEvent && event.localName == localName) {
        return event;
      }
    }
  }

  /// Calls [onChild] for each direct child element of [parent], which must be
  /// the element most recently read. [onText] receives direct text content.
  void children(
    XmlStartElementEvent parent,
    void Function(XmlStartElementEvent child) onChild, {
    void Function(String text)? onText,
  }) {
    if (parent.isSelfClosing) return;
    final inside = _depth;
    while (true) {
      final event = _read();
      if (event == null || _depth < inside) return;
      if (event is XmlStartElementEvent) {
        onChild(event);
        while (_depth > inside) {
          if (_read() == null) return;
        }
      } else if (onText != null && _depth == inside) {
        if (event is XmlTextEvent) onText(event.value);
        if (event is XmlCDATAEvent) onText(event.value);
      }
    }
  }

  /// All text inside [parent], including nested elements.
  String text(XmlStartElementEvent parent) {
    if (parent.isSelfClosing) return '';
    final inside = _depth;
    StringBuffer? buffer;
    String? single;
    while (true) {
      final event = _read();
      if (event == null || _depth < inside) break;
      final String value;
      if (event is XmlTextEvent) {
        value = event.value;
      } else if (event is XmlCDATAEvent) {
        value = event.value;
      } else {
        continue;
      }
      if (single == null && buffer == null) {
        single = value;
      } else {
        buffer ??= StringBuffer(single!);
        buffer.write(value);
      }
    }
    return buffer?.toString() ?? single ?? '';
  }
}
