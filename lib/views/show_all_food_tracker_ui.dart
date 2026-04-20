import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:flutter_food_tracker_app/views/add_food_tracker_ui.dart';
import 'package:flutter_food_tracker_app/models/task.dart';
import 'package:flutter_food_tracker_app/views/update_delete_food_tracker_ui.dart';


class ShowAllFoodTrackerUi extends StatefulWidget {
  const ShowAllFoodTrackerUi({super.key});

  @override
  State<ShowAllFoodTrackerUi> createState() => _ShowAllFoodTrackerUiState();
}

class _ShowAllFoodTrackerUiState extends State<ShowAllFoodTrackerUi> {
  // สร้าง instance/ตัวแทน/object ของ SupabaseService
  final service = SupabaseService();

  // สร้างตัวแปรเพื่อเก็บข้อมูลที่ได้จากการดึงข้อมูลจาก Supabase
  List<Task> tasks = [];

  // สร้างเมธอดเพื่อเรียกใช้งาน service ดึงข้อมูลมาเก็บในตัวแปร
  void loadTasks() async {
    final data = await service.getTasks();
    setState(() {
      tasks = data;
    });
  }

  @override
  initState() {
    super.initState();
    // เรียกใช้งานเมธอดเพื่อดึงข้อมูล ตอนหน้าจอถูกเปิดขึ้นมา
    loadTasks();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ส่วนของ Appbar
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text(
            'Food Tracker',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        // ส่วนของปุ่มเปิดไปหน้าเพิ่ม task
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddFoodTrackerUi(),
              ),
            );
          },
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        //ส่วนของตำแหน่งของปุ่มเปิดไปหน้าเพิ่ม task
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        //ส่วนของ body ที่แสดงโลโก้และข้อมูลที่ดึงจาก supabase
        body: Center(
          child: Column(
            children: [
              // แสดง logo
              SizedBox(height: 40),
              Image.asset(
                'assets/images/burgerlogo.png',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              // ส่วนของ ListView ที่แสดงข้อมูลที่ดึงจาก Supabase
              Expanded(
                child: ListView.builder(
                    // จำนวนรายการ
                    itemCount: tasks.length,
                    // หน้าตาของแต่ละรายการ
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 35,
                          right: 35,
                        ),
                        child: ListTile(
                          onTap: () {},
                          leading: (tasks[index].foodImageUrl != null &&
                                  tasks[index].foodImageUrl != "")
                              ? Image.network(
                                  tasks[index].foodImageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/burgerlogo.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                          title: Text(
                            'กิน: ${tasks[index].foodName}',
                          ),
                          subtitle: Text(
                            'วันที่: ${tasks[index].foodDate} มื้อ: ${tasks[index].foodMeal}',
                          ),
                          
                          trailing: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateDeleteFoodTrackerUi(
                                    task: tasks[index],
                                  ),
                                ),
                              ).then((value){
                                loadTasks();
                              });
                            },
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.red,
                            ),
                          ),
                          tileColor: index % 2 == 0 ? Colors.pink[50] : Colors.green[100],
                          contentPadding: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
        )
    );
  }
}