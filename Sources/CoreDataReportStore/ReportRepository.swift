//
//  ReportRepository.swift
//  RBizReportApp
//
//  Created by Igor Malyarov on 10.03.2021.
//

import CoreData
import Store
import TengizReportModel
import CoreDataTengizReportSP

public typealias CDReport = CoreDataTengizReportSP.Report

final class ReportRepository: CoreDataStore<TokenizedReport.Report, CDReport>, ObservableObject {}

extension TokenizedReport.Report: CoreDataStorable {
    public typealias Reflection = CDReport

    public func reflection(in context: NSManagedObjectContext) -> CDReport? {
        let companyPredicate = NSPredicate(format: "%K == %@", #keyPath(CDReport.company_), self.company)
        let monthPredicate = NSPredicate(format: "%K == %@", #keyPath(CDReport.month_), NSNumber(value: self.month))
        let yearPredicate = NSPredicate(format: "%K == %@", #keyPath(CDReport.year_), NSNumber(value: self.year))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [companyPredicate,
                                                                            monthPredicate,
                                                                            yearPredicate])
        let request = CDReport.fetchRequest(predicate)
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            #warning("change to Result type and return error .objectNotFound")
            return nil
        }
    }

}

extension CDReport: CoreDataManageable {
    public typealias Object = TokenizedReport.Report

    #warning("return Result<updated CDReport, some Error>")
    #warning("write tests for this")
    public func update(with object: TokenizedReport.Report) {
        monthStr = object.monthStr
        month = object.month
        year = object.year
        company = object.company
        revenue = object.revenue
        dailyAverage = object.dailyAverage
        openingBalance = object.openingBalance
        balance = object.balance
        runningBalance = object.runningBalance
        totalExpenses = object.totalExpenses

        if let context = self.managedObjectContext {
            // delete existing groups
            // cascade delete would delete all Items
            groups.forEach(context.delete)

            // create new groups
            object.groups.forEach { objectGroup in
                let group = ReportGroup(context: context)
                group.report = self
                group.groupNumber = objectGroup.groupNumber
                group.title = objectGroup.title
                group.amount = objectGroup.amount
                if let target = objectGroup.target {
                    group.target = target
                }
                group.note = objectGroup.note

                objectGroup.items.forEach { objectItem in
                    let item = ReportItem(context: context)
                    item.group = group
                    item.title = objectItem.title
                    item.amount = objectItem.amount
                    item.itemNumber = objectItem.itemNumber
                    item.note = objectItem.note

                    #warning("TokenizedReport.Report.Group.Item has no member 'hasIssue'")
                    // item.hasIssue = $0.hasIssue
                }
            }
        }
    }

    public func object() -> TokenizedReport.Report {
        func transformItem(item: ReportItem) -> TokenizedReport.Report.Group.Item {
            TokenizedReport.Report.Group.Item(itemNumber: item.itemNumber,
                                              title: item.title,
                                              amount: item.amount,
                                              note: item.note)
        }

        func transformGroup(group: ReportGroup) -> TokenizedReport.Report.Group {
            TokenizedReport.Report.Group(groupNumber: group.groupNumber,
                                         title: group.title,
                                         amount: group.amount,
                                         target: group.target == 0 ? nil : group.target,
                                         items: group.items.map(transformItem))
        }

        return TokenizedReport.Report(monthStr: monthStr,
                                      month: month,
                                      year: year,
                                      company: company,
                                      revenue: revenue,
                                      dailyAverage: dailyAverage,
                                      openingBalance: openingBalance,
                                      balance: balance,
                                      runningBalance: runningBalance,
                                      totalExpenses: totalExpenses,
                                      groups: groups.map(transformGroup))
    }
}
