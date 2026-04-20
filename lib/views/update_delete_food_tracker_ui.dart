import 'package:flutter/material.dart';
import 'dart:typed_data'; // ใช้ตัวนี้แทน dart:io เพื่อให้รันบน Web ได้
import 'package:flutter_food_tracker_app/models/task.dart';
import 'package:flutter_food_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class UpdateDeleteFoodTrackerUi extends StatefulWidget {
  final Task? task;
  UpdateDeleteFoodTrackerUi({super.key, this.task});

  @override
  State<UpdateDeleteFoodTrackerUi> createState() =>
      _UpdateDeleteFoodTrackerUiState();
}

class _UpdateDeleteFoodTrackerUiState extends State<UpdateDeleteFoodTrackerUi> {
  TextEditingController foodNameCtrl = TextEditingController();
  TextEditingController foodPersonCtrl = TextEditingController();
  TextEditingController foodDateCtrl = TextEditingController();
  TextEditingController foodPriceCtrl = TextEditingController();
  String? foodMeal = 'เช้า';
  String? foodImageUrl = '';

  // ตัวแปรเก็บไฟล์รูปภาพแบบ Bytes เพื่อให้รองรับการทำงานบน Web
  Uint8List? imageBytes;
  String? imageName;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      foodNameCtrl.text = widget.task!.foodName ?? '';
      foodPersonCtrl.text = widget.task!.foodPerson.toString();
      foodDateCtrl.text = widget.task!.foodDate ?? '';
      foodPriceCtrl.text = widget.task!.foodPrice.toString();
      foodMeal = widget.task!.foodMeal;
      foodImageUrl = widget.task!.foodImageUrl;
    }
  }

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

  Future<void> update() async {
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
      return;
    }

    final service = SupabaseService();

    // ถ้ามีการเลือกรูปใหม่ (imageBytes ไม่เป็น null)
    if (imageBytes != null && imageName != null) {
      // ลบรูปเก่าออกก่อน (ถ้ามีรูปเก่า)
      if (widget.task!.foodImageUrl != null &&
          widget.task!.foodImageUrl != '') {
        await service.deleteFile(widget.task!.foodImageUrl!);
      }
      // อัปโหลดรูปใหม่แบบ Bytes
      foodImageUrl = await service.uploadFile(imageBytes!, imageName!);
    }

    final task = Task(
      id: widget.task!.id,
      foodName: foodNameCtrl.text,
      foodPerson: int.parse(foodPersonCtrl.text),
      foodDate: foodDateCtrl.text,
      foodMeal: foodMeal,
      foodPrice: double.parse(foodPriceCtrl.text),
      foodImageUrl: foodImageUrl,
    );

    await service.updateTask(widget.task!.id!, task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกการแก้ไขสำเร็จ'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> delete() async {
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              title: Text('ยืนยันการลบข้อมูล'),
              content: Text('คุณต้องการลบข้อมูลใช่หรือไม่ ?'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final service = SupabaseService();
                    if (widget.task!.foodImageUrl != null &&
                        widget.task!.foodImageUrl != '') {
                      await service.deleteFile(widget.task!.foodImageUrl!);
                    }
                    await service.deleteTask(widget.task!.id!, widget.task!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ลบข้อมูลสําเร็จ'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text('ตกลง'),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text(
            'Food Tracker (แก้ไข/ลบ)',
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
          padding: EdgeInsets.only(top: 30, left: 45, right: 45, bottom: 50),
          child: Center(
            child: Column(
              children: [
                // ตรรกะการแสดงรูป: เช็กรูปใหม่ (imageBytes) ก่อน ถ้าไม่มีให้ไปเช็กรูปเก่า (foodImageUrl)
                imageBytes == null
                    ? (foodImageUrl != null && foodImageUrl != ''
                        ? InkWell(
                            onTap: () {
                              pickImage();
                            },
                            child: Image.network(
                              foodImageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              pickImage();
                            },
                            child: Icon(
                              Icons.add_a_photo_rounded,
                              size: 150,
                              color: Colors.grey[300],
                            ),
                          ))
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    update();
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
                    "บันทึกแก้ไข",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    delete().then((value) {
                      Navigator.pop(context);
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
                    "ลบข้อมูล",
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
