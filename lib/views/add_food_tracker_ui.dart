import 'package:flutter/material.dart';
import 'dart:typed_data'; // ใช้ตัวนี้แทน dart:io เพื่อให้รันบน Web ได้
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:flutter_food_tracker_app/models/task.dart';

class AddFoodTrackerUi extends StatefulWidget {
  const AddFoodTrackerUi({super.key});

  @override
  State<AddFoodTrackerUi> createState() => _AddFoodTrackerUiState();
}

class _AddFoodTrackerUiState extends State<AddFoodTrackerUi> {
  // สร้างตัวควบคุม textfeild และตัวแปรที่จะต้องเก็บข้อมูลที่ผู้ใช้ป้อนหรือเลือก
  TextEditingController foodNameCtrl = TextEditingController();
  TextEditingController foodPersonCtrl = TextEditingController();
  TextEditingController foodDateCtrl = TextEditingController();
  TextEditingController foodPriceCtrl = TextEditingController();
  String? foodMeal = 'เช้า';
  String? foodImageUrl = '';

  // ตัวแปรเก็บไฟล์รูปภาพแบบ Bytes เพื่อให้รองรับการทำงานบน Web
  Uint8List? imageBytes;
  String? imageName;

  //---- เปิดกล้อง/คลังภาพ และกำหนดค่ารูปเพื่อ upload ----
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);

    if (picked != null) {
      final bytes = await picked.readAsBytes(); // อ่านไฟล์เป็น Byte
      setState(() {
        imageBytes = bytes;
        imageName = picked.name; // เก็บชื่อไฟล์ไว้ใช้อัปโหลด
      });
    }
  }
  //-------------------------

  //---- เปิดปฏิทินเลือกวันที่ และกำหนดค่าวันที่ ----
  DateTime? selectedDate;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        foodDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> save() async {
    // Validate UI ว่าผู้ใช้งานป้อนหรือเลือกข้อมูลครบถ้วนหรือยัง ถ้ายังแสดงข้อความแจ้ง
    if (foodNameCtrl.text.isEmpty ||
        foodDateCtrl.text.isEmpty ||
        foodPersonCtrl.text.isEmpty ||
        foodMeal == null ||
        foodPriceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาป้อนข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return; //*** อย่าลืม return เพื่อไม่ให้ทำงานต่อ หรือ ให้ออกจากการทำงานของเมธอดนี้เลย
    }

    // สร้าง instance/object/ตัวแทน ของ SupabaseService เพื่อใช้งานเมธอดต่างๆ ที่สร้างไว้
    final service = SupabaseService();

    // ตรวจสอบว่ามีการถ่าย/เลือกรูปหรือไม่ ถ้ามีก็อัปโหลดไฟล์ ไปที่ task_bk
    // แล้วเอา URL ของไฟล์ที่อัปโหลดเก็บในตัวแปรเพื่อใช้บันทึกใน task_tb
    if (imageBytes != null && imageName != null) {
      //อัปโหลดไฟล์รูปแบบ Bytes ไปยัง task_bk
      foodImageUrl = await service.uploadFile(imageBytes!, imageName!);
    }

    // บันทึกข้อมูลลง task_tb
    // แพ็กข้อมูล
    final task = Task(
      foodName: foodNameCtrl.text,
      foodPerson: int.parse(foodPersonCtrl.text),
      foodDate: foodDateCtrl.text,
      foodMeal: foodMeal,
      foodPrice: double.parse(foodPriceCtrl.text),
      foodImageUrl: foodImageUrl,
    );
    // เรียกใช้เมธอด insertTask ที่สร้างไว้ใน SupabaseService เพื่อบันทึกข้อมูลลง task_tb
    await service.insertTask(task);

    // แจ้งผลการทำงาน
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกข้อมูลสำเร็จ'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // ย้อนกลับไปยังหน้าหลัก ShowAllTaskUi
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text(
            'Food Tracker (เพิ่ม)',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          )),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 45, right: 45, bottom: 50),
          child: Center(
            child: Column(
              children: [
                // ส่วนแสดงรูปและรูปกล้องเพื่อเปิดกล้อง
                imageBytes == null
                    ? InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          size: 150,
                          color: Colors.grey[300],
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Image.memory(
                          imageBytes!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                // ป้อนกินอะไร
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'กินอะไร',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: foodNameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น KFC, Pizza',
                  ),
                ),
                SizedBox(height: 20),
                // ป้อนกินมื้อไหน
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'กินมื้อไหน',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // ใช้ Array ในการสร้างปุ่ม เพื่อลดโค้ดซ้ำซ้อน
                  children: ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'].map((meal) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          foodMeal = meal;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            foodMeal == meal ? Colors.green : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        fixedSize: Size(
                          MediaQuery.of(context).size.width * 0.18,
                          45,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        meal,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                // ป้อนกินไปเท่าไหร่
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'กินไปเท่าไหร่',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: foodPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น 259',
                  ),
                ),
                SizedBox(height: 20),
                // ป้อนกินไปกี่คน
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'กินกันกี่คน',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: foodPersonCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น 3',
                  ),
                ),
                SizedBox(height: 20),
                // เลือกต้องเสร็จเมื่อไหร่ (วันไหน)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'กินไปวันไหน',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: foodDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น 2020-01-31',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () {
                    pickDate();
                  },
                ),
                // ปุ่มบันทึก
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    save();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      50,
                    ),
                  ),
                  child: Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // ปุ่มยกเลิก
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      foodDateCtrl.clear();
                      foodMeal = 'เช้า';
                      foodNameCtrl.clear();
                      foodPriceCtrl.clear();
                      foodPersonCtrl.clear();
                      imageBytes = null;
                      imageName = null;
                      foodImageUrl = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      50,
                    ),
                  ),
                  child: Text(
                    "ยกเลิก",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
