import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyBSjReQldADTToIhUaseroah1-HXXRiSC8', 
  );

  Future<String> generateMonthlyReport(List<Map<String, dynamic>> expenses) async {
    try {
      if (expenses.isEmpty) return "No expenses found for this month.";

      // Menukar data kepada teks yang mudah dibaca oleh AI
      final summary = expenses.map((e) => "- ${e['category']}: RM${e['amount']} (${e['date']})").join("\n");

      final prompt = '''
        Act as a professional financial advisor.
        Analyze these monthly expenses for the user:
        $summary
        
        Please provide a report in English with the following sections:
        1. TOTAL EXPENDITURE: Calculate the exact sum.
        2. KEY OBSERVATIONS: Identify the highest spending category and patterns.
        3. RISK ASSESSMENT: Mention any concerns.
        4. RECOMMENDATIONS: Provide 3 actionable tips to save money.

        Keep the tone encouraging and professional.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "AI failed to generate content.";
    } catch (e) {
      print("AiService Error: $e");
      return "Technical Error: Failed to reach AI Financial Advisor. Please check your API Key status.";
    }
  }
}