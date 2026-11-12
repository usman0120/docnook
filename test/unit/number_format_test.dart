import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';

String f(Object? value, String code) => NumberFormatter.format(value, code);

void main() {
  test('General', () {
    expect(f(42, 'General'), '42');
    expect(f(-7, 'General'), '-7');
    expect(f(3.5, 'General'), '3.5');
    expect(f(0.1 + 0.2, 'General'), '0.3');
    expect(f(1234567.891, 'General'), '1234567.891');
    expect(f(1e20, 'General'), '1E+20');
    expect(f(0.000000000123, 'General'), '1.23E-10');
    expect(f(123456789012, 'General'), '123456789012');
    expect(f(0, 'General'), '0');
    expect(f(5, ''), '5');
  });

  test('fixed decimals and grouping', () {
    expect(f(1234.567, '0'), '1235');
    expect(f(1234.567, '0.00'), '1234.57');
    expect(f(1234.567, '#,##0'), '1,235');
    expect(f(1234567.891, '#,##0.00'), '1,234,567.89');
    expect(f(-1234.5, '#,##0.00'), '-1,234.50');
    expect(f(0.5, '#,##0.00'), '0.50');
    expect(f(0.5, '#.##'), '.5');
    expect(f(12, '000'), '012');
    expect(f(1.5, '0.0##'), '1.5');
    expect(f(1.23456, '0.0##'), '1.235');
    expect(f(999, '#,##0'), '999');
    expect(f(-0.001, '0.00'), '0.00');
  });

  test('percent, thousands scaling and scientific', () {
    expect(f(0.256, '0%'), '26%');
    expect(f(0.256, '0.00%'), '25.60%');
    expect(f(1234567, '#,##0,'), '1,235');
    expect(f(1234567, '0.0,,"M"'), '1.2M');
    expect(f(12345, '0.00E+00'), '1.23E+04');
    expect(f(0.00012, '0.00E+00'), '1.20E-04');
  });

  test('currency, literals and sections', () {
    expect(f(1234.5, r'"$"#,##0.00'), r'$1,234.50');
    expect(f(1234.5, r'[$€-407] #,##0.00'), '€ 1,234.50');
    expect(f(1234.5, r'[$Rs-420]#,##0'), 'Rs1,235');
    expect(f(1234.5, '#,##0.00 "PKR"'), '1,234.50 PKR');
    expect(f(-1234.5, '#,##0.00;(#,##0.00)'), '(1,234.50)');
    expect(f(-5, '#,##0;[Red]-#,##0'), '-5');
    expect(f(0, '#,##0;-#,##0;"-"'), '-');
    expect(
      f(5, r'_($* #,##0.00_);_($* (#,##0.00);_($* "-"??_);_(@_)'),
      r' $5.00 ',
    );
    expect(f(1.5, r'0.0\ \k\g'), '1.5 kg');
  });

  test('text', () {
    expect(f('hello', 'General'), 'hello');
    expect(f('hello', '@'), 'hello');
    expect(f('hello', '0.00'), 'hello');
    expect(f('x', '0;-0;0;"<"@">"'), '<x>');
    expect(f(true, 'General'), 'TRUE');
    expect(f(const CellError('#N/A'), '0.00'), '#N/A');
    expect(f(null, '0.00'), '');
  });

  test('dates', () {
    // 45000 = 15 March 2023, a Wednesday.
    expect(f(45000, 'dd/mm/yyyy'), '15/03/2023');
    expect(f(45000, 'm/d/yy'), '3/15/23');
    expect(f(45000, 'd-mmm-yy'), '15-Mar-23');
    expect(f(45000, 'dddd, mmmm d, yyyy'), 'Wednesday, March 15, 2023');
    expect(f(45000, 'ddd'), 'Wed');
    expect(f(45000, 'yyyy-mm-dd'), '2023-03-15');
    expect(f(1, 'yyyy-mm-dd'), '1899-12-31');
    expect(f(-1, 'yyyy-mm-dd'), '########');
    expect(NumberFormatter.isDateFormat('dd/mm/yyyy'), isTrue);
    expect(NumberFormatter.isDateFormat('#,##0.00'), isFalse);
    expect(NumberFormatter.isDateFormat('General'), isFalse);
    expect(NumberFormatter.isDateFormat('"Day" 0'), isFalse);
  });

  test('times: m is minutes next to hours or seconds', () {
    expect(f(45000.5, 'dd/mm/yyyy hh:mm'), '15/03/2023 12:00');
    expect(f(0.75, 'h:mm AM/PM'), '6:00 PM');
    expect(f(0.25, 'h:mm:ss AM/PM'), '6:00:00 AM');
    expect(f(0, 'h:mm AM/PM'), '12:00 AM');
    expect(f(0.5104166667, 'hh:mm:ss'), '12:15:00');
    expect(f(0.000011574, 'mm:ss'), '00:01');
    expect(f(1.5, '[h]:mm:ss'), '36:00:00');
    expect(f(0.5000058, 'h:mm:ss.0'), '12:00:00.5');
    // Seconds that would round up carry into the minute instead of showing 60.
    expect(f(0.9999999, 'h:mm:ss'), '0:00:00');
  });

  test('1904 date system', () {
    expect(
      NumberFormatter.format(0, 'yyyy-mm-dd', date1904: true),
      '1904-01-01',
    );
  });

  test('built-in ids', () {
    expect(NumberFormatter.builtinCode(0), 'General');
    expect(NumberFormatter.builtinCode(4), '#,##0.00');
    expect(NumberFormatter.builtinCode(14), 'dd/mm/yyyy');
    expect(NumberFormatter.builtinCode(999), 'General');
  });
}
