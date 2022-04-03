import Foundation

extension CodingUserInfoKey {
  static let contentIdentifier = CodingUserInfoKey(rawValue: "contentIdentifier")!
}

// EOEnvelope is the generic envelope that EONET returns upon query
// since the actual result is keyed and of a different type every time,
// we use Decodable's userInfo to let the caller know what the expected key is

// EOEnvelope 这个类, 将生成的逻辑, 封装到了自己的内部.

// 这种, 在 YD 的代码里面也有. 
struct EOEnvelope<Content: Decodable>: Decodable {
  
  let content: Content
  
  private struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int? = nil
    
    init?(stringValue: String) {
      self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
      return nil
    }
  }
  
  init(from decoder: Decoder) throws {
    guard let ci = decoder.userInfo[CodingUserInfoKey.contentIdentifier],
          let contentIdentifier = ci as? String,
          let key = CodingKeys(stringValue: contentIdentifier) else {
            throw EOError.invalidDecoderConfiguration
          }
    // 这一句话, 会将 Dict Key 值, 和 CodingKeys 里面的值进行绑定.
    // 使用 forKey 的时候, 只能是使用 CodingKeys 的对象才可以.
    // 使用这种方式, 可以实现自定义解析的效果了.
    // 关键就在于, CodingKeys(stringValue: contentIdentifier) 可以使用外在值, 进行特定 Key 对象的生成了.
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // 其实在这里, 就是使用 key 的 stringvalue, 去 dict 里面取值.
    content = try container.decode(Content.self, forKey: key)
  }
}
