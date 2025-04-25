import 'dart:convert';
import 'package:flutter/material.dart';

/// 编码处理工具类，用于解决中文编码问题
class EncodingHelper {
  /// 尝试修复可能被错误编码的字符串
  static String fixEncoding(dynamic input) {
    if (input == null) return '';
    
    if (input is! String) {
      return input.toString();
    }
    
    final String str = input;
    
    // 如果字符串看起来正常，直接返回
    if (!_hasEncodingIssues(str)) {
      return str;
    }
    
    // 尝试各种编码转换方法
    try {
      // 方法1: 使用utf8.decode
      try {
        final result = utf8.decode(str.codeUnits, allowMalformed: true);
        if (!_hasEncodingIssues(result)) {
          debugPrint('方法1修复成功: $str -> $result');
          return result;
        }
      } catch (e) {
        // 忽略错误，尝试下一个方法
      }
      
      // 方法2: latin1 -> utf8转换
      try {
        final bytes = latin1.encode(str);
        final result = utf8.decode(bytes, allowMalformed: true);
        if (!_hasEncodingIssues(result)) {
          debugPrint('方法2修复成功: $str -> $result');
          return result;
        }
      } catch (e) {
        // 忽略错误，尝试下一个方法
      }
      
      // 方法3: 手动替换一些常见的错误编码模式
      final result = _manualReplacements(str);
      if (result != str) {
        debugPrint('方法3修复成功: $str -> $result');
        return result;
      }
    } catch (e) {
      debugPrint('编码修复失败: $e');
    }
    
    // 如果所有方法都失败，返回原始字符串
    return str;
  }
  
  /// 检查字符串是否可能有编码问题
  static bool _hasEncodingIssues(String str) {
    // 检查一些常见的错误编码模式
    return str.contains('�') || 
           str.contains('Ã') || 
           str.contains('é') ||
           str.contains('Ä') ||
           str.contains('Â') ||
           str.contains('Æ') ||
           str.contains('Ø');
  }
  
  /// 手动替换一些常见的错误编码模式
  static String _manualReplacements(String str) {
    var result = str;
    
    // 添加常见的错误编码替换
    final Map<String, String> replacements = {
      'é¿ä¼': '阿飞',
      'æå': '成功',
      // 可以根据应用中出现的具体乱码添加更多替换项
    };
    
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
} 