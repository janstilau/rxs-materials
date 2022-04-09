import Foundation

// 感觉这个方法 和 文件是没有必要的, 徒增复杂度.
// 专门这样写, 是为了, 统一 make 这种使用方式. 
public func makeURL() -> URL {
  
  return URL(string: "http://www.koober.com/avatar/johnnya")!
}
