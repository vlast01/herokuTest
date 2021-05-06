/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Fluent
import Vapor

final class Dinner: Model, Content {
  struct Public: Content {
    let id: UUID
    let date: Date
    let location: String
    let host: User.Public
    let invitees: [User.Public]
    let createdAt: Date?
    let updatedAt: Date?
  }
  
  static let schema = "dinners"
  
  @ID(key: "id")
  var id: UUID?
  
  @Field(key: "date")
  var date: Date
  
  @Field(key: "location")
  var location: String
  
  @Parent(key: "host_id")
  var host: User
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?
  
  @Siblings(through: DinnerInviteePivot.self, from: \.$dinner, to: \.$invitee)
  var invitees: [User]
  
  init() {}
  
  init(id: UUID? = nil, date: Date, location: String, hostId: User.IDValue) {
    self.id = id
    self.date = date
    self.$host.id = hostId
    self.location = location
  }
}

extension Dinner {
  func asPublic() throws -> Public {
    Public(id: try requireID(),
           date: date,
           location: location,
           host: try host.asPublic(),
           invitees: try invitees.map { try $0.asPublic() },
           createdAt: createdAt,
           updatedAt: updatedAt)
  }
}
