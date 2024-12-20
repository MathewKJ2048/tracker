import 'package:flutter/material.dart';
import 'dart:developer' as devlog;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';

const DefaultColor = Colors.black;
const AccentColor = Color.fromARGB(255, 42, 42, 42);
const MainColor = Colors.white;
const HueColor = Colors.cyan;

String default_text = '{"config":{"0":{"name":"0_event","time":"0000"},"1":{"name":"1_event","time":"0001"}},"data":{}}';

const String rootPath = '/storage/emulated/0';
const String adminPath = "$rootPath/Administration";
const String filePath = "$adminPath/tracker.json";

void save_file(parsedObject)
{
  String toWrite = jsonEncode(parsedObject);
  File(filePath).writeAsStringSync(toWrite);
}
String get_date_string(date_obj)
{
  return date_obj.toString().split(" ")[0];
}
String get_day(date_obj)
{
  List days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
  return days[date_obj.weekday%7];
}
void add_date_entry(date,jsonObj)
{
  if(!jsonObj.containsKey(date))jsonObj[date] = [];
  // tell(jsonObj);
}
bool check_presence(int event_index, String date, jsonObj)
{
  if(!jsonObj.containsKey(date))return false;
  var event_list = jsonObj[date];
  for(var e in event_list)
  {
    if(e.toString() == event_index.toString())return true;
  }
  return false;
}
bool set_presence(int event_index, String date, jsonObj, bool value)
{
  if(!jsonObj.containsKey(date))return false;
  if(value && !check_presence(event_index, date, jsonObj))
  {
    jsonObj[date].add(event_index);
  }
  else if(!value && check_presence(event_index, date, jsonObj))
  {
    return jsonObj[date].remove(event_index);
  }
  return true;
}

void tell(Object? q){devlog.log(q.toString());}
void auxFilePermission()
{
  Permission.manageExternalStorage.request().whenComplete((){
    return;
  });
}
String resolveFiles()
{  
  final adminDir = Directory(adminPath);
  if(!adminDir.existsSync())adminDir.createSync();
  final File dataFile = File(filePath);
  if(!dataFile.existsSync())dataFile.createSync();
  if(dataFile.readAsStringSync().isEmpty)dataFile.writeAsStringSync(default_text);
  return dataFile.readAsStringSync();
}
Map<String, dynamic> parse(json_data)
{
  return jsonDecode(json_data);
}

Widget getListText(text)
{
  return Text(text,
      style: const TextStyle(
      color: MainColor,
      fontSize: 16,
      )
    );
}
Widget getCheckBox(value, onChanged)
{
  return Checkbox(
  value: value, 
  onChanged: onChanged,
  activeColor: HueColor,
  side: const BorderSide(color: MainColor),
  );
}
Widget getTaskItem(taskName, taskCompleted, onChanged)
{
  return Padding
  (
    padding: const EdgeInsets.only(
      left: 4,
      right: 4,
      top: 4,
      bottom: 0
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AccentColor,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        children: 
        [
          getCheckBox(taskCompleted, onChanged),
          getListText(taskName),
        ],
      )
    ),
  );
}


class HomePage extends StatefulWidget
{
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> 
{

  Map<String, dynamic>? parsedData;
  DateTime? date;
  void dateReset()
  {
    setState(() {
      date = DateTime.now();
    });
  }
  void dateChanged(int amt)
  {
    setState(() {
      date = date?.add(Duration(days: amt));
      add_date_entry(get_date_string(date),parsedData!["data"]);  
    });
  }
  void checkBoxChanged(int index, String date, parsedData)
  {
    setState(() {
      final jsonObj = parsedData["data"];
      bool p = check_presence(index, get_date_string(date), jsonObj);
      set_presence(index, get_date_string(date), jsonObj, !p);
      save_file(parsedData);
      // tell(jsonObj);
    });
  }
  @override
  void initState()
  {
    super.initState();
    auxFilePermission();
    parsedData = parse(resolveFiles());
    date = DateTime.now();
    add_date_entry(get_date_string(date),parsedData!["data"]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: getListText("${get_date_string(date)}    ${get_day(date)}"),
        centerTitle: false, 
        backgroundColor: AccentColor,
        actions: [
          IconButton(onPressed: ()=>dateChanged(-1), icon: const Icon(Icons.arrow_back)),
          IconButton(onPressed: ()=>dateReset(), icon: const Icon(Icons.replay_outlined)),
          IconButton(onPressed: ()=>dateChanged(1), icon: const Icon(Icons.arrow_forward))
        ],
      ),
      backgroundColor: DefaultColor,
      body: ListView.builder(
        itemCount: parsedData!["config"].length,
        itemBuilder: (BuildContext context, index)
        {
          return getTaskItem(
            parsedData!["config"][index.toString()]["name"],
            check_presence(index, get_date_string(date), parsedData!["data"]),
            (value) => checkBoxChanged(index,get_date_string(date),parsedData),
          );
        },
      )
    );
  }
}


class MyApp extends StatelessWidget 
{
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) 
  {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      );
  }
}

void main() 
{
  runApp(const MyApp());
}