import Foundation
import ZIPFoundation

extension Archive {
    func extractArchive(from entry: Entry) throws -> Archive? {
        var archiveData = Data()
        _ = try self.extract(entry) { data in
            archiveData.append(data)
        }
        let archive = try Archive(data: archiveData, accessMode: .read)
        return archive
    }
}
