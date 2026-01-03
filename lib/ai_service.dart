import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey:
        'AIzaSyAZDndomHxDQ9x-yINYocpWJIEUvTB4xJc', // ⚠️ move this to env later
  );

  Future<String> generateMonthlyReport(
    List<Map<String, dynamic>> expenses,
  ) async {
    if (expenses.isEmpty) {
      return "No expenses found for this month.";
    }

    // 1️⃣ Convert expenses into readable text
    final expenseSummary = expenses
        .map((e) => "${e['category']}: RM${e['amount']}")
        .join(", ");

    // 2️⃣ Prompt for Gemini
    final prompt =
        '''
Act as a financial advisor.

Analyze these monthly expenses:
$expenseSummary

Provide:
1. Total expenditure
2. Key observations
3. Risk alert
4. Recommendations

Keep it concise and user-friendly.
''';

    // 3️⃣ Call Gemini
    final response = await model.generateContent([Content.text(prompt)]);

    return response.text ?? "Could not generate report.";
  }
}
