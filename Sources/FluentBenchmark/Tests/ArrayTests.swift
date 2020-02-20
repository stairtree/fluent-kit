extension FluentBenchmarker {
    public func testArray() throws {
        struct Qux: Codable {
            var foo: String
        }

        final class Foo: Model {
            static let schema = "foos"

            struct _Migration: Migration {
                func prepare(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos")
                        .field("id", .uuid, .identifier(auto: false))
                        .field("bar", .array(of: .int), .required)
                        .field("baz", .array(of: .string))
                        .field("qux", .array(of: .json), .required)
                        .create()
                }

                func revert(on database: Database) -> EventLoopFuture<Void> {
                    return database.schema("foos").delete()
                }
            }

            @ID(key: .id)
            var id: UUID?

            @Field(key: "bar")
            var bar: [Int]

            @Field(key: "baz")
            var baz: [String]?

            @Field(key: "qux")
            var qux: [Qux]

            init() { }

            init(id: UUID? = nil, bar: [Int], baz: [String]?, qux: [Qux]) {
                self.id = id
                self.bar = bar
                self.baz = baz
                self.qux = qux
            }
        }

        try runTest(#function, [
            Foo._Migration(),
        ]) {
            let new = Foo(
                bar: [1, 2, 3],
                baz: ["4", "5", "6"],
                qux: [.init(foo: "7"), .init(foo: "8"), .init(foo: "9")]
            )
            try new.create(on: self.database).wait()

            guard let fetched = try Foo.find(new.id, on: self.database).wait() else {
                XCTFail("foo didnt save")
                return
            }
            XCTAssertEqual(fetched.bar, [1, 2, 3])
            XCTAssertEqual(fetched.baz, ["4", "5", "6"])
            XCTAssertEqual(fetched.qux.map { $0.foo }, ["7", "8", "9"])
        }
    }

    public func testSet() throws {
        try self.runTest(#function, [
            FooMigration(),
        ]) {
            let foo = Foo(bar: ["a", "b", "c"])
            try foo.create(on: self.database).wait()
            let fetched = try Foo.find(foo.id, on: self.database).wait()
            XCTAssertEqual(fetched?.bar, foo.bar)
        }
    }

    public func testArrayStringBackedEnum() throws {
        try self.runTest(#function, [
            UserMigration(),
        ]) {
            // test array w/ 2 values
            do {
                let user = User(roles: [.admin, .employee])
                try user.create(on: self.database).wait()
                let fetched = try User.find(user.id, on: self.database).wait()
                XCTAssertEqual(fetched?.roles, user.roles)
            }
            // test empty array
            do {
                let user = User(roles: [])
                try user.create(on: self.database).wait()
                let fetched = try User.find(user.id, on: self.database).wait()
                XCTAssertEqual(fetched?.roles, user.roles)
            }
        }
    }
}

private enum Role: String, Codable, Equatable {
    case admin
    case employee
    case client
}

private final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "roles")
    var roles: [Role]

    init() { }

    init(id: UUID? = nil, roles: [Role]) {
        self.id = id
        self.roles = roles
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field(.id, .uuid, .identifier(auto: false))
            .field("roles", .array(of: .string), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: "id")
    var id: UUID?

    @Field(key: "bar")
    var bar: Set<String>

    init() { }

    init(id: IDValue? = nil, bar: Set<String>) {
        self.id = id
        self.bar = bar
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .array(of: .string), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}