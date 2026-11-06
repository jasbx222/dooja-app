// The former mock-data design gallery is intentionally not a runtime route.
import 'package:flutter/material.dart';

import '../app.dart';

class Gallery extends Scr {
  const Gallery({super.key});
  @override
  Widget view(c, s) =>
      unavailable(c, 'معرض التصميم غير متاح في النسخة المربوطة بالخادم');
}
