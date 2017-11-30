import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:angular/angular.dart';

/// A service used by virtual event listeners and hosts to dispatch events.
/// 
/// Users should not need to inject this service.
@Injectable()
class VirtualEventService {
  Node _host;
  final _listeners = new HashMap<String, _EventTracker>.identity();

  void _addListener(Node node, String eventName, EventListener listener) {
    _listeners[eventName] ??= new _EventTracker();
    var tracker = _listeners[eventName];

    tracker.count++;
    tracker.nodes[node] = listener;

    if (tracker.count == 1) {
      tracker.listener  ??= (Event event) {
        Node target = event.target;
        var listener = tracker.nodes[target];
        if (listener != null) {
          listener(event);
        }
      };
      _host.addEventListener(eventName, tracker.listener);
    }
  }

  void _removeListeners(Node node, String eventName) {
    var tracker = _listeners[eventName];
    if (tracker == null) return;
    if (tracker.nodes.remove(node) != null) {
      tracker.count--;
      if (tracker.count == 0) {
        _host.removeEventListener(eventName, tracker.listener);
      }
    }
  }
}

class _EventTracker {
  final nodes = new HashMap<Node, EventListener>.identity();
  int count = 0;
  EventListener listener;
}

/// A base class for virtual event listeners.
/// 
/// Override to create a virtual event listener by providing an event type [T], an
/// `@Output`, and a String for the event name.
abstract class VirtualEventDirective<T extends Event> implements OnInit, OnDestroy {
  final Element _element;
  final VirtualEventService _service;
  final String _name;
  final _onEvent = new StreamController<T>.broadcast();

  VirtualEventDirective(this._element, this._service, this._name);

  Stream<Event> get onEvent => _onEvent.stream;

  @override
  void ngOnInit() {
    _service._addListener(_element, _name, _onEvent.add);
  }

  @override
  void ngOnDestroy() {
    _service._removeListeners(_element, _name);
  }
}

// Warning message thrown in development mode if a user forgets to place the
// `[vt-host]` directive.
final _missingEventServiceWarning = r'''
  Error: virtual event directives must have a parent element with
  a `vt-host` directive placed on them.

  Example:
    <div vt-host>
       <div vt-click (click)="handleClick($event)></div>
    </div>
''';


/// A directive which hosts the native event listeners for virutal events.
/// 
/// Place this directive on a component to allow all child components to use
/// virtual event listeners.
/// 
/// __example_use__:
///     <div vt-host>
///       <div vt-click (click)="handleClick($event)"></div>
///     </div>
@Directive(
  selector: '[vt-host]',
  visibility: Visibility.none,
  providers: const [
    VirtualEventService,
  ]
)
class VtHost implements OnInit, OnDestroy {
  final Element _element;
  final VirtualEventService _service;

  VtHost(this._element, @Optional() this._service) {
    assert(_service != null, _missingEventServiceWarning);
  }

  @override
  void ngOnInit() {
    assert(_service._host == null);
    _service._host = _element;
  }

  @override
  void ngOnDestroy() {
    _service._listeners.clear();
    _service._host = null;
  }
}

/// A virtual click directive.
/// 
/// Overrides the native `click` output.
/// __example_use__:
/// 
///     <div vt-click (click)="handleClick($event)"></div>
@Directive(
  selector: '[vt-click]',
  visibility: Visibility.none,
)
class VtClick extends VirtualEventDirective<MouseEvent> {
  VtClick(Element element, @Optional() VirtualEventService service)
      : super(element, service, 'click');

  @Output('click')
  Stream<MouseEvent> get onEvent => super.onEvent;
}


/// A virtual mouseover directive.
/// 
/// Overrides the native `mouseover` output.
/// __example_use__:
/// 
///     <div vt-mouseover (mouseover)="handleMouse($event)"></div>
@Directive(
  selector: '[vt-mouseover]',
  visibility: Visibility.none,
)
class VtMouseover extends VirtualEventDirective<MouseEvent> {
  VtMouseover(Element element, @Optional() VirtualEventService service)
      : super(element, service, 'mouseover');

  @Output('mouseover')
  Stream<MouseEvent> get onEvent => super.onEvent;
}

/// A virtual touchstart directive.
/// 
/// Overrides the native `touchstart` output.
/// __example_use__:
/// 
///     <div vt-touchstart (touchstart)="handleTouch($event)"></div>
@Directive(
  selector: '[vt-touchstart]',
  visibility: Visibility.none,
)
class VtTouchstart extends VirtualEventDirective<TouchEvent> {
  VtTouchstart(Element element, @Optional() VirtualEventService service)
      : super(element, service, 'touchstart');

  @Output('touchstart')
  Stream<TouchEvent> get onEvent => super.onEvent;
}