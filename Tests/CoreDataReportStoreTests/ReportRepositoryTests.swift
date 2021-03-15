//
//  ReportRepositoryTests.swift
//
//
//  Created by Igor Malyarov on 10.03.2021.
//

import XCTest
@testable import Store
@testable import CoreDataTengizReportSP
@testable import TengizReportModel
@testable import TextReports
@testable import CoreDataReportStore

class ReportRepositoryTests: XCTestCase {
    var repository: ReportRepository!

    override func setUpWithError() throws {
        let stack = CoreDataStack(inMemory: true)
        repository = ReportRepository(context: stack.context)
    }

    func testEmptyRepository() throws {
        let expectation = expectation(description: String(describing: #function))
        _ = repository.fetchAll()
            .sink { completion in
                switch completion {
                    case .failure(_): XCTFail("Should not receive error.")
                    case .finished: expectation.fulfill()
                }
            } receiveValue: { value in
                XCTAssert(value.isEmpty)
            }

        waitForExpectations(timeout: 2)
    }

    // reflection.update(with: object) us used in insert(_ object: Object) =>
    // if insert + fetchAll works ok =>
    // update(with: object) is ok, no need for separate test
    func testInsertFetchDelete() throws {
        let expectation = expectation(description: String(describing: #function))

        let contentSaperavi_2021_01 = try ContentLoader.contentsOfSampleFile(named: ContentLoader.saperavi_2021_01).get()
        let reportSaperavi_2021_01 = try TokenizedReport(stringLiteral: contentSaperavi_2021_01).report().get()

        let contentSaperavi_2021_02 = try ContentLoader.contentsOfSampleFile(named: ContentLoader.saperavi_2021_02).get()
        let reportSaperavi_2021_02 = try TokenizedReport(stringLiteral: contentSaperavi_2021_02).report().get()

        _ = repository
            // check repository is empty
            .fetchAll()
            .tryFilter { reports in
                XCTAssert(reports.isEmpty, "Repository should be empty.")
                if reports.isEmpty {
                    return true
                } else {
                    struct NonEmptyRepository: Error {}
                    throw NonEmptyRepository()
                }
            }
            // insert
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_02)
            }
            .flatMap { _ in
                self.repository.fetchAll()
            }
            .tryFilter { reports in
                XCTAssertEqual(reports.count, 1, "Should be one report in the Repository after insert.")
                XCTAssertEqual(reports, [reportSaperavi_2021_02])
                if reports.count == 1 {
                    return true
                } else {
                    struct InsertOrFetchError: Error {}
                    throw InsertOrFetchError()
                }
            }
            // delete
            .flatMap { _ in
                self.repository.delete(reportSaperavi_2021_02)
            }
            .flatMap { _ in
                self.repository.fetchAll()
            }
            .tryFilter { reports in
                XCTAssert(reports.isEmpty, "Repository should be empty after delete.")
                if reports.isEmpty {
                    return true
                } else {
                    struct NonEmptyRepository: Error {}
                    throw NonEmptyRepository()
                }
            }
            // insert another
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_01)
            }
            // and another
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_01)
            }
            // and one more
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_01)
            }
            .flatMap { _ in
                self.repository.fetchAll()
            }
            .sink { completion in
                switch completion {
                    case .failure(_): XCTFail("Should not receive error.")
                    case .finished: expectation.fulfill()
                }
            } receiveValue: { reports in
                XCTAssertEqual(reports, [reportSaperavi_2021_01], "Insert should not add any duplicates.")
                XCTAssertEqual(reports.first?.month, 1)
                XCTAssertEqual(reports.first?.year, 2021)
            }

        waitForExpectations(timeout: 2)
    }

    func testInsertFetch() throws {
        let expectation = expectation(description: String(describing: #function))

        let contentSaperavi_2021_01 = try ContentLoader.contentsOfSampleFile(named: ContentLoader.saperavi_2021_01).get()
        let reportSaperavi_2021_01 = try TokenizedReport(stringLiteral: contentSaperavi_2021_01).report().get()

        let contentSaperavi_2021_02 = try ContentLoader.contentsOfSampleFile(named: ContentLoader.saperavi_2021_02).get()
        let reportSaperavi_2021_02 = try TokenizedReport(stringLiteral: contentSaperavi_2021_02).report().get()

        _ = repository
            // check repository is empty
            .fetchAll()
            .tryFilter { reports in
                XCTAssert(reports.isEmpty, "Repository should be empty.")
                if reports.isEmpty {
                    return true
                } else {
                    struct NonEmptyRepository: Error {}
                    throw NonEmptyRepository()
                }
            }
            // insert
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_02)
            }
            .flatMap { _ in
                self.repository.fetchAll()
            }
            .tryFilter { reports in
                XCTAssertEqual(reports.count, 1)
                if reports.count == 1 {
                    return true
                } else {
                    struct InsertOrFetchError: Error {}
                    throw InsertOrFetchError()
                }
            }
            // insert another
            .flatMap { _ in
                self.repository.insert(reportSaperavi_2021_01)
            }
            .flatMap { _ in
                self.repository.fetchAll()
            }
            .sink { completion in
                switch completion {
                    case .failure(_): XCTFail("Should not receive error.")
                    case .finished: expectation.fulfill()
                }
            } receiveValue: { reports in
                XCTAssertEqual(reports.count, 2, "One report should be added to repository.")
            }

        waitForExpectations(timeout: 2)
    }

}
