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

import Vapor
import Fluent

struct NewDinner: Content {
  let date: Date
  let location: String
}

struct DinnerController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let dinnersRoute = routes.grouped("dinners")

    dinnersRoute.get(":dinnerId", use: getDinner)
    dinnersRoute.post("new", use: create)
    dinnersRoute.put(":dinnerId", "invite", ":userId", use: inviteUser)
  }

  fileprivate func create(req: Request) throws -> EventLoopFuture<Dinner.Public> {
    throw Abort(.notImplemented)
  }

  fileprivate func getDinner(req: Request) throws -> EventLoopFuture<Dinner.Public> {
    guard let dinnerId = req.parameters.get("dinnerId", as: UUID.self) else {
        throw Abort(.badRequest)
    }

    return Dinner.query(on: req.db)
      .filter(\.$id == dinnerId)
      .with(\.$invitees)
      .with(\.$host)
      .first()
      .unwrap(or: Abort(.notFound))
      .flatMapThrowing { try $0.asPublic() }
  }

  fileprivate func inviteUser(req: Request) throws -> EventLoopFuture<Dinner.Public> {
    guard
      let dinnerId = req.parameters.get("dinnerId", as: UUID.self),
      let inviteeId = req.parameters.get("userId", as: UUID.self) else {
        throw Abort(.badRequest)
    }

    var dinner: Dinner!

    return queryDinner(dinnerId, req: req)
      .unwrap(or: Abort(.notFound))
      .flatMap { exDinner -> EventLoopFuture<User?> in
        dinner = exDinner
        return User.query(on: req.db)
          .filter(\.$id == inviteeId)
          .first()
    }
    .unwrap(or: Abort(.notFound))
    .flatMap { invitee in
      if dinner.invitees.contains(where: { $0.id == inviteeId }) {
        guard let publicDinner = try? dinner.asPublic() else {
          return req.eventLoop.future(error: Abort(.internalServerError))
        }

        return req.eventLoop.makeSucceededFuture(publicDinner)
      }

      return self.addInvitee(invitee: invitee, to: dinner, req: req)
    }
  }

  private func queryDinner(_ id: Dinner.IDValue, req: Request) -> EventLoopFuture<Dinner?> {
    Dinner.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$invitees)
      .with(\.$host)
      .first()
  }

  private func addInvitee(invitee: User, to dinner: Dinner, req: Request) -> EventLoopFuture<Dinner.Public> {
    dinner.$invitees.attach(invitee, on: req.db)
      .flatMap { dinner.save(on: req.db) } //update the
      .flatMap { dinner.$invitees.load(on: req.db) }
      .flatMapThrowing { _ in try dinner.asPublic() }
  }
}
