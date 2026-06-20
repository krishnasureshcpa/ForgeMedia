import Foundation
import GRDB
import ForgeMediaDomain

/// Repository for MediaPreset CRUD.
public final class PresetRepository: @unchecked Sendable {
    private let db: DatabaseService

    public init(db: DatabaseService) {
        self.db = db
    }

    public func all() throws -> [MediaPreset] {
        try db.read { db in
            try MediaPreset.fetchAll(db)
        }
    }

    public func fetch(id: String) throws -> MediaPreset? {
        try db.read { db in
            try MediaPreset.fetchOne(db, key: id)
        }
    }

    public func upsert(_ preset: MediaPreset) throws {
        try db.write { db in
            try preset.upsert(db)
        }
    }

    public func delete(id: String) throws {
        try db.write { db in
            try MediaPreset.deleteOne(db, key: id)
        }
    }
}