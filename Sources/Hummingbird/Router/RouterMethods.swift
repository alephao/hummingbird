//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2023 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes
import NIOCore

/// Conform to `RouterMethods` to add standard router verb (get, post ...) methods
public protocol RouterMethods<Context> {
    associatedtype Context: RequestContext

    /// Add responder to call when path and method are matched
    ///
    /// - Parameters:
    ///   - path: Path to match
    ///   - method: Request method to match
    ///   - responder: Responder to call if match is made
    /// - Returns: self
    @discardableResult func on<Responder: HTTPResponder>(
        _ path: RouterPath,
        method: HTTPRequest.Method,
        responder: Responder
    ) -> Self where Responder.Context == Context

    /// add group
    func group(_ path: RouterPath) -> RouterGroup<Context>

    /// add middleware
    func add(middleware: any RouterMiddleware<Context>) -> Self
}

extension RouterMethods {
    /// Add path for async closure
    @discardableResult public func on(
        _ path: RouterPath,
        method: HTTPRequest.Method,
        use closure: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        let responder = self.constructResponder(use: closure)
        self.on(path, method: method, responder: responder)
        return self
    }

    /// GET path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func get(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .get, use: handler)
    }

    /// PUT path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func put(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .put, use: handler)
    }

    /// DELETE path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func delete(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .delete, use: handler)
    }

    /// HEAD path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func head(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .head, use: handler)
    }

    /// POST path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func post(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .post, use: handler)
    }

    /// PATCH path for async closure returning type conforming to ResponseGenerator
    @discardableResult public func patch(
        _ path: RouterPath = "",
        use handler: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> Self {
        return self.on(path, method: .patch, use: handler)
    }

    internal func constructResponder(
        use closure: @Sendable @escaping (Request, Context) async throws -> some ResponseGenerator
    ) -> CallbackResponder<Context> {
        return CallbackResponder { request, context in
            let output = try await closure(request, context)
            return try output.response(from: request, context: context)
        }
    }

    internal func combinePaths(_ path1: String, _ path2: String) -> String {
        let path1 = path1.dropSuffix("/")
        let path2 = path2.dropPrefix("/")
        return "\(path1)/\(path2)"
    }
}
