import Foundation
import SwiftUI
import os

enum LLMCalError: LocalizedError {
    case apiKeyMissing
    case scriptNotFound
    case scriptPermissionDenied
    case scriptExecutionFailed(String)
    case outputParsingFailed(String)
    case textEncodingFailed
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "请在设置中配置 Anthropic API Key"
        case .scriptNotFound:
            return "找不到脚本文件"
        case .scriptPermissionDenied:
            return "脚本文件权限不足"
        case .scriptExecutionFailed(let error):
            return "执行脚本失败：\(error)"
        case .outputParsingFailed(let error):
            return "解析输出失败：\(error)"
        case .textEncodingFailed:
            return "文本编码失败"
        }
    }
}

class ShellExecutor {
    static let shared = ShellExecutor()
    private let scriptURL: URL
    private let logger = Logger(subsystem: "com.llmcal.app", category: "ShellExecutor")
    
    private init() {
        let sourceURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // Utils
            .deletingLastPathComponent() // LLMCalApp
        scriptURL = sourceURL.appendingPathComponent("calendar.sh")
        
        logger.info("Script path: \(self.scriptURL.path)")
        
        // 检查脚本文件是否存在
        if FileManager.default.fileExists(atPath: self.scriptURL.path) {
            logger.info("Script file exists")
            // 设置脚本文件权限
            do {
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: self.scriptURL.path)
                logger.info("Script file permissions set")
            } catch {
                logger.error("Failed to set script permissions: \(error.localizedDescription)")
            }
        } else {
            logger.error("Script file does not exist")
        }
    }
    
    func execute(text: String) async throws -> String {
        logger.info("Executing script at: \(self.scriptURL.path)")
        logger.info("Input text: \(text)")
        
        // 检查脚本是否存在
        guard FileManager.default.fileExists(atPath: self.scriptURL.path) else {
            logger.error("Script not found at path: \(self.scriptURL.path)")
            throw LLMCalError.scriptNotFound
        }
        
        // 检查脚本权限
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.scriptURL.path)
        if let permissions = attributes?[.posixPermissions] as? NSNumber {
            let permissionsInt = permissions.intValue
            logger.info("Script permissions: \(String(format: "%o", permissionsInt))")
            
            // 检查是否有执行权限
            if permissionsInt & 0o111 == 0 {
                logger.error("Script does not have execute permissions")
                throw LLMCalError.scriptPermissionDenied
            }
        }
        
        // 获取 API Key
        guard let apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey"), !apiKey.isEmpty else {
            logger.error("API Key is missing")
            throw LLMCalError.apiKeyMissing
        }
        
        logger.info("API Key is set")
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // 对输入文本进行 Base64 编码
        guard let textData = text.data(using: .utf8),
              let encodedText = textData.base64EncodedString().data(using: .utf8) else {
            logger.error("Failed to encode input text")
            throw LLMCalError.textEncodingFailed
        }
        
        process.arguments = [self.scriptURL.path, String(data: encodedText, encoding: .utf8) ?? "", "--base64"]
        
        var environment = ProcessInfo.processInfo.environment
        environment["ANTHROPIC_API_KEY"] = apiKey
        environment["SELECTED_LLM"] = "claude"
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment["LANG"] = "en_US.UTF-8"
        environment["LC_ALL"] = "en_US.UTF-8"
        process.environment = environment
        
        logger.info("Process environment set: SELECTED_LLM=\(environment["SELECTED_LLM"] ?? ""), PATH=\(environment["PATH"] ?? "")")
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            logger.info("Starting process execution...")
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            logger.info("Process exit status: \(process.terminationStatus)")
            logger.info("Script output: \(output)")
            if !error.isEmpty {
                logger.error("Script error: \(error)")
            }
            
            if process.terminationStatus != 0 {
                logger.error("Process failed with status \(process.terminationStatus)")
                let errorMessage = !error.isEmpty ? error : output
                throw LLMCalError.scriptExecutionFailed(errorMessage)
            }
            
            // 检查输出是否包含成功消息
            if output.contains("成功：事件已添加到日历") {
                logger.info("Event added successfully")
                return output
            }
            
            // 检查是否包含错误信息
            if output.contains("错误：") {
                logger.error("Script returned error message")
                throw LLMCalError.scriptExecutionFailed(output)
            }
            
            // 如果没有明确的成功或错误信息，则认为是解析失败
            logger.error("Failed to parse script output")
            throw LLMCalError.outputParsingFailed(output)
            
        } catch let error as LLMCalError {
            logger.error("Script execution error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Script execution error: \(error.localizedDescription)")
            throw LLMCalError.scriptExecutionFailed(error.localizedDescription)
        }
    }
}
