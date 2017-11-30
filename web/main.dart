import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:vt_events/vt_events.dart';

@Component(
  selector: 'app-component',
  template: r'''
  <div>Hello</div>
  <div vt-host>
    <div *ngFor="let item of items">
      <span vt-click (click)="handleClick($event, item)">Item: {{item}}</span>
    </div>
    <button vt-click (click)="addItem()">Add Item</button>
    <button vt-click (click)="removeItem()">Remove Item</button>
  </div>
  ''',
  directives: const [
    VtClick,
    VtHost,
    NgFor,
  ]
)
class AppComponent {
  final List<String> items = new List.generate(5, (i)=> '$i');

  void handleClick(MouseEvent event, String item) {
    print('clicked on $item');
  }

  void addItem() {
    items.add(new math.Random().nextInt(10000).toString());
  }

  void removeItem() {
    if (items.isEmpty) return;
    items.removeLast();
  }
}


void main() {
  bootstrap(AppComponent, [const Provider(VirtualEventService)]);
}
