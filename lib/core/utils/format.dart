import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

final _priceFormat = NumberFormat('#,##0.00');
final _dateFormat = DateFormat('d MMM yyyy, HH:mm');
final _dayFormat = DateFormat('d MMM yyyy');

String formatPrice(num value) => '${_priceFormat.format(value)} ${AppConstants.currency}';

String formatDate(DateTime? date) => date == null ? '' : _dateFormat.format(date.toLocal());

String formatDay(DateTime? date) => date == null ? '' : _dayFormat.format(date.toLocal());
