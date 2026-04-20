// ไฟล์นี้ใช้สำหรับสร้างการทำงานต่าง ๆ กับ Supabase
// CRUD กับ Table -> Database (PostgreSQL) -> Supabase
// Upload/delete file กับ Bucket -> Storage -> Supabase

import 'dart:io';
import 'package:flutter_food_tracker_app/models/task.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  // สร้าง instance/ตัวแทน ของ Supabase เพื่อใช้งาน
  final supabase = Supabase.instance.client;

  // สร้างคำสั่ง/เมธอดการทำงานต่าง ๆ กับ Supabase
  // เมธอดดึงข้อมูลงานทั้งหมดจาก task_tb และรีเทิร์นค่าที่ได้จากการดึงไปใช้งาน
  Future<List<Task>> getTasks() async {
    // ดึงข้อมูลงานทั้งหมดจาก task_tb
    final data = await supabase.from('food_tracker_tb').select('*');
    // รีเทิร์นค่าที่ได้จากการดึงไปใช้งาน
    return data.map((task) => Task.fromJson(task)).toList();
  }

  // เมธอดอัปโหลดไฟล์ไปยัง task_bk (รองรับทั้ง Web และ Mobile)
  Future<String> uploadFile(Uint8List fileBytes, String fileName) async {
    // 1. ดึงแค่นามสกุลไฟล์ออกมา (เช่น png, jpg) จะได้ไม่ติดภาษาไทยมาด้วย
    String extension = 'png'; // ตั้งค่าเริ่มต้นเผื่อไว้
    if (fileName.contains('.')) {
      extension = fileName.split('.').last;
    }

    // 2. สร้างชื่อไฟล์ใหม่ใช้แค่ Timestamp + นามสกุลไฟล์ (รับรองว่าไม่มีภาษาไทยปนแน่นอน)
    final newFileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';

    // ใช้ uploadBinary สำหรับอัปโหลด byte data
    await supabase.storage
        .from('food_tracker_bk')
        .uploadBinary(newFileName, fileBytes);

    // return ค่าข้อมูลที่ได้จากการอัปโหลดไปใช้งาน
    return supabase.storage.from('food_tracker_bk').getPublicUrl(newFileName);
  }

  // เมธอดเพิ่มข้อมูลไปยัง task_tb
  Future insertTask(Task task) async {
    await supabase.from('food_tracker_tb').insert(task.toJson());
  }
  // เมธอดลบไฟล์ที่อัปโหลดไปยัง task_bk
  Future deleteFile(String fileName) async {
    // ลบไฟล์ที่อัปโหลดไปยัง task_bk
    // ก่อนลบให้ตัดเลือกแค่ชื่อไฟล์ ไม่เอาที่อยู่ไฟล์
    fileName = fileName.split('/').last;
    await supabase.storage.from('food_tracker_bk').remove([fileName]);
  }

  // เมธอดแก้ไขข้อมูลใน task_tb
    Future updateTask(String id, Task task) async {
    await supabase.from('food_tracker_tb').update(task.toJson()).eq('id', id);
  } 

  // เมธอดลบข้อมูลใน task_tb
    Future deleteTask(String id, Task task) async {
    await supabase.from('food_tracker_tb').delete().eq('id', id);
  } 
}
