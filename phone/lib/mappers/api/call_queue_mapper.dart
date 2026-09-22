import 'package:api/api.dart' as api;

import 'package:webtrit_phone/models/models.dart';

mixin CallQueueApiMapper {
  CallQueue callQueueFromApi(api.CallQueue queue) {
    return CallQueue(
      id: queue.id,
      name: queue.name,
      loggedIn: queue.loggedIn,
      agentsTotal: queue.agentsTotal,
      agentsLoggedIn: queue.agentsLoggedIn,
      callersWaiting: queue.callersWaiting,
    );
  }

  List<CallQueue> callQueuesFromApi(Iterable<api.CallQueue> queues) => queues.map(callQueueFromApi).toList();
}
