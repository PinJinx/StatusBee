import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StatusBee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: '🐝StatusBee'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
List<String> formats = [];
List<String> formatNames = [];

  late List<DropdownMenuEntry<String>> formatEntry;
  List<Widget> fields = [];
  String outputText = "";
  String format = "";
  String copyText = "Copy";
  int fieldNum = 0;

  List<TextEditingController> fieldControllers = [];

  @override
  void initState() {
    super.initState();
    loadFormats();
    formatEntry = buildDropdownEntries();
  }

  List<DropdownMenuEntry<String>> buildDropdownEntries() {
    return [
      for (int i = 0; i < formatNames.length; i++)
        DropdownMenuEntry(label: formatNames[i], value: i.toString())
    ];
  }

  Future<void> loadFormats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get saved formats and names or fallback to default
    formats = prefs.getStringList('formats') ?? [
      "Nama Shivaya,\n\nWorkDone:\n<field1>\n\nWork Planned:\n<field2>\n\nRegards,\n<field3>",
    ];

    formatNames = prefs.getStringList('formatNames') ?? ["Amfoss Default"];
    
    formatEntry = buildDropdownEntries();
    setState(() {}); // Refresh UI
  }

  Future<void> saveFormats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('formats', formats);
    await prefs.setStringList('formatNames', formatNames);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choose Format", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownMenu<String>(
              onSelected: (value) {
                setState(() {
                  format = formats[int.parse(value!)];
                  fieldNum = format.split("field").length - 1;
                  if (fieldNum > 0) {
                    fieldControllers = buildController(fieldNum);
                    fields = setFields(fieldNum);
                    outputText = getOutput(format, fieldControllers);
                  }
                });
              },
              dropdownMenuEntries: formatEntry,
              width: MediaQuery.of(context).size.width,
            ),
            const SizedBox(height: 20),
            Column(children: fields),
            const SizedBox(height: 24),
            const Text("Output", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[400]!),
              ),
              width: double.infinity,
              child: Text(
                outputText.isEmpty ? "Your output will appear here." : outputText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 16,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () => copyToClipBoard(outputText),
                    icon: const Icon(Icons.copy),
                    label: Text(copyText),
                  ),
                  FloatingActionButton.extended(
                    onPressed: () => showAddFormatDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Format"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextEditingController> buildController(int count) {
    return List.generate(count, (_) => TextEditingController());
  }

  List<Widget> setFields(int count) {
    return List.generate(
      count,
      (i) => _buildLabeledField("field${i + 1}", "Enter field ${i + 1}", fieldControllers[i]),
    );
  }

  Future<void> copyToClipBoard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => copyText = "Copied");
    await Future.delayed(const Duration(seconds: 1));
    setState(() => copyText = "Copy");
  }

  Widget _buildLabeledField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
            onChanged: (_) {
              setState(() {
                outputText = getOutput(format, fieldControllers);
              });
            },
          ),
        ],
      ),
    );
  }

  void showAddFormatDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController formatController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Format"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Format Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formatController,
                decoration: const InputDecoration(
                  labelText: "Format Body (use <field1>, <field2>, ...)",
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && formatController.text.isNotEmpty) {
                setState(() {
                  formatNames.add(nameController.text);
                  formats.add(formatController.text);
                  formatEntry = buildDropdownEntries();
                });
                await saveFormats();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}




// Utility Methods

List<String> setPredefinedFormats() {
  return [
    "Nama Shivaya,\n\nWorkDone:\n<field1>\n\nWork Planned:\n<field2>\n\nRegards,\n<field3>",
  ];
}

List<String> setPredefinedFormatNames() {
  return ["Amfoss Default"];
}

String getOutput(String format, List<TextEditingController> controllers) {
  String result = format;
  for (int i = 0; i < controllers.length; i++) {
    if(controllers[i].text.isNotEmpty){
      result = result.replaceAll("<field${i + 1}>", controllers[i].text);
    }
  }
  return result;
}